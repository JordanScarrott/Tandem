# 03: Expense Creation Keypad, Auto-focus & Quick Date Shortcuts

**What to build:**
Refine `NewExpenseSheet.swift` and `CustomCalendarPicker.swift` by adding auto-focus on presentation via `@FocusState`, robust decimal/comma amount formatting, quick-tap date chips ("Today", "Yesterday") in the calendar picker, and spring animations when tapping smart suggestion pills.

**Blocked by:** 01 (Adaptive Dark Mode & Semantic Design System Tokens)

**Status:** completed

- [x] Add `@FocusState` to auto-focus amount input upon opening `NewExpenseSheet`.
- [x] Handle localized decimal separator input cleanly (supports comma `,` and period `.`).
- [x] Add "Today" and "Yesterday" quick-selection chips to `CustomCalendarPicker.swift`.
- [x] Add tactile haptic feedback and spring transition when tapping `SmartSuggestionsView` quick tags.
- [x] Verify keypad dismissal and scroll behavior on compact screens.

