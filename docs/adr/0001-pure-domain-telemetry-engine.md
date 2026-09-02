# 0001: Extract Pure Domain Spending Telemetry Engine

## Context & Decision

Financial calculations for monthly payday cycles, cumulative pace projections, category envelope statuses, and multi-period chart aggregations were previously implemented across 400+ lines of computed properties inside `DashboardViewModel`. This shallow architecture tangled UI state synchronization with time-sensitive math and made deterministic verification cumbersome.

We decided to extract all financial aggregation, pace modeling, and time-bucketing into a deep, pure-function module `SpendingTelemetryEngine` returning an immutable `SpendingTelemetrySnapshot`. The engine has zero UI or async dependencies and accepts explicit `asOf: Date` and `calendar: Calendar` arguments for 100% deterministic testability.

## Considered Options

- **Keep calculations in `DashboardViewModel`**: Rejected because UI state became a god-object, math was hard to test in isolation, and chart prototypes had to duplicate logic.
- **Split into separate `PaceEngine` and `ChartEngine`**: Rejected because both engines iterate over the same expense and category sets and depend on identical payday cycle intervals.

## Consequences

- All financial pacing and envelope calculations live in `SyncSpend/Engine/SpendingTelemetryEngine.swift`.
- `DashboardViewModel` shrinks significantly, delegating telemetry generation to `SpendingTelemetryEngine.analyze(...)`.
- Instant in-memory unit tests verify leap years, month-end clamps, and pace boundaries without mock databases or clock manipulation.
