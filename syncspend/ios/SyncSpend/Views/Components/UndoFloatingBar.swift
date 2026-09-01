import SwiftUI

public struct UndoFloatingBar: View {
    public let expense: ExpenseItem
    public let currency: CurrencyItem
    public let onUndo: () -> Void
    
    private let totalDuration: Double = 5.0
    @State private var progress: CGFloat = 1.0
    
    public init(expense: ExpenseItem, currency: CurrencyItem, onUndo: @escaping () -> Void) {
        self.expense = expense
        self.currency = currency
        self.onUndo = onUndo
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Theme.accentRed.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: "trash.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Theme.accentRed)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Deleted \(currency.format(cents: expense.amountCents))")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.primaryDark)
                    
                    Text(expense.note.isEmpty ? "Expense" : expense.note)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(Theme.mutedText)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Button {
                    Haptics.notification(.success)
                    onUndo()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.uturn.backward.circle.fill")
                            .font(.system(size: 14, weight: .bold))
                        Text("Undo")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundStyle(Theme.buttonForeground)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Theme.buttonDark)
                    .clipShape(Capsule())
                    .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 2)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 10)
            
            // 5-second Linear Countdown Progress Line
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Theme.subtleGray.opacity(0.5))
                        .frame(height: 3)
                    
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Theme.accentRed, Theme.accentBlue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * progress, height: 3)
                }
            }
            .frame(height: 3)
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Theme.cardBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.18), radius: 20, x: 0, y: 8)
        .padding(.horizontal, 16)
        .padding(.bottom, 84)
        .onAppear {
            progress = 1.0
            withAnimation(.linear(duration: totalDuration)) {
                progress = 0.0
            }
        }
    }
}
