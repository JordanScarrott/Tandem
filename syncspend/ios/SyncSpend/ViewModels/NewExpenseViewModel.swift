import Foundation
import Observation
import SwiftUI

public protocol ExpenseLoggingService: Sendable {
    func logExpense(
        amountCents: Int64,
        currency: String,
        categoryId: UInt64,
        paymentMethod: String,
        note: String,
        spentDate: Date
    ) async throws

    func updateExpense(
        expenseId: UInt64,
        amountCents: Int64,
        currency: String,
        categoryId: UInt64,
        paymentMethod: String,
        note: String,
        spentDate: Date,
        splitMode: String
    ) async throws

    func softDeleteExpense(expenseId: UInt64) async throws
}

extension SpacetimeService: ExpenseLoggingService {}

@Observable
public final class NewExpenseViewModel {
    public static let lastUsedPaymentMethodKey = "syncspend.lastUsedPaymentMethod"
    public static let lastUsedCategoryIdKey = "syncspend.lastUsedCategoryId"
    public static let defaultPaymentMethod = "Apple Pay"

    public var editingExpenseId: UInt64? = nil
    public var title: String = ""
    public var amountInput: String = ""
    public var selectedCategoryId: UInt64?
    public var selectedPaymentMethod: String = defaultPaymentMethod
    public var spentDate: Date = Date()
    public var selectedSplitMode: String = "PERSONAL"
    public var isSubmitting: Bool = false
    public var errorMessage: String?

    public var service: any ExpenseLoggingService
    private let userDefaults: UserDefaults

    public init(
        service: any ExpenseLoggingService = SpacetimeService.shared,
        userDefaults: UserDefaults = .standard
    ) {
        self.service = service
        self.userDefaults = userDefaults
        loadDefaults()
    }

    public func loadDefaults() {
        if let rawCat = userDefaults.object(forKey: Self.lastUsedCategoryIdKey) as? NSNumber {
            self.selectedCategoryId = rawCat.uint64Value
        } else {
            self.selectedCategoryId = nil
        }

        if let savedMethod = userDefaults.string(forKey: Self.lastUsedPaymentMethodKey), !savedMethod.isEmpty {
            self.selectedPaymentMethod = savedMethod
        } else {
            self.selectedPaymentMethod = Self.defaultPaymentMethod
        }
    }

    public func persistDefaults(categoryId: UInt64, paymentMethod: String) {
        userDefaults.set(NSNumber(value: categoryId), forKey: Self.lastUsedCategoryIdKey)
        userDefaults.set(paymentMethod, forKey: Self.lastUsedPaymentMethodKey)
    }

    public func reconcileSelectedCategory(with categories: [CategoryItem]) {
        if let current = selectedCategoryId, categories.contains(where: { $0.id == current }) {
            return
        }
        selectedCategoryId = categories.first?.id
    }

    public var isEditing: Bool {
        editingExpenseId != nil
    }

    public var parsedCents: Int64 {
        let clean = amountInput
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: ",", with: ".")
        guard let num = Double(clean), num > 0 else { return 0 }
        return Int64(round(num * 100.0))
    }

    public var canSave: Bool {
        parsedCents > 0 && selectedCategoryId != nil
    }

    public func formattedAmount(currencySymbol: String = "R") -> String {
        let rands = Double(parsedCents) / 100.0
        return String(format: "%@ %.2f", currencySymbol, rands)
    }

    public func populate(with expense: ExpenseItem) {
        self.editingExpenseId = expense.id
        self.title = expense.note
        let rands = Double(expense.amountCents) / 100.0
        self.amountInput = String(format: "%.2f", rands)
        self.selectedCategoryId = expense.categoryId
        self.selectedPaymentMethod = expense.paymentMethod.isEmpty ? Self.defaultPaymentMethod : expense.paymentMethod
        self.spentDate = expense.spentDate
        self.selectedSplitMode = expense.splitMode ?? "PERSONAL"
    }

    public func applySuggestion(title: String, amountString: String, categoryId: UInt64?) {
        self.title = title
        self.amountInput = amountString
        if let catId = categoryId {
            self.selectedCategoryId = catId
        }
    }

    public func saveExpense(
        categories: [CategoryItem] = [],
        currencyCode: String = "ZAR",
        accountId: String = "acc-personal"
    ) async -> Bool {
        guard canSave, let catId = selectedCategoryId else { return false }
        isSubmitting = true
        errorMessage = nil

        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        let categoryName = categories.first(where: { $0.id == catId })?.name ?? "Expense"
        let finalNote = trimmedTitle.isEmpty ? categoryName : trimmedTitle

        do {
            if let expId = editingExpenseId {
                try await service.updateExpense(
                    expenseId: expId,
                    amountCents: parsedCents,
                    currency: currencyCode,
                    categoryId: catId,
                    paymentMethod: selectedPaymentMethod,
                    note: finalNote,
                    spentDate: spentDate,
                    splitMode: selectedSplitMode
                )
            } else {
                try await service.logExpense(
                    amountCents: parsedCents,
                    currency: currencyCode,
                    categoryId: catId,
                    paymentMethod: selectedPaymentMethod,
                    note: finalNote,
                    spentDate: spentDate
                )
            }
            persistDefaults(categoryId: catId, paymentMethod: selectedPaymentMethod)
            isSubmitting = false
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            self.isSubmitting = false
            return false
        }
    }

    public func deleteExpense() async -> Bool {
        guard let expId = editingExpenseId else { return false }
        isSubmitting = true
        errorMessage = nil
        do {
            try await service.softDeleteExpense(expenseId: expId)
            isSubmitting = false
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            self.isSubmitting = false
            return false
        }
    }

    public func reset() {
        editingExpenseId = nil
        title = ""
        amountInput = ""
        loadDefaults()
        spentDate = Date()
        selectedSplitMode = "PERSONAL"
        errorMessage = nil
    }
}
