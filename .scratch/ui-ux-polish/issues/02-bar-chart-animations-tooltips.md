# 02: Interactive Bar Chart Animations, Tooltips & Day Selection Polish

**What to build:**
Enhance the weekly spending bar chart in `WeeklySpendingCard.swift` with smooth spring entry/value transition animations, an interactive tooltip bubble with amount details, subtle tap haptics, and tap-to-dismiss behavior when tapping outside active bars.

**Blocked by:** 01 (Adaptive Dark Mode & Semantic Design System Tokens)

**Status:** completed

- [x] Add `.animation(.spring(response: 0.45, dampingFraction: 0.75), value: chartData)` on bar height adjustments when accounts change or data loads.
- [x] Highlight the selected bar with an accent indicator or distinctive fill contrast when active.
- [x] Render the tooltip popup with smooth scale and opacity transition above the active bar.
- [x] Allow tapping the chart background or card to dismiss active tooltips.
- [x] Refine x-axis day labels and y-axis step guidelines for balanced spacing and alignment.

