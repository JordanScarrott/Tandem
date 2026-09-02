# 03: iOS Domain Bridge & Daily Allowance Telemetry Snapshot

**What to build:**
Update the client-side `SpendingTelemetryEngine` and `DashboardViewModel` in iOS to consume the backend SpacetimeDB daily allowance and simplified total aggregates, producing a clean `SpendingTelemetrySnapshot` with `availableToday`, `dailyTotals`, and `envelopeAvailability`.

**Blocked by:** 02: SpacetimeDB Daily Budget Telemetry & Headroom Engine

**Status:** completed

- [x] Update `SpendingTelemetrySnapshot` data structures to include `availableToday`, `todaySpent`, `daysRemainingInCycle`, and simplified single-series daily totals.
- [x] Connect `SpacetimeDBClient` subscriptions to stream real-time telemetry updates into `DashboardViewModel`.
- [x] Maintain offline / local fallback in `SpendingTelemetryEngine` matching SpacetimeDB backend calculation rules.
- [x] Add unit tests in `SyncSpendTests` validating `SpendingTelemetryEngine` calculations.
