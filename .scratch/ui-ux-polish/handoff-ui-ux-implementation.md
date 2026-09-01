# Handoff: SyncSpend iOS UI/UX Polish Implementation

## 1. Objective of Next Session

The implementation agent will execute the UI/UX polish tickets generated during the audit under `.scratch/ui-ux-polish/issues/`.
Work will proceed sequentially across the tracer-bullet tickets:
1. `01-dark-mode-semantic-tokens.md`
2. `02-bar-chart-animations-tooltips.md`
3. `03-expense-creation-keypad-shortcuts.md`
4. `04-transaction-feed-swipe-undo-bar.md`
5. `05-sheets-modals-detents-polish.md`
6. `06-e2e-ui-verification-build.md`

---

## 2. Codebase & Ticket References

- **Tickets Directory:** `.scratch/ui-ux-polish/issues/`
  - [01-dark-mode-semantic-tokens.md](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/.scratch/ui-ux-polish/issues/01-dark-mode-semantic-tokens.md)
  - [02-bar-chart-animations-tooltips.md](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/.scratch/ui-ux-polish/issues/02-bar-chart-animations-tooltips.md)
  - [03-expense-creation-keypad-shortcuts.md](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/.scratch/ui-ux-polish/issues/03-expense-creation-keypad-shortcuts.md)
  - [04-transaction-feed-swipe-undo-bar.md](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/.scratch/ui-ux-polish/issues/04-transaction-feed-swipe-undo-bar.md)
  - [05-sheets-modals-detents-polish.md](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/.scratch/ui-ux-polish/issues/05-sheets-modals-detents-polish.md)
  - [06-e2e-ui-verification-build.md](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/.scratch/ui-ux-polish/issues/06-e2e-ui-verification-build.md)

- **Key iOS Source Files:**
  - Theme: [`syncspend/ios/SyncSpend/Theme/Theme.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/Theme/Theme.swift)
  - Dashboard: [`syncspend/ios/SyncSpend/Views/MainDashboardView.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/Views/MainDashboardView.swift)
  - Chart: [`syncspend/ios/SyncSpend/Views/Components/WeeklySpendingCard.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/Views/Components/WeeklySpendingCard.swift)
  - Transactions: [`syncspend/ios/SyncSpend/Views/Components/TransactionGroupListView.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/Views/Components/TransactionGroupListView.swift) & [`TransactionRowView.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/Views/Components/TransactionRowView.swift)
  - New Expense: [`syncspend/ios/SyncSpend/Views/NewExpenseSheet.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/Views/NewExpenseSheet.swift)
  - Calendar Picker: [`syncspend/ios/SyncSpend/Views/Components/CustomCalendarPicker.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/Views/Components/CustomCalendarPicker.swift)
  - Sheets: [`AccountsSheet.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/Views/AccountsSheet.swift), [`SettingsView.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/Views/SettingsView.swift), [`SearchFilterSheet.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/Views/SearchFilterSheet.swift)

---

## 3. Suggested Skills for the Implementation Agent

- `tdd` — Test-driven and incremental implementation of components and view states.
- `codebase-design` — Maintain clean component seams and cohesive design tokens.

---

## 4. Verification Commands

```bash
# 1. Regenerate Xcode project if needed
cd syncspend/ios && xcodegen generate

# 2. Compile and verify iOS simulator build
xcodebuild -project syncspend/ios/SyncSpend.xcodeproj -scheme SyncSpend -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```
