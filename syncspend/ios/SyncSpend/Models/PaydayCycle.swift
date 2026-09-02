import Foundation

public struct PaydayCycle: Equatable, Hashable {
    public let billingCycleStartDay: UInt8
    public let startDate: Date
    public let endDate: Date
    
    public init(billingCycleStartDay: UInt8, startDate: Date, endDate: Date) {
        self.billingCycleStartDay = billingCycleStartDay
        self.startDate = startDate
        self.endDate = endDate
    }
    
    public func contains(date: Date) -> Bool {
        date >= startDate && date < endDate
    }
    
    public var dateRangeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        
        let endDisplay = Calendar.current.date(byAdding: .day, value: -1, to: endDate) ?? endDate
        return "\(formatter.string(from: startDate)) – \(formatter.string(from: endDisplay))"
    }
    
    public var daysRemaining: Int {
        let now = Date()
        if now >= endDate { return 0 }
        let diff = Calendar.current.dateComponents([.day], from: now, to: endDate)
        return max(0, diff.day ?? 0)
    }
    
    public var totalDays: Int {
        let diff = Calendar.current.dateComponents([.day], from: startDate, to: endDate)
        return max(1, diff.day ?? 30)
    }
    
    public var currentDayIndex: Int {
        let now = Date()
        if now < startDate { return 1 }
        if now >= endDate { return totalDays }
        let diff = Calendar.current.dateComponents([.day], from: startDate, to: now)
        return max(1, min(totalDays, (diff.day ?? 0) + 1))
    }
    
    public var cycleProgressPercentage: Double {
        let total = endDate.timeIntervalSince(startDate)
        guard total > 0 else { return 1.0 }
        let elapsed = Date().timeIntervalSince(startDate)
        return max(0.0, min(1.0, elapsed / total))
    }
    
    public func idealCumulativeCents(totalBudgetCents: Int64, atDayIndex dayIndex: Int) -> Int64 {
        guard totalDays > 0, totalBudgetCents > 0 else { return 0 }
        let fraction = min(1.0, max(0.0, Double(dayIndex) / Double(totalDays)))
        return Int64(Double(totalBudgetCents) * fraction)
    }
    
    public func dailyIdealAllowanceCents(totalBudgetCents: Int64) -> Int64 {
        guard totalDays > 0, totalBudgetCents > 0 else { return 0 }
        return totalBudgetCents / Int64(totalDays)
    }
    
    public var cycleDates: [Date] {
        var dates: [Date] = []
        let calendar = Calendar.current
        var curr = startDate
        while curr < endDate {
            dates.append(curr)
            guard let next = calendar.date(byAdding: .day, value: 1, to: curr) else { break }
            curr = next
        }
        return dates
    }
    
    public static func current(
        billingCycleStartDay: UInt8 = 1,
        currentDate: Date = Date(),
        calendar: Calendar = .current
    ) -> PaydayCycle {
        let dayAnchor = max(1, min(28, Int(billingCycleStartDay)))
        
        let currentYear = calendar.component(.year, from: currentDate)
        let currentMonth = calendar.component(.month, from: currentDate)
        let currentDay = calendar.component(.day, from: currentDate)
        
        let startDate: Date
        let endDate: Date
        
        if currentDay >= dayAnchor {
            // Started on dayAnchor of current month
            var startComps = DateComponents()
            startComps.year = currentYear
            startComps.month = currentMonth
            startComps.day = dayAnchor
            startComps.hour = 0
            startComps.minute = 0
            startComps.second = 0
            
            let start = calendar.date(from: startComps) ?? currentDate
            let end = calendar.date(byAdding: .month, value: 1, to: start) ?? currentDate
            
            startDate = start
            endDate = end
        } else {
            // Started on dayAnchor of previous month
            let prevMonthDate = calendar.date(byAdding: .month, value: -1, to: currentDate) ?? currentDate
            let prevYear = calendar.component(.year, from: prevMonthDate)
            let prevMonth = calendar.component(.month, from: prevMonthDate)
            
            var startComps = DateComponents()
            startComps.year = prevYear
            startComps.month = prevMonth
            startComps.day = dayAnchor
            startComps.hour = 0
            startComps.minute = 0
            startComps.second = 0
            
            var endComps = DateComponents()
            endComps.year = currentYear
            endComps.month = currentMonth
            endComps.day = dayAnchor
            endComps.hour = 0
            endComps.minute = 0
            endComps.second = 0
            
            startDate = calendar.date(from: startComps) ?? currentDate
            endDate = calendar.date(from: endComps) ?? currentDate
        }
        
        return PaydayCycle(
            billingCycleStartDay: UInt8(dayAnchor),
            startDate: startDate,
            endDate: endDate
        )
    }
}

public struct CategoryEnvelopeStatus: Identifiable, Equatable, Hashable {
    public var id: UInt64 { category.id }
    public let category: CategoryItem
    public let spentCents: Int64
    public let budgetCents: Int64?
    
    public var isOverspent: Bool {
        guard let budget = budgetCents, budget > 0 else { return false }
        return spentCents > budget
    }
    
    public var overspentCents: Int64 {
        guard let budget = budgetCents, spentCents > budget else { return 0 }
        return spentCents - budget
    }
    
    public var remainingCents: Int64? {
        guard let budget = budgetCents else { return nil }
        return budget - spentCents
    }
    
    public var progressRatio: Double {
        guard let budget = budgetCents, budget > 0 else { return 0.0 }
        return min(1.0, max(0.0, Double(spentCents) / Double(budget)))
    }
    
    public var percentage: Int {
        guard let budget = budgetCents, budget > 0 else { return 0 }
        return Int((Double(spentCents) / Double(budget)) * 100.0)
    }
    
    public init(category: CategoryItem, spentCents: Int64) {
        self.category = category
        self.spentCents = spentCents
        self.budgetCents = category.monthlyBudgetCents
    }
}
