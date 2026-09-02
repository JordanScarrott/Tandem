# Handoff: Implement SpacetimeDB Daily Budget Telemetry & Headroom Engine (Ticket 02)

## 1. Current Progress & Milestone Completed

**Ticket 01 Completed:** Dynamic Daily Allowance & Budget Pacing Research document published at [`docs/research/pennies-daily-budget-pacing.md`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/docs/research/pennies-daily-budget-pacing.md).

---

## 2. Next Agent Objective

Execute **Ticket 02: SpacetimeDB Daily Budget Telemetry & Headroom Engine** ([`02-spacetimedb-daily-budget-telemetry-engine.md`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/.scratch/daily-allowance-ui-simplification/issues/02-spacetimedb-daily-budget-telemetry-engine.md)).

### Core Focus:
Implement backend domain logic and queries/views in the SpacetimeDB Rust module ([`syncspend/server/src/lib.rs`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/server/src/lib.rs)) to compute dynamic spending telemetry:
1. **Daily Aggregated Spending Totals**: Aggregate total expenditures per calendar day without stacked multi-category complexity.
2. **Dynamic Daily Allowance Formula**: Calculate $A_{\text{base}}(d) = \lfloor (B - S_{\text{prior}}) / R_d \rfloor$ and $A_{\text{today}}(d) = A_{\text{base}}(d) - S_{\text{today}}$ with overspend/deficit guards.
3. **Category Envelope Headroom**: Compute spent amounts vs assigned budget limit and per-envelope daily allowance.
4. **Backend Unit Tests**: Verify dynamic allowance recalculation across single-day spend, multi-day roll-overs, overspending, and zero/unset budgets.

---

## 3. Related Tracer-Bullet Tickets

Located in [`.scratch/daily-allowance-ui-simplification/issues/`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/.scratch/daily-allowance-ui-simplification/issues/):
- [x] [01-research-pennies-daily-allowance-metric.md](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/.scratch/daily-allowance-ui-simplification/issues/01-research-pennies-daily-allowance-metric.md) (Completed)
- [ ] [02-spacetimedb-daily-budget-telemetry-engine.md](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/.scratch/daily-allowance-ui-simplification/issues/02-spacetimedb-daily-budget-telemetry-engine.md) (Current Ticket)
- [ ] [03-ios-domain-bridge-telemetry-snapshot.md](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/.scratch/daily-allowance-ui-simplification/issues/03-ios-domain-bridge-telemetry-snapshot.md) (Blocked by 02)
- [ ] [04-simplified-totals-hero-chart.md](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/.scratch/daily-allowance-ui-simplification/issues/04-simplified-totals-hero-chart.md) (Blocked by 03)
- [ ] [05-category-envelope-focus-state-swap.md](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/.scratch/daily-allowance-ui-simplification/issues/05-category-envelope-focus-state-swap.md) (Blocked by 04)
- [ ] [06-end-to-end-verification-tests.md](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/.scratch/daily-allowance-ui-simplification/issues/06-end-to-end-verification-tests.md) (Blocked by 05)

---

## 4. Key References & Codebase Context

- **Research Document:** [`docs/research/pennies-daily-budget-pacing.md`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/docs/research/pennies-daily-budget-pacing.md)
- **SpacetimeDB Server Module:** [`syncspend/server/src/lib.rs`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/server/src/lib.rs)
- **iOS Telemetry Engine:** [`syncspend/ios/SyncSpend/Engine/SpendingTelemetryEngine.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/Engine/SpendingTelemetryEngine.swift)
- **Domain Glossary:** [`CONTEXT.md`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/CONTEXT.md)
- **ADR 0001 (Pure Domain Telemetry):** [`docs/adr/0001-pure-domain-telemetry-engine.md`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/docs/adr/0001-pure-domain-telemetry-engine.md)
