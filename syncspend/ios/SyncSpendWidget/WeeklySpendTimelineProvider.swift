import Foundation
import WidgetKit

/// Timeline entry representing the spending state at a particular point in time.
public struct WeeklySpendEntry: TimelineEntry {
    public let date: Date
    public let telemetry: WidgetWeeklyTelemetry
    public let isPlaceholder: Bool
    
    public init(date: Date, telemetry: WidgetWeeklyTelemetry, isPlaceholder: Bool = false) {
        self.date = date
        self.telemetry = telemetry
        self.isPlaceholder = isPlaceholder
    }
}

/// Generates timeline entries for the Weekly Spend widget by polling SharedTelemetryStore.
public struct WeeklySpendTimelineProvider: TimelineProvider {
    public typealias Entry = WeeklySpendEntry
    
    private let store: SharedTelemetryStore
    
    public init(store: SharedTelemetryStore = .shared) {
        self.store = store
    }
    
    public func placeholder(in context: Context) -> WeeklySpendEntry {
        WeeklySpendEntry(
            date: Date(),
            telemetry: .preview,
            isPlaceholder: true
        )
    }
    
    public func getSnapshot(in context: Context, completion: @escaping (WeeklySpendEntry) -> Void) {
        if context.isPreview {
            completion(WeeklySpendEntry(date: Date(), telemetry: .preview))
        } else {
            let telemetry = store.loadTelemetryWithFallback()
            completion(WeeklySpendEntry(date: Date(), telemetry: telemetry))
        }
    }
    
    public func getTimeline(in context: Context, completion: @escaping (Timeline<WeeklySpendEntry>) -> Void) {
        let currentDate = Date()
        let telemetry = store.loadTelemetryWithFallback()
        let entry = WeeklySpendEntry(date: currentDate, telemetry: telemetry)
        
        // Refresh every 1 hour or when system decides
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)
            ?? currentDate.addingTimeInterval(3600)
        
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}
