# Research: Pennies Dynamic Daily Budget Allowance & Pacing Mechanics

**Ticket:** [01: Research Pennies Daily Allowance & Budget Pacing Mechanics](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/.scratch/daily-allowance-ui-simplification/issues/01-research-pennies-daily-allowance-metric.md)  
**Author / Engine:** SyncSpend Domain Research  
**Primary References:**
- *Pennies* by Emile Bennett (App Store Editor's Choice, [emilebennett.com](https://www.emilebennett.com), Apple Design Award Nominee)
- *The Philosophy of Daily Budgeting & Cognitive Micro-Pacing* (Behavioral Economics of Spending Pacing)
- *Tandem / SyncSpend Domain Context* ([`CONTEXT.md`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/CONTEXT.md), [`docs/adr/0001-pure-domain-telemetry-engine.md`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/docs/adr/0001-pure-domain-telemetry-engine.md))

---

## 1. Executive Summary & The "Pennies" Paradigm

Traditional budgeting applications (e.g. Mint, legacy bank dashboards) present users with static monthly progress bars (e.g. "$1,200 of $2,000 spent"). While mathematically accurate, this macro-level presentation causes **cognitive dissonance and mid-cycle spending fatigue**:
1. At the start of a month, users feel artificially rich seeing large remaining sums, leading to front-loaded overspending.
2. By mid-to-late cycle, users struggle to calculate how much they can safely spend on an ad-hoc expense (e.g., lunch, groceries) without jeopardizing the rest of the cycle.

**Pennies (created by Emile Bennett in 2014)** pioneered the "Daily Allowance" paradigm. Rather than showing intimidating macro charts, Pennies translates complex monthly or payday cycles into a single, glanceable, action-oriented financial metric: **"Available to spend today"**.

When you spend less than your daily allowance, the surplus automatically redistributes across the remaining days in your cycle, increasing your future daily allowance. When you overspend today, the excess is absorbed by subsequent days, reducing tomorrow's allowance without breaking the overall budget.

This document formalizes the mathematical models, lifecycle transitions, edge cases, category interactions, and UI states required for SyncSpend's SpacetimeDB Rust engine and iOS frontend.

---

## 2. Core Mechanics & Mathematical Specification

### 2.1 Domain Definitions & Variables

| Variable | Definition | Unit / Type |
| :--- | :--- | :--- |
| $B$ | Total Budget allocation for the active Payday Cycle (Global or Category Envelope) | Integer Cents ($i64$) |
| $D$ | Total number of calendar days in the active Payday Cycle | Integer ($u32$) |
| $d$ | Current calendar day index within the cycle ($1 \le d \le D$) | Integer ($u32$) |
| $R_d$ | Days remaining in the cycle, **including today** ($R_d = D - d + 1$) | Integer ($u32 \ge 1$) |
| $S_{\text{prior}}$ | Cumulative spent amount on past days within the cycle ($1 \dots d-1$) | Integer Cents ($i64$) |
| $S_{\text{today}}$ | Cumulative spent amount logged specifically on day $d$ | Integer Cents ($i64$) |
| $S_{\text{cycle}}$ | Total spent in cycle to date ($S_{\text{cycle}} = S_{\text{prior}} + S_{\text{today}}$) | Integer Cents ($i64$) |
| $H_{\text{cycle}}$ | Remaining cycle headroom ($H_{\text{cycle}} = B - S_{\text{cycle}}$) | Integer Cents ($i64$) |

---

### 2.2 Dynamic Daily Allowance Formula

At any point during day $d$, the **Start-of-Day Base Allowance** ($A_{\text{base}}$) is computed by taking the total unspent budget entering day $d$ and dividing it equally across all remaining days $R_d$:

$$A_{\text{base}}(d) = \left\lfloor \frac{B - S_{\text{prior}}}{R_d} \right\rfloor = \left\lfloor \frac{B - S_{\text{prior}}}{D - d + 1} \right\rfloor$$

The real-time **Available to Spend Today** ($A_{\text{today}}$) represents how much headroom the user has left *right now* for today:

$$A_{\text{today}}(d) = A_{\text{base}}(d) - S_{\text{today}} = \left\lfloor \frac{B - S_{\text{prior}}}{D - d + 1} \right\rfloor - S_{\text{today}}$$

#### Alternative Equivalent Representation:
$$A_{\text{today}}(d) = \left\lfloor \frac{H_{\text{cycle}} + S_{\text{today}}}{R_d} \right\rfloor - S_{\text{today}}$$

---

### 2.3 Intra-Day and Inter-Day Dynamic Redistribution

The core behavioral magic of Pennies is how it reacts across three distinct spending states:

```
                                  [ Start of Day d ]
                                           │
                                           ▼
                         Compute Base Allowance: A_base(d)
                                           │
                                           ▼
                     ┌─────────────────────┴─────────────────────┐
                     │                                           │
             [ Spend Today: S_today ]                    [ No Spend Today ]
                     │                                           │
         ┌───────────┴───────────┐                               │
         ▼                       ▼                               ▼
S_today ≤ A_base(d)     S_today > A_base(d)             Surplus Rollover:
  (Under Budget)           (Overspent Today)             Full A_base(d) rolls over
         │                       │                               │
         ▼                       ▼                               ▼
A_today ≥ 0             A_today < 0                     Tomorrow's A_base(d+1)
Remaining surplus       Deficit absorbed by              increases for all
spreads over days       days d+1...D                    subsequent days
d+1...D
```

#### Case 1: Underspending on Day $d$ ($S_{\text{today}} < A_{\text{base}}(d)$)
- **Today's Status:** User is healthy ($A_{\text{today}} > 0$).
- **Surplus:** $\Delta_{\text{surplus}} = A_{\text{base}}(d) - S_{\text{today}}$.
- **Next Day's Base Allowance ($d+1$):**
  $$A_{\text{base}}(d+1) = \left\lfloor \frac{B - (S_{\text{prior}} + S_{\text{today}})}{R_{d+1}} \right\rfloor = \left\lfloor \frac{(B - S_{\text{prior}} - A_{\text{base}}(d)) + \Delta_{\text{surplus}}}{R_d - 1} \right\rfloor$$
  Because $\Delta_{\text{surplus}} > 0$, the unspent portion is distributed over the remaining $R_d - 1$ days, increasing each subsequent day's base allowance by $\approx \frac{\Delta_{\text{surplus}}}{R_d - 1}$.

#### Case 2: Overspending on Day $d$ ($S_{\text{today}} > A_{\text{base}}(d)$)
- **Today's Status:** User has exceeded today's allowance ($A_{\text{today}} < 0$).
- **Deficit:** $\Delta_{\text{deficit}} = S_{\text{today}} - A_{\text{base}}(d)$.
- **Next Day's Base Allowance ($d+1$):**
  $$A_{\text{base}}(d+1) = \left\lfloor \frac{B - (S_{\text{prior}} + S_{\text{today}})}{R_{d+1}} \right\rfloor$$
  The excess spend reduces the remaining budget pool, automatically lowering future daily allowances by $\approx \frac{\Delta_{\text{deficit}}}{R_d - 1}$ without any manual adjustment required from the user.

#### Case 3: Complete Cycle Exhaustion ($S_{\text{cycle}} \ge B$)
- When total spending matches or exceeds the cycle budget:
  $$H_{\text{cycle}} \le 0 \implies A_{\text{base}}(d') = 0 \quad \forall d'$$
  $$A_{\text{today}} = \min(0, -S_{\text{today}})$$
- The UI transitions into an explicit **Over Budget** warning state, displaying the exact cycle deficit ($S_{\text{cycle}} - B$).

---

## 3. Concrete Numerical Example

Consider a monthly Payday Cycle of $D = 30$ days with a total discretionary budget $B = \$1,500.00$ ($150,000$ cents):

| Day ($d$) | Days Left ($R_d$) | Prior Spend ($S_{\text{prior}}$) | Start-of-Day Base ($A_{\text{base}}$) | Spent Today ($S_{\text{today}}$) | Available Today ($A_{\text{today}}$) | Next Day Base ($A_{\text{base}}(d+1)$) | Status / Notes |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| **Day 1** | 30 | \$0.00 | **\$50.00** | \$30.00 | **+\$20.00** | **\$50.68** | Under budget by \$20. \$20 rolls into remaining 29 days (+\$0.68/day). |
| **Day 2** | 29 | \$30.00 | **\$50.68** | \$0.00 | **+\$50.68** | **\$52.50** | Zero spend. Full \$50.68 rolls into remaining 28 days (+\$1.81/day). |
| **Day 3** | 28 | \$30.00 | **\$52.50** | \$150.00 | **-\$97.50** | **\$48.88** | Large purchase (dinner/party). Overspent today by \$97.50; future daily budget absorbed hit smoothly (-\$3.62/day). |
| **Day 4** | 27 | \$180.00 | **\$48.88** | \$48.88 | **\$0.00** | **\$48.88** | Spent exact allowance. Remaining daily allowance holds steady. |

---

## 4. Category Envelopes vs. Global Headroom

In Pennies, each distinct budget (e.g., "Groceries", "Entertainment", "Trip") operates as an independent daily pacing engine. In SyncSpend / Tandem, we combine the strength of **Global Payday Cycle Telemetry** with **Discrete Category Envelopes**.

### 4.1 Dual-Level Metric Structure

1. **Global Dashboard View (Default)**:
   - Evaluates total discretionary budget ($B_{\text{global}} = \sum \text{Envelope Limits}$ or configured global cap).
   - Surfaces global $A_{\text{today}}^{\text{global}}$ as the primary hero metric.
   - Shows a single-series daily bar chart of total spending per day.

2. **Category Envelope Focus View (On Tap / Selection)**:
   - When the user taps a Category Envelope (e.g. "Dining Out", cap R3,000), the hero metric instantly contextualizes to that specific envelope:
     $$A_{\text{base}}^{\text{cat}}(d) = \left\lfloor \frac{B_{\text{cat}} - S_{\text{prior}}^{\text{cat}}}{R_d} \right\rfloor$$
     $$A_{\text{today}}^{\text{cat}}(d) = A_{\text{base}}^{\text{cat}}(d) - S_{\text{today}}^{\text{cat}}$$
   - The hero bar chart spotlights historical daily spend for that category alone against the category's daily allowance guideline.

---

## 5. Visual UX Telemetry & Health States

Pennies achieved high user delight by mapping numerical status to immediate chromatic feedback:

```
┌────────────────────────────────────────────────────────┐
│                      SYNCSPEND                         │
│                                                        │
│                  AVAILABLE TODAY                       │
│                     R 450.00                           │
│           ● Healthy • R2,450 left in cycle             │
│                                                        │
│      [ Bar Chart: Daily Spend vs Daily Allowance ]     │
│   |    |    |    |    |    |                           │
│   |    |    |    |    |    |     |                     │
│  Mon  Tue  Wed  Thu  Fri  Sat   Sun (Today)            │
│  ───────────────────────────────- - - - - - - - -      │
│                                                        │
│  CATEGORY ENVELOPES (Tap to focus)                     │
│  [ Groceries: R1,200/R3,000 ]  [ Dining: R800/R1,500 ] │
└────────────────────────────────────────────────────────┘
```

### 5.1 Chromatic Health Thresholds

| State | Metric Condition | Visual Presentation | Semantic Meaning |
| :--- | :--- | :--- | :--- |
| **Healthy (Green)** | $S_{\text{today}} \le 0.80 \times A_{\text{base}}$ ($A_{\text{today}} \ge 0.20 \times A_{\text{base}}$) | `Theme.accentGreen` (`#10B981`) | Spending is well within today's allowance. High confidence to spend. |
| **Pacing / Caution (Amber)** | $0.80 \times A_{\text{base}} < S_{\text{today}} \le A_{\text{base}}$ | `Theme.accentYellow` (`#F59E0B`) | Approaching today's limit. Mindful spending recommended. |
| **Exceeded Today (Rose / Orange)** | $A_{\text{base}} < S_{\text{today}} \le A_{\text{base}} + \text{buffer}$ AND $S_{\text{cycle}} < B$ | `Theme.accentOrange` (`#F97316`) | Over today's allowance, but overall cycle budget remains healthy. |
| **Over Budget (Red)** | $S_{\text{cycle}} \ge B$ (Total Cycle Depleted) | `Theme.accentRed` (`#EF4444`) | Cycle budget completely exhausted. Deficit mode. |

---

## 6. Edge Cases & Boundary Handling

### 6.1 Last Day of Cycle ($d = D, R_d = 1$)
- On the final day of the payday cycle, $R_d = 1$.
- $A_{\text{base}}(D) = B - S_{\text{prior}} = H_{\text{cycle}}$.
- Available today is exactly equal to the entire remaining cycle headroom.

### 6.2 Cycle Boundary Transition ($d = D \to d = 1$)
- **Standard Pennies Model (Reset):** At 00:00 on the new cycle start date, $S_{\text{prior}}$ resets to $0$, and $A_{\text{base}}(1) = \lfloor B / D_{\text{new}} \rfloor$.
- **Rollover Options:**
  - *Option A (Default - Fresh Start):* Unspent surplus is banked into savings; new cycle starts clean at $B$.
  - *Option B (Debt Rollover):* If the previous cycle ended in deficit ($S_{\text{cycle}} > B$), the deficit can optionally reduce the starting budget of the next cycle ($B_{\text{effective}} = B - \text{Deficit}$).

### 6.3 Integer Division & Cent Truncation
- All domain arithmetic uses **integer cents ($i64$)**.
- Division by $R_d$ uses integer floor division (`remaining_cents / days_remaining`).
- The residual cent remainder $(\text{cents} \pmod{R_d})$ remains in the unspent pool and is naturally accounted for on subsequent days, guaranteeing zero cumulative rounding drift.

### 6.4 Zero or Unset Budget Cap ($B = 0$)
- If no budget cap is set, $A_{\text{base}}$ and $A_{\text{today}}$ are undefined / null.
- The UI displays total spend to date without pacing indicators or overspend warnings.

---

## 7. SpacetimeDB & Swift Implementation Architecture

### 7.1 SpacetimeDB Rust Types & Telemetry Structs

To support fast client reactivity and minimize client-side compute overhead, the SpacetimeDB module can compute and provide a `DailyBudgetTelemetry` struct:

```rust
pub struct DailyBudgetTelemetry {
    pub cycle_total_budget_cents: i64,
    pub cycle_spent_cents: i64,
    pub cycle_headroom_cents: i64,
    pub cycle_total_days: u32,
    pub cycle_current_day_index: u32,
    pub cycle_days_remaining: u32,
    pub today_spent_cents: i64,
    pub today_base_allowance_cents: i64,
    pub today_available_cents: i64,
    pub health_state: String, // "HEALTHY", "CAUTION", "OVER_TODAY", "OVER_CYCLE"
}

pub struct EnvelopeDailyTelemetry {
    pub category_id: u64,
    pub monthly_budget_cents: i64,
    pub spent_cents: i64,
    pub headroom_cents: i64,
    pub today_spent_cents: i64,
    pub today_base_allowance_cents: i64,
    pub today_available_cents: i64,
}
```

### 7.2 Swift Pure Domain Calculations (`SpendingTelemetryEngine.swift`)

The Swift domain engine will ingest these metrics into `SpendingTelemetrySnapshot`, powering the simplified dashboard:
- `pace.todayAvailableCents`: For the primary hero card figure.
- `pace.todayBaseAllowanceCents`: For the reference baseline.
- `distribution.dailyAggregates`: For the clean single-series totals bar chart.
- `envelopes`: For the interactive envelope chips with tap-to-focus swap.

---

## 8. Summary of Research Conclusions for Downstream Tickets

1. **Ticket 02 (SpacetimeDB):** Implement the `(B - S_prior) / R_d` formula and daily aggregation reducer directly in the Rust module, ensuring full test coverage for under-spend, over-spend, and month boundary rollovers.
2. **Ticket 03 (iOS Domain Bridge):** Add `todayAvailableCents`, `todayBaseAllowanceCents`, and health enum to `PaceTelemetry` and `SpendingTelemetrySnapshot`.
3. **Ticket 04 (Simplified Hero Chart):** Replace multi-category bar charts with single-series daily spend bars and the prominent "Available to Spend Today" hero metric.
4. **Ticket 05 (Category Envelope Focus Swap):** Allow tapping an envelope to recalculate and swap the hero view to that envelope's daily allowance and spending trajectory.
5. **Ticket 06 (E2E Verification):** Comprehensive automated test suite verifying exact math across 28/29/30/31 day cycles and leap years.
