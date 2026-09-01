# Handoff: SpacetimeDB Authentication & Database Security Implementation

## 1. Session Objective for Next Agent
Implement end-to-end authentication and database security for SyncSpend / Tandem on SpacetimeDB 1.12.0. Work through the tracer-bullet ticket backlog in dependency order:
1. Harden backend tables (convert to private tables + implement `#[spacetimedb::view]` server-side row isolation).
2. Enforce caller identity verification and token claims inspection in Rust reducers.
3. Implement native iOS `KeychainManager.swift` + `AuthService.swift` (OIDC PKCE + `ASWebAuthenticationSession`).
4. Connect iOS `SpacetimeService.swift` to server views and build native `LoginView.swift` app startup flow.
5. Integrate OIDC in the React prototype and verify multi-user row isolation.

---

## 2. Suggested Skills
- `tdd` (for test-driven verification of views, token authorization, and multi-tenant row isolation)
- `codebase-design` (for clean module seam between auth session management, Keychain, and SpacetimeDB networking)
- `modern-web-guidance` (for React OIDC integration patterns)

---

## 3. Primary Reference Artifacts
- **Research Specification & Architecture Blueprint**: [`docs/research/spacetimedb_auth_and_security.md`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/docs/research/spacetimedb_auth_and_security.md)
- **Wayfinder Milestones**: [`wayfinder.md`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/wayfinder.md)
- **Backend Code**: [`syncspend/server/src/lib.rs`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/server/src/lib.rs)
- **iOS Network Service**: [`syncspend/ios/SyncSpend/Services/SpacetimeService.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/Services/SpacetimeService.swift)
- **React Prototype**: [`syncspend/syncspend_ios_budgeting_app.tsx`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/syncspend_ios_budgeting_app.tsx)

---

## 4. Ticket Backlog & Dependency Graph

Local tracer-bullet tickets have been published under `.scratch/spacetimedb-auth/issues/`:

```text
[01: Private Tables & Server Views]  <--- Frontier (Can start immediately)
      │
      ├────────────────────────────┬────────────────────────────┐
      ▼                            ▼                            ▼
[02: Reducer Caller Auth]    [03: iOS Keychain & Auth]    [06: React OIDC Auth]
      │                            │
      └─────────────┬──────────────┘
                    ▼
       [04: iOS Client Views Integration]
                    │
                    ▼
       [05: iOS Startup & Login Flow]
                    │
                    ▼
       [07: Multi-User Segregation Verification]
```

### Ticket Directory
1. `01`: [`.scratch/spacetimedb-auth/issues/01-private-tables-and-server-views.md`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/.scratch/spacetimedb-auth/issues/01-private-tables-and-server-views.md) (Status: `ready-for-agent`)
2. `02`: [`.scratch/spacetimedb-auth/issues/02-reducer-caller-authorization.md`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/.scratch/spacetimedb-auth/issues/02-reducer-caller-authorization.md) (Blocked by: `01`)
3. `03`: [`.scratch/spacetimedb-auth/issues/03-native-ios-keychain-and-auth-service.md`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/.scratch/spacetimedb-auth/issues/03-native-ios-keychain-and-auth-service.md) (Status: `ready-for-agent`)
4. `04`: [`.scratch/spacetimedb-auth/issues/04-ios-client-view-integration.md`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/.scratch/spacetimedb-auth/issues/04-ios-client-view-integration.md) (Blocked by: `01`, `02`, `03`)
5. `05`: [`.scratch/spacetimedb-auth/issues/05-native-ios-app-startup-and-login-flow.md`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/.scratch/spacetimedb-auth/issues/05-native-ios-app-startup-and-login-flow.md) (Blocked by: `03`, `04`)
6. `06`: [`.scratch/spacetimedb-auth/issues/06-react-prototype-oidc-auth.md`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/.scratch/spacetimedb-auth/issues/06-react-prototype-oidc-auth.md) (Blocked by: `01`, `02`)
7. `07`: [`.scratch/spacetimedb-auth/issues/07-multi-user-segregation-verification.md`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/.scratch/spacetimedb-auth/issues/07-multi-user-segregation-verification.md) (Blocked by: `04`, `05`, `06`)

---

## 5. Key Architecture & Technical Gotchas
1. **Public vs Private Tables**:
   - In SpacetimeDB 1.x / 1.12.0, `#[table(name = expense, public)]` allows any connected client to run SQL queries across the whole table.
   - Removing `public` makes the table completely private.
   - Clients must query public views (`#[spacetimedb::view(name = my_expenses, public)]`) which inspect `ctx.sender` to enforce server-side row security.
2. **Deterministic Identity Generation**:
   - `Identity = SHA256(issuer || subject)`. When an OIDC token is passed in `Authorization: Bearer <id_token>`, SpacetimeDB maps the verified user to a stable `Identity`.
3. **iOS Keychain**:
   - Tokens must never be stored in `UserDefaults`. `KeychainManager.swift` manages `id_token` and `refresh_token`.
4. **Current Build Status**:
   - iOS build: `xcodebuild -project syncspend/ios/SyncSpend.xcodeproj -scheme SyncSpend -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` -> **SUCCEEDED**.
