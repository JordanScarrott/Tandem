import XCTest
@testable import SyncSpend

final class SharedTelemetryStoreTests: XCTestCase {
    
    private var testStore: SharedTelemetryStore!
    private let testSuiteName = "test_group_syncspend_\(UUID().uuidString)"
    
    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }
    
    override func setUp() {
        super.setUp()
        testStore = SharedTelemetryStore(suiteName: testSuiteName)
        testStore.clear()
    }
    
    override func tearDown() {
        testStore.clear()
        UserDefaults.standard.removePersistentDomain(forName: testSuiteName)
        super.tearDown()
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
    
    func testFallback_WhenStoreEmpty() {
        XCTAssertNil(testStore.loadTelemetry())
        
        let fallback = testStore.loadTelemetryWithFallback()
        XCTAssertEqual(fallback.currencySymbol, "R")
        XCTAssertEqual(fallback.dailySpendings.count, 7)
        XCTAssertEqual(fallback.weeklyTotalCents, 84000)
    }
    
    func testSaveAndLoad_DirectPayload() {
        let days = [
            WidgetDaySpend(day: "Mon", amountCents: 15000, isToday: false),
            WidgetDaySpend(day: "Tue", amountCents: 20000, isToday: true)
        ]
        
        let payload = WidgetWeeklyTelemetry(
            weeklyTotalCents: 35000,
            currencySymbol: "$",
            currencyCode: "USD",
            dailySpendings: days,
            isCyclePacingAhead: true,
            cyclePaceDeltaCents: 5000,
            freeToSpendCents: 100000,
            statusText: "Pacing ahead by $ 50",
            lastUpdated: makeDate(year: 2026, month: 8, day: 26)
        )
        
        testStore.save(telemetry: payload)
        
        guard let loaded = testStore.loadTelemetry() else {
            XCTFail("Failed to load telemetry from store")
            return
        }
        
        XCTAssertEqual(loaded.weeklyTotalCents, 35000)
        XCTAssertEqual(loaded.currencySymbol, "$")
        XCTAssertEqual(loaded.currencyCode, "USD")
        XCTAssertEqual(loaded.dailySpendings.count, 2)
        XCTAssertEqual(loaded.dailySpendings[1].day, "Tue")
        XCTAssertTrue(loaded.dailySpendings[1].isToday)
        XCTAssertTrue(loaded.isCyclePacingAhead)
        XCTAssertEqual(loaded.cyclePaceDeltaCents, 5000)
        XCTAssertEqual(loaded.formattedWeeklyTotal, "$ 350")
    }
    
    func testSaveAndLoad_FromTelemetrySnapshot() {
        let asOf = makeDate(year: 2026, month: 8, day: 26) // Wednesday
        let cycleStart = makeDate(year: 2026, month: 8, day: 1)
        let cycleEnd = makeDate(year: 2026, month: 9, day: 1)
        let cycle = PaydayCycle(billingCycleStartDay: 1, startDate: cycleStart, endDate: cycleEnd)
        
        let cat = CategoryItem(id: 1, name: "Groceries", icon: "cart", colorHex: "#10B981", monthlyBudgetCents: 500000)
        let exp1 = ExpenseItem(id: 10, amountCents: 30000, currency: "ZAR", categoryId: 1, paymentMethod: "Card", note: "Mon", spentAtMillis: dateToMillis(makeDate(year: 2026, month: 8, day: 24)))
        let exp2 = ExpenseItem(id: 11, amountCents: 45000, currency: "ZAR", categoryId: 1, paymentMethod: "Card", note: "Wed", spentAtMillis: dateToMillis(makeDate(year: 2026, month: 8, day: 26)))
        
        let snapshot = SpendingTelemetryEngine.analyze(
            expenses: [exp1, exp2],
            categories: [cat],
            paydayCycle: cycle,
            period: .thisWeek,
            currency: CurrencyItem.defaultCurrency,
            startWeekOn: "Sunday",
            asOf: asOf,
            calendar: calendar
        )
        
        testStore.save(snapshot: snapshot, currency: CurrencyItem.defaultCurrency, asOf: asOf, calendar: calendar)
        
        guard let loaded = testStore.loadTelemetry() else {
            XCTFail("Failed to load snapshot from store")
            return
        }
        
        XCTAssertEqual(loaded.weeklyTotalCents, 75000)
        XCTAssertEqual(loaded.formattedWeeklyTotal, "R 750")
        XCTAssertEqual(loaded.currencySymbol, "R")
        XCTAssertEqual(loaded.dailySpendings.count, 7)
        
        let monSpend = loaded.dailySpendings.first(where: { $0.day == "Mon" })
        let wedSpend = loaded.dailySpendings.first(where: { $0.day == "Wed" })
        
        XCTAssertEqual(monSpend?.amountCents, 30000)
        XCTAssertEqual(wedSpend?.amountCents, 45000)
    }
}
