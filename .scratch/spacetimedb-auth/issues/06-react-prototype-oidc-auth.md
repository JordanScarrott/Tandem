# 06: React Prototype OIDC Auth Integration

**What to build:**
Integrate OIDC authentication into the web prototype (`syncspend/syncspend_ios_budgeting_app.tsx` and `src/`). Wrap the application with `AuthProvider` / auth coordinator state, pass the verified `id_token` / identity, and provide a web login screen matching the native iOS UX.

**Blocked by:** 
- 01: Private Tables & Fine-Grained Server Views in SpacetimeDB Rust Module
- 02: Server-Side Claims Validation & Reducer Caller Authorization

**Status:** completed

- [x] Configure OIDC state with SpacetimeAuth authority and redirect scheme.
- [x] Integrate `isAuthenticated` state handling in prototype app shell.
- [x] Connect `DbConnection` / auth token passing in prototype.
- [x] Implement responsive web login card with "Sign In with SpacetimeAuth" trigger, guest mode, and session logout in settings.
