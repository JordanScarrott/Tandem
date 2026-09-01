# Handoff: iOS Main Dashboard Scroll-Based Sticky UX & Visual Polish

## 1. Objective for Next Session
The user wants to refine the iOS app's UX, specifically focusing on **[`MainDashboardView.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/Views/MainDashboardView.swift)** and its child components to introduce **professional-level, scroll-based sticky elements and subtle, high-craft visual interactions**:
- When scrolling down, key elements stick, morph, or dock in natural, subtle ways:
  - **Top Navigation / Filter Bar**: Collapses into a clean compact blur header with account pill and quick action buttons when scrolled past the hero area.
  - **Transaction Date Section Headers**: Use sticky section headers (`LazyVStack(pinnedViews: [.sectionHeaders])` with glassmorphic ultra-thin materials and blurred background) so day groupings stick cleanly while scrolling through expenses.
  - **Active Filter / Category Pills**: Dock or tuck cleanly below the navigation bar when filters are applied.
  - **Subtle Elevation & Shadow Transitions**: Header and sticky bars gain subtle elevation, border stroke, and glassmorphism only when content scrolls beneath them.
  - **Scroll-Driven Micro-Interactions**: Compact summary of spending when hero card scrolls out of view.

---

## 2. Current State of the Codebase

### A. Backend (SpacetimeDB + Rust Module `ad-guitar-1941`)
- **Location**: [`syncspend/server/src/lib.rs`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/server/src/lib.rs)
- **Status**: Milestone 2 (`TICKET-SP-01`) is fully deployed and verified with multi-user isolation on `https://maincloud.spacetimedb.com`.
- **Key Tables**: `UserProfile` (clamped `billing_cycle_start_day` 1..28), `Category` (with `space_id: Option<u64>` and `is_archived`), `Expense` (with `deleted_at: Option<Timestamp>` soft delete).

### B. iOS Client (SwiftUI / iOS 17+)
- **Location**: [`syncspend/ios/SyncSpend/`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/)
- **Completed Components**:
  - [`Views/MainDashboardView.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/Views/MainDashboardView.swift): Main dashboard orchestrator.
  - [`Views/Components/WeeklySpendingCard.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/Views/Components/WeeklySpendingCard.swift): Bar chart with week/period spending.
  - [`Views/Components/CategoryEnvelopesDashboardSection.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/Views/Components/CategoryEnvelopesDashboardSection.swift): Payday cycle envelope tracker, progress bars, crimson overspend warnings, and 1-tap filtering.
  - [`Views/Components/TransactionGroupListView.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/Views/Components/TransactionGroupListView.swift): Grouped transaction list by date.
  - [`Views/Components/TransactionRowView.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/Views/Components/TransactionRowView.swift): Swipe-to-delete row with haptics.
  - [`Views/Components/UndoFloatingBar.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/Views/Components/UndoFloatingBar.swift): 5-second linear progress countdown toast.
  - [`Views/CategoryEnvelopeSheet.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/Views/CategoryEnvelopeSheet.swift): Create & edit envelopes with caps, icons, colors, and archive.
  - [`Views/ManageEnvelopesSheet.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/Views/ManageEnvelopesSheet.swift): Envelopes list in Settings.
  - [`Views/NewExpenseSheet.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/Views/NewExpenseSheet.swift): High-velocity rapid expense logging.
  - [`Views/OnboardingPaydaySheet.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/Views/OnboardingPaydaySheet.swift): Payday onboarding modal.
  - [`Theme/Theme.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/Theme/Theme.swift): Design tokens, adaptive system colors, haptics.

---

## 3. Key Files & Areas to Touch for UX Improvements

1. **[`syncspend/ios/SyncSpend/Views/MainDashboardView.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/Views/MainDashboardView.swift)**:
   - Introduce scroll tracking via `GeometryReader` / `PreferenceKey` (or iOS 17 `.onScrollGeometryChange` / `ScrollView` coordinate space).
   - Implement sticky top navigation bar that morphs into a blur header (`.background(.ultraThinMaterial)`) when scrolled.
2. **[`syncspend/ios/SyncSpend/Views/Components/TransactionGroupListView.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/Views/Components/TransactionGroupListView.swift)**:
   - Convert list to use `LazyVStack(pinnedViews: [.sectionHeaders])` or sticky date header cards so section titles (e.g. *"Today"*, *"Yesterday"*, *"24 Aug 2026"*) float and stick smoothly as the user scrolls.
3. **[`syncspend/ios/SyncSpend/Views/Components/WeeklySpendingCard.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/Views/Components/WeeklySpendingCard.swift)**:
   - Add subtle parallax or scale compression when pulled down or scrolled up.
4. **[`syncspend/ios/SyncSpend/Theme/Theme.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/Theme/Theme.swift)**:
   - Ensure header blur materials, shadow tokens, and border separators match dark and light modes seamlessly.

---

## 4. Build & Validation Commands

- **Regenerate Xcode Project (if adding new files)**:
  ```bash
  cd syncspend/ios && xcodegen generate
  ```
- **Build & Verify Code**:
  ```bash
  cd syncspend/ios && xcodebuild -project SyncSpend.xcodeproj -scheme SyncSpend -destination "generic/platform=iOS Simulator" clean build CODE_SIGNING_ALLOWED=NO
  ```

---

## 5. Suggested Skills for the Next Agent
- **`codebase-design`**: Clean separation of SwiftUI view modifiers and stateful coordinators.
- **`code-review`**: Validating layout performance and 60fps scroll smoothness.
- **`modern-web-guidance`**: Motion, sticky scrolling mechanics, and fluid transition patterns.