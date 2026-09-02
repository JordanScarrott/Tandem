import SwiftUI
import WidgetKit

@main
struct SyncSpendWidgetBundle: WidgetBundle {
    var body: some Widget {
        DailyAllowanceWidget()
        WeeklySpendWidget()
        QuickLogWidget()
        if #available(iOS 18.0, *) {
            QuickLogControlWidget()
        }
    }
}
