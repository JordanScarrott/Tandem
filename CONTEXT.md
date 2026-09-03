# SyncSpend

A frictionless personal and couple financial budgeting application on iOS backed by SpacetimeDB, combining dynamic daily allowance micro-pacing ("Pennies" paradigm) with real-time multiplayer synchronization.

Comprehensive guide, architecture diagrams, and ASD-STE100 system glossary: [docs/domain-guide.md](docs/domain-guide.md).

## Language

**Payday Cycle**:
The recurring monthly budgeting window `[previous_payday, next_payday)` anchored to a user's payday (clamped to days 1–28).
_Avoid_: Billing cycle, budget period, pay period

**Category Envelope**:
A designated monthly budget allocation in integer cents for a specific spending category, supporting live remaining balances and soft overspend alerts.
_Avoid_: Budget bucket, category limit, budget pool, spending cap

**Spending Telemetry**:
The consolidated financial state of a payday cycle, comprising cumulative pace projections, category envelope statuses, and time-bucketed spending curves.
_Avoid_: Chart data, dashboard statistics, analytics, BI metrics

**Cycle Pace**:
The real-time comparison between actual cumulative spending to date and the ideal linear daily allowance curve within the active payday cycle.
_Avoid_: Spending rate, burn rate, velocity

**Expense**:
An integer-cent expenditure logged by an owner, assigned to a category and payment method, with optional soft-deletion and couple space tagging.
_Avoid_: Transaction, purchase, charge, line item

**Base Daily Allowance**:
The start-of-day allowance calculated by dividing unspent budget entering the day by the remaining cycle days ($A_{\text{base}}$).
_Avoid_: Daily budget, daily quota, baseline allowance

**Available to Spend Today**:
The real-time remaining spending allowance for the current calendar day after subtracting today's logged expenses ($A_{\text{today}}$).
_Avoid_: Daily remaining, day cash, remaining today

**Couple Space**:
A shared domain context linking two authenticated user identities with defined split ratios for cooperative expense tracking and settlement.
_Avoid_: Shared room, joint account, couple profile

