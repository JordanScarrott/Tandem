import SwiftUI

public struct DailyBudgetHeroView: View {
    @Bindable public var viewModel: DashboardViewModel
    @Binding public var focusedCategoryId: UInt64?
    public var onAddEnvelope: () -> Void
    public var onEditEnvelope: (CategoryItem) -> Void
    
    @State private var selectedDay: String? = nil
    
    public init(
        viewModel: DashboardViewModel,
        focusedCategoryId: Binding<UInt64?>,
        onAddEnvelope: @escaping () -> Void,
        onEditEnvelope: @escaping (CategoryItem) -> Void
    ) {
        self.viewModel = viewModel
        self._focusedCategoryId = focusedCategoryId
        self.onAddEnvelope = onAddEnvelope
        self.onEditEnvelope = onEditEnvelope
    }
    
    private var focusedEnvelopeStatus: CategoryEnvelopeStatus? {
        guard let catId = focusedCategoryId else { return nil }
        return viewModel.envelopeStatuses.first { $0.category.id == catId }
    }
    
    private var focusedCategory: CategoryItem? {
        guard let catId = focusedCategoryId else { return nil }
        return viewModel.categories.first { $0.id == catId }
    }
    
    // Dynamic health colors
    private func healthColor(for state: BudgetHealthState) -> Color {
        switch state {
        case .healthy: return Theme.accentGreen
        case .caution: return Theme.accentYellow
        case .overToday: return Theme.accentOrange
        case .overCycle: return Theme.accentRed
        }
    }
    
