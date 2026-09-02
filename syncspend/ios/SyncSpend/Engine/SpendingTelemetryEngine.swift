import Foundation
import SwiftUI

/// Pure domain calculation engine for SyncSpend financial telemetry.
/// Encapsulates payday cycle pace projections, category envelope statuses, and multi-period spending distributions.
public enum SpendingTelemetryEngine {
    
    /// Analyzes a set of expenses and categories for a payday cycle, producing an immutable telemetry snapshot.
    public static func analyze(
        expenses: [ExpenseItem],
        categories: [CategoryItem],
        paydayCycle: PaydayCycle,
        period: FilterPeriod = .thisWeek,
        currency: CurrencyItem = CurrencyItem.defaultCurrency,
        startWeekOn: String = "Sunday",
        asOf: Date = Date(),
        calendar: Calendar = .current
    ) -> SpendingTelemetrySnapshot {
        
        let pace = calculatePaceTelemetry(
            expenses: expenses,
            categories: categories,
            paydayCycle: paydayCycle,
            currency: currency,
            asOf: asOf,
            calendar: calendar
        )
        
        let envelopes = calculateEnvelopeTelemetry(
            expenses: expenses,
            categories: categories,
            paydayCycle: paydayCycle,
            asOf: asOf,
            calendar: calendar
        )
        
        let distribution = calculateDistributionTelemetry(
            expenses: expenses,
            categories: categories,
            period: period,
            startWeekOn: startWeekOn,
            asOf: asOf,
            calendar: calendar
        )
        
        return SpendingTelemetrySnapshot(
            pace: pace,
            envelopes: envelopes,
            distribution: distribution
        )
    }
    
    // MARK: - Pace Telemetry
    
