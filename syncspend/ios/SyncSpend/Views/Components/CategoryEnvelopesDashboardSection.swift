import SwiftUI

public struct CategoryEnvelopesDashboardSection: View {
    public let cycle: PaydayCycle
    public let envelopeStatuses: [CategoryEnvelopeStatus]
    public let totalSpentCents: Int64
    public let totalBudgetCents: Int64
    public let currency: CurrencyItem
    @Binding public var selectedCategoryId: UInt64?
    public var onAddEnvelope: () -> Void
    public var onEditEnvelope: (CategoryItem) -> Void
    
    public init(
        cycle: PaydayCycle,
        envelopeStatuses: [CategoryEnvelopeStatus],
        totalSpentCents: Int64,
        totalBudgetCents: Int64,
        currency: CurrencyItem,
        selectedCategoryId: Binding<UInt64?>,
        onAddEnvelope: @escaping () -> Void,
        onEditEnvelope: @escaping (CategoryItem) -> Void
    ) {
        self.cycle = cycle
        self.envelopeStatuses = envelopeStatuses
        self.totalSpentCents = totalSpentCents
        self.totalBudgetCents = totalBudgetCents
        self.currency = currency
        self._selectedCategoryId = selectedCategoryId
        self.onAddEnvelope = onAddEnvelope
        self.onEditEnvelope = onEditEnvelope
    }
    
    private var isCycleOverspent: Bool {
        totalBudgetCents > 0 && totalSpentCents > totalBudgetCents
    }
    
    private var cycleProgressRatio: Double {
        guard totalBudgetCents > 0 else { return 0.0 }
        return min(1.0, max(0.0, Double(totalSpentCents) / Double(totalBudgetCents)))
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Section Header with Payday Cycle Window Pill
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("CATEGORY ENVELOPES")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.mutedText)
                        .tracking(0.5)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.accentBlue)
                        
                        Text("Payday Cycle • \(cycle.dateRangeFormatted)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.primaryDark)
                    }
                }
                
                Spacer()
                
                // Days Left Pill
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 10))
                    Text("\(cycle.daysRemaining)d left")
                        .font(.system(size: 11, weight: .bold))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Theme.chipBackground)
                .foregroundStyle(Theme.primaryDark)
                .clipShape(Capsule())
            }
            .padding(.horizontal, 4)
            
            // Cycle Overview Card
            if totalBudgetCents > 0 {
                VStack(spacing: 10) {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Monthly Budget Allocation")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Theme.mutedText)
                            
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text(formatCents(totalSpentCents))
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundStyle(isCycleOverspent ? Theme.accentRed : Theme.primaryDark)
                                
                                Text("of \(formatCents(totalBudgetCents))")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Theme.mutedText)
                            }
                        }
                        
                        Spacer()
                        
                        if isCycleOverspent {
                            let overspent = totalSpentCents - totalBudgetCents
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 11))
                                Text("-\(formatCents(overspent)) over")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Theme.accentRed.opacity(0.12))
                            .foregroundStyle(Theme.accentRed)
                            .clipShape(Capsule())
                        } else {
                            let remaining = totalBudgetCents - totalSpentCents
                            Text("\(formatCents(remaining)) left")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Theme.accentGreen)
                        }
                    }
                    
                    // Overall Progress Bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Theme.subtleGray)
                                .frame(height: 7)
                            
                            Capsule()
                                .fill(
                                    isCycleOverspent
                                    ? LinearGradient(colors: [Theme.accentRed, Theme.accentRed.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                                    : LinearGradient(colors: [Theme.accentBlue, Theme.accentGreen], startPoint: .leading, endPoint: .trailing)
                                )
                                .frame(width: max(7, geo.size.width * CGFloat(cycleProgressRatio)), height: 7)
                        }
                    }
                    .frame(height: 7)
                }
                .padding(14)
                .background(Theme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous)
                        .strokeBorder(isCycleOverspent ? Theme.accentRed.opacity(0.35) : Theme.cardBorder, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.02), radius: 8, x: 0, y: 2)
            }
            
            // Horizontal Envelope Cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(envelopeStatuses) { envelope in
                        let isSelected = selectedCategoryId == envelope.category.id
                        
                        EnvelopeCard(
                            envelope: envelope,
                            currency: currency,
                            isSelected: isSelected,
                            onTap: {
                                Haptics.selection()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    if isSelected {
                                        selectedCategoryId = nil
                                    } else {
                                        selectedCategoryId = envelope.category.id
                                    }
                                }
                            },
                            onEdit: {
                                Haptics.impact(.medium)
                                onEditEnvelope(envelope.category)
                            }
                        )
                    }
                    
                    // Add New Envelope Card Button
                    Button {
                        Haptics.impact(.light)
                        onAddEnvelope()
                    } label: {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Theme.chipBackground)
                                    .frame(width: 40, height: 40)
                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(Theme.primaryDark)
                            }
                            
                            Text("New\nEnvelope")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Theme.mutedText)
                                .multilineTextAlignment(.center)
                        }
                        .frame(width: 100, height: 142)
                        .background(Theme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .strokeBorder(Theme.cardBorder, style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 2)
            }
        }
    }
    
    private func formatCents(_ cents: Int64) -> String {
        let rands = Double(cents) / 100.0
        return String(format: "%@ %.0f", currency.symbol, rands)
    }
}

