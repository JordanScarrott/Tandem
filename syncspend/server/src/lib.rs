use spacetimedb::{table, reducer, view, Identity, Timestamp, ReducerContext, ViewContext, Table};

#[table(name = user_profile)]
pub struct UserProfile {
    #[primary_key]
    pub identity: Identity,
    pub display_name: String,
    pub default_currency: String, // "ZAR"
    pub billing_cycle_start_day: u8, // 1–31
    pub created_at: Timestamp,
}

#[table(name = category)]
pub struct Category {
    #[primary_key]
    #[auto_inc]
    pub id: u64,
    #[index(btree)]
    pub owner: Identity,
    pub name: String,
    pub icon: String, // SF Symbol name e.g. "cart.fill"
    pub color_hex: String, // e.g. "#10B981"
    pub monthly_budget_cents: Option<i64>,
    pub is_archived: bool,
}

#[table(name = couple_space)]
pub struct CoupleSpace {
    #[primary_key]
    #[auto_inc]
    pub id: u64,
    pub name: String,
    #[index(btree)]
    pub partner_a: Identity,
    #[index(btree)]
    pub partner_b: Identity,
    pub split_ratio_a: u8, // e.g. 50 (for 50/50) or 60 (for 60/40)
    pub split_ratio_b: u8,
    pub created_at: Timestamp,
}

#[table(name = couple_invite)]
pub struct CoupleInvite {
    #[primary_key]
    pub code: String, // 6-character code e.g. "XK92LM"
    pub space_id: u64,
    #[index(btree)]
    pub creator: Identity,
    pub expires_at: Timestamp,
    pub is_accepted: bool,
}

#[table(name = expense)]
pub struct Expense {
    #[primary_key]
    #[auto_inc]
    pub id: u64,
    #[index(btree)]
    pub owner: Identity,
    pub amount_cents: i64,
    pub currency: String,
    pub category_id: u64,
    pub payment_method: String,
    pub note: String,
    pub spent_at_millis: i64,
    pub created_at: Timestamp,
    pub updated_at: Timestamp,
    pub deleted_at: Option<Timestamp>,
    pub space_id: Option<u64>,
    pub split_mode: String, // "PERSONAL", "EQUAL", "PROPORTIONAL", "PAID_FOR_PARTNER"
}

#[table(name = expense_split)]
pub struct ExpenseSplit {
    #[primary_key]
    #[auto_inc]
    pub id: u64,
    #[index(btree)]
    pub expense_id: u64,
    #[index(btree)]
    pub space_id: u64,
    #[index(btree)]
    pub payer: Identity,
    pub partner_a_share_cents: i64,
    pub partner_b_share_cents: i64,
    pub created_at: Timestamp,
}

// --- Views ---

#[view(name = my_categories, public)]
pub fn my_categories(ctx: &ViewContext) -> Vec<Category> {
    ctx.db.category()
        .owner()
        .filter(&ctx.sender)
        .filter(|cat| !cat.is_archived)
        .collect()
}

#[view(name = my_expenses, public)]
pub fn my_expenses(ctx: &ViewContext) -> Vec<Expense> {
    let mut expenses: Vec<Expense> = ctx.db.expense()
        .owner()
        .filter(&ctx.sender)
        .filter(|e| e.deleted_at.is_none())
        .collect();

    let mut couple_spaces: Vec<CoupleSpace> = ctx.db.couple_space()
        .partner_a()
        .filter(&ctx.sender)
        .collect();

    couple_spaces.extend(
        ctx.db.couple_space()
            .partner_b()
            .filter(&ctx.sender)
    );

    let empty_partner = Identity::from_byte_array([0; 32]);
    for space in couple_spaces {
        let partner = if space.partner_a == ctx.sender {
            space.partner_b
        } else {
            space.partner_a
        };

        if partner != empty_partner {
            let partner_expenses = ctx.db.expense()
                .owner()
                .filter(&partner)
                .filter(|e| e.space_id == Some(space.id) && e.deleted_at.is_none());
            expenses.extend(partner_expenses);
        }
    }

    expenses
}

#[view(name = my_profile, public)]
pub fn my_profile(ctx: &ViewContext) -> Option<UserProfile> {
    ctx.db.user_profile().identity().find(ctx.sender)
}

#[view(name = my_couple_space, public)]
pub fn my_couple_space(ctx: &ViewContext) -> Option<CoupleSpace> {
    if let Some(space) = ctx.db.couple_space().partner_a().filter(&ctx.sender).next() {
        return Some(space);
    }
    ctx.db.couple_space().partner_b().filter(&ctx.sender).next()
}

// --- Auth Validation Helper ---

