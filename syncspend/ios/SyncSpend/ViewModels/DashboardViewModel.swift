import Foundation
import Observation
import SwiftUI

public struct DaySpending: Identifiable {
    public var id: String { day }
    public let day: String
    public let amountCents: Int64
    public let date: Date
}

public enum FilterPeriod: String, CaseIterable, Identifiable {
    case today = "Today"
    case thisWeek = "This Week"
    case thisMonth = "This Month"
    case thisYear = "This Year"
    case allTime = "All Time"
    
    public var id: String { rawValue }
    public var title: String { rawValue }
}

@Observable
public final class DashboardViewModel {
    public var service = SpacetimeService.shared
    
    public static let defaultPaymentMethods = [
        "Bank Transfer",
        "Cash",
        "Credit Card",
        "Debit Card",
        "E-Wallet",
        "Apple Pay"
    ]
    
    // Data State
    public var accounts: [AccountItem] = AccountItem.defaultAccounts
    public var activeAccountId: String = "acc-personal"
    public var categories: [CategoryItem] = []
    public var expenses: [ExpenseItem] = []
    public var isLoading: Bool = false
    public var errorMessage: String?
    
    // Filtering & Preferences
    public var selectedPeriod: FilterPeriod = .thisWeek
    public var selectedFilterCategoryId: UInt64? = nil
    public var selectedPaymentMethod: String? = nil
    public var searchQuery: String = ""
    public var currency: CurrencyItem = CurrencyItem.defaultCurrency
    public var startWeekOn: String = "Sunday" // "Sunday" or "Monday"
    public var smartSuggestionsEnabled: Bool = true
    
    // Undo soft-deletion state
    public var lastDeletedExpense: ExpenseItem?
    public var showingUndoBar: Bool = false
    private var undoTimer: Timer?
    
    public init() {}
    
    public var activeAccount: AccountItem {
        accounts.first(where: { $0.id == activeAccountId }) ?? accounts.first ?? AccountItem.defaultAccounts[0]
    }
    
    public func categoryFor(id: UInt64) -> CategoryItem? {
        categories.first(where: { $0.id == id })
    }
    
    // Filtered expenses for active account
    public var accountExpenses: [ExpenseItem] {
        expenses.filter { exp in
            (exp.accountId ?? "acc-personal") == activeAccountId
        }
    }
    
    public var isFilterActive: Bool {
        selectedFilterCategoryId != nil || (selectedPaymentMethod != nil && selectedPaymentMethod != "All") || selectedPeriod != .thisWeek
    }
    
    public var activeFilterDescription: String {
        var parts: [String] = []
        if selectedPeriod != .thisWeek {
            parts.append(selectedPeriod.title)
        }
        if let catId = selectedFilterCategoryId, let cat = categoryFor(id: catId) {
            parts.append(cat.name)
        }
        if let method = selectedPaymentMethod, method != "All" {
            parts.append(method)
        }
        return parts.joined(separator: ", ")
    }
    
    public func clearAllFilters() {
        selectedFilterCategoryId = nil
        selectedPaymentMethod = nil
        selectedPeriod = .thisWeek
    }

    public var periodTitle: String {
        switch selectedPeriod {
        case .today:
            return "Spent today"
        case .thisWeek:
            return "Spent this week"
        case .thisMonth:
            return "Spent this month"
        case .thisYear:
            return "Spent this year"
        case .allTime:
            return "Total spent"
        }
    }
    
    // Base expenses filtered by active account, search query, category, and payment method
    public var baseFilteredExpenses: [ExpenseItem] {
        var filtered = accountExpenses
        
        if !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty {
            let q = searchQuery.lowercased()
            filtered = filtered.filter { exp in
                let catName = categoryFor(id: exp.categoryId)?.name.lowercased() ?? ""
                return exp.note.lowercased().contains(q) || catName.contains(q) || String(exp.amountCents).contains(q)
            }
        }
        
        if let catId = selectedFilterCategoryId {
            filtered = filtered.filter { $0.categoryId == catId }
        }
        
        if let method = selectedPaymentMethod, !method.isEmpty, method != "All" {
            filtered = filtered.filter { exp in
                exp.paymentMethod.localizedCaseInsensitiveContains(method) ||
                method.localizedCaseInsensitiveContains(exp.paymentMethod)
            }
        }
        
        return filtered
    }
    
