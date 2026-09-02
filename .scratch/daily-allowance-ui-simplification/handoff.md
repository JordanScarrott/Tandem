# Handoff: Dynamic Daily Allowance & Simplified UI Architecture

## 1. Objective of Next Phase

The goal is to implement the **Pennies-inspired Dynamic Daily Allowance Architecture** and simplified home dashboard experience:
1. **Backend-first**: Model the dynamic daily headroom redistribution and total aggregate spending in SpacetimeDB (Rust).
2. **Simplified Visual Hierarchy**:
   - Replace complex stacked multi-category bars with a bold, single-series **Total Daily Spend** bar chart.
   - Surface a prominent **"Available to Spend Today"** hero metric with pace health indicators.
   - Decouple **Category Envelopes** into standalone availability facts (spent vs limit) with tap-to-focus swap interactions.

---

## 2. Tracer-Bullet Tickets

All tickets are documented under [`.scratch/daily-allowance-ui-simplification/issues/`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/.scratch/daily-allowance-ui-simplification/issues/):

1. **[01-research-pennies-daily-allowance-metric.md](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/.scratch/daily-allowance-ui-simplification/issues/01-research-pennies-daily-allowance-metric.md)**
   - Research *Pennies* (by Emile Bennett) daily budget calculation, dynamic rollover across payday cycle, and category allocations.
   - Deliverable: `docs/research/pennies-daily-budget-pacing.md`.
   - Blocked by: None (Start immediately).

2. **[02-spacetimedb-daily-budget-telemetry-engine.md](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/.scratch/daily-allowance-ui-simplification/issues/02-spacetimedb-daily-budget-telemetry-engine.md)**
   - Implement pure domain logic & reducers in SpacetimeDB module for daily totals, dynamic "Available Today", and envelope balances.
   - Blocked by: `01`.

3. **[03-ios-domain-bridge-telemetry-snapshot.md](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/.scratch/daily-allowance-ui-simplification/issues/03-ios-domain-bridge-telemetry-snapshot.md)**
   - Update iOS `SpendingTelemetrySnapshot`, `SpendingTelemetryEngine`, and `DashboardViewModel` to stream and store new telemetry metrics.
   - Blocked by: `02`.

4. **[04-simplified-totals-hero-chart.md](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/.scratch/daily-allowance-ui-simplification/issues/04-simplified-totals-hero-chart.md)**
   - Build simplified dashboard hero with prominent "Available Today" number and clean totals-only daily bar chart.
   - Blocked by: `03`.

5. **[05-category-envelope-focus-state-swap.md](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/.scratch/daily-allowance-ui-simplification/issues/05-category-envelope-focus-state-swap.md)**
   - Implement envelope focus interaction: tapping an envelope swaps the hero chart for that category's individual budget availability.
   - Blocked by: `04`.

6. **[06-end-to-end-verification-tests.md](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/.scratch/daily-allowance-ui-simplification/issues/06-end-to-end-verification-tests.md)**
   - Automated unit test suite (SpacetimeDB + iOS) and full build verification.
   - Blocked by: `05`.

---

## 3. Key Reference Files

| Component | File Path |
| :--- | :--- |
| **SpacetimeDB Module** | [`syncspend/spacetimedb/server/src/lib.rs`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/spacetimedb/server/src/lib.rs) |
| **Telemetry Engine (iOS)** | [`syncspend/ios/SyncSpend/Engine/SpendingTelemetryEngine.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/Engine/SpendingTelemetryEngine.swift) |
| **Telemetry Snapshot & Models** | [`syncspend/ios/SyncSpend/Engine/SpendingTelemetrySnapshot.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/Engine/SpendingTelemetrySnapshot.swift) |
| **Dashboard ViewModel** | [`syncspend/ios/SyncSpend/ViewModels/DashboardViewModel.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/ViewModels/DashboardViewModel.swift) |
| **Main Dashboard View** | [`syncspend/ios/SyncSpend/Views/MainDashboardView.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/Views/MainDashboardView.swift) |
| **Theme & Tokens** | [`syncspend/ios/SyncSpend/Theme/Theme.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/Theme/Theme.swift) |
| **ADR 0001** | [`docs/adr/0001-pure-domain-telemetry-engine.md`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/docs/adr/0001-pure-domain-telemetry-engine.md) |
