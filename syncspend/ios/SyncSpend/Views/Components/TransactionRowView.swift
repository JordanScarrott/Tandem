import SwiftUI

public struct TransactionRowView: View {
    public let expense: ExpenseItem
    public let category: CategoryItem?
    public let currency: CurrencyItem
    public let onDelete: () -> Void
    
    public init(
        expense: ExpenseItem,
        category: CategoryItem?,
        currency: CurrencyItem,
        onDelete: @escaping () -> Void
    ) {
        self.expense = expense
        self.category = category
        self.currency = currency
        self.onDelete = onDelete
    }
    
    private var formattedDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: expense.spentDate)
    }
    
    public var body: some View {
        HStack(spacing: 14) {
            // Category Icon Badge (Squircle)
            ZStack {
                RoundedRectangle(cornerRadius: Theme.squircleCornerRadius, style: .continuous)
                    .fill(Color(hex: "#F2F2F7") ?? Color(.systemGray6))
                    .frame(width: 44, height: 44)
                
                Image(systemName: category?.icon ?? "tag.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(category?.color ?? Theme.primaryDark)
            }
            
            // Title & Date
            VStack(alignment: .leading, spacing: 2) {
                Text(expense.note.isEmpty ? (category?.name ?? "Expense") : expense.note)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.primaryDark)
                    .lineLimit(1)
                
                Text(formattedDateString)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Theme.mutedText)
            }
            
            Spacer()
            
            // Amount
            Text(currency.format(cents: expense.amountCents))
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.primaryDark)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Theme.cardBackground)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash.fill")
            }
        }
    }
}
