import Foundation
import WidgetKit

/// Lightweight, Codable snapshot specifically tailored for SyncSpend WidgetKit widgets.
public struct WidgetWeeklyTelemetry: Codable, Equatable {
    public let weeklyTotalCents: Int64
    public let currencySymbol: String
    public let currencyCode: String
    public let dailySpendings: [WidgetDaySpend]
    public let isCyclePacingAhead: Bool
    public let cyclePaceDeltaCents: Int64
    public let freeToSpendCents: Int64
    public let statusText: String
    public let todayAvailableCents: Int64
    public let todayBaseAllowanceCents: Int64
    public let todaySpentCents: Int64
    public let healthState: BudgetHealthState
    public let daysRemainingInCycle: Int
    public let lastUpdated: Date
    
    public init(
        weeklyTotalCents: Int64,
        currencySymbol: String,
        currencyCode: String,
        dailySpendings: [WidgetDaySpend],
        isCyclePacingAhead: Bool,
        cyclePaceDeltaCents: Int64,
        freeToSpendCents: Int64,
        statusText: String,
        todayAvailableCents: Int64 = 0,
        todayBaseAllowanceCents: Int64 = 0,
        todaySpentCents: Int64 = 0,
        healthState: BudgetHealthState = .healthy,
        daysRemainingInCycle: Int = 1,
        lastUpdated: Date = Date()
    ) {
        self.weeklyTotalCents = weeklyTotalCents
        self.currencySymbol = currencySymbol
        self.currencyCode = currencyCode
        self.dailySpendings = dailySpendings
        self.isCyclePacingAhead = isCyclePacingAhead
        self.cyclePaceDeltaCents = cyclePaceDeltaCents
        self.freeToSpendCents = freeToSpendCents
        self.statusText = statusText
        self.todayAvailableCents = todayAvailableCents
        self.todayBaseAllowanceCents = todayBaseAllowanceCents
        self.todaySpentCents = todaySpentCents
        self.healthState = healthState
        self.daysRemainingInCycle = daysRemainingInCycle
        self.lastUpdated = lastUpdated
    }
    
    public var formattedWeeklyTotal: String {
        formatCurrency(cents: weeklyTotalCents)
    }
    
    public var formattedTodayAvailable: String {
        formatCurrency(cents: todayAvailableCents)
    }
    
    public var formattedTodayBaseAllowance: String {
        formatCurrency(cents: todayBaseAllowanceCents)
    }
    
    public var formattedPaceDelta: String {
        formatCurrency(cents: cyclePaceDeltaCents)
    }
    
    public var formattedFreeToSpend: String {
        formatCurrency(cents: freeToSpendCents)
    }
    
    private func formatCurrency(cents: Int64) -> String {
        let amount = Double(cents) / 100.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        formatter.groupingSeparator = " "
        formatter.decimalSeparator = ","
        
        let formattedNumber = formatter.string(from: NSNumber(value: amount)) ?? String(format: "%.0f", amount)
        return "\(currencySymbol) \(formattedNumber)"
    }
    
    /// Sensible sample data for Widget previews and uninitialized state.
    public static var preview: WidgetWeeklyTelemetry {
        let sampleDays: [WidgetDaySpend] = [
            WidgetDaySpend(day: "Mon", amountCents: 12000, isToday: false),
            WidgetDaySpend(day: "Tue", amountCents: 24500, isToday: false),
            WidgetDaySpend(day: "Wed", amountCents: 8500, isToday: false),
            WidgetDaySpend(day: "Thu", amountCents: 39000, isToday: true),
            WidgetDaySpend(day: "Fri", amountCents: 0, isToday: false),
            WidgetDaySpend(day: "Sat", amountCents: 0, isToday: false),
            WidgetDaySpend(day: "Sun", amountCents: 0, isToday: false)
        ]
        
        return WidgetWeeklyTelemetry(
            weeklyTotalCents: 84000,
            currencySymbol: "R",
            currencyCode: "ZAR",
            dailySpendings: sampleDays,
            isCyclePacingAhead: false,
            cyclePaceDeltaCents: 15000,
            freeToSpendCents: 280000,
            statusText: "On track • R 150 under pace",
            todayAvailableCents: 45000,
            todayBaseAllowanceCents: 50000,
            todaySpentCents: 5000,
            healthState: .healthy,
            daysRemainingInCycle: 22,
            lastUpdated: Date()
        )
    }
}