private struct EnvelopeCard: View {
    let envelope: CategoryEnvelopeStatus
    let currency: CurrencyItem
    let isSelected: Bool
    let onTap: () -> Void
    let onEdit: () -> Void
    
    private var category: CategoryItem { envelope.category }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                // Header: Icon + Category Name + Selected Tag
                HStack(alignment: .center, spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(category.color.opacity(0.18))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: category.icon)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(category.color)
                    }
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text(category.name)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Theme.primaryDark)
                            .lineLimit(1)
                        
                        if let budget = envelope.budgetCents {
                            Text("Cap: \(formatCents(budget))")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(Theme.mutedText)
                        } else {
                            Text("Flexible")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(Theme.mutedText)
                        }
                    }
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Theme.accentBlue)
                    }
                }
                
                // Spent Amount Display
                VStack(alignment: .leading, spacing: 2) {
                    Text(formatCents(envelope.spentCents))
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(envelope.isOverspent ? Theme.accentRed : Theme.primaryDark)
                    
                    if envelope.isOverspent {
                        HStack(spacing: 3) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 9))
                            Text("-\(formatCents(envelope.overspentCents)) over")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundStyle(Theme.accentRed)
                    } else if let remaining = envelope.remainingCents {
                        Text("\(formatCents(remaining)) left")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Theme.mutedText)
                    } else {
                        Text("Spent this cycle")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Theme.mutedText)
                    }
                }
                
                // Progress Bar
                if envelope.budgetCents != nil {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Theme.subtleGray)
                                .frame(height: 5)
                            
                            Capsule()
                                .fill(envelope.isOverspent ? Theme.accentRed : category.color)
                                .frame(width: max(5, geo.size.width * CGFloat(envelope.progressRatio)), height: 5)
                        }
                    }
                    .frame(height: 5)
                } else {
                    Capsule()
                        .fill(category.color.opacity(0.3))
                        .frame(height: 4)
                }
            }
            .padding(14)
            .frame(width: 156, height: 142)
            .background(Theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(
                        isSelected
                        ? Theme.accentBlue
                        : (envelope.isOverspent ? Theme.accentRed.opacity(0.4) : Theme.cardBorder),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .shadow(
                color: isSelected ? Theme.accentBlue.opacity(0.18) : Color.black.opacity(0.03),
                radius: isSelected ? 8 : 6,
                x: 0,
                y: 2
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                onEdit()
            } label: {
                Label("Edit Envelope Cap & Details", systemImage: "pencil")
            }
        }
    }
    
    private func formatCents(_ cents: Int64) -> String {
        let rands = Double(cents) / 100.0
        return String(format: "%@ %.0f", currency.symbol, rands)
    }
}
