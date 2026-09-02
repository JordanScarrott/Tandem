import SwiftUI

public enum BudgetPrototypeVariant: String, CaseIterable, Identifiable {
    case variantA = "Variant A: Stacked Bars"
    case variantB = "Variant B: Cumulative Pace"
    case variantC = "Variant C: Integrated Hero"
    
    public var id: String { rawValue }
    
    public var shortTitle: String {
        switch self {
        case .variantA: return "A: Stacked Bars"
        case .variantB: return "B: Cumulative Pace"
        case .variantC: return "C: Integrated Hero"
        }
    }
    
    public var subtitle: String {
        switch self {
        case .variantA: return "Category color segments & daily allowance rule"
        case .variantB: return "Continuous pace curve vs ideal trajectory"
        case .variantC: return "All-in-one command center with embedded envelopes"
        }
    }
}

// MARK: - Main Prototype Container
public struct BudgetTelemetryPrototypeView: View {
    @Bindable public var viewModel: DashboardViewModel
    @Binding public var currentVariant: BudgetPrototypeVariant
    public var onAddEnvelope: () -> Void
    public var onEditEnvelope: (CategoryItem) -> Void
    
    @State private var spotlightCategoryId: UInt64? = nil
    @State private var heroTelemetryMode: HeroChartMode = .stackedBars
    
    public enum HeroChartMode: String, CaseIterable {
        case stackedBars = "Daily Bars"
        case paceCurve = "Cycle Pace"
    }
    
    public init(
        viewModel: DashboardViewModel,
        currentVariant: Binding<BudgetPrototypeVariant>,
        onAddEnvelope: @escaping () -> Void,
        onEditEnvelope: @escaping (CategoryItem) -> Void
    ) {
        self.viewModel = viewModel
        self._currentVariant = currentVariant
        self.onAddEnvelope = onAddEnvelope
        self.onEditEnvelope = onEditEnvelope
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            switch currentVariant {
            case .variantA:
                VariantA_StackedBarsView(
                    viewModel: viewModel,
                    spotlightCategoryId: $spotlightCategoryId,
                    onAddEnvelope: onAddEnvelope,
                    onEditEnvelope: onEditEnvelope
                )
            case .variantB:
                VariantB_CumulativePaceView(
                    viewModel: viewModel,
                    onAddEnvelope: onAddEnvelope,
                    onEditEnvelope: onEditEnvelope
                )
            case .variantC:
                VariantC_IntegratedHeroView(
                    viewModel: viewModel,
                    heroTelemetryMode: $heroTelemetryMode,
                    spotlightCategoryId: $spotlightCategoryId,
                    onAddEnvelope: onAddEnvelope,
                    onEditEnvelope: onEditEnvelope
                )
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: currentVariant)
    }
}

// MARK: - Floating Prototype Switcher Pill
public struct PrototypeFloatingSwitcher: View {
    @Binding public var currentVariant: BudgetPrototypeVariant
    
    public init(currentVariant: Binding<BudgetPrototypeVariant>) {
        self._currentVariant = currentVariant
    }
    
    private func cyclePrevious() {
        Haptics.selection()
        let all = BudgetPrototypeVariant.allCases
        guard let index = all.firstIndex(of: currentVariant) else { return }
        let prevIndex = (index - 1 + all.count) % all.count
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            currentVariant = all[prevIndex]
        }
    }
    
    private func cycleNext() {
        Haptics.selection()
        let all = BudgetPrototypeVariant.allCases
        guard let index = all.firstIndex(of: currentVariant) else { return }
        let nextIndex = (index + 1) % all.count
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            currentVariant = all[nextIndex]
        }
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            // Left Chevron
            Button(action: cyclePrevious) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.buttonForeground)
                    .frame(width: 28, height: 28)
                    .background(Color.white.opacity(0.18))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            
            // Middle Label
            VStack(spacing: 2) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 6, height: 6)
                    Text("PROTOTYPE: \(currentVariant.shortTitle)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.buttonForeground)
                }
                
                Text(currentVariant.subtitle)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Theme.buttonForeground.opacity(0.75))
                    .lineLimit(1)
            }
            .frame(maxWidth: 220)
            
            // Right Chevron
            Button(action: cycleNext) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.buttonForeground)
                    .frame(width: 28, height: 28)
                    .background(Color.white.opacity(0.18))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Theme.buttonDark.opacity(0.95))
                .shadow(color: Color.black.opacity(0.35), radius: 14, x: 0, y: 6)
        )
        .overlay(
            Capsule()
                .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
        )
    }
}

