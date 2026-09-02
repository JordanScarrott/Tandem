# Handoff: Consolidating Home Page Prototypes & User Experience Grilling

## 1. Context & Objective for Next Agent

The previous agent successfully completed:
1. **SyncSpend iOS WidgetKit Extension (`SyncSpendWidgetExtension`)**:
   - `WeeklySpendWidget` (`systemSmall` & `systemMedium`) displaying centered "SPENT THIS WEEK" amount.
   - `SharedTelemetryStore` for App Group data bridging.
   - 100% test pass rate across `SyncSpendTests` (9/9 tests passed) and clean Xcode builds.
2. **Current Goal**:
   - Help the user consolidate and pick the best parts of the 3 home page prototypes (`Variant A: Stacked Bars`, `Variant B: Cumulative Pace`, `Variant C: Integrated Hero` in [`BudgetTelemetryPrototypeView.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/Views/Prototypes/BudgetTelemetryPrototypeView.swift)) to synthesize the final, unified SyncSpend Home Page experience.
   - Run the `/grilling` protocol with the user to explore what their favorite aspects and interaction patterns are from a real user perspective.

---

## 2. Inventory of Current Prototypes & Design Elements

### Primary Prototype Location
- [`syncspend/ios/SyncSpend/Views/Prototypes/BudgetTelemetryPrototypeView.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/Views/Prototypes/BudgetTelemetryPrototypeView.swift)
- [`syncspend/ios/SyncSpend/Views/MainDashboardView.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/Views/MainDashboardView.swift)

### The 3 Core Variants:
1. **Variant A: Stacked Bars** (`VariantA_StackedBarsView`):
   - **Hero Visual**: Multi-category segmented vertical bars for each day with color-coded spend buckets.
   - **Daily Allowance Rule**: Dotted / dashed target reference line showing daily ideal budget allowance.
   - **Category Breakdown Spotlight**: Interactive tap-to-filter category envelopes beneath the chart.
   - **Strengths**: High visual clarity on *what* was spent per category per day.

2. **Variant B: Cumulative Pace** (`VariantB_CumulativePaceView`):
   - **Hero Visual**: Smooth continuous cumulative spend curve plotted against an ideal linear budget pace.
   - **Pacing Feedback**: Clear "Ahead of pace" / "Under pace" delta pill with daily allowance breakdown.
   - **Category Envelopes Grid**: Standalone 2-column or list envelope cards showing percentage used and overspend warning.
   - **Strengths**: Maximum awareness of payday cycle burn rate and time remaining in cycle.

3. **Variant C: Integrated Hero** (`VariantC_IntegratedHeroView`):
   - **Hero Visual**: Toggleable Command Center switching between `Daily Bars` and `Cycle Pace` inside a unified card.
   - **Envelope Spotlight Rail**: Horizontal scrolling category chips with inline progress rings and mini values.
   - **Dynamic Summary**: Free-to-spend headroom + daily allowance + payday countdown in one header block.
   - **Strengths**: Highest information density; lets power users toggle visual telemetry modes.

---

## 3. Initial Grilling Frontier (Round 1)

Below is the initial round of user-perspective grilling questions designed to pinpoint what feels best in actual daily usage.

---

❓ **Q1** - **Primary Hero Telemetry Style**: From a daily financial tracking perspective, what gives you the most immediate clarity when opening the app?
- **Option A (Daily Categorized Stacked Bars)**: Seeing daily vertical bars showing exact categories spent per day.
- **Option B (Cumulative Pace Curve)**: Seeing the cumulative trajectory curve showing whether you're ahead/behind budget pace for the payday cycle.
- **Option C (Dual / Segmented Toggle)**: Having the integrated hero that lets you switch between Daily Bars and Cycle Pace on demand.
- **Option D (Hybrid Card)**: Large primary spend/headroom number on top, with a compact dual-mode chart beneath it.

➡️ **Recommendation**: Option C or D. An all-in-one command card gives the large key number immediately while offering the switch between granular daily bars and cycle pace trajectory without cluttering the screen.

---

❓ **Q2** - **Category Envelopes Layout & Interaction**: How do you prefer to view and interact with your Category Envelopes on the home screen?
- **Option A (Horizontal Scroll Rail with Progress Rings)**: Compact horizontal chip carousel at the top of the feed (as in Variant C).
- **Option B (2-Column Grid Cards)**: Prominent grid cards showing category icon, progress bar, spent amount, and remaining budget (as in Variant B).
- **Option C (Directly Filterable Feed)**: Tapping an envelope highlights that category on the chart and filters the expense list below simultaneously.

➡️ **Recommendation**: Option C combined with Option B. Tapping a category envelope should spotlight its segment on the chart and filter the recent transaction list below, creating a cohesive, interactive feedback loop.

---

❓ **Q3** - **Payday Cycle vs. Calendar Month Orientation**: SyncSpend calculates telemetry based on your custom *Payday Cycle* (e.g. 25th of the month to 25th of next month). How prominent should cycle pacing be relative to weekly spending?
- **Option A (Cycle First)**: The hero prominently displays "Days Left in Cycle" and "Free to Spend this Cycle", with weekly breakdown as secondary telemetry.
- **Option B (Weekly First)**: The hero focuses on "Spent This Week" (matching the new Home Screen widget), with cycle pacing as a secondary pill.
- **Option C (Context-Aware / User Selectable)**: The hero reflects whatever filter period is selected in the top bar (This Week vs This Month vs Payday Cycle).

➡️ **Recommendation**: Option C (Context-Aware). When filtered to "This Week", it highlights weekly spend (aligning with the widget); when viewing the payday cycle, it surfaces burn rate and remaining allowance.

---

❓ **Q4** - **Transaction List & Activity Feed Hierarchy**: What is your preferred position and format for the recent expense transactions?
- **Option A (Sticky Bottom Section with Day Grouping)**: Chronological list grouped by "Today", "Yesterday", and past dates with category icons and quick-swipe deletion.
- **Option B (Collapsible Drawer / Sheet)**: Focused hero view with an expandable bottom sheet for transaction history.
- **Option C (Inline Feed with Empty State Prompts)**: Smooth scrolling list seamlessly flowing beneath the telemetry hero with quick-add buttons.

➡️ **Recommendation**: Option A. Chronological grouping by day ("Today", "Yesterday") with swipe actions and subtle category badge styling provides the quickest glanceability.

---

## 4. Key Reference Files

| Component | File Path |
| :--- | :--- |
| **Prototypes View** | [`syncspend/ios/SyncSpend/Views/Prototypes/BudgetTelemetryPrototypeView.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/Views/Prototypes/BudgetTelemetryPrototypeView.swift) |
| **Main Dashboard** | [`syncspend/ios/SyncSpend/Views/MainDashboardView.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/Views/MainDashboardView.swift) |
| **Spending Telemetry Engine** | [`syncspend/ios/SyncSpend/Engine/SpendingTelemetryEngine.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/Engine/SpendingTelemetryEngine.swift) |
| **Telemetry Snapshot & Models** | [`syncspend/ios/SyncSpend/Engine/SpendingTelemetrySnapshot.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/Engine/SpendingTelemetrySnapshot.swift) |
| **Dashboard ViewModel** | [`syncspend/ios/SyncSpend/ViewModels/DashboardViewModel.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/ViewModels/DashboardViewModel.swift) |
| **Theme & Card Styles** | [`syncspend/ios/SyncSpend/Theme/Theme.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/Theme/Theme.swift) |
| **Widget View** | [`syncspend/ios/SyncSpendWidget/WeeklySpendWidgetView.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpendWidget/WeeklySpendWidgetView.swift) |
| **ADR 0001 (Telemetry Engine)** | [`docs/adr/0001-pure-domain-telemetry-engine.md`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/docs/adr/0001-pure-domain-telemetry-engine.md) |
| **Domain Glossary** | [`CONTEXT.md`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/CONTEXT.md) |

---

## 5. Suggested Skills for Next Agent

- **`grilling`**: Continue the interactive interview tree to clarify and lock down all design decisions with the user.
- **`codebase-design`**: Integrate chosen UI components with clean, deep seams to `SpendingTelemetryEngine` and `DashboardViewModel`.
- **`prototype`**: Build rapid UI iterations for any contested home page elements before final integration.
- **`tdd`**: Add unit tests for any new view model states or interaction filters.
