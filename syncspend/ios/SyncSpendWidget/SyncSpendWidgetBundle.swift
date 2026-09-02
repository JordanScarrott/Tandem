import SwiftUI
import WidgetKit

@main
struct SyncSpendWidgetBundle: WidgetBundle {
    var body: some Widget {
        DailyAllowanceWidget()
        WeeklySpendWidget()
    }
}