    public static func calculatePaceTelemetry(
        expenses: [ExpenseItem],
        categories: [CategoryItem],
        paydayCycle: PaydayCycle,
        currency: CurrencyItem,
        asOf: Date,
        calendar: Calendar
    ) -> PaceTelemetry {
        let totalBudgetCents: Int64 = categories.compactMap(\.monthlyBudgetCents).reduce(0, +)
        let cycleExpenses = expenses.filter { paydayCycle.contains(date: $0.spentDate) }
        let totalSpentCents = cycleExpenses.reduce(0) { $0 + $1.amountCents }
        
        let totalDays = paydayCycle.totalDays(calendar: calendar)
        let currentDayIndex = paydayCycle.currentDayIndex(asOf: asOf, calendar: calendar)
        let daysRemaining = max(1, paydayCycle.daysRemaining(asOf: asOf, calendar: calendar))
        let dailyAllowance = paydayCycle.dailyIdealAllowanceCents(totalBudgetCents: totalBudgetCents, calendar: calendar)
        let freeToSpend = max(0, totalBudgetCents - totalSpentCents)
        let idealPaceSpend = paydayCycle.idealCumulativeCents(totalBudgetCents: totalBudgetCents, atDayIndex: currentDayIndex, calendar: calendar)
        let isPacingAhead = totalSpentCents > idealPaceSpend
        let paceDelta = abs(totalSpentCents - idealPaceSpend)
        
        // Pennies dynamic daily allowance calculation
        let todayExpenses = cycleExpenses.filter { calendar.isDate($0.spentDate, inSameDayAs: asOf) }
        let todaySpentCents: Int64 = todayExpenses.reduce(0) { $0 + $1.amountCents }
        let priorSpentCents: Int64 = max(0, totalSpentCents - todaySpentCents)
        
        let todayBaseAllowanceCents: Int64
        let todayAvailableCents: Int64
        let healthState: BudgetHealthState
        
        if totalBudgetCents <= 0 {
            todayBaseAllowanceCents = 0
            todayAvailableCents = -todaySpentCents
            healthState = .healthy
        } else if totalSpentCents >= totalBudgetCents {
            todayBaseAllowanceCents = 0
            todayAvailableCents = -todaySpentCents
            healthState = .overCycle
        } else {
            let unspentPrior = max(0, totalBudgetCents - priorSpentCents)
            todayBaseAllowanceCents = unspentPrior / Int64(daysRemaining)
            todayAvailableCents = todayBaseAllowanceCents - todaySpentCents
            
            if todayAvailableCents < 0 {
                healthState = .overToday
            } else if todaySpentCents > (todayBaseAllowanceCents * 8) / 10 {
                healthState = .caution
            } else {
                healthState = .healthy
            }
        }
        
        let statusText: String
        if totalBudgetCents <= 0 {
            statusText = "No monthly cap configured"
        } else if totalSpentCents > totalBudgetCents {
            let over = totalSpentCents - totalBudgetCents
            statusText = "Over budget by \(currency.format(cents: over))"
        } else if healthState == .overToday {
            statusText = "Over today's allowance • Cycle healthy"
        } else if isPacingAhead {
            statusText = "Pacing over by \(currency.format(cents: paceDelta))"
        } else {
            statusText = "On track • \(currency.format(cents: paceDelta)) under pace"
        }
        
        var runningSpend: Int64 = 0
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        formatter.calendar = calendar
        
        var points: [CyclePacePoint] = []
        let dates = paydayCycle.cycleDates(calendar: calendar)
        
        for (index, date) in dates.enumerated() {
            let dayNum = index + 1
            let isPastOrToday = dayNum <= currentDayIndex
            let isToday = calendar.isDate(date, inSameDayAs: asOf)
            
            if isPastOrToday {
                let daySpend = cycleExpenses
                    .filter { calendar.isDate($0.spentDate, inSameDayAs: date) }
                    .reduce(0) { $0 + $1.amountCents }
                runningSpend += daySpend
            }
            
            let idealSpend = paydayCycle.idealCumulativeCents(totalBudgetCents: totalBudgetCents, atDayIndex: dayNum, calendar: calendar)
            
            points.append(CyclePacePoint(
                dayNumber: dayNum,
                date: date,
                dateLabel: formatter.string(from: date),
                actualCumulativeCents: isPastOrToday ? runningSpend : nil,
                idealCumulativeCents: idealSpend,
                isToday: isToday,
                isFuture: dayNum > currentDayIndex
            ))
        }
        
        return PaceTelemetry(
            pacePoints: points,
            totalDays: totalDays,
            currentDayIndex: currentDayIndex,
            daysRemaining: daysRemaining,
            cycleTotalBudgetCents: totalBudgetCents,
            cycleTotalSpentCents: totalSpentCents,
            dailyBudgetAllowanceCents: dailyAllowance,
            idealPaceSpendToDateCents: idealPaceSpend,
            freeToSpendCents: freeToSpend,
            cyclePaceDeltaCents: paceDelta,
            isCyclePacingAhead: isPacingAhead,
            statusText: statusText,
            todaySpentCents: todaySpentCents,
            todayBaseAllowanceCents: todayBaseAllowanceCents,
            todayAvailableCents: todayAvailableCents,
            healthState: healthState
        )
    }
    
    // MARK: - Envelope Telemetry
    
