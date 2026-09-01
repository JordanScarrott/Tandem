import SwiftUI

public struct TransactionGroupListView: View {
    public let groupedExpenses: [(key: String, expenses: [ExpenseItem])]
    public let categories: [CategoryItem]
    public let currency: CurrencyItem
    public let accountName: String
    public let onDelete: (ExpenseItem) -> Void
    
    public init(
        groupedExpenses: [(key: String, expenses: [ExpenseItem])],
        categories: [CategoryItem],
        currency: CurrencyItem,
        accountName: String,
        onDelete: @escaping (ExpenseItem) -> Void
    ) {
        self.groupedExpenses = groupedExpenses
        self.categories = categories
        self.currency = currency
        self.accountName = accountName
        self.onDelete = onDelete
    }
    
    private func categoryFor(id: UInt64) -> CategoryItem? {
        categories.first(where: { $0.id == id })
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            if groupedExpenses.isEmpty {
                // Empty state matching prototype
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.black.opacity(0.04))
                            .frame(width: 56, height: 56)
                        
                        Image(systemName: "creditcard")
                            .font(.system(size: 26))
                            .foregroundStyle(Theme.mutedText)
                    }
                    .padding(.bottom, 4)
                    
                    Text("No expenses found")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.primaryDark)
                    
                    Text("Tap the black plus button below to log your first purchase in \(accountName).")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(Theme.mutedText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.vertical, 40)
            } else {
                ForEach(groupedExpenses, id: \.key) { group in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(group.key)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Theme.mutedText)
                            .padding(.horizontal, 8)
                        
                        VStack(spacing: 0) {
                            ForEach(Array(group.expenses.enumerated()), id: \.element.id) { index, item in
                                TransactionRowView(
                                    expense: item,
                                    category: categoryFor(id: item.categoryId),
                                    currency: currency,
                                    onDelete: { onDelete(item) }
                                )
                                
                                if index < group.expenses.count - 1 {
                                    Divider()
                                        .padding(.leading, 72)
                                }
                            }
                        }
                        .background(Theme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous)
                                .strokeBorder(Theme.cardBorder, lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.02), radius: 8, x: 0, y: 2)
                    }
                }
            }
        }
    }
}
