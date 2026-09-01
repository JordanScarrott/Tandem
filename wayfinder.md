Here is your Wayfinder sequence for **Milestone 2: Personal Ledger Power-Ups, Dedicated Categories & Soft Deletes**.

### Milestone 2 Execution Map

| Ticket | Scope | Deliverables |
| --- | --- | --- |
| **TICKET-02** *(Current)* | Backend (Rust) | `user_profile` table, `category` table with starter seeds, soft-delete (`deleted_at`), and `restore_expense` reducer. |
| **TICKET-03** | iOS Client | Category management, swipe-to-delete with haptic undo bar, and custom category creation. |
| **TICKET-04** | Backend (Rust) | `couple_space`, `couple_invite` (6-char pairing code), and `expense_split` proportional engine. |
| **TICKET-05** | iOS Client | Partner invite handshake sheet + "Yours, Mine, Ours" 3-way split toggle. |

---

### Copy-Paste Prompt for Your Agent: **TICKET-02**

```markdown
# Agent Ticket: TICKET-02 – Backend Categories, User Profiles & Soft Deletion

## Context
Iteration 1 verified single-user expense logging with hardcoded category strings. We now need a normalized relational model supporting:
1. Dynamic categories with icons, hex colors, and monthly budget limits.
2. User profile initialization that automatically seeds standard starter categories.
3. Safe soft-deletion (`deleted_at: Option<Timestamp>`) with an atomic restore/undo reducer.

---

## 1. Schema & Reducer Spec (`server/src/lib.rs`)

Replace `server/src/lib.rs` with the following implementation:

```rust
use spacetimedb::{table, reducer, Identity, Timestamp, ReducerContext};

#[table(name = user_profile, public)]
pub struct UserProfile {
    #[primary_key]
    pub identity: Identity,
    pub display_name: String,
    pub default_currency: String, // "ZAR"
    pub billing_cycle_start_day: u8, // 1–31
    pub created_at: Timestamp,
}

#[table(name = category, public)]
pub struct Category {
    #[primary_key]
    #[auto_inc]
    pub id: u64,
    pub owner: Identity,
    pub name: String,
    pub icon: String, // SF Symbol name e.g. "cart.fill"
    pub color_hex: String, // e.g. "#10B981"
    pub monthly_budget_cents: Option<i64>,
    pub is_archived: bool,
}

#[table(name = expense, public)]
pub struct Expense {
    #[primary_key]
    #[auto_inc]
    pub id: u64,
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
}

// --- Reducers ---

#[reducer]
pub fn initialize_user_profile(
    ctx: &ReducerContext,
    display_name: String,
    default_currency: String,
    billing_cycle_start_day: u8,
) -> Result<(), String> {
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
pub fn log_expense(
    ctx: &ReducerContext,
    amount_cents: i64,
    currency: String,
    category_id: u64,
    payment_method: String,
    note: String,
    spent_at_millis: i64,
) -> Result<(), String> {
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
    });

    Ok(())
}

#[reducer]
pub fn soft_delete_expense(ctx: &ReducerContext, expense_id: u64) -> Result<(), String> {
    let mut expense = ctx.db.expense().id().find(expense_id)
        .ok_or("Expense not found")?;

    if expense.owner != ctx.sender {
        return Err("Unauthorized to delete this record".into());
    }

    expense.deleted_at = Some(ctx.timestamp);
    expense.updated_at = ctx.timestamp;
    ctx.db.expense().id().update(expense);

    Ok(())
}

#[reducer]
pub fn restore_expense(ctx: &ReducerContext, expense_id: u64) -> Result<(), String> {
    let mut expense = ctx.db.expense().id().find(expense_id)
        .ok_or("Expense not found")?;

    if expense.owner != ctx.sender {
        return Err("Unauthorized to restore this record".into());
    }

    expense.deleted_at = None;
    expense.updated_at = ctx.timestamp;
    ctx.db.expense().id().update(expense);

    Ok(())
}

```

---

## 2. Verification Steps

1. Run `cargo check` inside `server/`.
2. Ensure `spacetime build --module-path server` compiles without warnings.
3. Test locally via CLI:
* Call `initialize_user_profile`:
```bash
spacetime call syncspend initialize_user_profile '["Jordan", "ZAR", 1]'

```


* Verify seeded categories:
```bash
spacetime sql syncspend "SELECT id, name, icon, color_hex, monthly_budget_cents FROM category;"

```


* Call `log_expense` with a valid `category_id` (e.g. 1) and confirm row insertion.
* Call `soft_delete_expense` and verify `deleted_at IS NOT NULL`.
* Call `restore_expense` and verify `deleted_at IS NULL`.



Report the CLI verification outputs when completed.

```

<FollowUp label="Want me to prepare TICKET-03 for the iOS client UI once this compiles?" query="TICKET-02 is ready. Please draft TICKET-03 for connecting the new Category schema and Soft Delete actions in SwiftUI."/>

```