import SwiftUI
import WidgetKit

/// Dedicated Lock Screen / Home Screen Quick-Action Widget for 1-tap expense entry.
public struct QuickLogWidget: Widget {
    public static let kind: String = "com.tandem.syncspend.quick-log"
    
    public init() {}
    
    public var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: Self.kind,
            provider: QuickLogTimelineProvider()
        ) { entry in
            QuickLogWidgetView(entry: entry)
        }
        .configurationDisplayName("Quick Log Expense")
        .description("One tap from your Lock Screen or Home Screen to record an expense immediately.")
        .supportedFamilies([.accessoryCircular, .accessoryInline, .systemSmall])
        .contentMarginsDisabled()
    }
}

public struct QuickLogEntry: TimelineEntry {
    public let date: Date
    
    public init(date: Date = Date()) {
        self.date = date
    }
}

public struct QuickLogTimelineProvider: TimelineProvider {
    public typealias Entry = QuickLogEntry
    
    public init() {}
    
    public func placeholder(in context: Context) -> QuickLogEntry {
        QuickLogEntry()
    }
    
    public func getSnapshot(in context: Context, completion: @escaping (QuickLogEntry) -> Void) {
        completion(QuickLogEntry())
    }
    
    public func getTimeline(in context: Context, completion: @escaping (Timeline<QuickLogEntry>) -> Void) {
        let entry = QuickLogEntry(date: Date())
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 24, to: Date()) ?? Date().addingTimeInterval(86400)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

public struct QuickLogWidgetView: View {
    @Environment(\.widgetFamily) var family
    public let entry: QuickLogEntry
    
    private let deepLinkURL = URL(string: "syncspend://log-expense")
    
    public init(entry: QuickLogEntry) {
        self.entry = entry
    }
    
    public var body: some View {
        Group {
            switch family {
            case .accessoryCircular:
                accessoryCircularView
                    .containerBackground(for: .widget) {
                        AccessoryWidgetBackground()
                    }
            case .accessoryInline:
                accessoryInlineView
                    .containerBackground(for: .widget) {
                        Color.clear
                    }
            default:
                systemSmallView
                    .containerBackground(for: .widget) {
                        Color(uiColor: .systemGroupedBackground)
                    }
            }
        }
        .widgetURL(deepLinkURL)
    }
    
    // MARK: - Lock Screen Circular Accessory
    private var accessoryCircularView: some View {
        VStack(spacing: 2) {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .bold))
            Text("LOG")
                .font(.system(size: 9, weight: .black, design: .rounded))
                .tracking(0.6)
        }
    }
    
    // MARK: - Lock Screen Inline Accessory
    private var accessoryInlineView: some View {
        Label("Log Expense", systemImage: "plus.circle.fill")
    }
    
    // MARK: - Home Screen Small Widget
    private var systemSmallView: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(uiColor: .label))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Color(uiColor: .systemBackground))
            }
            
            VStack(spacing: 2) {
                Text("Log Expense")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.primary)
                
                Text("Tap to record")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
