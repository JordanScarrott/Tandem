# SyncSpend

A frictionless single-player budgeting and envelope tracking experience on iOS backed by SpacetimeDB, designed to support future couple synchronization.

## Language

**Payday Cycle**:
The recurring monthly budgeting window `[previous_payday, next_payday)` anchored to a user's payday (clamped to days 1–28).
_Avoid_: Billing cycle, budget period, pay period

**Category Envelope**:
A designated monthly budget allocation in integer cents for a specific spending category, supporting live remaining balances and soft overspend alerts.
_Avoid_: Budget bucket, category limit, budget pool

**Spending Telemetry**:
The consolidated financial state of a payday cycle, comprising cumulative pace projections, category envelope statuses, and time-bucketed spending curves.
_Avoid_: Chart data, dashboard statistics, analytics

**Cycle Pace**:
The real-time comparison between actual cumulative spending to date and the ideal linear daily allowance curve within the active payday cycle.
_Avoid_: Spending rate, burn rate, velocity

**Expense**:
An integer-cent expenditure logged by an owner, assigned to a category and payment method, with optional soft-deletion and couple space tagging.
_Avoid_: Transaction, purchase, charge
