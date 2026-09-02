import SwiftUI
import WidgetKit

public struct WeeklySpendWidgetView: View {
    @Environment(\.widgetFamily) var family
    public let entry: WeeklySpendEntry
    
    public init(entry: WeeklySpendEntry) {
        self.entry = entry
    }
    
    public var body: some View {
        VStack(alignment: .center, spacing: 6) {
            Text("SPENT THIS WEEK")
                .font(.system(size: family == .systemSmall ? 10 : 12, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
                .tracking(0.6)
                .multilineTextAlignment(.center)
            
            Text(entry.telemetry.formattedWeeklyTotal)
                .font(.system(size: family == .systemSmall ? 32 : 44, weight: .bold, design: .rounded))
                .foregroundStyle(Color.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .containerBackground(for: .widget) {
            Color(uiColor: .systemGroupedBackground)
        }
    }
}

// MARK: - Previews
#Preview("Small Widget", as: .systemSmall) {
    WeeklySpendWidget()
} timeline: {
    WeeklySpendEntry(date: Date(), telemetry: .preview)
}

#Preview("Medium Widget", as: .systemMedium) {
    WeeklySpendWidget()
} timeline: {
    WeeklySpendEntry(date: Date(), telemetry: .preview)
}
