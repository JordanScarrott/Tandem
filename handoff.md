# Handoff: SyncSpend iOS In-Depth UI/UX Polish Audit & Ticket Breakdown

## 1. Goal of Next Session

The next session is dedicated to an **in-depth UI/UX audit and polish session** for the SyncSpend iOS application.
The agent must:
1. **Audit the Entire App:** Review all views, components, typography, layout paddings, animations, micro-interactions, haptics, color contrast, and empty states.
2. **Focus on Refinement & Polish (Not Massive Overhauls):** Identify high-impact UI/UX polish improvements without restructuring the core architecture.
3. **Generate `/to-tickets`:** Break down the identified polish items into small, independent tracer-bullet tickets with clear acceptance criteria and dependency blocking edges.
4. **Prepare for `/handoff`:** Package the tickets so an implementation agent can iteratively execute and verify them.

---

## 2. Current State & Repository Context

- **Recent Commit:** `9fa83a2` (`feat: initial commit with decoupled SyncSpend iOS architecture, SpacetimeDB backend, and modern UI`)
- **Backend:** SpacetimeDB Cloud (`ad-guitar-1941` at `https://maincloud.spacetimedb.com`) with active reducers for profiles, categories, single/couple expenses, and soft-delete/restoration.
- **Client App Structure:**
  - Root Entry: [`syncspend/ios/SyncSpend/App/SyncSpendApp.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/App/SyncSpendApp.swift)
  - Design Tokens: [`syncspend/ios/SyncSpend/Theme/Theme.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/Theme/Theme.swift)
  - Models: [`Account.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/Models/Account.swift), [`Currency.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/Models/Currency.swift), [`Expense.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/Models/Expense.swift), [`Category.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/Models/Category.swift)
  - State Management (`@Observable`):
    - [`DashboardViewModel.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/ViewModels/DashboardViewModel.swift)
    - [`NewExpenseViewModel.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/ViewModels/NewExpenseViewModel.swift)
    - [`SettingsViewModel.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/ViewModels/SettingsViewModel.swift)
  - Primary Dashboard & Components:
    - [`MainDashboardView.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/Views/MainDashboardView.swift)
    - [`WeeklySpendingCard.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/Views/Components/WeeklySpendingCard.swift)
    - [`TransactionGroupListView.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/Views/Components/TransactionGroupListView.swift)
    - [`TransactionRowView.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/Views/Components/TransactionRowView.swift)
    - [`AccountPickerPill.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/Views/Components/AccountPickerPill.swift)
    - [`CustomCalendarPicker.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/Views/Components/CustomCalendarPicker.swift)
    - [`SmartSuggestionsView.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/Views/Components/SmartSuggestionsView.swift)
    - [`UndoFloatingBar.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/Views/Components/UndoFloatingBar.swift)
  - Modal Sheets & Overlays:
    - [`NewExpenseSheet.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/Views/NewExpenseSheet.swift)
    - [`AccountsSheet.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/Views/AccountsSheet.swift)
    - [`SettingsView.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/Views/SettingsView.swift)
    - [`SearchFilterSheet.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/Views/SearchFilterSheet.swift)
    - [`ProUpgradeModal.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/Views/ProUpgradeModal.swift)
    - [`AddCategorySheet.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/Views/AddCategorySheet.swift)
  - Networking: [`SpacetimeService.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/Services/SpacetimeService.swift)

---

## 3. Areas to Audit for UI/UX Polish

The auditing agent should inspect each of these specific areas:

1. **Dashboard & Bar Chart Polish:**
   - Bar chart animations on load and data refresh.
   - Tooltip alignment and dismiss gesture/timeout.
   - Visual balance of x-axis day labels and y-axis currency guidelines.
   - Smooth transition when switching accounts.

2. **Expense Creation & Keypad Flow:**
   - Amount entry formatting: auto-decimal comma/point handling, cursor focus.
   - Tactile feedback on preset smart suggestion tap.
   - Visual styling of Category/Payment selectors (ensure smooth sheet detents and presentation).
   - Date picker sheet interaction and quick "Today" / "Yesterday" buttons if useful.

3. **Transaction Feed & Swipe Gestures:**
   - Swipe-to-delete spring haptics and visual cues.
   - Floating undo bar positioning (safe area avoidance, keyboard avoidance).
   - Category icon squircle color harmony and contrast.
   - Date formatting consistency (e.g. "Today", "Yesterday", "28 Aug").

4. **Sheets & Modals Polish:**
   - Drag indicator styling and sheet presentation detents across iOS versions.
   - Dark mode contrast and background materials (`.ultraThinMaterial`).
   - Settings list layout and toggle tint consistency.
   - Account switcher modal edit mode reorder/delete animations.

---

## 4. Suggested Skills for the Next Agent

- `to-tickets` — Break down the audit findings into structured tracer-bullet tickets with blocking edges.
- `handoff` — Package the generated tickets into a handoff document for the implementation agent.
- `codebase-design` — Maintain clean component seams and state boundaries.

---

## 5. Verification Commands

- **Regenerate Xcode Project:**
  ```bash
  cd syncspend/ios && xcodegen generate
  ```
- **Build iOS Target:**
  ```bash
  xcodebuild -project syncspend/ios/SyncSpend.xcodeproj -scheme SyncSpend -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
  ```
- **Run SpacetimeDB Dev Server (if testing live queries):**
  ```bash
  cd syncspend && ~/.local/bin/spacetime dev
  ```