    private func healthBadgeText(for state: BudgetHealthState) -> String {
        switch state {
        case .healthy: return "Healthy"
        case .caution: return "Caution"
        case .overToday: return "Over Today's Allowance"
        case .overCycle: return "Over Cycle Budget"
        }
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            // Main Hero Card
            VStack(alignment: .leading, spacing: 14) {
                // Header Row (Context & Filter status)
                HStack(alignment: .center) {
                    if let focused = focusedEnvelopeStatus {
                        let catColor = Color.fromHex(focused.category.colorHex)
                        HStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(catColor.opacity(0.2))
                                    .frame(width: 32, height: 32)
                                
                                Image(systemName: focused.category.icon)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(catColor)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(focused.category.name)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(Theme.primaryDark)
                                
                                Text("Envelope Telemetry")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(Theme.mutedText)
                            }
                        }
                        
                        Spacer()
                        
                        Button {
                            Haptics.selection()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                focusedCategoryId = nil
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 14))
                                Text("All Categories")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundStyle(Theme.accentBlue)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Theme.accentBlue.opacity(0.1))
                            .clipShape(Capsule())
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("AVAILABLE TO SPEND TODAY")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Theme.mutedText)
                                .tracking(0.5)
                            
                            Text(viewModel.currentPaydayCycle.dateRangeFormatted)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Theme.mutedText)
                        }
                        
                        Spacer()
                        
                        // Health Badge Pill
                        let state = viewModel.todayHealthState
                        HStack(spacing: 5) {
                            Circle()
                                .fill(healthColor(for: state))
                                .frame(width: 7, height: 7)
                            
                            Text(healthBadgeText(for: state))
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(healthColor(for: state))
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(healthColor(for: state).opacity(0.12))
                        .clipShape(Capsule())
                    }
                }
                
                // Big Number Readout
                VStack(alignment: .leading, spacing: 4) {
                    if let focused = focusedEnvelopeStatus {
                        let catColor = Color.fromHex(focused.category.colorHex)
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(viewModel.currency.format(cents: focused.todayAvailableCents))
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundStyle(focused.todayAvailableCents < 0 ? Theme.accentOrange : Theme.primaryDark)
                                .contentTransition(.numericText())
                            
                            Text("available today")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Theme.mutedText)
                        }
                        
                        // Envelope Progress Sub-bar
                        if let budget = focused.budgetCents, budget > 0 {
                            VStack(alignment: .leading, spacing: 6) {
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(Theme.cardBorder)
                                            .frame(height: 6)
                                        
                                        Capsule()
                                            .fill(catColor)
                                            .frame(width: geo.size.width * CGFloat(focused.progressRatio), height: 6)
                                    }
                                }
                                .frame(height: 6)
                                
                                HStack {
                                    Text("\(viewModel.currency.format(cents: focused.spentCents)) spent")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(Theme.mutedText)
                                    
                                    Spacer()
                                    
                                    Text("\(viewModel.currency.format(cents: max(0, budget - focused.spentCents))) remaining of \(viewModel.currency.format(cents: budget))")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(Theme.mutedText)
                                }
                            }
                            .padding(.top, 4)
                        }
                    } else {
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(viewModel.currency.format(cents: viewModel.todayAvailableCents))
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundStyle(viewModel.todayAvailableCents < 0 ? Theme.accentOrange : Theme.primaryDark)
                                .contentTransition(.numericText())
                            
                            if viewModel.todayAvailableCents < 0 {
                                Text("(Deficit)")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Theme.accentOrange)
                            }
                        }
                        
                        HStack(spacing: 8) {
                            Text("Base allowance: **\(viewModel.currency.format(cents: viewModel.todayBaseAllowanceCents))/day**")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundStyle(Theme.mutedText)
                            
                            Text("•")
                                .foregroundStyle(Theme.mutedText.opacity(0.5))
                            
                            Text("**\(viewModel.daysRemainingInCycle)** days left")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundStyle(Theme.mutedText)
                        }
                    }
                }
                
                Divider()
                    .padding(.vertical, 2)
                
                // Simplified Daily Spend Bar Chart
                SingleSeriesDailyBarChart(
                    chartData: viewModel.telemetry.distribution.chartData,
                    dailyAllowanceCents: focusedEnvelopeStatus != nil
                        ? (focusedEnvelopeStatus?.todayBaseAllowanceCents ?? 0)
                        : viewModel.todayBaseAllowanceCents,
                    currency: viewModel.currency,
                    accentColor: focusedCategory != nil ? Color.fromHex(focusedCategory!.colorHex) : Theme.accentGreen,
                    selectedDay: $selectedDay
                )
                .frame(height: 140)
            }
            .padding(18)
            .background(Theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous)
                    .stroke(Theme.cardBorder, lineWidth: 1)
            )
            
            // Category Envelopes Section (Tap-to-Focus)
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("CATEGORY ENVELOPES")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Theme.mutedText)
                        .tracking(0.5)
                    
                    Spacer()
                    
                    Button {
                        Haptics.impact(.light)
                        onAddEnvelope()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 11, weight: .bold))
                            Text("Add Envelope")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(Theme.accentBlue)
                    }
                }
                
                // Category Envelope Chips Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(viewModel.envelopeStatuses) { env in
                        let isSelected = focusedCategoryId == env.category.id
                        let catColor = Color.fromHex(env.category.colorHex)
                        
                        Button {
                            Haptics.selection()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                if isSelected {
                                    focusedCategoryId = nil
                                } else {
                                    focusedCategoryId = env.category.id
                                }
                            }
                        } label: {
                            HStack(spacing: 10) {
                                ZStack {
                                    Circle()
                                        .fill(catColor.opacity(0.18))
                                        .frame(width: 32, height: 32)
                                    
                                    Image(systemName: env.category.icon)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(catColor)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(env.category.name)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(Theme.primaryDark)
                                        .lineLimit(1)
                                    
                                    if let rem = env.remainingCents {
                                        Text("\(viewModel.currency.format(cents: rem)) left")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundStyle(rem < 0 ? Theme.accentOrange : Theme.mutedText)
                                    } else {
                                        Text("\(viewModel.currency.format(cents: env.spentCents)) spent")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundStyle(Theme.mutedText)
                                    }
                                }
                                
                                Spacer()
                            }
                            .padding(10)
                            .background(isSelected ? catColor.opacity(0.12) : Theme.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(isSelected ? catColor : Theme.cardBorder, lineWidth: isSelected ? 1.5 : 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button {
                                onEditEnvelope(env.category)
                            } label: {
                                Label("Edit Envelope", systemImage: "pencil")
                            }
                        }
                    }
                }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: focusedCategoryId)
    }
}

