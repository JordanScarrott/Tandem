# 05: Native iOS App Startup & Login Screen Flow

**What to build:**
Create a modern, animated `LoginView.swift` and connect the startup authentication coordinator in `SyncSpendApp.swift` / `ContentView.swift`. When the app launches, check Keychain for a valid session. If valid, silently transition to `MainDashboardView`. If not, display `LoginView` with "Sign in with Apple" and "Sign in with SpacetimeAuth". Add account display and a "Sign Out" button to `AccountsSheet.swift`.

**Blocked by:** 
- 03: Native iOS Secure Keychain & OIDC AuthService with PKCE
- 04: iOS Client View Integration & Query Refactor

**Status:** completed

- [x] Create `LoginView.swift` under `syncspend/ios/SyncSpend/Views/` with branded header, value propositions, and styled login action buttons.
- [x] Connect `AuthService.shared` to `SyncSpendApp.swift` or `ContentView.swift` to render `LoginView` when `!authService.isAuthenticated` and `MainDashboardView` when `authService.isAuthenticated`.
- [x] Ensure `initializeUserProfile` is invoked seamlessly on first successful login to provision starter categories and profile.
- [x] Add user profile info (name, email, avatar badge) and a "Log Out" button with confirmation alert in `AccountsSheet.swift`.
- [x] Verify build passes in Xcode (`xcodebuild ... build`).
