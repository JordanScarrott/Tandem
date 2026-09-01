# 07: Multi-User Segregation & Couple Space Integration Verification

**What to build:**
Run end-to-end integration and security testing across multiple authenticated identities. Verify that User A cannot read User B's personal expenses or categories under any circumstance, that couple partners sharing a `CoupleSpace` see shared expenses in real-time, and that unauthorized modifications are rejected by the SpacetimeDB server module.

**Blocked by:** 
- 04: iOS Client View Integration & Query Refactor
- 05: Native iOS App Startup & Login Screen Flow
- 06: React Prototype OIDC Auth Integration

**Status:** completed

- [x] Write integration test script verifying that calling `SELECT * FROM expense;` fails or returns 0 rows directly.
- [x] Verify that calling `SELECT * FROM my_expenses;` as User A returns only User A's expenses.
- [x] Verify that when User A and Partner B join a `CoupleSpace`, calling `SELECT * FROM my_expenses;` for Partner B includes the shared couple expenses.
- [x] Verify that soft-deleting an expense from Partner B updates in real-time for User A.
- [x] Verify token renewal / silent session restoration after app restart.