    public static func calculateEnvelopeTelemetry(
        expenses: [ExpenseItem],
        categories: [CategoryItem],
        paydayCycle: PaydayCycle,
        asOf: Date = Date(),
        calendar: Calendar = .current
    ) -> EnvelopeTelemetry {
        let cycleExpenses = expenses.filter { paydayCycle.contains(date: $0.spentDate) }
        let totalBudget: Int64 = categories.compactMap(\.monthlyBudgetCents).reduce(0, +)
        let totalSpent: Int64 = cycleExpenses.reduce(0) { $0 + $1.amountCents }
        let freeToSpend: Int64 = max(0, totalBudget - totalSpent)
        let daysRemaining = max(1, paydayCycle.daysRemaining)
        
        let statuses: [CategoryEnvelopeStatus] = categories.map { cat in
            let catExpenses = cycleExpenses.filter { $0.categoryId == cat.id }
            let spent = catExpenses.reduce(0) { $0 + $1.amountCents }
            let budget = cat.monthlyBudgetCents ?? 0
            
            let todaySpent: Int64 = catExpenses
                .filter { calendar.isDate($0.spentDate, inSameDayAs: asOf) }
                .reduce(0) { $0 + $1.amountCents }
            let priorSpent: Int64 = max(0, spent - todaySpent)
            
            let baseAllowance: Int64
            let availableToday: Int64
            let healthState: BudgetHealthState
            
            if budget <= 0 {
                baseAllowance = 0
                availableToday = -todaySpent
                healthState = .healthy
            } else if spent >= budget {
                baseAllowance = 0
                availableToday = -todaySpent
                healthState = .overCycle
            } else {
                let unspentPrior = max(0, budget - priorSpent)
                baseAllowance = unspentPrior / Int64(daysRemaining)
                availableToday = baseAllowance - todaySpent
                
                if availableToday < 0 {
                    healthState = .overToday
                } else if todaySpent > (baseAllowance * 8) / 10 {
                    healthState = .caution
                } else {
                    healthState = .healthy
                }
            }
            
            return CategoryEnvelopeStatus(
                category: cat,
                spentCents: spent,
                todaySpentCents: todaySpent,
                todayBaseAllowanceCents: baseAllowance,
                todayAvailableCents: availableToday,
                healthState: healthState
            )
        }
        
        let overspentCount = statuses.filter(\.isOverspent).count
        
        return EnvelopeTelemetry(
            statuses: statuses,
            overspentCount: overspentCount,
            totalBudgetCents: totalBudget,
            totalSpentCents: totalSpent,
            freeToSpendCents: freeToSpend
        )
    }
    
    // MARK: - Distribution Telemetry
    
