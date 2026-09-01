# 01: Private Tables & Fine-Grained Server Views in SpacetimeDB Rust Module

**What to build:**
Harden the SpacetimeDB module so that sensitive data is isolated on the server. Remove the `public` modifier from all tables (`user_profile`, `category`, `expense`, `couple_space`, `couple_invite`, `expense_split`) to prevent unauthorized full-table scans. Implement public server-side read-only views (`my_categories`, `my_expenses`, `my_profile`, `my_couple_space`) using `ViewContext` and indexed queries against `ctx.sender`.

**Blocked by:** None (can start immediately)

**Status:** completed

- [x] Remove `public` from `#[spacetimedb::table]` declarations for `user_profile`, `category`, `expense`, `couple_space`, `couple_invite`, and `expense_split` in `syncspend/server/src/lib.rs`.
- [x] Implement `#[spacetimedb::view(name = my_categories, public)]` returning only active categories where `category.owner == ctx.sender`.
- [x] Implement `#[spacetimedb::view(name = my_expenses, public)]` returning active expenses owned by `ctx.sender` or belonging to any `CoupleSpace` where `space.partner_a == ctx.sender || space.partner_b == Some(ctx.sender)`.
- [x] Implement `#[spacetimedb::view(name = my_profile, public)]` returning the caller's profile.
- [x] Implement `#[spacetimedb::view(name = my_couple_space, public)]` returning the caller's active couple space.
- [x] Publish module update with `spacetime publish` and verify with CLI / SQL that direct table access is blocked while views return filtered records.