fn verify_caller_auth(ctx: &ReducerContext) -> Result<(), String> {
    if let Some(jwt) = ctx.sender_auth().jwt() {
        let issuer = jwt.issuer();
        // Allow SpacetimeDB OIDC issuer, maincloud/localhost identity token issuers
        if issuer != "https://auth.spacetimedb.com/oidc"
            && issuer != "https://maincloud.spacetimedb.com"
            && issuer != "localhost"
            && !issuer.ends_with(".spacetimedb.com") {
            return Err("Unauthorized token issuer".into());
        }
    }
    Ok(())
}

// --- Helper Functions ---

fn generate_invite_code(timestamp: Timestamp, sender: Identity, space_id: u64) -> String {
    let chars = b"ABCDEFGHJKLMNPQRSTUVWXYZ23456789"; // Base32 without ambiguous characters (0, O, 1, I)
    let ts_micros = timestamp.to_micros_since_unix_epoch();
    let mut hash = (ts_micros ^ (space_id as i64 * 31)) as u64;
    let sender_bytes = sender.to_byte_array();
    for (i, &byte) in sender_bytes.iter().enumerate() {
        hash = hash.wrapping_add((byte as u64) << ((i % 8) * 8));
    }

    let mut code = String::with_capacity(6);
    for _ in 0..6 {
        let idx = (hash % (chars.len() as u64)) as usize;
        code.push(chars[idx] as char);
        hash = hash.rotate_left(5) ^ 0x5bd1e9955bd1e995;
    }
    code
}

fn is_authorized_expense_actor(ctx: &ReducerContext, expense: &Expense) -> bool {
    if expense.owner == ctx.sender {
        return true;
    }
    if let Some(space_id) = expense.space_id {
        if let Some(space) = ctx.db.couple_space().id().find(space_id) {
            return space.partner_a == ctx.sender || space.partner_b == ctx.sender;
        }
    }
    false
}

// --- Reducers ---

#[reducer]
pub fn initialize_user_profile(
    ctx: &ReducerContext,
    display_name: String,
    default_currency: String,
    billing_cycle_start_day: u8,
) -> Result<(), String> {
    verify_caller_auth(ctx)?;

    if ctx.db.user_profile().identity().find(ctx.sender).is_some() {
        return Ok(()); // Already initialized
    }

    ctx.db.user_profile().insert(UserProfile {
        identity: ctx.sender,
        display_name,
        default_currency: default_currency.to_uppercase(),
        billing_cycle_start_day: billing_cycle_start_day.clamp(1, 28),
        created_at: ctx.timestamp,
    });

    // Seed default starter categories
    let starter_categories = [
        ("Groceries", "cart.fill", "#10B981", Some(600_000)), // R6,000 budget
        ("Dining & Coffee", "cup.and.saucer.fill", "#F59E0B", Some(250_000)), // R2,500
        ("Transport / Fuel", "fuelpump.fill", "#3B82F6", Some(200_000)), // R2,000
        ("Utilities", "bolt.fill", "#8B5CF6", None),
        ("Personal Fun", "sparkles", "#EC4899", Some(150_000)), // R1,500
    ];

    for (name, icon, color, budget) in starter_categories {
        ctx.db.category().insert(Category {
            id: 0,
            owner: ctx.sender,
            name: name.into(),
            icon: icon.into(),
            color_hex: color.into(),
            monthly_budget_cents: budget,
            is_archived: false,
        });
    }

    Ok(())
}

#[reducer]
pub fn create_category(
    ctx: &ReducerContext,
    name: String,
    icon: String,
    color_hex: String,
    monthly_budget_cents: Option<i64>,
) -> Result<(), String> {
    verify_caller_auth(ctx)?;

    if name.trim().is_empty() {
        return Err("Category name cannot be empty".into());
    }

    ctx.db.category().insert(Category {
        id: 0,
        owner: ctx.sender,
        name: name.trim().into(),
        icon,
        color_hex,
        monthly_budget_cents,
        is_archived: false,
    });

    Ok(())
}

#[reducer]
pub fn create_couple_space(
    ctx: &ReducerContext,
    name: String,
    split_ratio_a: u8,
    split_ratio_b: u8,
) -> Result<(), String> {
    verify_caller_auth(ctx)?;

    if split_ratio_a + split_ratio_b != 100 {
        return Err("Split ratios must sum to 100%".into());
    }

    let space = ctx.db.couple_space().insert(CoupleSpace {
        id: 0,
        name: if name.trim().is_empty() { "Couple Space".into() } else { name.trim().into() },
        partner_a: ctx.sender,
        partner_b: Identity::from_byte_array([0; 32]),
        split_ratio_a,
        split_ratio_b,
        created_at: ctx.timestamp,
    });

    let code = generate_invite_code(ctx.timestamp, ctx.sender, space.id);

    // 7 days expiration (7 * 24 * 60 * 60 * 1_000_000 microseconds)
    let expires_micros = ctx.timestamp.to_micros_since_unix_epoch() + (7 * 24 * 60 * 60 * 1_000_000);
    let expires_at = Timestamp::from_micros_since_unix_epoch(expires_micros);

    ctx.db.couple_invite().insert(CoupleInvite {
        code,
        space_id: space.id,
        creator: ctx.sender,
        expires_at,
        is_accepted: false,
    });

    Ok(())
}

