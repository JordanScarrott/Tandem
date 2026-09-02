use spacetimedb::SpacetimeType;
use crate::{Category, Expense};

#[derive(SpacetimeType, Clone, Debug, PartialEq, Eq)]
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

#[derive(SpacetimeType, Clone, Debug, PartialEq, Eq)]
pub struct EnvelopeDailyTelemetry {
    pub category_id: u64,
    pub name: String,
    pub monthly_budget_cents: i64,
    pub spent_cents: i64,
    pub headroom_cents: i64,
    pub today_spent_cents: i64,
    pub today_base_allowance_cents: i64,
    pub today_available_cents: i64,
    pub health_state: String,
}

#[derive(SpacetimeType, Clone, Debug, PartialEq, Eq)]
pub struct DailySpendSummary {
    pub day_timestamp_millis: i64,
    pub total_spent_cents: i64,
    pub is_today: bool,
}

/// Computes the Pennies-style dynamic daily allowance and pacing health state.
///
/// Formulas:
/// - Base Allowance: A_base(d) = floor((B - S_prior) / R_d)
/// - Available Today: A_today(d) = A_base(d) - S_today
///
/// Health States:
/// - "OVER_CYCLE": Total cycle spend meets or exceeds total budget (H_cycle <= 0).
/// - "OVER_TODAY": Spent today exceeds today's base allowance (A_today < 0), but cycle is not exhausted.
/// - "CAUTION": Spent today exceeds 80% of today's base allowance.
/// - "HEALTHY": Spent today is within 80% of today's base allowance.
pub fn compute_daily_allowance(
    budget_cents: i64,
    prior_spent_cents: i64,
    today_spent_cents: i64,
    days_remaining: u32,
) -> (i64, i64, &'static str) {
    if budget_cents <= 0 {
        return (0, -today_spent_cents, "HEALTHY");
    }

    let r_d = days_remaining.max(1) as i64;
    let total_spent = prior_spent_cents + today_spent_cents;
    let cycle_headroom = budget_cents - total_spent;

    if cycle_headroom <= 0 {
        let base_allowance = 0;
        let available_today = -today_spent_cents.max(0);
        return (base_allowance, available_today, "OVER_CYCLE");
    }

    let unspent_prior = (budget_cents - prior_spent_cents).max(0);
    let base_allowance = unspent_prior / r_d;
    let available_today = base_allowance - today_spent_cents;

    let health_state = if available_today < 0 {
        "OVER_TODAY"
    } else if today_spent_cents > (base_allowance * 8) / 10 {
        "CAUTION"
    } else {
        "HEALTHY"
    };

    (base_allowance, available_today, health_state)
}

/// Aggregates daily expenditures into clean single-series day buckets.
pub fn aggregate_daily_spending(
    expenses: &[Expense],
    start_millis: i64,
    end_millis: i64,
    today_start_millis: i64,
) -> Vec<DailySpendSummary> {
    const MILLIS_PER_DAY: i64 = 86_400_000;
    if start_millis >= end_millis {
        return Vec::new();
    }

    let num_days = (((end_millis - start_millis) + MILLIS_PER_DAY - 1) / MILLIS_PER_DAY) as usize;
    let mut summaries: Vec<DailySpendSummary> = (0..num_days)
        .map(|i| {
            let day_start = start_millis + (i as i64 * MILLIS_PER_DAY);
            DailySpendSummary {
                day_timestamp_millis: day_start,
                total_spent_cents: 0,
                is_today: day_start <= today_start_millis && today_start_millis < day_start + MILLIS_PER_DAY,
            }
        })
        .collect();

    for expense in expenses {
        if expense.deleted_at.is_some() {
            continue;
        }
        if expense.spent_at_millis < start_millis || expense.spent_at_millis >= end_millis {
            continue;
        }

        let day_idx = ((expense.spent_at_millis - start_millis) / MILLIS_PER_DAY) as usize;
        if day_idx < summaries.len() {
            summaries[day_idx].total_spent_cents += expense.amount_cents;
        }
    }

    summaries
}

/// Computes per-category envelope availability balances and dynamic daily allowances.
pub fn compute_envelope_telemetry(
    categories: &[Category],
    expenses: &[Expense],
    cycle_start_millis: i64,
    today_start_millis: i64,
    days_remaining: u32,
) -> Vec<EnvelopeDailyTelemetry> {
    let mut result = Vec::new();

    for category in categories {
        if category.is_archived {
            continue;
        }

        let budget = category.monthly_budget_cents.unwrap_or(0);

        let mut prior_spent = 0i64;
        let mut today_spent = 0i64;

        for expense in expenses {
            if expense.deleted_at.is_some() || expense.category_id != category.id {
                continue;
            }
            if expense.spent_at_millis < cycle_start_millis {
                continue;
            }

            if expense.spent_at_millis >= today_start_millis {
                today_spent += expense.amount_cents;
            } else {
                prior_spent += expense.amount_cents;
            }
        }

        let total_spent = prior_spent + today_spent;
        let headroom = budget - total_spent;

        let (base_allowance, available_today, health_state) =
            compute_daily_allowance(budget, prior_spent, today_spent, days_remaining);

        result.push(EnvelopeDailyTelemetry {
            category_id: category.id,
            name: category.name.clone(),
            monthly_budget_cents: budget,
            spent_cents: total_spent,
            headroom_cents: headroom,
            today_spent_cents: today_spent,
            today_base_allowance_cents: base_allowance,
            today_available_cents: available_today,
            health_state: health_state.to_string(),
        });
    }

    result
}

