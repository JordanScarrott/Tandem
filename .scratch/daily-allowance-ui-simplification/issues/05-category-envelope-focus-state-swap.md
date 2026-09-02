# 05: Category Envelope Focus Swap Interaction

**What to build:**
Implement the envelope interaction pattern where tapping a category envelope swaps the main hero visual with a dedicated focus card showing that envelope's individual budget availability (spent vs total envelope limit) and filtered category activity, with a simple dismiss/return button back to the global overview.

**Blocked by:** 04: Simplified Totals-Only Hero Chart & "Available Today" Metric

**Status:** completed

- [x] Render envelope items showing individual available budget / remaining balance as standalone facts.
- [x] Implement smooth transition when an envelope is selected to swap the hero chart with the focused envelope status card (showing remaining budget, spent amount, and progress bar/gauge).
- [x] Filter the transaction feed below to only display expenses belonging to the focused category.
- [x] Provide clear "All Categories" / Back dismissal to return seamlessly to the global daily totals hero.
