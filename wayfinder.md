# Wayfinder Map: Single-Player Budgeting & Envelope Engine

## Destination
A complete, frictionless **Single-Player Budgeting and Category Envelope Experience** on iOS backed by SpacetimeDB:
1. Payday-anchored monthly budgeting cycles with automatic starter envelope seeding.
2. Ultra-fast transaction logging (Amount first -> Note -> Sliding Wheel pickers -> Auto-fallback title -> Bottom confirmation).
3. Live category envelope tracking with dynamic budget adjustment and visual overspend warnings.
4. Transient 5-second swipe-to-delete undo flow.

---

## Notes
- **Domain Language**: Integer accounting (`amount_cents: i64`), payday cycle windows `[previous_payday, next_payday)`, category envelopes (`monthly_budget_cents`), soft deletion (`deleted_at: Option<Timestamp>`), dual-scope seam (`space_id: Option<u64>` defaults to `None`).
- **Interaction Model**: Wheel/roller picker interface (like iOS timer/alarm wheels), thumb-reachable bottom CTA, auto-default description to category name if left blank.
- **Skills**: `wayfinder`, `domain-modeling`, `wait-what`.

---

## Decisions So Far

- **Onboarding & Payday Anchor**: Upfront modal for display name and payday anchor (1–28). "Skip for now" initializes standard defaults (`display_name: "You"`, `default_currency: "ZAR"`, `billing_cycle_start_day: 1`) and seeds 5 envelopes immediately.
- **Zero-Rollover Clean Slate**: Monthly budget cycles reset cleanly on the user's payday. Cycle window strictly bounds expenses `[previous_payday, next_payday)` clamped by `min(billing_cycle_start_day, days_in_month)`.
- **Soft Overspend Warnings**: Spending beyond envelope limits displays warning indicators (red bar, negative remaining balance); no hard blocks.
- **Strict Category Envelopes**: All expenses require a category. Archiving preserves historical expense records while hiding the envelope from active creation pickers.
- **5-Second Transient Undo**: Deletion updates `deleted_at: Option<Timestamp>` and presents a floating haptic action bar with "Undo" triggering `restore_expense`.
- **High-Velocity Entry Flow**:
  1. Amount entered first via custom numeric keypad / field.
  2. Note/description immediately below amount. If left blank, defaults automatically to the chosen category name.
  3. Sliding wheel / roller list for category and payment method selection.
  4. Prominent bottom confirm button (no reaching for top-right navigation bar).

---

## User Stories & Ticket Breakdown

### [TICKET-SP-01] [COMPLETED] Backend: Profile, Envelopes & Soft-Delete Engine (Rust)
- **User Story**: As a user, I want my profile initialized with my payday anchor, 5 starter envelopes automatically generated, and full CRUD + soft-delete/restore capabilities for expenses.
- **Table Schemas (`server/src/lib.rs`)**:
  ```rust
  #[table(name = user_profile)]
  pub struct UserProfile {
      #[primary_key]
      pub identity: Identity,
      pub display_name: String,
      pub default_currency: String, // "ZAR"
      pub billing_cycle_start_day: u8, // 1–28
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
      pub space_id: Option<u64>, // Seam for future multiplayer sync (defaults to None)
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
      pub space_id: Option<u64>, // Seam for future multiplayer sync (defaults to None)
      pub split_mode: String,
  }
  ```
- **Reducers to Implement / Update**:
  - `initialize_user_profile(display_name, default_currency, billing_cycle_start_day)`: Clamps day to 1–28, auto-seeds 5 starter envelopes.
  - `update_user_profile(display_name, billing_cycle_start_day)`: Updates display name and payday anchor.
  - `create_category(name, icon, color_hex, monthly_budget_cents)`
  - `update_category(category_id, name, icon, color_hex, monthly_budget_cents)`
  - `archive_category(category_id)`: Toggles `is_archived = true`.
  - `log_expense(amount_cents, currency, category_id, payment_method, note, spent_at_millis)`
  - `update_expense(expense_id, amount_cents, currency, category_id, payment_method, note, spent_at_millis, split_mode)`
  - `soft_delete_expense(expense_id)`: Sets `deleted_at = Some(ctx.timestamp)`.
  - `restore_expense(expense_id)`: Sets `deleted_at = None`.
- **Views**:
  - `my_profile`: Caller's profile.
  - `my_categories`: Active envelopes (`owner == ctx.sender && !is_archived`).
  - `my_expenses`: Active expenses (`owner == ctx.sender && deleted_at IS NULL`), sorted by `spent_at_millis DESC`.

---

### [TICKET-SP-02] [COMPLETED] iOS: First-Run Onboarding Modal & Settings Payday Configuration
- **User Story**: As a new user, I want a clean onboarding screen to set my name and payday (with a skip button), and ability to adjust my payday anchor anytime in Settings.
- **Scope**:
  - `OnboardingPaydaySheet.swift`: Greeting, name input, payday day picker (1–28), "Start Budgeting" CTA, and "Skip for now" button.
  - `SettingsView.swift`: Profile section displaying current payday anchor (e.g. "Payday: 25th of every month") with sheet to update.
  - Auto-initialization trigger on first launch if uninitialized.

---

### [TICKET-SP-03] [COMPLETED] iOS: High-Velocity Rapid Expense Sheet (Wheel Picker & Auto-Defaults)
- **User Story**: As a user logging an expense on the go, I want to type the amount, optionally add a note, slide through wheel pickers for category/method, and tap a bottom button to log in under 3 seconds.
- **Scope**:
  - `NewExpenseSheet.swift` redesign:
    - Amount field focused on appear.
    - Description field immediately below. (If blank on submit, populate with selected category name).
    - Wheel/roller sliding selection for Category (icon + name) and Payment Method (Cash, Card, EFT, etc.).
    - Prominent bottom "Add Transaction" CTA above keyboard.
  - Instant SpacetimeDB mutation via `log_expense`.

---

### [TICKET-SP-04] [COMPLETED] iOS: Payday-Cycle Category Envelope Dashboard & Overspend Indicators
- **User Story**: As a user reviewing my budget, I want to see how much I've spent vs. my monthly envelope limit for the current payday cycle, with clear visual alerts if an envelope is over budget.
- **Scope**:
  - Cycle calculation utility: Computes `[start_date, end_date]` for active payday window.
  - Category Envelope cards: Spent amount, budget limit, progress bar (accent color when healthy, crimson warning when exceeded with "-R... over budget" badge).
  - Category filter toggle on dashboard.

---

### [TICKET-SP-05] [COMPLETED] iOS: Swipe-to-Delete & 5-Second Haptic Floating Undo Bar
- **User Story**: As a user who accidentally deleted a transaction, I want a 5-second transient floating bar with an "Undo" button to restore it immediately.
- **Scope**:
  - `TransactionRowView.swift`: Swipe action to delete triggering `soft_delete_expense`.
  - `UndoFloatingBar.swift`: Global floating banner appearing on delete with a 5-second linear progress timer and "Undo" tap target triggering `restore_expense`.
  - Haptic feedback (`Haptics.notification`) on deletion and restoration.

---

## Not Yet Specified (Fog of War)
- Custom recurring bills detection (e.g. rent/subscriptions automatically allocated on payday).
- CSV / Bank statement export per payday cycle.
- Split-space transition helper (migrating single-player envelopes into a couple space when pairing).

---

## Out of Scope
- Couple pairing and proportional expense splitting (deferred to Milestone 3).
- OCR receipt camera scanning.
- External bank account API aggregators.