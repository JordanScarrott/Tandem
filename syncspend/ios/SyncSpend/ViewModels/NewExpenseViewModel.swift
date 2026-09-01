import Foundation
import Observation
import SwiftUI

@Observable
public final class NewExpenseViewModel {
    public var editingExpenseId: UInt64? = nil
    public var title: String = ""
    public var amountInput: String = ""
    public var selectedCategoryId: UInt64?
    public var selectedPaymentMethod: String = "Apple Pay"
    public var spentDate: Date = Date()
    public var selectedSplitMode: String = "PERSONAL"
    public var isSubmitting: Bool = false
    public var errorMessage: String?
    
    public var service = SpacetimeService.shared
    
    public init() {}
    
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
        self.selectedPaymentMethod = expense.paymentMethod.isEmpty ? "Apple Pay" : expense.paymentMethod
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
        selectedPaymentMethod = "Apple Pay"
        spentDate = Date()
        selectedSplitMode = "PERSONAL"
        errorMessage = nil
    }
}