    // Expenses matching all active filters including period
    public var filteredExpenses: [ExpenseItem] {
        let calendar = Calendar.current
        let now = Date()
        let filtered = baseFilteredExpenses
        
        switch selectedPeriod {
        case .today:
            return filtered.filter { calendar.isDateInToday($0.spentDate) }
        case .thisWeek:
            guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: now) else { return filtered }
            return filtered.filter { $0.spentDate >= weekInterval.start && $0.spentDate < weekInterval.end }
        case .thisMonth:
            guard let monthInterval = calendar.dateInterval(of: .month, for: now) else { return filtered }
            return filtered.filter { $0.spentDate >= monthInterval.start && $0.spentDate < monthInterval.end }
        case .thisYear:
            guard let yearInterval = calendar.dateInterval(of: .year, for: now) else { return filtered }
            return filtered.filter { $0.spentDate >= yearInterval.start && $0.spentDate < yearInterval.end }
        case .allTime:
            return filtered
        }
    }
    
    // Total spent for the selected period
    public var periodTotalCents: Int64 {
        filteredExpenses.reduce(0) { $0 + $1.amountCents }
    }
    
    public var weeklyTotalCents: Int64 {
        periodTotalCents
    }
    
    // Dynamic Chart Data based on selectedPeriod
    public var chartData: [DaySpending] {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedPeriod {
        case .today:
            let timeLabels = ["12 AM", "6 AM", "12 PM", "6 PM"]
            var totals: [String: Int64] = [:]
            for label in timeLabels { totals[label] = 0 }
            
            let todayExpenses = baseFilteredExpenses.filter { calendar.isDateInToday($0.spentDate) }
            for exp in todayExpenses {
                let hour = calendar.component(.hour, from: exp.spentDate)
                let bucketLabel: String
                if hour < 6 {
                    bucketLabel = "12 AM"
                } else if hour < 12 {
                    bucketLabel = "6 AM"
                } else if hour < 18 {
                    bucketLabel = "12 PM"
                } else {
                    bucketLabel = "6 PM"
                }
                totals[bucketLabel, default: 0] += exp.amountCents
            }
            return timeLabels.map { DaySpending(day: $0, amountCents: totals[$0] ?? 0, date: now) }
            
        case .thisWeek:
            let daySymbols = startWeekOn == "Sunday"
                ? ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
                : ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
            
            var totals: [String: Int64] = [:]
            for sym in daySymbols { totals[sym] = 0 }
            
            guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: now) else {
                return daySymbols.map { DaySpending(day: $0, amountCents: 0, date: now) }
            }
            
            for exp in baseFilteredExpenses {
                if exp.spentDate >= weekInterval.start && exp.spentDate < weekInterval.end {
                    let weekday = calendar.component(.weekday, from: exp.spentDate)
                    let sym = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"][weekday - 1]
                    totals[sym, default: 0] += exp.amountCents
                }
            }
            return daySymbols.map { DaySpending(day: $0, amountCents: totals[$0] ?? 0, date: now) }
            
        case .thisMonth:
            let weekLabels = ["Week 1", "Week 2", "Week 3", "Week 4"]
            var totals: [String: Int64] = [:]
            for label in weekLabels { totals[label] = 0 }
            
            guard let monthInterval = calendar.dateInterval(of: .month, for: now) else {
                return weekLabels.map { DaySpending(day: $0, amountCents: 0, date: now) }
            }
            
            for exp in baseFilteredExpenses {
                if exp.spentDate >= monthInterval.start && exp.spentDate < monthInterval.end {
                    let dayOfMonth = calendar.component(.day, from: exp.spentDate)
                    let bucketLabel: String
                    if dayOfMonth <= 7 {
                        bucketLabel = "Week 1"
                    } else if dayOfMonth <= 14 {
                        bucketLabel = "Week 2"
                    } else if dayOfMonth <= 21 {
                        bucketLabel = "Week 3"
                    } else {
                        bucketLabel = "Week 4"
                    }
                    totals[bucketLabel, default: 0] += exp.amountCents
                }
            }
            return weekLabels.map { DaySpending(day: $0, amountCents: totals[$0] ?? 0, date: now) }
            
        case .thisYear:
            let monthLabels = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
            var totals: [String: Int64] = [:]
            for label in monthLabels { totals[label] = 0 }
            
            guard let yearInterval = calendar.dateInterval(of: .year, for: now) else {
                return monthLabels.map { DaySpending(day: $0, amountCents: 0, date: now) }
            }
            
            for exp in baseFilteredExpenses {
                if exp.spentDate >= yearInterval.start && exp.spentDate < yearInterval.end {
                    let month = calendar.component(.month, from: exp.spentDate)
                    if month >= 1 && month <= 12 {
                        let label = monthLabels[month - 1]
                        totals[label, default: 0] += exp.amountCents
                    }
                }
            }
            return monthLabels.map { DaySpending(day: $0, amountCents: totals[$0] ?? 0, date: now) }
            
        case .allTime:
            let currentYear = calendar.component(.year, from: now)
            let expenseYears = baseFilteredExpenses.map { calendar.component(.year, from: $0.spentDate) }
            let minYear = min(currentYear - 4, expenseYears.min() ?? (currentYear - 4))
            let yearLabels = Array(minYear...currentYear).map { String($0) }
            
            var totals: [String: Int64] = [:]
            for label in yearLabels { totals[label] = 0 }
            
            for exp in baseFilteredExpenses {
                let yearStr = String(calendar.component(.year, from: exp.spentDate))
                if totals[yearStr] != nil {
                    totals[yearStr, default: 0] += exp.amountCents
                }
            }
            return yearLabels.map { DaySpending(day: $0, amountCents: totals[$0] ?? 0, date: now) }
        }
    }
    
    public var weeklyChartData: [DaySpending] {
        chartData
    }
    
    // Grouped expenses by Day Name / Date
    public var groupedExpenses: [(key: String, expenses: [ExpenseItem])] {
        let filtered = filteredExpenses
        
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMM"
        
        let groups = Dictionary(grouping: filtered) { exp in
            let date = exp.spentDate
            let cal = Calendar.current
            if cal.isDateInToday(date) {
                return "Today"
            } else if cal.isDateInYesterday(date) {
                return "Yesterday"
            } else {
                return formatter.string(from: date)
            }
        }
        
        // Sort groups with recent dates first
        return groups.map { (key: $0.key, expenses: $0.value.sorted(by: { $0.spentAtMillis > $1.spentAtMillis })) }
            .sorted { g1, g2 in
                guard let first1 = g1.expenses.first, let first2 = g2.expenses.first else { return false }
                return first1.spentAtMillis > first2.spentAtMillis
            }
    }

    
    // MARK: - Data Actions
    
    public func refreshAll() async {
        isLoading = true
        await loadCategories()
        await loadExpenses()
        isLoading = false
    }
    
    public func loadCategories() async {
        do {
            var fetched = try await service.fetchCategories()
            if fetched.isEmpty {
                try await service.initializeUserProfile()
                fetched = try await service.fetchCategories()
            }
            self.categories = fetched
        } catch {
            print("DashboardViewModel: Failed to load categories: \(error)")
        }
    }
    
    public func loadExpenses() async {
        do {
            let fetched = try await service.fetchRecentExpenses()
            self.expenses = fetched
        } catch {
            print("DashboardViewModel: Failed to load expenses: \(error)")
        }
    }
    
    public func deleteExpense(_ item: ExpenseItem) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            expenses.removeAll(where: { $0.id == item.id })
            lastDeletedExpense = item
            showingUndoBar = true
        }
        
        undoTimer?.invalidate()
        undoTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            withAnimation {
                self?.showingUndoBar = false
                self?.lastDeletedExpense = nil
            }
        }
        
        Task {
            do {
                try await service.softDeleteExpense(expenseId: item.id)
            } catch {
                print("Failed to soft delete: \(error)")
                await loadExpenses()
            }
        }
    }
    
    public func undoDelete(_ item: ExpenseItem) {
        undoTimer?.invalidate()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            showingUndoBar = false
        }
        
        Task {
            do {
                try await service.restoreExpense(expenseId: item.id)
                await loadExpenses()
            } catch {
                print("Failed to restore: \(error)")
            }
        }
    }
    
    public func addAccount(name: String) {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let newAcc = AccountItem(
            id: "acc-\(UUID().uuidString.prefix(8))",
            name: name.trimmingCharacters(in: .whitespaces),
            icon: "briefcase.fill",
            balanceCents: 0,
            isDefault: false
        )
        accounts.append(newAcc)
        activeAccountId = newAcc.id
    }
    
    public func deleteAccount(id: String) {
        guard accounts.count > 1 else { return }
        accounts.removeAll(where: { $0.id == id })
        if activeAccountId == id {
            activeAccountId = accounts.first?.id ?? "acc-personal"
        }
    }
}
