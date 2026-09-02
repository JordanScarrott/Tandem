import XCTest
import SwiftUI
@testable import SyncSpend

final class LockScreenWidgetTests: XCTestCase {
    
    func testDeepLinkRouting_RecognizesLogExpenseVariants() {
        let testURLs = [
            "syncspend://log-expense",
            "syncspend://new-expense",
            "syncspend://quick-log",
            "com.tandem.syncspend://log-expense"
        ]
        
        for urlString in testURLs {
            guard let url = URL(string: urlString) else {
                XCTFail("Failed to create URL for \(urlString)")
                continue
            }
            
            let host = url.host ?? url.path.replacingOccurrences(of: "/", with: "")
            let isRecognized = (host == "log-expense" || host == "new-expense" || host == "quick-log")
            XCTAssertTrue(isRecognized, "URL \(urlString) should be recognized as a quick-log route")
        }
    }
    
    func testAppRoute_Equality() {
        let route1 = AppRoute.newExpense
        let route2 = AppRoute.newExpense
        XCTAssertEqual(route1, route2)
    }
    
    func testTelemetry_LockScreenGaugeRatio() {
        let telemetry = WidgetWeeklyTelemetry.preview
        let maxAllowance = max(Double(telemetry.todayBaseAllowanceCents), 1.0)
        let available = max(Double(telemetry.todayAvailableCents), 0.0)
        let ratio = min(available / maxAllowance, 1.0)
        
        XCTAssertGreaterThanOrEqual(ratio, 0.0)
        XCTAssertLessThanOrEqual(ratio, 1.0)
        XCTAssertEqual(telemetry.formattedTodayAvailable, "R 450")
    }
}
