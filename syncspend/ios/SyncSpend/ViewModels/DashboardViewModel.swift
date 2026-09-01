import Foundation
import Observation
import SwiftUI

public struct DaySpending: Identifiable {
    public var id: String { day }
    public let day: String
    public let amountCents: Int64
    public let date: Date
}

@Observable
public final class DashboardViewModel {
    public var service = SpacetimeService.shared
    
    // Data State
    public var accounts: [AccountItem] = AccountItem.defaultAccounts
    public var activeAccountId: String = "acc-personal"
    public var categories: [CategoryItem] = []
    public var expenses: [ExpenseItem] = []
    public var isLoading: Bool = false
    public var errorMessage: String?
    
    // Filtering & Preferences
    public var selectedFilterCategoryId: UInt64? = nil
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
    
    // Total spent this current week for active account
    public var weeklyTotalCents: Int64 {
        let calendar = Calendar.current
        let now = Date()
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: now) else {
            return accountExpenses.reduce(0) { $0 + $1.amountCents }
        }
        
        return accountExpenses
            .filter { exp in
                let date = exp.spentDate
                return date >= weekInterval.start && date < weekInterval.end
            }
            .reduce(0) { $0 + $1.amountCents }
    }
    
    // 7-Day Chart Data for current week
    public var weeklyChartData: [DaySpending] {
        let calendar = Calendar.current
        let daySymbols = startWeekOn == "Sunday"
            ? ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            : ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        
        var totals: [String: Int64] = [:]
        for sym in daySymbols { totals[sym] = 0 }
        
        let now = Date()
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: now) else {
            return daySymbols.map { DaySpending(day: $0, amountCents: 0, date: Date()) }
        }
        
        for exp in accountExpenses {
            if exp.spentDate >= weekInterval.start && exp.spentDate < weekInterval.end {
                let weekday = calendar.component(.weekday, from: exp.spentDate)
                // Calendar weekday: 1 = Sunday, 7 = Saturday
                let sym = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"][weekday - 1]
                totals[sym, default: 0] += exp.amountCents
            }
        }
        
        return daySymbols.map { sym in
            DaySpending(day: sym, amountCents: totals[sym] ?? 0, date: Date())
        }
    }
    
    // Grouped expenses by Day Name / Date
    public var groupedExpenses: [(key: String, expenses: [ExpenseItem])] {
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
        
        // Group by calendar day string (e.g. "Friday, 28 August")
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        
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
