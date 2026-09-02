import XCTest
@testable import SyncSpend

final class SpendingTelemetryEngineTests: XCTestCase {
    
    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }
    
    private func makeDate(year: Int, month: Int, day: Int, hour: Int = 12) -> Date {
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = day
        comps.hour = hour
        comps.minute = 0
        comps.second = 0
        return calendar.date(from: comps)!
    }
    
    private func dateToMillis(_ date: Date) -> Int64 {
        Int64(date.timeIntervalSince1970 * 1000.0)
    }
    
    // MARK: - Payday Cycle Date Anchor Tests
    
    func testPaydayCycleWindow_MiddleOfMonthAnchor() {
        let currentDate = makeDate(year: 2026, month: 8, day: 26)
        let cycle = PaydayCycle.current(billingCycleStartDay: 25, currentDate: currentDate, calendar: calendar)
        
        XCTAssertEqual(cycle.billingCycleStartDay, 25)
        
        let startDay = calendar.component(.day, from: cycle.startDate)
        let startMonth = calendar.component(.month, from: cycle.startDate)
        let endDay = calendar.component(.day, from: cycle.endDate)
        let endMonth = calendar.component(.month, from: cycle.endDate)
        
        XCTAssertEqual(startDay, 25)
        XCTAssertEqual(startMonth, 8)
        XCTAssertEqual(endDay, 25)
        XCTAssertEqual(endMonth, 9)
        XCTAssertTrue(cycle.contains(date: currentDate))
    }
    
    func testPaydayCycleWindow_BeforeAnchorDayInMonth() {
        let currentDate = makeDate(year: 2026, month: 8, day: 10)
        let cycle = PaydayCycle.current(billingCycleStartDay: 25, currentDate: currentDate, calendar: calendar)
        
        let startDay = calendar.component(.day, from: cycle.startDate)
        let startMonth = calendar.component(.month, from: cycle.startDate)
        let endDay = calendar.component(.day, from: cycle.endDate)
        let endMonth = calendar.component(.month, from: cycle.endDate)
        
        XCTAssertEqual(startDay, 25)
        XCTAssertEqual(startMonth, 7)
        XCTAssertEqual(endDay, 25)
        XCTAssertEqual(endMonth, 8)
        XCTAssertTrue(cycle.contains(date: currentDate))
    }
    
    // MARK: - Pace Telemetry Tests
    
    func testPaceTelemetry_OnTrackUnderPace() {
        let cycleStart = makeDate(year: 2026, month: 8, day: 1)
        let cycleEnd = makeDate(year: 2026, month: 9, day: 1)
        let asOf = makeDate(year: 2026, month: 8, day: 15) // Day 15 of 31
        let cycle = PaydayCycle(billingCycleStartDay: 1, startDate: cycleStart, endDate: cycleEnd)
        
        let categories = [
            CategoryItem(id: 1, name: "Groceries", icon: "cart", colorHex: "#10B981", monthlyBudgetCents: 310000, isArchived: false) // R3100 / month = R100/day
        ]
        
        let spentDate = makeDate(year: 2026, month: 8, day: 5)
        let expenses = [
            ExpenseItem(id: 101, amountCents: 100000, currency: "ZAR", categoryId: 1, paymentMethod: "Card", note: "Shop 1", spentAtMillis: dateToMillis(spentDate)) // R1000 spent vs R1500 ideal
        ]
        
        let telemetry = SpendingTelemetryEngine.analyze(
            expenses: expenses,
            categories: categories,
            paydayCycle: cycle,
            asOf: asOf,
            calendar: calendar
        )
        
        XCTAssertEqual(telemetry.pace.cycleTotalBudgetCents, 310000)
        XCTAssertEqual(telemetry.pace.cycleTotalSpentCents, 100000)
        XCTAssertEqual(telemetry.pace.freeToSpendCents, 210000)
        XCTAssertFalse(telemetry.pace.isCyclePacingAhead) // Not over pace
        XCTAssertTrue(telemetry.pace.statusText.contains("under pace"))
        XCTAssertEqual(telemetry.pace.pacePoints.count, 31)
    }
    
    func testPaceTelemetry_OverBudget() {
        let cycleStart = makeDate(year: 2026, month: 8, day: 1)
        let cycleEnd = makeDate(year: 2026, month: 9, day: 1)
        let asOf = makeDate(year: 2026, month: 8, day: 10)
        let cycle = PaydayCycle(billingCycleStartDay: 1, startDate: cycleStart, endDate: cycleEnd)
        
        let categories = [
            CategoryItem(id: 1, name: "Dining", icon: "fork.knife", colorHex: "#EF4444", monthlyBudgetCents: 100000, isArchived: false) // R1000 budget
        ]
        
        let spentDate = makeDate(year: 2026, month: 8, day: 5)
        let expenses = [
            ExpenseItem(id: 201, amountCents: 150000, currency: "ZAR", categoryId: 1, paymentMethod: "Card", note: "Fancy dinner", spentAtMillis: dateToMillis(spentDate)) // R1500 spent
        ]
        
        let telemetry = SpendingTelemetryEngine.analyze(
            expenses: expenses,
            categories: categories,
            paydayCycle: cycle,
            asOf: asOf,
            calendar: calendar
        )
        
        XCTAssertEqual(telemetry.pace.cycleTotalSpentCents, 150000)
        XCTAssertEqual(telemetry.pace.freeToSpendCents, 0)
        XCTAssertTrue(telemetry.pace.statusText.contains("Over budget"))
        XCTAssertEqual(telemetry.envelopes.overspentCount, 1)
    }
    
    // MARK: - Envelope Telemetry Tests
    
    func testEnvelopeTelemetry_CalculatesRemainingAndProgress() {
        let cycleStart = makeDate(year: 2026, month: 8, day: 1)
        let cycleEnd = makeDate(year: 2026, month: 9, day: 1)
        let asOf = makeDate(year: 2026, month: 8, day: 15)
        let cycle = PaydayCycle(billingCycleStartDay: 1, startDate: cycleStart, endDate: cycleEnd)
        
        let cat1 = CategoryItem(id: 1, name: "Groceries", icon: "cart", colorHex: "#10B981", monthlyBudgetCents: 200000, isArchived: false) // R2000
        let cat2 = CategoryItem(id: 2, name: "Fuel", icon: "fuelpump", colorHex: "#3B82F6", monthlyBudgetCents: 100000, isArchived: false) // R1000
        
        let d1 = makeDate(year: 2026, month: 8, day: 5)
        let d2 = makeDate(year: 2026, month: 8, day: 8)
        let expenses = [
            ExpenseItem(id: 301, amountCents: 50000, currency: "ZAR", categoryId: 1, paymentMethod: "Card", note: "Woolies", spentAtMillis: dateToMillis(d1)), // R500
            ExpenseItem(id: 302, amountCents: 120000, currency: "ZAR", categoryId: 2, paymentMethod: "Card", note: "Shell", spentAtMillis: dateToMillis(d2)) // R1200 (overspent by R200)
        ]
        
        let telemetry = SpendingTelemetryEngine.analyze(
            expenses: expenses,
            categories: [cat1, cat2],
            paydayCycle: cycle,
            asOf: asOf,
            calendar: calendar
        )
        
        let env1 = telemetry.envelopes.statuses.first(where: { $0.category.id == 1 })!
        let env2 = telemetry.envelopes.statuses.first(where: { $0.category.id == 2 })!
        
        XCTAssertEqual(env1.spentCents, 50000)
        XCTAssertEqual(env1.remainingCents, 150000)
        XCTAssertFalse(env1.isOverspent)
        XCTAssertEqual(env1.progressRatio, 0.25, accuracy: 0.001)
        
        XCTAssertEqual(env2.spentCents, 120000)
        XCTAssertEqual(env2.remainingCents, -20000)
        XCTAssertTrue(env2.isOverspent)
        XCTAssertEqual(env2.overspentCents, 20000)
        XCTAssertEqual(telemetry.envelopes.overspentCount, 1)
    }
    
    // MARK: - Distribution Telemetry Tests
    
    func testDistributionTelemetry_ThisWeekBuckets() {
        let asOf = makeDate(year: 2026, month: 8, day: 26) // Wednesday
        let cycleStart = makeDate(year: 2026, month: 8, day: 1)
        let cycleEnd = makeDate(year: 2026, month: 9, day: 1)
        let cycle = PaydayCycle(billingCycleStartDay: 1, startDate: cycleStart, endDate: cycleEnd)
        
        let cat = CategoryItem(id: 1, name: "Groceries", icon: "cart", colorHex: "#10B981", monthlyBudgetCents: 500000, isArchived: false)
        
        let dMon = makeDate(year: 2026, month: 8, day: 24)
        let dWed = makeDate(year: 2026, month: 8, day: 26)
        let expenses = [
            ExpenseItem(id: 401, amountCents: 45000, currency: "ZAR", categoryId: 1, paymentMethod: "Card", note: "Mon spend", spentAtMillis: dateToMillis(dMon)), // Monday
            ExpenseItem(id: 402, amountCents: 35000, currency: "ZAR", categoryId: 1, paymentMethod: "Card", note: "Wed spend", spentAtMillis: dateToMillis(dWed))  // Wednesday
        ]
        
        let telemetry = SpendingTelemetryEngine.analyze(
            expenses: expenses,
            categories: [cat],
            paydayCycle: cycle,
            period: .thisWeek,
            startWeekOn: "Sunday",
            asOf: asOf,
            calendar: calendar
        )
        
        XCTAssertEqual(telemetry.distribution.periodTotalCents, 80000)
        XCTAssertEqual(telemetry.distribution.chartData.count, 7)
        XCTAssertEqual(telemetry.distribution.categorizedChartData.count, 7)
        
        let monBucket = telemetry.distribution.chartData.first(where: { $0.day == "Mon" })!
        let wedBucket = telemetry.distribution.chartData.first(where: { $0.day == "Wed" })!
        
        XCTAssertEqual(monBucket.amountCents, 45000)
        XCTAssertEqual(wedBucket.amountCents, 35000)
    }
    
    // MARK: - Dynamic Daily Allowance Tests (Pennies Model)
    
    func testDynamicDailyAllowance_DayOneAndSurplusRollover() {
        let cycleStart = makeDate(year: 2026, month: 8, day: 1)
        let cycleEnd = makeDate(year: 2026, month: 8, day: 31) // 30 day cycle
        let asOfDay1 = makeDate(year: 2026, month: 8, day: 1)
        let cycle = PaydayCycle(billingCycleStartDay: 1, startDate: cycleStart, endDate: cycleEnd)
        
        let cat = CategoryItem(id: 1, name: "Groceries", icon: "cart", colorHex: "#10B981", monthlyBudgetCents: 150000, isArchived: false) // R1,500 total
        
        // Day 1: Spent R30 (3,000 cents) out of R50 base allowance
        let expenseDay1 = ExpenseItem(id: 1, amountCents: 3000, currency: "ZAR", categoryId: 1, paymentMethod: "Card", note: "Lunch", spentAtMillis: dateToMillis(asOfDay1))
        
        let tel1 = SpendingTelemetryEngine.analyze(
            expenses: [expenseDay1],
            categories: [cat],
            paydayCycle: cycle,
            asOf: asOfDay1,
            calendar: calendar
        )
        
        XCTAssertEqual(tel1.pace.todayBaseAllowanceCents, 5000) // R50.00 base
        XCTAssertEqual(tel1.pace.todaySpentCents, 3000)         // R30.00 spent
        XCTAssertEqual(tel1.pace.todayAvailableCents, 2000)     // R20.00 available
        XCTAssertEqual(tel1.pace.healthState, .healthy)
        
        // Day 2: 29 days remaining, prior spent = R30
        let asOfDay2 = makeDate(year: 2026, month: 8, day: 2)
        let tel2 = SpendingTelemetryEngine.analyze(
            expenses: [expenseDay1],
            categories: [cat],
            paydayCycle: cycle,
            asOf: asOfDay2,
            calendar: calendar
        )
        
        // (150,000 - 3,000) / 29 = 5,068 cents
        XCTAssertEqual(tel2.pace.todayBaseAllowanceCents, 5068)
        XCTAssertEqual(tel2.pace.todayAvailableCents, 5068)
        XCTAssertEqual(tel2.pace.healthState, .healthy)
    }
    
    func testDynamicDailyAllowance_DeficitAbsorption() {
        let cycleStart = makeDate(year: 2026, month: 8, day: 1)
        let cycleEnd = makeDate(year: 2026, month: 8, day: 31)
        let asOfDay3 = makeDate(year: 2026, month: 8, day: 3)
        let cycle = PaydayCycle(billingCycleStartDay: 1, startDate: cycleStart, endDate: cycleEnd)
        
        let cat = CategoryItem(id: 1, name: "Groceries", icon: "cart", colorHex: "#10B981", monthlyBudgetCents: 150000, isArchived: false)
        
        let expDay1 = ExpenseItem(id: 1, amountCents: 3000, currency: "ZAR", categoryId: 1, paymentMethod: "Card", note: "Day 1", spentAtMillis: dateToMillis(makeDate(year: 2026, month: 8, day: 1)))
        let expDay3 = ExpenseItem(id: 2, amountCents: 15000, currency: "ZAR", categoryId: 1, paymentMethod: "Card", note: "Day 3 Big Dinner", spentAtMillis: dateToMillis(asOfDay3)) // R150 spent
        
        let tel3 = SpendingTelemetryEngine.analyze(
            expenses: [expDay1, expDay3],
            categories: [cat],
            paydayCycle: cycle,
            asOf: asOfDay3,
            calendar: calendar
        )
        
        // 28 days remaining entering Day 3. Base = (150,000 - 3,000) / 28 = 5,250 cents.
        XCTAssertEqual(tel3.pace.todayBaseAllowanceCents, 5250)
        XCTAssertEqual(tel3.pace.todayAvailableCents, -9750) // Overspent today by R97.50
        XCTAssertEqual(tel3.pace.healthState, .overToday)
        
        // Day 4: Prior spent = 3,000 + 15,000 = 18,000 cents. 27 days left.
        let asOfDay4 = makeDate(year: 2026, month: 8, day: 4)
        let tel4 = SpendingTelemetryEngine.analyze(
            expenses: [expDay1, expDay3],
            categories: [cat],
            paydayCycle: cycle,
            asOf: asOfDay4,
            calendar: calendar
        )
        
        // (150,000 - 18,000) / 27 = 4,888 cents
        XCTAssertEqual(tel4.pace.todayBaseAllowanceCents, 4888)
        XCTAssertEqual(tel4.pace.todayAvailableCents, 4888)
        XCTAssertEqual(tel4.pace.healthState, .healthy)
    }
}
