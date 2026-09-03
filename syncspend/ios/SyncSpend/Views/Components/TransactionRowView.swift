import SwiftUI

public struct TransactionRowView: View {
    public let expense: ExpenseItem
    public let category: CategoryItem?
    public let currency: CurrencyItem
    public let onDelete: () -> Void
    public let onTap: (() -> Void)?
    
    @State private var dragOffset: CGFloat = 0
    @State private var isSwiped: Bool = false
    
    public init(
        expense: ExpenseItem,
        category: CategoryItem?,
        currency: CurrencyItem,
        onDelete: @escaping () -> Void,
        onTap: (() -> Void)? = nil
    ) {
        self.expense = expense
        self.category = category
        self.currency = currency
        self.onDelete = onDelete
        self.onTap = onTap
    }
    
    private var formattedDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: expense.spentDate)
    }
    
    public var body: some View {
        ZStack(alignment: .trailing) {
            // Trailing Delete Action Button (revealed on swipe)
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    dragOffset = 0
                    isSwiped = false
                }
                Haptics.notification(.warning)
                onDelete()
            } label: {
                ZStack {
                    Theme.accentRed
                    VStack(spacing: 4) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 18, weight: .bold))
                        Text("Delete")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(.white)
                }
                .frame(width: 80)
                .frame(maxHeight: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            // Main Foreground Row
            HStack(spacing: 14) {
                // Category Icon Badge (Squircle)
                ZStack {
                    RoundedRectangle(cornerRadius: Theme.squircleCornerRadius, style: .continuous)
                        .fill((category?.color ?? Theme.accentBlue).opacity(0.15))
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
            .contentShape(Rectangle())
            .offset(x: dragOffset)
            .gesture(
                DragGesture(minimumDistance: 15)
                    .onChanged { value in
                        let horizontal = value.translation.width
                        let vertical = value.translation.height
                        guard abs(horizontal) > abs(vertical) * 0.8 else { return }
                        
                        if isSwiped {
                            let newOffset = -80 + horizontal
                            dragOffset = min(0, max(-160, newOffset))
                        } else {
                            if horizontal < 0 {
                                dragOffset = max(-160, horizontal)
                            }
                        }
                    }
                    .onEnded { value in
                        let horizontal = value.translation.width
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            if isSwiped {
                                if horizontal > 30 {
                                    dragOffset = 0
                                    isSwiped = false
                                } else if horizontal < -60 || value.predictedEndTranslation.width < -100 {
                                    dragOffset = 0
                                    isSwiped = false
                                    Haptics.notification(.warning)
                                    onDelete()
                                } else {
                                    dragOffset = -80
                                    isSwiped = true
                                }
                            } else {
                                if horizontal < -120 || value.predictedEndTranslation.width < -140 {
                                    dragOffset = 0
                                    isSwiped = false
                                    Haptics.notification(.warning)
                                    onDelete()
                                } else if horizontal < -40 || value.predictedEndTranslation.width < -60 {
                                    dragOffset = -80
                                    isSwiped = true
                                    Haptics.impact(.medium)
                                } else {
                                    dragOffset = 0
                                    isSwiped = false
                                }
                            }
                        }
                    }
            )
            .onTapGesture {
                if isSwiped {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        dragOffset = 0
                        isSwiped = false
                    }
                } else if let onTap = onTap {
                    Haptics.impact(.light)
                    onTap()
                }
            }
            .contextMenu {
                if let onTap = onTap {
                    Button {
                        onTap()
                    } label: {
                        Label("Edit Expense", systemImage: "pencil")
                    }
                }
                Button(role: .destructive) {
                    Haptics.notification(.warning)
                    onDelete()
                } label: {
                    Label("Delete Expense", systemImage: "trash")
                }
            }
        }
    }
}
