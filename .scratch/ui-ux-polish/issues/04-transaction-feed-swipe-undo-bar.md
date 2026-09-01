# 04: Transaction Feed Date Formatting, Swipe Haptics & Undo Bar Polish

**What to build:**
Upgrade `TransactionGroupListView.swift`, `TransactionRowView.swift`, and `UndoFloatingBar.swift` with rich relative date headers ("Today", "Yesterday", "Monday, 28 Aug"), sensory haptics on swipe deletion, an empty state action button, and safe-area floating undo bar positioning.

**Blocked by:** 01 (Adaptive Dark Mode & Semantic Design System Tokens)

**Status:** completed

- [x] Format transaction group headers to include weekday and day-month context (e.g. "Monday, 28 Aug").
- [x] Add an action button in the empty state ("+ Log Expense") that directly presents `NewExpenseSheet`.
- [x] Add `.sensoryFeedback` or haptic trigger when full swipe-to-delete activates.
- [x] Ensure `UndoFloatingBar` floats cleanly above the FAB with proper safe-area padding and smooth `.spring` dismissal.

