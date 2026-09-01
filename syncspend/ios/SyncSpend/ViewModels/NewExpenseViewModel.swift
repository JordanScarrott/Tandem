import Foundation
import Observation
import SwiftUI

@Observable
public final class NewExpenseViewModel {
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
    
    public var parsedCents: Int64 {
        let clean = amountInput
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: ",", with: ".")
        guard let num = Double(clean), num > 0 else { return 0 }
        return Int64(round(num * 100.0))
    }
    
    public var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty && parsedCents > 0 && selectedCategoryId != nil
    }
    
    public func applySuggestion(title: String, amountString: String, categoryId: UInt64?) {
        self.title = title
        self.amountInput = amountString
        if let catId = categoryId {
            self.selectedCategoryId = catId
        }
    }
    
    public func saveExpense(currencyCode: String = "ZAR", accountId: String = "acc-personal") async -> Bool {
        guard canSave, let catId = selectedCategoryId else { return false }
        isSubmitting = true
        errorMessage = nil
        
        do {
            try await service.logExpense(
                amountCents: parsedCents,
                currency: currencyCode,
                categoryId: catId,
                paymentMethod: selectedPaymentMethod,
                note: title.trimmingCharacters(in: .whitespaces),
                spentDate: spentDate
            )
            isSubmitting = false
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            self.isSubmitting = false
            return false
        }
    }
    
    public func reset() {
        title = ""
        amountInput = ""
        selectedPaymentMethod = "Apple Pay"
        spentDate = Date()
        selectedSplitMode = "PERSONAL"
        errorMessage = nil
    }
}