#[reducer]
pub fn join_couple_space(ctx: &ReducerContext, invite_code: String) -> Result<(), String> {
    verify_caller_auth(ctx)?;

    let code_upper = invite_code.trim().to_uppercase();
    let mut invite = ctx.db.couple_invite().code().find(&code_upper)
        .ok_or("Invalid invite code")?;

    if invite.is_accepted {
        return Err("This invite has already been used".into());
    }

    if ctx.timestamp.to_micros_since_unix_epoch() > invite.expires_at.to_micros_since_unix_epoch() {
        return Err("Invite code has expired".into());
    }

    if invite.creator == ctx.sender {
        return Err("You cannot join your own couple space invite".into());
    }

    let mut space = ctx.db.couple_space().id().find(invite.space_id)
        .ok_or("Couple space not found")?;

    let empty_partner = Identity::from_byte_array([0; 32]);
    if space.partner_b != empty_partner {
        return Err("Couple space is already full".into());
    }

    space.partner_b = ctx.sender;
    ctx.db.couple_space().id().update(space);

    invite.is_accepted = true;
    ctx.db.couple_invite().code().update(invite);

    Ok(())
}

#[reducer]
pub fn update_split_ratios(
    ctx: &ReducerContext,
    space_id: u64,
    split_ratio_a: u8,
    split_ratio_b: u8,
) -> Result<(), String> {
    verify_caller_auth(ctx)?;

    if split_ratio_a + split_ratio_b != 100 {
        return Err("Split ratios must sum to 100%".into());
    }

    let mut space = ctx.db.couple_space().id().find(space_id)
        .ok_or("Couple space not found")?;

    if space.partner_a != ctx.sender && space.partner_b != ctx.sender {
        return Err("Unauthorized to modify this couple space".into());
    }

    space.split_ratio_a = split_ratio_a;
    space.split_ratio_b = split_ratio_b;
    ctx.db.couple_space().id().update(space);

    Ok(())
}

#[reducer]
pub fn log_expense(
    ctx: &ReducerContext,
    amount_cents: i64,
    currency: String,
    category_id: u64,
    payment_method: String,
    note: String,
    spent_at_millis: i64,
) -> Result<(), String> {
    verify_caller_auth(ctx)?;

    if amount_cents <= 0 {
        return Err("Amount must be greater than zero".into());
    }

    let category = ctx.db.category().id().find(category_id)
        .ok_or("Category not found")?;

    if category.owner != ctx.sender {
        return Err("Unauthorized category access".into());
    }

    ctx.db.expense().insert(Expense {
        id: 0,
        owner: ctx.sender,
        amount_cents,
        currency: currency.to_uppercase(),
        category_id,
        payment_method,
        note,
        spent_at_millis,
        created_at: ctx.timestamp,
        updated_at: ctx.timestamp,
        deleted_at: None,
        space_id: None,
        split_mode: "PERSONAL".into(),
    });

    Ok(())
}

#[reducer]
pub fn log_couple_expense(
    ctx: &ReducerContext,
    space_id: u64,
    amount_cents: i64,
    currency: String,
    category_id: u64,
    payment_method: String,
    note: String,
    spent_at_millis: i64,
    split_mode: String,
) -> Result<(), String> {
    verify_caller_auth(ctx)?;

    if amount_cents <= 0 {
        return Err("Amount must be greater than zero".into());
    }

    let space = ctx.db.couple_space().id().find(space_id)
        .ok_or("Couple space not found")?;

    let is_partner_a = space.partner_a == ctx.sender;
    let is_partner_b = space.partner_b == ctx.sender;

    if !is_partner_a && !is_partner_b {
        return Err("Unauthorized to log expense in this couple space".into());
    }

    let category = ctx.db.category().id().find(category_id)
        .ok_or("Category not found")?;

    let is_cat_owner = category.owner == ctx.sender || category.owner == space.partner_a || category.owner == space.partner_b;
    if !is_cat_owner {
        return Err("Unauthorized category access".into());
    }

    let (share_a_cents, share_b_cents) = match split_mode.to_uppercase().as_str() {
        "EQUAL" => {
            let half = amount_cents / 2;
            (half, amount_cents - half)
        }
        "PROPORTIONAL" => {
            let share_a = (amount_cents * space.split_ratio_a as i64 + 50) / 100;
            (share_a, amount_cents - share_a)
        }
        "PAID_FOR_PARTNER" => {
            if is_partner_a {
                (0, amount_cents)
            } else {
                (amount_cents, 0)
            }
        }
        _ => {
            // Default to PERSONAL / full payer share
            if is_partner_a {
                (amount_cents, 0)
            } else {
                (0, amount_cents)
            }
        }
    };

    let expense = ctx.db.expense().insert(Expense {
        id: 0,
        owner: ctx.sender,
        amount_cents,
        currency: currency.to_uppercase(),
        category_id,
        payment_method,
        note,
        spent_at_millis,
        created_at: ctx.timestamp,
        updated_at: ctx.timestamp,
        deleted_at: None,
        space_id: Some(space_id),
        split_mode: split_mode.to_uppercase(),
    });

    ctx.db.expense_split().insert(ExpenseSplit {
        id: 0,
        expense_id: expense.id,
        space_id,
        payer: ctx.sender,
        partner_a_share_cents: share_a_cents,
        partner_b_share_cents: share_b_cents,
        created_at: ctx.timestamp,
    });

    Ok(())
}

