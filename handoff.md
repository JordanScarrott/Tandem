# Handoff: Single-Player Budgeting & Envelope Engine Implementation

## 1. Context & Next Steps
We completed the architectural design, user story mapping, and schema specification for the **Single-Player Budgeting & Category Envelope Engine** (Milestone 2).
The complete map of decisions and tickets is recorded in [`wayfinder.md`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/wayfinder.md).

**Next Task for Incoming Agent:**
Begin implementation starting with **`TICKET-SP-01`** (Backend: Profile, Envelopes & Soft-Delete Engine in `syncspend/server/src/lib.rs`).

---

## 2. Settled Decisions & Guardrails
- **Integer Accounting:** All monetary values in `i64` ZAR cents (`amount_cents`, `monthly_budget_cents`).
- **Payday Cycle Window:** Bounded to `[previous_payday, next_payday)` clamped to `min(billing_cycle_start_day, days_in_month)`. Zero rollover.
- **Onboarding:** First-run modal sets name & payday (1–28). "Skip for now" seeds defaults (`"You"`, `"ZAR"`, day `1`) and 5 starter envelopes.
- **Rapid Entry Flow:** Amount first $\rightarrow$ Note field (defaults to category name if blank) $\rightarrow$ Sliding wheel pickers for category and payment method $\rightarrow$ Bottom confirm CTA.
- **Overspending Alerts:** Soft visual alerts (red progress bar, negative remaining); no hard blocking.
- **5-Second Transient Undo:** Soft delete (`deleted_at: Option<Timestamp>`) with a floating haptic countdown toast on iOS.

---

## 3. Ticket Roadmap
1. **`TICKET-SP-01` (Backend - Rust)**: Update `server/src/lib.rs` with `UserProfile`, `Category` (with `space_id: Option<u64>` seam), `update_user_profile`, `create_category`, `update_category`, `archive_category`, and soft-delete/restore reducers. Verify with `cargo check` and `spacetime build`.
2. **`TICKET-SP-02` (iOS UI)**: First-Run Onboarding Modal (with "Skip for now") and Settings Payday anchor configuration.
3. **`TICKET-SP-03` (iOS UI)**: High-Velocity Rapid Expense Sheet (Amount $\rightarrow$ Note $\rightarrow$ Wheel Pickers $\rightarrow$ Default Title $\rightarrow$ Bottom CTA).
4. **`TICKET-SP-04` (iOS UI)**: Payday-Cycle Category Envelope Dashboard cards with overspend indicators.
5. **`TICKET-SP-05` (iOS UI)**: Swipe-to-Delete with 5-Second Transient Haptic Floating Undo Bar.

---

## 4. Key Files
- Map & Specs: [`wayfinder.md`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/wayfinder.md)
- Backend: [`syncspend/server/src/lib.rs`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/server/src/lib.rs)
- iOS Services: [`syncspend/ios/SyncSpend/Services/SpacetimeService.swift`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/Services/SpacetimeService.swift)
- iOS Views: [`syncspend/ios/SyncSpend/Views/`](file:///Users/jordanscarrott/Documents/GitHub/personal/Tandem/syncspend/ios/SyncSpend/Views/)

---

## 5. Suggested Skills
- `wayfinder` (to track ticket progress)
- `domain-modeling`
- `tdd`