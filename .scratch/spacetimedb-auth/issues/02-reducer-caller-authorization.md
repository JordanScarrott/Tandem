# 02: Server-Side Claims Validation & Reducer Caller Authorization

**What to build:**
Enforce server-side caller authorization and OIDC JWT claims validation inside all mutating reducers in `syncspend/server/src/lib.rs`. Ensure that callers cannot create expenses with unowned categories, modify or delete other users' expenses, or perform couple space operations without authorized membership. Inspect `ctx.sender_auth().jwt()` to verify trusted issuer and audience.

**Blocked by:** 01: Private Tables & Fine-Grained Server Views in SpacetimeDB Rust Module

**Status:** completed

- [x] Implement `verify_caller_auth(ctx: &ReducerContext)` helper inspecting `ctx.sender_auth().jwt()`.
- [x] In `initialize_user_profile`: ensure caller profile is keyed deterministically by `ctx.sender` and seeds starter categories with `owner = ctx.sender`.
- [x] In `create_category`: verify `category.owner` is assigned to `ctx.sender`.
- [x] In `log_expense` & `log_couple_expense`: verify referenced category belongs to caller or is default; verify `paid_by` and `owner` belong to caller or couple space partners.
- [x] In `soft_delete_expense` & `restore_expense`: verify caller is owner or authorized couple partner before updating `deleted_at`.
- [x] In `join_couple_space`: verify invite code validity and assign `partner_b = Some(ctx.sender)`.
