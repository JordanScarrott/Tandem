import SwiftUI

public struct WeeklySpendingCard: View {
    public let totalCents: Int64
    public let currency: CurrencyItem
    public let chartData: [DaySpending]
    
    @State private var selectedDay: String?
    
    public init(totalCents: Int64, currency: CurrencyItem, chartData: [DaySpending]) {
        self.totalCents = totalCents
        self.currency = currency
        self.chartData = chartData
    }
    
    private var maxAmountCents: Int64 {
        let highest = chartData.map(\.amountCents).max() ?? 0
        if highest <= 0 { return 150_000 } // Default R1,500 ceiling
        let rands = Double(highest) / 100.0
        let ceilingRands = ceil(rands / 500.0) * 500.0
        return max(150_000, Int64(ceilingRands * 100.0))
    }
    
    private var stepLabels: [String] {
        let maxVal = Double(maxAmountCents) / 100.0
        let step = maxVal / 3.0
        return [
            String(format: "%.0f", maxVal),
            String(format: "%.0f", step * 2),
            String(format: "%.0f", step),
            "0"
        ]
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Spent this week")
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(Theme.mutedText)
            
            Text(currency.format(cents: totalCents))
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.primaryDark)
                .tracking(-0.5)
                .padding(.bottom, 16)
            
            // Custom Bar Chart with Horizontal Guidelines
            ZStack(alignment: .bottom) {
                // Horizontal Guidelines
                VStack(spacing: 0) {
                    ForEach(Array(stepLabels.enumerated()), id: \.offset) { index, label in
                        HStack(spacing: 8) {
                            Rectangle()
                                .fill(Color.black.opacity(0.06))
                                .frame(height: 1)
                            
                            Text(label)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Theme.mutedText)
                                .frame(width: 36, alignment: .trailing)
                        }
                        if index < stepLabels.count - 1 {
                            Spacer()
                        }
                    }
                }
                .frame(height: 170)
                .padding(.bottom, 24)
                
                // Bars Stack
                HStack(alignment: .bottom, spacing: 0) {
                    ForEach(chartData) { item in
                        let ratio = maxAmountCents > 0
                            ? min(1.0, max(0.0, Double(item.amountCents) / Double(maxAmountCents)))
                            : 0.0
                        let isSelected = selectedDay == item.day
                        let hasSpend = item.amountCents > 0
                        
                        VStack(spacing: 8) {
                            // Bar Container
                            ZStack(alignment: .bottom) {
                                // Tooltip popup
                                if isSelected && hasSpend {
                                    Text(currency.format(cents: item.amountCents))
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(Color.black)
                                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                                        .offset(y: -((140 * ratio) + 26))
                                        .transition(.opacity.combined(with: .scale))
                                        .zIndex(2)
                                }
                                
                                // Clickable Bar
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(hasSpend ? Theme.primaryDark : Color.clear)
                                    .frame(width: 26, height: max(4, 140 * ratio))
                                    .clipShape(
                                        UnevenRoundedRectangle(
                                            topLeadingRadius: 13,
                                            bottomLeadingRadius: 4,
                                            bottomTrailingRadius: 4,
                                            topTrailingRadius: 13
                                        )
                                    )
                            }
                            .frame(height: 140, alignment: .bottom)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    if selectedDay == item.day {
                                        selectedDay = nil
                                    } else {
                                        selectedDay = item.day
                                    }
                                }
                            }
                            
                            // Day Label
                            Text(item.day)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(isSelected ? Theme.primaryDark : Theme.mutedText)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.trailing, 44) // Offset for guideline labels
            }
        }
        .syncSpendCard(padding: 24, cornerRadius: Theme.largeCardCornerRadius)
    }
}