// MARK: - Single Series Daily Bar Chart
public struct SingleSeriesDailyBarChart: View {
    public let chartData: [DaySpending]
    public let dailyAllowanceCents: Int64
    public let currency: CurrencyItem
    public let accentColor: Color
    @Binding public var selectedDay: String?
    
    public init(
        chartData: [DaySpending],
        dailyAllowanceCents: Int64,
        currency: CurrencyItem,
        accentColor: Color = Theme.accentGreen,
        selectedDay: Binding<String?>
    ) {
        self.chartData = chartData
        self.dailyAllowanceCents = dailyAllowanceCents
        self.currency = currency
        self.accentColor = accentColor
        self._selectedDay = selectedDay
    }
    
    private var maxAmountCents: Int64 {
        let maxSpend = chartData.map(\.amountCents).max() ?? 0
        let ceiling = max(maxSpend, dailyAllowanceCents, 5_000) // Minimum R50 ceiling
        let rands = Double(ceiling) / 100.0
        let step = rands > 5_000 ? 2_000.0 : (rands > 1_000 ? 500.0 : 100.0)
        let ceilingRands = ceil(rands / step) * step
        return max(5_000, Int64(ceilingRands * 100.0))
    }
    
    public var body: some View {
        GeometryReader { geo in
            let chartHeight = geo.size.height - 24
            let maxVal = CGFloat(maxAmountCents)
            
            VStack(spacing: 6) {
                // Tooltip Row if bar selected
                if let selected = selectedDay, let dayData = chartData.first(where: { $0.day == selected }) {
                    HStack {
                        Text("\(dayData.day): **\(currency.format(cents: dayData.amountCents))**")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Theme.primaryDark)
                        Spacer()
                    }
                    .transition(.opacity)
                }
                
                ZStack(alignment: .bottom) {
                    // Dotted Allowance Guideline
                    if dailyAllowanceCents > 0 {
                        let allowanceRatio = CGFloat(dailyAllowanceCents) / maxVal
                        let allowanceY = chartHeight * (1.0 - min(1.0, allowanceRatio))
                        
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: allowanceY))
                            path.addLine(to: CGPoint(x: geo.size.width, y: allowanceY))
                        }
                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .foregroundStyle(Theme.mutedText.opacity(0.4))
                    }
                    
                    // Bars Row
                    HStack(alignment: .bottom, spacing: 0) {
                        ForEach(chartData) { item in
                            let ratio = maxVal > 0 ? CGFloat(item.amountCents) / maxVal : 0
                            let barHeight = max(4, chartHeight * min(1.0, ratio))
                            let isSelected = selectedDay == item.day
                            let isOverDaily = item.amountCents > dailyAllowanceCents && dailyAllowanceCents > 0
                            let barFillColor: Color = isOverDaily ? Theme.accentOrange : accentColor
                            
                            VStack(spacing: 6) {
                                Spacer()
                                
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(barFillColor)
                                    .opacity(isSelected || selectedDay == nil ? 1.0 : 0.4)
                                    .frame(width: max(12, geo.size.width / CGFloat(max(1, chartData.count * 2))), height: barHeight)
                                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: item.amountCents)
                                
                                Text(item.day)
                                    .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                                    .foregroundStyle(isSelected ? Theme.primaryDark : Theme.mutedText)
                            }
                            .frame(maxWidth: .infinity)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                Haptics.selection()
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                    if selectedDay == item.day {
                                        selectedDay = nil
                                    } else {
                                        selectedDay = item.day
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
