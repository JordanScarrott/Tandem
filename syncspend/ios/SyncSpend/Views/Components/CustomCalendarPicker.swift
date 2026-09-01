import SwiftUI

public struct CustomCalendarPicker: View {
    @Binding public var selectedDate: Date
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentMonthDate: Date
    
    public init(selectedDate: Binding<Date>) {
        self._selectedDate = selectedDate
        self._currentMonthDate = State(initialValue: selectedDate.wrappedValue)
    }
    
    private var calendar: Calendar { Calendar.current }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonthDate)
    }
    
    private var daysInMonth: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonthDate),
              let firstDayOfWeek = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonthDate)) else {
            return []
        }
        
        let weekday = calendar.component(.weekday, from: firstDayOfWeek)
        let blanks = weekday - 1 // 1 is Sunday
        
        var days: [Date?] = Array(repeating: nil, count: blanks)
        
        var current = monthInterval.start
        while current < monthInterval.end {
            days.append(current)
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }
        return days
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            // Sheet Top Header
            HStack {
                Button {
                    dismiss()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "#E5E5EA") ?? Color(.systemGray5))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Theme.primaryDark)
                    }
                }
                
                Spacer()
                
                Text("Date")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.primaryDark)
                
                Spacer()
                
                Color.clear.frame(width: 32, height: 32)
            }
            .padding(.horizontal, 4)
            
            // Month Navigation Row
            HStack {
                Text(monthYearString)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Theme.primaryDark)
                
                Spacer()
                
                HStack(spacing: 16) {
                    Button {
                        if let prev = calendar.date(byAdding: .month, value: -1, to: currentMonthDate) {
                            currentMonthDate = prev
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Theme.primaryDark)
                    }
                    
                    Button {
                        if let next = calendar.date(byAdding: .month, value: 1, to: currentMonthDate) {
                            currentMonthDate = next
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Theme.primaryDark)
                    }
                }
            }
            .padding(.horizontal, 6)
            
            // Weekday Header
            let weekdaySymbols = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
            HStack {
                ForEach(weekdaySymbols, id: \.self) { sym in
                    Text(sym)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.mutedText)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Day Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, dayDate in
                    if let dayDate = dayDate {
                        let isSelected = calendar.isDate(dayDate, inSameDayAs: selectedDate)
                        let isToday = calendar.isDateInToday(dayDate)
                        let dayNum = calendar.component(.day, from: dayDate)
                        
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            selectedDate = dayDate
                            dismiss()
                        } label: {
                            Text("\(dayNum)")
                                .font(.system(size: 15, weight: isSelected ? .bold : .medium))
                                .frame(width: 38, height: 38)
                                .background(
                                    Circle()
                                        .fill(
                                            isSelected ? Theme.buttonDark : (isToday ? Color.black.opacity(0.1) : Color.clear)
                                        )
                                )
                                .foregroundStyle(
                                    isSelected ? .white : Theme.primaryDark
                                )
                        }
                        .buttonStyle(.plain)
                    } else {
                        Color.clear.frame(width: 38, height: 38)
                    }
                }
            }
        }
        .padding(20)
        .background(Theme.appBackground)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
    }
}