    public static func calculateDistributionTelemetry(
        expenses: [ExpenseItem],
        categories: [CategoryItem],
        period: FilterPeriod,
        startWeekOn: String,
        asOf: Date,
        calendar: Calendar
    ) -> DistributionTelemetry {
        let periodExpenses = filterExpenses(expenses, forPeriod: period, asOf: asOf, calendar: calendar)
        let periodTotalCents = periodExpenses.reduce(0) { $0 + $1.amountCents }
        
        let periodTitle: String
        switch period {
        case .today: periodTitle = "Spent today"
        case .thisWeek: periodTitle = "Spent this week"
        case .thisMonth: periodTitle = "Spent this month"
        case .thisYear: periodTitle = "Spent this year"
        case .allTime: periodTitle = "Total spent"
        }
        
        let categoryMap = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })
        
        switch period {
        case .today:
            let timeLabels = ["12 AM", "6 AM", "12 PM", "6 PM"]
            var totals: [String: Int64] = [:]
            var segmentsByLabel: [String: [DayCategorySegment]] = [:]
            for label in timeLabels {
                totals[label] = 0
                segmentsByLabel[label] = []
            }
            
            for label in timeLabels {
                let bucketExpenses = periodExpenses.filter { exp in
                    let hour = calendar.component(.hour, from: exp.spentDate)
                    if label == "12 AM" { return hour < 6 }
                    if label == "6 AM" { return hour >= 6 && hour < 12 }
                    if label == "12 PM" { return hour >= 12 && hour < 18 }
                    return hour >= 18
                }
                
                let byCat = Dictionary(grouping: bucketExpenses, by: { $0.categoryId })
                var segments: [DayCategorySegment] = []
                for (catId, exps) in byCat {
                    let sum = exps.reduce(0) { $0 + $1.amountCents }
                    let cat = categoryMap[catId]
                    let name = cat?.name ?? "Other"
                    let color = cat?.color ?? Theme.accentBlue
                    segments.append(DayCategorySegment(day: label, categoryId: catId, categoryName: name, color: color, amountCents: sum))
                }
                segmentsByLabel[label] = segments
                totals[label] = bucketExpenses.reduce(0) { $0 + $1.amountCents }
            }
            
            let chartData = timeLabels.map { DaySpending(day: $0, amountCents: totals[$0] ?? 0, date: asOf) }
            let catData = timeLabels.map { label in
                let segs = segmentsByLabel[label] ?? []
                let sum = segs.reduce(0) { $0 + $1.amountCents }
                return DaySpendingWithCategories(day: label, date: asOf, totalAmountCents: sum, segments: segs)
            }
            
            return DistributionTelemetry(chartData: chartData, categorizedChartData: catData, periodTotalCents: periodTotalCents, period: period, periodTitle: periodTitle)
            
        case .thisWeek:
            let daySymbols = startWeekOn == "Sunday"
                ? ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
                : ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
            
            var chartData: [DaySpending] = []
            var catData: [DaySpendingWithCategories] = []
            
            for (idx, sym) in daySymbols.enumerated() {
                let targetWeekday = startWeekOn == "Sunday" ? (idx + 1) : ((idx + 1) % 7 + 1)
                let dayExpenses = periodExpenses.filter { exp in
                    calendar.component(.weekday, from: exp.spentDate) == targetWeekday
                }
                
                let dayTotal = dayExpenses.reduce(0) { $0 + $1.amountCents }
                chartData.append(DaySpending(day: sym, amountCents: dayTotal, date: asOf))
                
                let byCat = Dictionary(grouping: dayExpenses, by: { $0.categoryId })
                var segments: [DayCategorySegment] = []
                for (catId, exps) in byCat {
                    let sum = exps.reduce(0) { $0 + $1.amountCents }
                    let cat = categoryMap[catId]
                    let name = cat?.name ?? "Other"
                    let color = cat?.color ?? Theme.accentBlue
                    segments.append(DayCategorySegment(day: sym, categoryId: catId, categoryName: name, color: color, amountCents: sum))
                }
                catData.append(DaySpendingWithCategories(day: sym, date: asOf, totalAmountCents: dayTotal, segments: segments))
            }
            
            return DistributionTelemetry(chartData: chartData, categorizedChartData: catData, periodTotalCents: periodTotalCents, period: period, periodTitle: periodTitle)
            
        case .thisMonth:
            let weekLabels = ["Week 1", "Week 2", "Week 3", "Week 4"]
            var chartData: [DaySpending] = []
            var catData: [DaySpendingWithCategories] = []
            
            for label in weekLabels {
                let weekExpenses = periodExpenses.filter { exp in
                    let dom = calendar.component(.day, from: exp.spentDate)
                    if label == "Week 1" { return dom <= 7 }
                    if label == "Week 2" { return dom > 7 && dom <= 14 }
                    if label == "Week 3" { return dom > 14 && dom <= 21 }
                    return dom > 21
                }
                
                let weekTotal = weekExpenses.reduce(0) { $0 + $1.amountCents }
                chartData.append(DaySpending(day: label, amountCents: weekTotal, date: asOf))
                
                let byCat = Dictionary(grouping: weekExpenses, by: { $0.categoryId })
                var segments: [DayCategorySegment] = []
                for (catId, exps) in byCat {
                    let sum = exps.reduce(0) { $0 + $1.amountCents }
                    let cat = categoryMap[catId]
                    let name = cat?.name ?? "Other"
                    let color = cat?.color ?? Theme.accentBlue
                    segments.append(DayCategorySegment(day: label, categoryId: catId, categoryName: name, color: color, amountCents: sum))
                }
                catData.append(DaySpendingWithCategories(day: label, date: asOf, totalAmountCents: weekTotal, segments: segments))
            }
            
            return DistributionTelemetry(chartData: chartData, categorizedChartData: catData, periodTotalCents: periodTotalCents, period: period, periodTitle: periodTitle)
            
        case .thisYear:
            let monthLabels = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
            var chartData: [DaySpending] = []
            var catData: [DaySpendingWithCategories] = []
            
            for (mIdx, label) in monthLabels.enumerated() {
                let targetMonth = mIdx + 1
                let mExpenses = periodExpenses.filter {
                    calendar.component(.month, from: $0.spentDate) == targetMonth
                }
                
                let mTotal = mExpenses.reduce(0) { $0 + $1.amountCents }
                chartData.append(DaySpending(day: label, amountCents: mTotal, date: asOf))
                
                let byCat = Dictionary(grouping: mExpenses, by: { $0.categoryId })
                var segments: [DayCategorySegment] = []
                for (catId, exps) in byCat {
                    let sum = exps.reduce(0) { $0 + $1.amountCents }
                    let cat = categoryMap[catId]
                    let name = cat?.name ?? "Other"
                    let color = cat?.color ?? Theme.accentBlue
                    segments.append(DayCategorySegment(day: label, categoryId: catId, categoryName: name, color: color, amountCents: sum))
                }
                catData.append(DaySpendingWithCategories(day: label, date: asOf, totalAmountCents: mTotal, segments: segments))
            }
            
            return DistributionTelemetry(chartData: chartData, categorizedChartData: catData, periodTotalCents: periodTotalCents, period: period, periodTitle: periodTitle)
            
        case .allTime:
            let currentYear = calendar.component(.year, from: asOf)
            let expenseYears = periodExpenses.map { calendar.component(.year, from: $0.spentDate) }
            let minYear = min(currentYear - 4, expenseYears.min() ?? (currentYear - 4))
            let yearLabels = Array(minYear...currentYear).map { String($0) }
            
            var chartData: [DaySpending] = []
            var catData: [DaySpendingWithCategories] = []
            
            for yearLabel in yearLabels {
                guard let yNum = Int(yearLabel) else { continue }
                let yExpenses = periodExpenses.filter {
                    calendar.component(.year, from: $0.spentDate) == yNum
                }
                
                let yTotal = yExpenses.reduce(0) { $0 + $1.amountCents }
                chartData.append(DaySpending(day: yearLabel, amountCents: yTotal, date: asOf))
                
                let byCat = Dictionary(grouping: yExpenses, by: { $0.categoryId })
                var segments: [DayCategorySegment] = []
                for (catId, exps) in byCat {
                    let sum = exps.reduce(0) { $0 + $1.amountCents }
                    let cat = categoryMap[catId]
                    let name = cat?.name ?? "Other"
                    let color = cat?.color ?? Theme.accentBlue
                    segments.append(DayCategorySegment(day: yearLabel, categoryId: catId, categoryName: name, color: color, amountCents: sum))
                }
                catData.append(DaySpendingWithCategories(day: yearLabel, date: asOf, totalAmountCents: yTotal, segments: segments))
            }
            
            return DistributionTelemetry(chartData: chartData, categorizedChartData: catData, periodTotalCents: periodTotalCents, period: period, periodTitle: periodTitle)
        }
    }
    
    // MARK: - Private Period Filtering
    
    private static func filterExpenses(
        _ expenses: [ExpenseItem],
        forPeriod period: FilterPeriod,
        asOf: Date,
        calendar: Calendar
    ) -> [ExpenseItem] {
        switch period {
        case .today:
            return expenses.filter { calendar.isDate($0.spentDate, inSameDayAs: asOf) }
        case .thisWeek:
            guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: asOf) else { return expenses }
            return expenses.filter { $0.spentDate >= weekInterval.start && $0.spentDate < weekInterval.end }
        case .thisMonth:
            guard let monthInterval = calendar.dateInterval(of: .month, for: asOf) else { return expenses }
            return expenses.filter { $0.spentDate >= monthInterval.start && $0.spentDate < monthInterval.end }
        case .thisYear:
            guard let yearInterval = calendar.dateInterval(of: .year, for: asOf) else { return expenses }
            return expenses.filter { $0.spentDate >= yearInterval.start && $0.spentDate < yearInterval.end }
        case .allTime:
            return expenses
        }
    }
}