// MARK: - Variant A: Stacked Category Bar Telemetry
public struct VariantA_StackedBarsView: View {
    @Bindable public var viewModel: DashboardViewModel
    @Binding public var spotlightCategoryId: UInt64?
    public var onAddEnvelope: () -> Void
    public var onEditEnvelope: (CategoryItem) -> Void
    
    @State private var selectedDay: String? = nil
    
    private var chartData: [DaySpendingWithCategories] {
        viewModel.chartDataWithCategories
    }
    
    private var maxAmountCents: Int64 {
        let highest = chartData.map(\.totalAmountCents).max() ?? 0
        let allowance = viewModel.dailyBudgetAllowanceCents
        let peak = max(highest, allowance)
        if peak <= 0 { return 150_000 }
        let rands = Double(peak) / 100.0
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
        VStack(spacing: 16) {
            // Main Telemetry Card
            VStack(alignment: .leading, spacing: 12) {
                // Header Row: Payday Cycle Pill + Days Left
                HStack(alignment: .center) {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.accentBlue)
                        Text("Cycle • \(viewModel.currentPaydayCycle.dateRangeFormatted)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.primaryDark)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 10))
                        Text("\(viewModel.currentPaydayCycle.daysRemaining)d left")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Theme.chipBackground)
                    .foregroundStyle(Theme.primaryDark)
                    .clipShape(Capsule())
                }
                
                // Big Metric Row
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.periodTitle)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(Theme.mutedText)
                        
                        Text(viewModel.currency.format(cents: viewModel.periodTotalCents))
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.primaryDark)
                            .contentTransition(.numericText())
                    }
                    
                    Spacer()
                    
                    if viewModel.dailyBudgetAllowanceCents > 0 {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Daily Allowance")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Theme.mutedText)
                            
                            HStack(spacing: 4) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 11))
                                Text(viewModel.currency.format(cents: viewModel.dailyBudgetAllowanceCents))
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                            }
                            .foregroundStyle(Theme.accentBlue)
                        }
                    }
                }
                
                // Stacked Bar Chart
                ZStack(alignment: .bottom) {
                    // Guidelines
                    VStack(spacing: 0) {
                        ForEach(Array(stepLabels.enumerated()), id: \.offset) { index, label in
                            HStack(spacing: 8) {
                                Rectangle()
                                    .fill(Theme.cardBorder)
                                    .frame(height: 1)
                                
                                Text(label)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(Theme.mutedText)
                                    .frame(width: 36, alignment: .trailing)
                            }
                            if index < stepLabels.count - 1 {
                                Spacer()
                            }
                        }
                    }
                    .frame(height: 160)
                    .padding(.bottom, 22)
                    
                    // Daily Allowance Reference Line
                    if viewModel.dailyBudgetAllowanceCents > 0 && maxAmountCents > 0 {
                        let allowanceRatio = min(1.0, Double(viewModel.dailyBudgetAllowanceCents) / Double(maxAmountCents))
                        HStack(spacing: 4) {
                            Rectangle()
                                .stroke(Theme.accentBlue.opacity(0.8), style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                                .frame(height: 1)
                            
                            Text("CAP")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(Theme.accentBlue)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Theme.accentBlue.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 3))
                        }
                        .padding(.trailing, 42)
                        .offset(y: -((130 * allowanceRatio) + 22))
                    }
                    
                    // Stacked Bars
                    HStack(alignment: .bottom, spacing: 0) {
                        ForEach(chartData) { item in
                            let totalRatio = maxAmountCents > 0
                                ? min(1.0, max(0.0, Double(item.totalAmountCents) / Double(maxAmountCents)))
                                : 0.0
                            let isSelected = selectedDay == item.day
                            let hasSpend = item.totalAmountCents > 0
                            
                            VStack(spacing: 6) {
                                // Bar with segments
                                ZStack(alignment: .bottom) {
                                    // Tooltip Popup
                                    if isSelected && hasSpend {
                                        VStack(alignment: .center, spacing: 2) {
                                            Text(viewModel.currency.format(cents: item.totalAmountCents))
                                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                                .foregroundStyle(Theme.buttonForeground)
                                            
                                            if !item.segments.isEmpty {
                                                ForEach(item.segments.prefix(3)) { seg in
                                                    HStack(spacing: 4) {
                                                        Circle()
                                                            .fill(seg.color)
                                                            .frame(width: 5, height: 5)
                                                        Text("\(seg.categoryName): \(viewModel.currency.format(cents: seg.amountCents))")
                                                            .font(.system(size: 9, weight: .medium))
                                                            .foregroundStyle(Theme.buttonForeground.opacity(0.85))
                                                    }
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 6)
                                        .background(Theme.buttonDark)
                                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                        .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 3)
                                        .offset(y: -((130 * totalRatio) + 36))
                                        .transition(.scale(scale: 0.85).combined(with: .opacity))
                                        .zIndex(5)
                                    }
                                    
                                    // Stacked Bar Segments
                                    if hasSpend {
                                        VStack(spacing: 1) {
                                            ForEach(item.segments) { seg in
                                                let segHeight = item.totalAmountCents > 0
                                                    ? max(3, (130 * totalRatio) * CGFloat(Double(seg.amountCents) / Double(item.totalAmountCents)))
                                                    : 0
                                                let isSpotlighted = spotlightCategoryId == nil || spotlightCategoryId == seg.categoryId
                                                
                                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                                    .fill(seg.color.opacity(isSpotlighted ? 1.0 : 0.18))
                                                    .frame(width: 22, height: segHeight)
                                                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: spotlightCategoryId)
                                            }
                                        }
                                        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 10, bottomLeadingRadius: 3, bottomTrailingRadius: 3, topTrailingRadius: 10))
                                    } else {
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(Color.clear)
                                            .frame(width: 22, height: 4)
                                    }
                                }
                                .frame(height: 130, alignment: .bottom)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    Haptics.selection()
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        selectedDay = (selectedDay == item.day) ? nil : item.day
                                    }
                                }
                                
                                // Day Label
                                Text(item.day)
                                    .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                                    .foregroundStyle(isSelected ? Theme.accentBlue : Theme.mutedText)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.trailing, 42)
                }
            }
            .syncSpendCard(padding: 20, cornerRadius: Theme.largeCardCornerRadius)
            
            // Spotlight Category Envelope Strip
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("CATEGORY SPOTLIGHT")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Theme.mutedText)
                        .tracking(0.5)
                    
                    Spacer()
                    
                    if spotlightCategoryId != nil {
                        Button("Reset Spotlight") {
                            Haptics.selection()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                spotlightCategoryId = nil
                                viewModel.selectedFilterCategoryId = nil
                            }
                        }
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.accentBlue)
                    }
                }
                .padding(.horizontal, 4)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(viewModel.envelopeStatuses) { envelope in
                            let isSpotlight = spotlightCategoryId == envelope.category.id
                            
                            Button {
                                Haptics.selection()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    if isSpotlight {
                                        spotlightCategoryId = nil
                                        viewModel.selectedFilterCategoryId = nil
                                    } else {
                                        spotlightCategoryId = envelope.category.id
                                        viewModel.selectedFilterCategoryId = envelope.category.id
                                    }
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    ZStack {
                                        Circle()
                                            .fill(envelope.category.color.opacity(0.2))
                                            .frame(width: 28, height: 28)
                                        Image(systemName: envelope.category.icon)
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundStyle(envelope.category.color)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(envelope.category.name)
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundStyle(Theme.primaryDark)
                                        
                                        HStack(spacing: 2) {
                                            Text(viewModel.currency.format(cents: envelope.spentCents))
                                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                                .foregroundStyle(envelope.isOverspent ? Theme.accentRed : Theme.mutedText)
                                            
                                            if let cap = envelope.budgetCents {
                                                Text("/ \(viewModel.currency.format(cents: cap))")
                                                    .font(.system(size: 10, weight: .regular))
                                                    .foregroundStyle(Theme.mutedText.opacity(0.7))
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(Theme.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .strokeBorder(isSpotlight ? envelope.category.color : Theme.cardBorder, lineWidth: isSpotlight ? 2 : 1)
                                )
                                .shadow(color: isSpotlight ? envelope.category.color.opacity(0.2) : Color.black.opacity(0.02), radius: 6, x: 0, y: 2)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button {
                                    onEditEnvelope(envelope.category)
                                } label: {
                                    Label("Edit Envelope", systemImage: "pencil")
                                }
                            }
                        }
                    }
                    .padding(.vertical, 2)
                    .padding(.horizontal, 2)
                }
            }
        }
    }
}

