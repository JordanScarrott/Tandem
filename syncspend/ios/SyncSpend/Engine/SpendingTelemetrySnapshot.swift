import Foundation
import SwiftUI

/// Period for filtering spending data.
public enum FilterPeriod: String, CaseIterable, Identifiable, Codable, Equatable, Hashable {
    case today = "Today"
    case thisWeek = "This Week"
    case thisMonth = "This Month"
    case thisYear = "This Year"
    case allTime = "All Time"
    
    public var id: String { rawValue }
    public var title: String { rawValue }
}

/// Category segment within a daily spending bucket.
public struct DayCategorySegment: Identifiable, Equatable, Hashable {
    public var id: String { "\(day)_\(categoryId)" }
    public let day: String
    public let categoryId: UInt64
    public let categoryName: String
    public let color: Color
    public let amountCents: Int64
    
    public init(day: String, categoryId: UInt64, categoryName: String, color: Color, amountCents: Int64) {
        self.day = day
        self.categoryId = categoryId
        self.categoryName = categoryName
        self.color = color
        self.amountCents = amountCents
    }
}

/// Daily spending total aggregated with category segments.
public struct DaySpendingWithCategories: Identifiable, Equatable {
    public var id: String { day }
    public let day: String
    public let date: Date
    public let totalAmountCents: Int64
    public let segments: [DayCategorySegment]
    
    public init(day: String, date: Date, totalAmountCents: Int64, segments: [DayCategorySegment]) {
        self.day = day
        self.date = date
        self.totalAmountCents = totalAmountCents
        self.segments = segments
    }
}

/// Progression point in a payday cycle pace chart.
public struct CyclePacePoint: Identifiable, Equatable, Hashable {
    public var id: Int { dayNumber }
    public let dayNumber: Int
    public let date: Date
    public let dateLabel: String
    public let actualCumulativeCents: Int64?
    public let idealCumulativeCents: Int64
    public let isToday: Bool
    public let isFuture: Bool
    
    public init(
        dayNumber: Int,
        date: Date,
        dateLabel: String,
        actualCumulativeCents: Int64?,
        idealCumulativeCents: Int64,
        isToday: Bool,
        isFuture: Bool
    ) {
        self.dayNumber = dayNumber
        self.date = date
        self.dateLabel = dateLabel
        self.actualCumulativeCents = actualCumulativeCents
        self.idealCumulativeCents = idealCumulativeCents
        self.isToday = isToday
        self.isFuture = isFuture
    }
}

/// Simplified day spending summary bucket.
public struct DaySpending: Identifiable, Equatable, Hashable {
    public var id: String { day }
    public let day: String
    public let amountCents: Int64
    public let date: Date
    
    public init(day: String, amountCents: Int64, date: Date) {
        self.day = day
        self.amountCents = amountCents
        self.date = date
    }
}

/// Telemetry regarding payday cycle pacing, budget headroom, and daily allowances.
public struct PaceTelemetry: Equatable {
    public let pacePoints: [CyclePacePoint]
    public let totalDays: Int
    public let currentDayIndex: Int
    public let daysRemaining: Int
    public let cycleTotalBudgetCents: Int64
    public let cycleTotalSpentCents: Int64
    public let dailyBudgetAllowanceCents: Int64
    public let idealPaceSpendToDateCents: Int64
    public let freeToSpendCents: Int64
    public let cyclePaceDeltaCents: Int64
    public let isCyclePacingAhead: Bool
    public let statusText: String
    
    public init(
        pacePoints: [CyclePacePoint],
        totalDays: Int,
        currentDayIndex: Int,
        daysRemaining: Int,
        cycleTotalBudgetCents: Int64,
        cycleTotalSpentCents: Int64,
        dailyBudgetAllowanceCents: Int64,
        idealPaceSpendToDateCents: Int64,
        freeToSpendCents: Int64,
        cyclePaceDeltaCents: Int64,
        isCyclePacingAhead: Bool,
        statusText: String
    ) {
        self.pacePoints = pacePoints
        self.totalDays = totalDays
        self.currentDayIndex = currentDayIndex
        self.daysRemaining = daysRemaining
        self.cycleTotalBudgetCents = cycleTotalBudgetCents
        self.cycleTotalSpentCents = cycleTotalSpentCents
        self.dailyBudgetAllowanceCents = dailyBudgetAllowanceCents
        self.idealPaceSpendToDateCents = idealPaceSpendToDateCents
        self.freeToSpendCents = freeToSpendCents
        self.cyclePaceDeltaCents = cyclePaceDeltaCents
        self.isCyclePacingAhead = isCyclePacingAhead
        self.statusText = statusText
    }
}

/// Telemetry regarding category envelope health, budget utilization, and overspending.
public struct EnvelopeTelemetry: Equatable {
    public let statuses: [CategoryEnvelopeStatus]
    public let overspentCount: Int
    public let totalBudgetCents: Int64
    public let totalSpentCents: Int64
    public let freeToSpendCents: Int64
    
    public init(
        statuses: [CategoryEnvelopeStatus],
        overspentCount: Int,
        totalBudgetCents: Int64,
        totalSpentCents: Int64,
        freeToSpendCents: Int64
    ) {
        self.statuses = statuses
        self.overspentCount = overspentCount
        self.totalBudgetCents = totalBudgetCents
        self.totalSpentCents = totalSpentCents
        self.freeToSpendCents = freeToSpendCents
    }
}

/// Telemetry regarding period-based spending distribution across time buckets and categories.
public struct DistributionTelemetry: Equatable {
    public let chartData: [DaySpending]
    public let categorizedChartData: [DaySpendingWithCategories]
    public let periodTotalCents: Int64
    public let period: FilterPeriod
    public let periodTitle: String
    
    public init(
        chartData: [DaySpending],
        categorizedChartData: [DaySpendingWithCategories],
        periodTotalCents: Int64,
        period: FilterPeriod,
        periodTitle: String
    ) {
        self.chartData = chartData
        self.categorizedChartData = categorizedChartData
        self.periodTotalCents = periodTotalCents
        self.period = period
        self.periodTitle = periodTitle
    }
}

/// The unified, immutable financial intelligence snapshot for a payday cycle and filter period.
public struct SpendingTelemetrySnapshot: Equatable {
    public let pace: PaceTelemetry
    public let envelopes: EnvelopeTelemetry
    public let distribution: DistributionTelemetry
    
    public init(
        pace: PaceTelemetry,
        envelopes: EnvelopeTelemetry,
        distribution: DistributionTelemetry
    ) {
        self.pace = pace
        self.envelopes = envelopes
        self.distribution = distribution
    }
}
