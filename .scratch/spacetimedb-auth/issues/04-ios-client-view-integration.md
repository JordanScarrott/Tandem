# 04: iOS Client View Integration & Query Refactor

**What to build:**
Refactor `SpacetimeService.swift` in the iOS app to query server-side views (`SELECT * FROM my_categories;`, `SELECT * FROM my_expenses;`, `SELECT * FROM my_profile;`, `SELECT * FROM my_couple_space;`) instead of raw tables. Attach `Authorization: Bearer <id_token>` from `KeychainManager` to all HTTP REST calls and remove obsolete client-side filtering logic (`cleanOwner != cleanMy`).

**Blocked by:** 
- 01: Private Tables & Fine-Grained Server Views in SpacetimeDB Rust Module
- 02: Server-Side Claims Validation & Reducer Caller Authorization
- 03: Native iOS Secure Keychain & OIDC AuthService with PKCE

**Status:** completed

- [x] Update `SpacetimeService.swift` to retrieve `authToken` directly from `KeychainManager`.
- [x] In `fetchCategories()`: query `SELECT * FROM my_categories;` and parse results without client-side owner filtering.
- [x] In `fetchExpenses()`: query `SELECT * FROM my_expenses;` and parse results without client-side owner filtering.
- [x] Implement `fetchProfile()` querying `SELECT * FROM my_profile;`.
- [x] Implement `fetchCoupleSpace()` querying `SELECT * FROM my_couple_space;`.
- [x] Ensure all reducer calls (`initialize_user_profile`, `log_expense`, `create_category`, etc.) send the Bearer token in the `Authorization` header.
