import SwiftUI
import WidgetKit

public struct DailyAllowanceWidgetView: View {
    @Environment(\.widgetFamily) var family
    public let entry: WeeklySpendEntry
    
    public init(entry: WeeklySpendEntry) {
        self.entry = entry
    }
    
    private var healthColor: Color {
        switch entry.telemetry.healthState {
        case .healthy: return Theme.accentGreen
        case .caution: return Theme.accentYellow
        case .overToday: return Theme.accentOrange
        case .overCycle: return Theme.accentRed
        }
    }
    
    private var healthLabel: String {
        switch entry.telemetry.healthState {
        case .healthy: return "Healthy"
        case .caution: return "Caution"
        case .overToday: return "Over Today"
        case .overCycle: return "Over Budget"
        }
    }
    
    public var body: some View {
        Group {
            switch family {
            case .systemMedium:
                mediumView
            default:
                smallView
            }
        }
        .containerBackground(for: .widget) {
            Color(uiColor: .systemGroupedBackground)
        }
    }
    
    // MARK: - Small Widget View
    private var smallView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("AVAILABLE TODAY")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.mutedText)
                    .tracking(0.6)
                
                Spacer()
                
                Circle()
                    .fill(healthColor)
                    .frame(width: 8, height: 8)
            }
            
            Spacer()
            
            Text(entry.telemetry.formattedTodayAvailable)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(entry.telemetry.todayAvailableCents < 0 ? Theme.accentOrange : Theme.primaryDark)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(healthLabel)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(healthColor)
                    
                    Text("•")
                        .foregroundStyle(Theme.mutedText.opacity(0.5))
                    
                    Text("\(entry.telemetry.daysRemainingInCycle)d left")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.mutedText)
                }
                
                Text("\(entry.telemetry.formattedTodayBaseAllowance)/day base")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundStyle(Theme.mutedText)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
    
    // MARK: - Medium Widget View
    private var mediumView: some View {
        HStack(spacing: 16) {
            // Left Column: Available Today Readout
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(healthColor)
                        .frame(width: 8, height: 8)
                    
                    Text("AVAILABLE TODAY")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.mutedText)
                        .tracking(0.6)
                }
                
                Spacer()
                
                Text(entry.telemetry.formattedTodayAvailable)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(entry.telemetry.todayAvailableCents < 0 ? Theme.accentOrange : Theme.primaryDark)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                
                Spacer()
                
                HStack(spacing: 6) {
                    Text(healthLabel)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(healthColor)
                    
                    Text("•")
                        .foregroundStyle(Theme.mutedText.opacity(0.5))
                    
                    Text("\(entry.telemetry.formattedTodayBaseAllowance)/day")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.mutedText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Divider()
                .padding(.vertical, 8)
            
            // Right Column: Mini Spending Bar Graph
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("THIS WEEK")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.mutedText)
                        .tracking(0.5)
                    
                    Spacer()
                    
                    Text(entry.telemetry.formattedWeeklyTotal)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Theme.primaryDark)
                }
                
                GeometryReader { geo in
                    let maxSpend = entry.telemetry.dailySpendings.map(\.amountCents).max() ?? 0
                    let ceiling = max(maxSpend, entry.telemetry.todayBaseAllowanceCents, 5_000)
                    let maxVal = CGFloat(ceiling)
                    let chartHeight = geo.size.height - 18
                    
                    HStack(alignment: .bottom, spacing: 4) {
                        ForEach(entry.telemetry.dailySpendings) { day in
                            let ratio = maxVal > 0 ? CGFloat(day.amountCents) / maxVal : 0
                            let barHeight = max(3, chartHeight * min(1.0, ratio))
                            let isOver = day.amountCents > entry.telemetry.todayBaseAllowanceCents && entry.telemetry.todayBaseAllowanceCents > 0
                            
                            VStack(spacing: 3) {
                                Spacer()
                                
                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                    .fill(isOver ? Theme.accentOrange : (day.isToday ? Theme.accentGreen : Theme.subtleGray))
                                    .frame(height: barHeight)
                                
                                Text(day.day)
                                    .font(.system(size: 8, weight: day.isToday ? .bold : .medium))
                                    .foregroundStyle(day.isToday ? Theme.primaryDark : Theme.mutedText)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Previews
#Preview("Small Available Today", as: .systemSmall) {
    DailyAllowanceWidget()
} timeline: {
    WeeklySpendEntry(date: Date(), telemetry: .preview)
}

#Preview("Medium Available Today", as: .systemMedium) {
    DailyAllowanceWidget()
} timeline: {
    WeeklySpendEntry(date: Date(), telemetry: .preview)
}
