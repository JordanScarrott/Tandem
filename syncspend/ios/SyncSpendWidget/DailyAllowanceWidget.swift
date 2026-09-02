import SwiftUI
import WidgetKit

public struct DailyAllowanceWidget: Widget {
    public static let kind: String = "com.tandem.syncspend.daily-allowance"
    
    public init() {}
    
    public var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: Self.kind,
            provider: WeeklySpendTimelineProvider()
        ) { entry in
            DailyAllowanceWidgetView(entry: entry)
        }
        .configurationDisplayName("Available Today")
        .description("Instant view of your daily spending headroom to keep your payday cycle on track.")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}
