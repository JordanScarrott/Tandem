# 02: SpacetimeDB Daily Budget Telemetry & Headroom Engine

**What to build:**
Implement the backend domain logic and tables/views in SpacetimeDB (Rust module) to compute dynamic spending telemetry: calculating daily aggregated spending totals, remaining cycle headroom, remaining days in payday cycle, dynamic "Available Today" allowance, and individual envelope availability balances.

**Blocked by:** 01: Research Pennies Daily Allowance & Budget Pacing Mechanics

**Status:** completed

- [x] Implement pure backend domain functions to calculate daily aggregated spending totals per user without multi-category stack complexity.
- [x] Implement dynamic daily allowance formula: `(Remaining Cycle Budget - Today's Spent) / Days Remaining in Cycle` (with floor/overspend guards).
- [x] Compute per-category envelope availability: spent amount vs. assigned budget limit and remaining headroom per envelope.
- [x] Expose clean subscription tables/views for client consumption.
- [x] Write unit tests for SpacetimeDB module verifying dynamic allowance updates when new expenses are inserted or deleted.