/// Represents a single day bucket in the 7-day widget distribution.
public struct WidgetDaySpend: Codable, Equatable, Identifiable {
    public var id: String { day }
    public let day: String
    public let amountCents: Int64
    public let isToday: Bool
    
    public init(day: String, amountCents: Int64, isToday: Bool) {
        self.day = day
        self.amountCents = amountCents
        self.isToday = isToday
    }
}

/// Shared data bridge connecting the main application and WidgetKit extensions.
public final class SharedTelemetryStore {
    public static let shared = SharedTelemetryStore()
    
    public static let appGroupSuiteName = "group.com.tandem.syncspend"
    public static let telemetryStorageKey = "syncspend_widget_weekly_telemetry"
    
    private let userDefaults: UserDefaults
    
    public init(suiteName: String? = appGroupSuiteName) {
        if let suiteName = suiteName, let groupDefaults = UserDefaults(suiteName: suiteName) {
            self.userDefaults = groupDefaults
        } else {
            self.userDefaults = .standard
        }
    }
    
    /// Persists the latest weekly telemetry to shared UserDefaults and notifies WidgetCenter.
    public func save(
        snapshot: SpendingTelemetrySnapshot,
        currency: CurrencyItem,
        asOf: Date = Date(),
        calendar: Calendar = .current
    ) {
        let dailySpendings: [WidgetDaySpend] = snapshot.distribution.chartData.map { daySpend in
            let isToday = calendar.isDate(daySpend.date, inSameDayAs: asOf)
            return WidgetDaySpend(
                day: daySpend.day,
                amountCents: daySpend.amountCents,
                isToday: isToday
            )
        }
        
        let weeklyTelemetry = WidgetWeeklyTelemetry(
            weeklyTotalCents: snapshot.distribution.periodTotalCents,
            currencySymbol: currency.symbol,
            currencyCode: currency.code,
            dailySpendings: dailySpendings,
            isCyclePacingAhead: snapshot.pace.isCyclePacingAhead,
            cyclePaceDeltaCents: snapshot.pace.cyclePaceDeltaCents,
            freeToSpendCents: snapshot.pace.freeToSpendCents,
            statusText: snapshot.pace.statusText,
            todayAvailableCents: snapshot.pace.todayAvailableCents,
            todayBaseAllowanceCents: snapshot.pace.todayBaseAllowanceCents,
            todaySpentCents: snapshot.pace.todaySpentCents,
            healthState: snapshot.pace.healthState,
            daysRemainingInCycle: snapshot.pace.daysRemaining,
            lastUpdated: asOf
        )
        
        save(telemetry: weeklyTelemetry)
    }
    
    /// Directly saves a `WidgetWeeklyTelemetry` payload.
    public func save(telemetry: WidgetWeeklyTelemetry) {
        if let encoded = try? JSONEncoder().encode(telemetry) {
            userDefaults.set(encoded, forKey: Self.telemetryStorageKey)
        }
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
    
    /// Loads the persisted `WidgetWeeklyTelemetry` or returns the sample preview if empty.
    public func loadTelemetry() -> WidgetWeeklyTelemetry? {
        guard let data = userDefaults.data(forKey: Self.telemetryStorageKey),
              let decoded = try? JSONDecoder().decode(WidgetWeeklyTelemetry.self, from: data) else {
            return nil
        }
        return decoded
    }
    
    /// Returns stored telemetry or fallback preview data.
    public func loadTelemetryWithFallback() -> WidgetWeeklyTelemetry {
        loadTelemetry() ?? .preview
    }
    
    /// Clears persisted telemetry (used for testing or logout).
    public func clear() {
        userDefaults.removeObject(forKey: Self.telemetryStorageKey)
    }
}