#[reducer]
pub fn soft_delete_expense(ctx: &ReducerContext, expense_id: u64) -> Result<(), String> {
    verify_caller_auth(ctx)?;

    let mut expense = ctx.db.expense().id().find(expense_id)
        .ok_or("Expense not found")?;

    if !is_authorized_expense_actor(ctx, &expense) {
        return Err("Unauthorized to delete this record".into());
    }

    expense.deleted_at = Some(ctx.timestamp);
    expense.updated_at = ctx.timestamp;
    ctx.db.expense().id().update(expense);

    Ok(())
}

#[reducer]
pub fn restore_expense(ctx: &ReducerContext, expense_id: u64) -> Result<(), String> {
    verify_caller_auth(ctx)?;

    let mut expense = ctx.db.expense().id().find(expense_id)
        .ok_or("Expense not found")?;

    if !is_authorized_expense_actor(ctx, &expense) {
        return Err("Unauthorized to restore this record".into());
    }

    expense.deleted_at = None;
    expense.updated_at = ctx.timestamp;
    ctx.db.expense().id().update(expense);

    Ok(())
}

#[reducer]
pub fn update_expense(
    ctx: &ReducerContext,
    expense_id: u64,
    amount_cents: i64,
    currency: String,
    category_id: u64,
    payment_method: String,
    note: String,
    spent_at_millis: i64,
    split_mode: String,
) -> Result<(), String> {
    verify_caller_auth(ctx)?;

    if amount_cents <= 0 {
        return Err("Amount must be greater than zero".into());
    }

    let mut expense = ctx.db.expense().id().find(expense_id)
        .ok_or("Expense not found")?;

    if !is_authorized_expense_actor(ctx, &expense) {
        return Err("Unauthorized to modify this record".into());
    }

    let category = ctx.db.category().id().find(category_id)
        .ok_or("Category not found")?;

    if let Some(space_id) = expense.space_id {
        let space = ctx.db.couple_space().id().find(space_id)
            .ok_or("Couple space not found")?;

        let is_cat_owner = category.owner == ctx.sender || category.owner == space.partner_a || category.owner == space.partner_b;
        if !is_cat_owner {
            return Err("Unauthorized category access".into());
        }

        let is_partner_a = expense.owner == space.partner_a;

        let (share_a_cents, share_b_cents) = match split_mode.to_uppercase().as_str() {
            "EQUAL" => {
                let half = amount_cents / 2;
                (half, amount_cents - half)
            }
            "PROPORTIONAL" => {
                let share_a = (amount_cents * space.split_ratio_a as i64 + 50) / 100;
                (share_a, amount_cents - share_a)
            }
            "PAID_FOR_PARTNER" => {
                if is_partner_a {
                    (0, amount_cents)
                } else {
                    (amount_cents, 0)
                }
            }
            _ => {
                if is_partner_a {
                    (amount_cents, 0)
                } else {
                    (0, amount_cents)
                }
            }
        };

        if let Some(mut split) = ctx.db.expense_split().expense_id().filter(&expense.id).next() {
            split.partner_a_share_cents = share_a_cents;
            split.partner_b_share_cents = share_b_cents;
            ctx.db.expense_split().id().update(split);
        }

        expense.split_mode = split_mode.to_uppercase();
    } else {
        if category.owner != ctx.sender {
            return Err("Unauthorized category access".into());
        }
        expense.split_mode = "PERSONAL".into();
    }

    expense.amount_cents = amount_cents;
    expense.currency = currency.to_uppercase();
    expense.category_id = category_id;
    expense.payment_method = payment_method;
    expense.note = note;
    expense.spent_at_millis = spent_at_millis;
    expense.updated_at = ctx.timestamp;

    ctx.db.expense().id().update(expense);

    Ok(())
}