// MARK: - Variant B: Cumulative Cycle Burn-Down & Pace Trajectory
public struct VariantB_CumulativePaceView: View {
    @Bindable public var viewModel: DashboardViewModel
    public var onAddEnvelope: () -> Void
    public var onEditEnvelope: (CategoryItem) -> Void
    
    @State private var selectedPacePoint: CyclePacePoint? = nil
    
    private var pacePoints: [CyclePacePoint] {
        viewModel.cyclePacePoints
    }
    
    private var totalBudgetCents: Int64 {
        viewModel.cycleTotalBudgetCents
    }
    
    private var maxScaleCents: Int64 {
        let maxSpent = pacePoints.compactMap(\.actualCumulativeCents).max() ?? 0
        let target = max(totalBudgetCents, maxSpent)
        return max(150_000, Int64(Double(target) * 1.15))
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            // Main Cumulative Pace Card
            VStack(alignment: .leading, spacing: 14) {
                // Header Row: Payday Cycle Range & Days Left
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.accentBlue)
                        Text(viewModel.currentPaydayCycle.dateRangeFormatted)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.primaryDark)
                    }
                    
                    Spacer()
                    
                    // Pace Status Pill
                    HStack(spacing: 4) {
                        Circle()
                            .fill(viewModel.isCyclePacingAhead ? Theme.accentRed : Theme.accentGreen)
                            .frame(width: 6, height: 6)
                        Text(viewModel.cyclePaceStatusText)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(viewModel.isCyclePacingAhead ? Theme.accentRed : Theme.accentGreen)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background((viewModel.isCyclePacingAhead ? Theme.accentRed : Theme.accentGreen).opacity(0.12))
                    .clipShape(Capsule())
                }
                
                // Hero "Free to Spend" Metric
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("FREE TO SPEND")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Theme.mutedText)
                            .tracking(0.5)
                        
                        Text(viewModel.currency.format(cents: viewModel.freeToSpendCents))
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(viewModel.freeToSpendCents > 0 ? Theme.accentGreen : Theme.accentRed)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Spent So Far")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Theme.mutedText)
                        
                        Text(viewModel.currency.format(cents: viewModel.cycleTotalSpentCents))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.primaryDark)
                    }
                }
                
                // Interactive Trajectory Curve
                ZStack(alignment: .bottom) {
                    // Dotted Reference Lines (0, 50%, 100% of budget)
                    VStack(spacing: 0) {
                        HStack {
                            Text("Budget Cap: \(viewModel.currency.format(cents: totalBudgetCents))")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(Theme.mutedText)
                            Spacer()
                        }
                        Rectangle()
                            .stroke(Theme.cardBorder, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                            .frame(height: 1)
                        
                        Spacer()
                        
                        Rectangle()
                            .fill(Theme.cardBorder.opacity(0.5))
                            .frame(height: 1)
                    }
                    .frame(height: 140)
                    .padding(.bottom, 20)
                    
                    // Curve Canvas
                    GeometryReader { geo in
                        let w = geo.size.width
                        let h = geo.size.height - 20
                        let totalDays = max(1, pacePoints.count - 1)
                        
                        // Ideal Pace Line Path
                        Path { path in
                            for (idx, pt) in pacePoints.enumerated() {
                                let x = (CGFloat(idx) / CGFloat(totalDays)) * w
                                let y = h - (h * CGFloat(Double(pt.idealCumulativeCents) / Double(maxScaleCents)))
                                if idx == 0 {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                        }
                        .stroke(Theme.mutedText.opacity(0.5), style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                        
                        // Actual Cumulative Area Path
                        let pastPoints = pacePoints.filter { $0.actualCumulativeCents != nil }
                        if !pastPoints.isEmpty {
                            Path { path in
                                for (idx, pt) in pastPoints.enumerated() {
                                    let spend = pt.actualCumulativeCents ?? 0
                                    let x = (CGFloat(idx) / CGFloat(totalDays)) * w
                                    let y = h - (h * CGFloat(Double(spend) / Double(maxScaleCents)))
                                    if idx == 0 {
                                        path.move(to: CGPoint(x: x, y: y))
                                    } else {
                                        path.addLine(to: CGPoint(x: x, y: y))
                                    }
                                }
                                // Close area to bottom
                                if let lastIdx = pastPoints.indices.last {
                                    let lastX = (CGFloat(lastIdx) / CGFloat(totalDays)) * w
                                    path.addLine(to: CGPoint(x: lastX, y: h))
                                    path.addLine(to: CGPoint(x: 0, y: h))
                                    path.closeSubpath()
                                }
                            }
                            .fill(
                                LinearGradient(
                                    colors: [
                                        (viewModel.isCyclePacingAhead ? Theme.accentRed : Theme.accentBlue).opacity(0.28),
                                        (viewModel.isCyclePacingAhead ? Theme.accentRed : Theme.accentBlue).opacity(0.02)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            
                            // Actual Cumulative Stroke Line
                            Path { path in
                                for (idx, pt) in pastPoints.enumerated() {
                                    let spend = pt.actualCumulativeCents ?? 0
                                    let x = (CGFloat(idx) / CGFloat(totalDays)) * w
                                    let y = h - (h * CGFloat(Double(spend) / Double(maxScaleCents)))
                                    if idx == 0 {
                                        path.move(to: CGPoint(x: x, y: y))
                                    } else {
                                        path.addLine(to: CGPoint(x: x, y: y))
                                    }
                                }
                            }
                            .stroke(
                                viewModel.isCyclePacingAhead ? Theme.accentRed : Theme.accentBlue,
                                style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                            )
                            
                            // Current Day Marker Dot
                            if let last = pastPoints.last, let lastIdx = pastPoints.indices.last {
                                let spend = last.actualCumulativeCents ?? 0
                                let x = (CGFloat(lastIdx) / CGFloat(totalDays)) * w
                                let y = h - (h * CGFloat(Double(spend) / Double(maxScaleCents)))
                                
                                Circle()
                                    .fill(viewModel.isCyclePacingAhead ? Theme.accentRed : Theme.accentBlue)
                                    .frame(width: 8, height: 8)
                                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                    .shadow(color: Color.black.opacity(0.2), radius: 3)
                                    .position(x: x, y: y)
                            }
                        }
                    }
                    .frame(height: 140)
                    
                    // Bottom Axis Date Labels
                    HStack {
                        if let first = pacePoints.first {
                            Text("Day 1 (\(first.dateLabel))")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(Theme.mutedText)
                        }
                        Spacer()
                        Text("Today (\(viewModel.currentPaydayCycle.currentDayIndex)d)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Theme.accentBlue)
                        Spacer()
                        if let last = pacePoints.last {
                            Text("Payday (\(last.dateLabel))")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(Theme.mutedText)
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .syncSpendCard(padding: 20, cornerRadius: Theme.largeCardCornerRadius)
            
            // Envelope List with Monarch-Style Pace Notches
            VStack(alignment: .leading, spacing: 10) {
                Text("ENVELOPE BURN PACING")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Theme.mutedText)
                    .tracking(0.5)
                    .padding(.horizontal, 4)
                
                VStack(spacing: 8) {
                    ForEach(viewModel.envelopeStatuses) { envelope in
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(envelope.category.color.opacity(0.18))
                                    .frame(width: 32, height: 32)
                                Image(systemName: envelope.category.icon)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(envelope.category.color)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(envelope.category.name)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(Theme.primaryDark)
                                    Spacer()
                                    Text("\(viewModel.currency.format(cents: envelope.spentCents)) / \(envelope.budgetCents != nil ? viewModel.currency.format(cents: envelope.budgetCents!) : "Flex")")
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        .foregroundStyle(envelope.isOverspent ? Theme.accentRed : Theme.mutedText)
                                }
                                
                                // Progress Bar with Cycle Pace Notch
                                GeometryReader { geo in
                                    let barWidth = geo.size.width
                                    let cycleProgress = CGFloat(viewModel.currentPaydayCycle.cycleProgressPercentage)
                                    let spendProgress = CGFloat(envelope.progressRatio)
                                    
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(Theme.subtleGray)
                                            .frame(height: 6)
                                        
                                        // Filled Spend
                                        Capsule()
                                            .fill(envelope.isOverspent ? Theme.accentRed : envelope.category.color)
                                            .frame(width: max(4, barWidth * spendProgress), height: 6)
                                        
                                        // Calendar Pace Notch Indicator (Monarch style)
                                        Rectangle()
                                            .fill(Theme.primaryDark)
                                            .frame(width: 2, height: 10)
                                            .offset(x: barWidth * cycleProgress)
                                    }
                                }
                                .frame(height: 10)
                            }
                        }
                        .padding(12)
                        .background(Theme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(Theme.cardBorder, lineWidth: 1)
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Variant C: Integrated Hybrid Hero (All-in-One Command Center)
public struct VariantC_IntegratedHeroView: View {
    @Bindable public var viewModel: DashboardViewModel
    @Binding public var heroTelemetryMode: BudgetTelemetryPrototypeView.HeroChartMode
    @Binding public var spotlightCategoryId: UInt64?
    public var onAddEnvelope: () -> Void
    public var onEditEnvelope: (CategoryItem) -> Void
    
    public var body: some View {
        VStack(spacing: 12) {
            // Unified Single Hero Card
            VStack(spacing: 16) {
                // Top Header: Cycle Progress Ring & Remaining Budget & Segmented Mode Switcher
                HStack(alignment: .center) {
                    // Small Cycle Ring
                    ZStack {
                        Circle()
                            .stroke(Theme.subtleGray, lineWidth: 4)
                            .frame(width: 38, height: 38)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(viewModel.currentPaydayCycle.cycleProgressPercentage))
                            .stroke(Theme.accentBlue, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .frame(width: 38, height: 38)
                        
                        Text("\(viewModel.currentPaydayCycle.daysRemaining)d")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Theme.primaryDark)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Payday in \(viewModel.currentPaydayCycle.daysRemaining) days")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Theme.mutedText)
                        
                        HStack(spacing: 4) {
                            Text(viewModel.currency.format(cents: viewModel.freeToSpendCents))
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(viewModel.freeToSpendCents > 0 ? Theme.primaryDark : Theme.accentRed)
                            Text("left to spend")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Theme.mutedText)
                        }
                    }
                    
                    Spacer()
                    
                    // Chart Mode Segmented Picker
                    Picker("Mode", selection: $heroTelemetryMode) {
                        Text("Bars").tag(BudgetTelemetryPrototypeView.HeroChartMode.stackedBars)
                        Text("Pace").tag(BudgetTelemetryPrototypeView.HeroChartMode.paceCurve)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 120)
                }
                
                // Center Chart: Switchable between Stacked Bars and Continuous Pace
                if heroTelemetryMode == .stackedBars {
                    StackedBarsSubchart(viewModel: viewModel, spotlightCategoryId: $spotlightCategoryId)
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                } else {
                    CumulativePaceSubchart(viewModel: viewModel)
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                }
                
                Divider()
                    .background(Theme.cardBorder)
                
                // Embedded Category Envelopes Grid in Card Footer
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("ENVELOPES ALLOCATION")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Theme.mutedText)
                            .tracking(0.5)
                        
                        Spacer()
                        
                        Button {
                            Haptics.impact(.light)
                            onAddEnvelope()
                        } label: {
                            HStack(spacing: 3) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 11))
                                Text("New")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundStyle(Theme.accentBlue)
                        }
                    }
                    
                    // Horizontal Scrollable Envelope Capsules
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(viewModel.envelopeStatuses) { envelope in
                                let isSelected = viewModel.selectedFilterCategoryId == envelope.category.id
                                
                                Button {
                                    Haptics.selection()
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        if isSelected {
                                            viewModel.selectedFilterCategoryId = nil
                                            spotlightCategoryId = nil
                                        } else {
                                            viewModel.selectedFilterCategoryId = envelope.category.id
                                            spotlightCategoryId = envelope.category.id
                                        }
                                    }
                                } label: {
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack(spacing: 6) {
                                            Circle()
                                                .fill(envelope.category.color)
                                                .frame(width: 8, height: 8)
                                            
                                            Text(envelope.category.name)
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundStyle(Theme.primaryDark)
                                                .lineLimit(1)
                                            
                                            Spacer(minLength: 4)
                                            
                                            if envelope.isOverspent {
                                                Image(systemName: "exclamationmark.triangle.fill")
                                                    .font(.system(size: 9))
                                                    .foregroundStyle(Theme.accentRed)
                                            }
                                        }
                                        
                                        Text(viewModel.currency.format(cents: envelope.spentCents))
                                            .font(.system(size: 13, weight: .bold, design: .rounded))
                                            .foregroundStyle(envelope.isOverspent ? Theme.accentRed : Theme.primaryDark)
                                        
                                        // Mini Progress Capsule
                                        GeometryReader { geo in
                                            ZStack(alignment: .leading) {
                                                Capsule()
                                                    .fill(Theme.subtleGray)
                                                    .frame(height: 3)
                                                
                                                Capsule()
                                                    .fill(envelope.isOverspent ? Theme.accentRed : envelope.category.color)
                                                    .frame(width: max(3, geo.size.width * CGFloat(envelope.progressRatio)), height: 3)
                                            }
                                        }
                                        .frame(height: 3)
                                    }
                                    .padding(10)
                                    .frame(width: 118)
                                    .background(Theme.cardBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .strokeBorder(isSelected ? envelope.category.color : Theme.cardBorder, lineWidth: isSelected ? 1.5 : 1)
                                    )
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button {
                                        onEditEnvelope(envelope.category)
                                    } label: {
                                        Label("Edit Envelope", systemImage: "pencil")
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            .syncSpendCard(padding: 18, cornerRadius: Theme.largeCardCornerRadius)
        }
    }
}

// MARK: - Subchart Helpers
private struct StackedBarsSubchart: View {
    let viewModel: DashboardViewModel
    @Binding var spotlightCategoryId: UInt64?
    
    var body: some View {
        let chartData = viewModel.chartDataWithCategories
        let allowance = viewModel.dailyBudgetAllowanceCents
        let highest = chartData.map(\.totalAmountCents).max() ?? 0
        let ceiling = max(150_000, max(highest, allowance))
        
        HStack(alignment: .bottom, spacing: 0) {
            ForEach(chartData) { item in
                let totalRatio = ceiling > 0
                    ? min(1.0, max(0.0, Double(item.totalAmountCents) / Double(ceiling)))
                    : 0.0
                let hasSpend = item.totalAmountCents > 0
                
                VStack(spacing: 4) {
                    ZStack(alignment: .bottom) {
                        if hasSpend {
                            VStack(spacing: 1) {
                                ForEach(item.segments) { seg in
                                    let segHeight = item.totalAmountCents > 0
                                        ? max(2, (90 * totalRatio) * CGFloat(Double(seg.amountCents) / Double(item.totalAmountCents)))
                                        : 0
                                    let isSpotlighted = spotlightCategoryId == nil || spotlightCategoryId == seg.categoryId
                                    
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(seg.color.opacity(isSpotlighted ? 1.0 : 0.15))
                                        .frame(width: 18, height: segHeight)
                                }
                            }
                            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 6, bottomLeadingRadius: 2, bottomTrailingRadius: 2, topTrailingRadius: 6))
                        } else {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Theme.subtleGray.opacity(0.4))
                                .frame(width: 18, height: 2)
                        }
                    }
                    .frame(height: 90, alignment: .bottom)
                    
                    Text(item.day)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Theme.mutedText)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 110)
    }
}

private struct CumulativePaceSubchart: View {
    let viewModel: DashboardViewModel
    
    var body: some View {
        let pacePoints = viewModel.cyclePacePoints
        let totalBudget = viewModel.cycleTotalBudgetCents
        let maxSpend = pacePoints.compactMap(\.actualCumulativeCents).max() ?? 0
        let maxScale = max(150_000, Int64(Double(max(totalBudget, maxSpend)) * 1.1))
        
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height - 18
            let totalDays = max(1, pacePoints.count - 1)
            
            // Dotted Ideal Pace Line
            Path { path in
                for (idx, pt) in pacePoints.enumerated() {
                    let x = (CGFloat(idx) / CGFloat(totalDays)) * w
                    let y = h - (h * CGFloat(Double(pt.idealCumulativeCents) / Double(maxScale)))
                    if idx == 0 { path.move(to: CGPoint(x: x, y: y)) }
                    else { path.addLine(to: CGPoint(x: x, y: y)) }
                }
            }
            .stroke(Theme.mutedText.opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
            
            // Actual Area & Line
            let past = pacePoints.filter { $0.actualCumulativeCents != nil }
            if !past.isEmpty {
                Path { path in
                    for (idx, pt) in past.enumerated() {
                        let spend = pt.actualCumulativeCents ?? 0
                        let x = (CGFloat(idx) / CGFloat(totalDays)) * w
                        let y = h - (h * CGFloat(Double(spend) / Double(maxScale)))
                        if idx == 0 { path.move(to: CGPoint(x: x, y: y)) }
                        else { path.addLine(to: CGPoint(x: x, y: y)) }
                    }
                    if let lastIdx = past.indices.last {
                        let lastX = (CGFloat(lastIdx) / CGFloat(totalDays)) * w
                        path.addLine(to: CGPoint(x: lastX, y: h))
                        path.addLine(to: CGPoint(x: 0, y: h))
                        path.closeSubpath()
                    }
                }
                .fill(LinearGradient(colors: [Theme.accentBlue.opacity(0.25), Theme.accentBlue.opacity(0.01)], startPoint: .top, endPoint: .bottom))
                
                Path { path in
                    for (idx, pt) in past.enumerated() {
                        let spend = pt.actualCumulativeCents ?? 0
                        let x = (CGFloat(idx) / CGFloat(totalDays)) * w
                        let y = h - (h * CGFloat(Double(spend) / Double(maxScale)))
                        if idx == 0 { path.move(to: CGPoint(x: x, y: y)) }
                        else { path.addLine(to: CGPoint(x: x, y: y)) }
                    }
                }
                .stroke(Theme.accentBlue, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            }
        }
        .frame(height: 110)
    }
}
