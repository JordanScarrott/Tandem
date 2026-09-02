import SwiftUI
import WidgetKit

public struct WeeklySpendWidget: Widget {
    public static let kind: String = "com.tandem.syncspend.weekly-spend"
    
    public init() {}
    
    public var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: Self.kind,
            provider: WeeklySpendTimelineProvider()
        ) { entry in
            WeeklySpendWidgetView(entry: entry)
        }
        .configurationDisplayName("Weekly Spend")
        .description("Track your spending this week and stay on budget pace.")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}
