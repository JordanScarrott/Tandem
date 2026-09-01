import SwiftUI

public struct WeeklySpendingCard: View {
    public let title: String
    public let totalCents: Int64
    public let currency: CurrencyItem
    public let chartData: [DaySpending]
    
    @State private var selectedDay: String?
    
    public init(
        title: String = "Spent this week",
        totalCents: Int64,
        currency: CurrencyItem,
        chartData: [DaySpending]
    ) {
        self.title = title
        self.totalCents = totalCents
        self.currency = currency
        self.chartData = chartData
    }
    
    private var isDenseChart: Bool {
        chartData.count > 7
    }
    
    private var barWidth: CGFloat {
        if chartData.count > 7 {
            return 15
        } else if chartData.count <= 4 {
            return 32
        } else {
            return 26
        }
    }
    
    private var barTopRadius: CGFloat {
        if chartData.count > 7 {
            return 7.5
        } else if chartData.count <= 4 {
            return 16
        } else {
            return 13
        }
    }
    
    private var maxAmountCents: Int64 {
        let highest = chartData.map(\.amountCents).max() ?? 0
        if highest <= 0 { return 150_000 } // Default R1,500 ceiling
        let rands = Double(highest) / 100.0
        let step = rands > 10_000 ? 5_000.0 : (rands > 2_000 ? 1_000.0 : 500.0)
        let ceilingRands = ceil(rands / step) * step
        return max(150_000, Int64(ceilingRands * 100.0))
    }
    
    private var stepLabels: [String] {
        let maxVal = Double(maxAmountCents) / 100.0
        let step = maxVal / 3.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.groupingSeparator = " "
        
        let v3 = formatter.string(from: NSNumber(value: maxVal)) ?? String(format: "%.0f", maxVal)
        let v2 = formatter.string(from: NSNumber(value: step * 2)) ?? String(format: "%.0f", step * 2)
        let v1 = formatter.string(from: NSNumber(value: step)) ?? String(format: "%.0f", step)
        return [v3, v2, v1, "0"]
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(Theme.mutedText)
            
            Text(currency.format(cents: totalCents))
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.primaryDark)
                .tracking(-0.5)
                .padding(.bottom, 16)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: totalCents)
            
            // Custom Bar Chart with Horizontal Guidelines
            ZStack(alignment: .bottom) {
                // Horizontal Guidelines
                VStack(spacing: 0) {
                    ForEach(Array(stepLabels.enumerated()), id: \.offset) { index, label in
                        HStack(spacing: 8) {
                            Rectangle()
                                .fill(Theme.cardBorder)
                                .frame(height: 1)
                            
                            Text(label)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Theme.mutedText)
                                .frame(width: 40, alignment: .trailing)
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
                        let isAnySelected = selectedDay != nil
                        
                        VStack(spacing: 8) {
                            // Bar Container
                            ZStack(alignment: .bottom) {
                                // Tooltip popup
                                if isSelected && hasSpend {
                                    VStack(spacing: 2) {
                                        Text(currency.format(cents: item.amountCents))
                                            .font(.system(size: 11, weight: .bold, design: .rounded))
                                            .foregroundStyle(Theme.buttonForeground)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Theme.buttonDark)
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                    .shadow(color: Color.black.opacity(0.18), radius: 6, x: 0, y: 3)
                                    .offset(y: -((140 * ratio) + 30))
                                    .transition(.scale(scale: 0.85).combined(with: .opacity))
                                    .zIndex(2)
                                }
                                
                                // Clickable Bar
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(
                                        hasSpend
                                            ? (isSelected
                                                ? Theme.accentBlue
                                                : (isAnySelected ? Theme.primaryDark.opacity(0.4) : Theme.primaryDark))
                                            : Color.clear
                                    )
                                    .frame(width: barWidth, height: max(4, 140 * ratio))
                                    .clipShape(
                                        UnevenRoundedRectangle(
                                            topLeadingRadius: barTopRadius,
                                            bottomLeadingRadius: 3,
                                            bottomTrailingRadius: 3,
                                            topTrailingRadius: barTopRadius
                                        )
                                    )
                                    .animation(.spring(response: 0.45, dampingFraction: 0.75), value: item.amountCents)
                                    .overlay(
                                        isSelected && hasSpend
                                            ? UnevenRoundedRectangle(
                                                topLeadingRadius: barTopRadius,
                                                bottomLeadingRadius: 3,
                                                bottomTrailingRadius: 3,
                                                topTrailingRadius: barTopRadius
                                            ).strokeBorder(Theme.accentBlue.opacity(0.8), lineWidth: 1.5)
                                            : nil
                                    )
                            }
                            .frame(height: 140, alignment: .bottom)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                Haptics.selection()
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    if selectedDay == item.day {
                                        selectedDay = nil
                                    } else {
                                        selectedDay = item.day
                                    }
                                }
                            }
                            
                            // Day Label
                            Text(item.day)
                                .font(.system(size: isDenseChart ? 10 : 11, weight: isSelected ? .bold : .medium))
                                .foregroundStyle(isSelected ? Theme.accentBlue : (isAnySelected ? Theme.mutedText.opacity(0.7) : Theme.mutedText))
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.trailing, 48) // Offset for guideline labels
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if selectedDay != nil {
                    Haptics.selection()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        selectedDay = nil
                    }
                }
            }
        }
        .syncSpendCard(padding: 24, cornerRadius: Theme.largeCardCornerRadius)
        .onTapGesture {
            if selectedDay != nil {
                Haptics.selection()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    selectedDay = nil
                }
            }
        }
    }
}

