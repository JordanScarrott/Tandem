import SwiftUI

public struct UndoFloatingBar: View {
    public let expense: ExpenseItem
    public let currency: CurrencyItem
    public let onUndo: () -> Void
    
    public init(expense: ExpenseItem, currency: CurrencyItem, onUndo: @escaping () -> Void) {
        self.expense = expense
        self.currency = currency
        self.onUndo = onUndo
    }
    
    public var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "trash.fill")
                .font(.system(size: 16))
                .foregroundStyle(Theme.accentRed)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Deleted \(currency.format(cents: expense.amountCents))")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.primaryDark)
                
                Text(expense.note.isEmpty ? "Expense" : expense.note)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Theme.mutedText)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onUndo()
            } label: {
                Text("UNDO")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.primaryDark)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.08))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.white.opacity(0.4), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 6)
        .padding(.horizontal, 16)
        .padding(.bottom, 80)
    }
}
