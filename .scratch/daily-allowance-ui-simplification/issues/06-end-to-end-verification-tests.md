# 06: End-to-End Verification & Unit Tests

**What to build:**
Comprehensive automated and UI verification validating that SpacetimeDB telemetry computations, iOS `SpendingTelemetryEngine` calculations, daily allowance updates, chart interactions, and envelope focus swaps function flawlessly with 100% test pass rate.

**Blocked by:** 05: Category Envelope Focus Swap Interaction

**Status:** completed

- [x] Write SpacetimeDB integration tests verifying dynamic recalculation of `available_today` as expenses are logged, edited, or deleted.
- [x] Write iOS unit tests for `DashboardViewModel` and `SpendingTelemetryEngine` covering daily allowance formulas and zero/negative headroom edge cases.
- [x] Verify clean Xcode build and run full test suite with all tests passing.
