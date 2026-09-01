# 03: Native iOS Secure Keychain & OIDC AuthService with PKCE

**What to build:**
Implement secure local storage and an OIDC authentication service for the iOS client. Replace `UserDefaults` token storage with `KeychainManager.swift` using `kSecClassGenericPassword`. Implement `AuthService.swift` using `ASWebAuthenticationSession` with PKCE authorization code flow against SpacetimeAuth (`https://auth.spacetimedb.com/oidc`), token exchange (`/oidc/token`), and automatic session verification on startup.

**Blocked by:** None (can start immediately)

**Status:** completed

- [x] Create `KeychainManager.swift` under `syncspend/ios/SyncSpend/Services/` to securely save, load, and clear `id_token` and `refresh_token`.
- [x] Create `AuthService.swift` under `syncspend/ios/SyncSpend/Services/` with `@Observable` state (`isAuthenticated`, `currentUserEmail`, `currentUserName`).
- [x] Implement PKCE generator (`code_verifier` and `code_challenge` using CryptoKit SHA256).
- [x] Implement `loginWithSpacetimeAuth()` launching `ASWebAuthenticationSession` with callback URL scheme `syncspend://auth/callback`.
- [x] Implement `exchangeCodeForTokens(code:verifier:)` making `POST /oidc/token` to retrieve and store `id_token` and `refresh_token`.
- [x] Implement silent token refresh using `refresh_token` when `id_token` is expired.
- [x] Implement `logout()` clearing Keychain tokens and resetting authentication state.