#[cfg(test)]
mod tests {
    use super::*;
    use spacetimedb::{Identity, Timestamp};

    #[test]
    fn test_day_one_base_allowance() {
        // Budget = R1,500 ($150,000 cents), 30 days cycle, Day 1
        let budget = 150_000;
        let prior_spent = 0;
        let today_spent = 3_000; // R30 spent today
        let days_remaining = 30;

        let (base, available, health) =
            compute_daily_allowance(budget, prior_spent, today_spent, days_remaining);

        assert_eq!(base, 5_000); // R50.00 base allowance
        assert_eq!(available, 2_000); // R20.00 available today
        assert_eq!(health, "HEALTHY");
    }

    #[test]
    fn test_surplus_rollover_increases_next_day_base() {
        // Day 1: User spent R30 out of R50 base -> R20 surplus rolls over
        // Day 2: Prior spent = R30, 29 days remaining
        let budget = 150_000;
        let prior_spent = 3_000;
        let today_spent = 0;
        let days_remaining = 29;

        let (base, available, health) =
            compute_daily_allowance(budget, prior_spent, today_spent, days_remaining);

        // (150,000 - 3,000) / 29 = 147,000 / 29 = 5,068 cents (~R50.68)
        assert_eq!(base, 5_068);
        assert_eq!(available, 5_068);
        assert_eq!(health, "HEALTHY");
    }

    #[test]
    fn test_deficit_absorption_decreases_subsequent_base() {
        // Day 3: Prior spent R30, User spends R150 on Day 3 (overspending base R52.50 by R97.50)
        let budget = 150_000;
        let prior_spent = 3_000;
        let today_spent = 15_000; // R150.00
        let days_remaining = 28;

        let (base, available, health) =
            compute_daily_allowance(budget, prior_spent, today_spent, days_remaining);

        assert_eq!(base, 5_250); // Base was R52.50
        assert_eq!(available, -9_750); // Overspent by R97.50
        assert_eq!(health, "OVER_TODAY");

        // Day 4: Prior spent is now R30 + R150 = R180 (18,000 cents), 27 days left
        let (next_base, next_available, next_health) =
            compute_daily_allowance(budget, 18_000, 0, 27);

        // (150,000 - 18,000) / 27 = 132,000 / 27 = 4,888 cents (~R48.88)
        assert_eq!(next_base, 4_888);
        assert_eq!(next_available, 4_888);
        assert_eq!(next_health, "HEALTHY");
    }

    #[test]
    fn test_cycle_exhaustion() {
        // User spends R1,600 on an R1,500 total budget
        let budget = 150_000;
        let prior_spent = 140_000;
        let today_spent = 20_000; // Total 160,000
        let days_remaining = 15;

        let (base, available, health) =
            compute_daily_allowance(budget, prior_spent, today_spent, days_remaining);

        assert_eq!(base, 0);
        assert_eq!(available, -20_000);
        assert_eq!(health, "OVER_CYCLE");
    }

    #[test]
    fn test_caution_threshold_at_80_percent() {
        let budget = 150_000;
        let prior_spent = 0;
        let days_remaining = 30; // base = 5,000
        let today_spent = 4_200; // 84% of base

        let (base, available, health) =
            compute_daily_allowance(budget, prior_spent, today_spent, days_remaining);

        assert_eq!(base, 5_000);
        assert_eq!(available, 800);
        assert_eq!(health, "CAUTION");
    }

    #[test]
    fn test_aggregate_daily_spending() {
        let dummy_owner = Identity::from_byte_array([1; 32]);
        let now = Timestamp::from_micros_since_unix_epoch(1_000_000);

        let expenses = vec![
            Expense {
                id: 1,
                owner: dummy_owner,
                amount_cents: 2_500,
                currency: "ZAR".into(),
                category_id: 1,
                payment_method: "CARD".into(),
                note: "Lunch".into(),
                spent_at_millis: 100_000_000,
                created_at: now,
                updated_at: now,
                deleted_at: None,
                space_id: None,
                split_mode: "PERSONAL".into(),
            },
            Expense {
                id: 2,
                owner: dummy_owner,
                amount_cents: 1_500,
                currency: "ZAR".into(),
                category_id: 1,
                payment_method: "CARD".into(),
                note: "Coffee".into(),
                spent_at_millis: 100_000_000 + 3_600_000, // Same day
                created_at: now,
                updated_at: now,
                deleted_at: None,
                space_id: None,
                split_mode: "PERSONAL".into(),
            },
            Expense {
                id: 3,
                owner: dummy_owner,
                amount_cents: 9_999,
                currency: "ZAR".into(),
                category_id: 1,
                payment_method: "CARD".into(),
                note: "Deleted".into(),
                spent_at_millis: 100_000_000,
                created_at: now,
                updated_at: now,
                deleted_at: Some(now), // Deleted!
                space_id: None,
                split_mode: "PERSONAL".into(),
            },
        ];

        let summaries = aggregate_daily_spending(
            &expenses,
            100_000_000,
            100_000_000 + (3 * 86_400_000),
            100_000_000,
        );

        assert_eq!(summaries.len(), 3);
        assert_eq!(summaries[0].total_spent_cents, 4_000); // 2,500 + 1,500 (deleted ignored)
        assert_eq!(summaries[0].is_today, true);
        assert_eq!(summaries[1].total_spent_cents, 0);
        assert_eq!(summaries[2].total_spent_cents, 0);
    }
}
