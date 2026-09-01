import SwiftUI

public struct SearchFilterSheet: View {
    @Binding public var searchQuery: String
    @Binding public var selectedCategoryId: UInt64?
    public let categories: [CategoryItem]
    public let expenses: [ExpenseItem]
    public let currency: CurrencyItem
    @Environment(\.dismiss) private var dismiss
    
    public init(
        searchQuery: Binding<String>,
        selectedCategoryId: Binding<UInt64?>,
        categories: [CategoryItem],
        expenses: [ExpenseItem],
        currency: CurrencyItem
    ) {
        self._searchQuery = searchQuery
        self._selectedCategoryId = selectedCategoryId
        self.categories = categories
        self.expenses = expenses
        self.currency = currency
    }
    
    private var filteredExpenses: [ExpenseItem] {
        var list = expenses
        let q = searchQuery.trimmingCharacters(in: .whitespaces).lowercased()
        if !q.isEmpty {
            list = list.filter { exp in
                let catName = categories.first(where: { $0.id == exp.categoryId })?.name.lowercased() ?? ""
                return exp.note.lowercased().contains(q) || catName.contains(q) || String(exp.amountCents).contains(q)
            }
        }
        if let catId = selectedCategoryId {
            list = list.filter { $0.categoryId == catId }
        }
        return list
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: date)
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Top Search Bar
                HStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 15))
                            .foregroundStyle(Theme.mutedText)
                        
                        TextField("Search transactions...", text: $searchQuery)
                            .font(.system(size: 15))
                            .foregroundStyle(Theme.primaryDark)
                        
                        if !searchQuery.isEmpty {
                            Button {
                                searchQuery = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(Theme.mutedText)
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Theme.cardBackground)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .strokeBorder(Theme.cardBorder, lineWidth: 1)
                    )
                    
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.primaryDark)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                // Category Filter Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        Button {
                            Haptics.selection()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedCategoryId = nil
                            }
                        } label: {
                            Text("All Categories")
                                .font(.system(size: 13, weight: .medium))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(selectedCategoryId == nil ? Theme.buttonDark : Theme.cardBackground)
                                .foregroundStyle(selectedCategoryId == nil ? Theme.buttonForeground : Theme.primaryDark)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .strokeBorder(selectedCategoryId == nil ? Color.clear : Theme.cardBorder, lineWidth: 1)
                                )
                        }
                        
                        ForEach(categories) { cat in
                            let isSelected = selectedCategoryId == cat.id
                            Button {
                                Haptics.selection()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    selectedCategoryId = isSelected ? nil : cat.id
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: cat.icon)
                                        .font(.system(size: 11))
                                    Text(cat.name)
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(isSelected ? Theme.buttonDark : Theme.cardBackground)
                                .foregroundStyle(isSelected ? Theme.buttonForeground : Theme.primaryDark)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .strokeBorder(isSelected ? Color.clear : Theme.cardBorder, lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                
                // Results List
                VStack(alignment: .leading, spacing: 8) {
                    Text("MATCHING TRANSACTIONS (\(filteredExpenses.count))")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.mutedText)
                        .padding(.horizontal, 20)
                        .tracking(0.5)
                    
                    if filteredExpenses.isEmpty {
                        VStack(spacing: 6) {
                            Text("No results match your search.")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Theme.mutedText)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                    } else {
                        ScrollView {
                            VStack(spacing: 0) {
                                ForEach(Array(filteredExpenses.enumerated()), id: \.element.id) { index, item in
                                    let cat = categories.first(where: { $0.id == item.categoryId })
                                    HStack(spacing: 12) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .fill((cat?.color ?? Theme.accentBlue).opacity(0.15))
                                                .frame(width: 36, height: 36)
                                            
                                            Image(systemName: cat?.icon ?? "tag.fill")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundStyle(cat?.color ?? Theme.primaryDark)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.note.isEmpty ? (cat?.name ?? "Expense") : item.note)
                                                .font(.system(size: 15, weight: .semibold))
                                                .foregroundStyle(Theme.primaryDark)
                                            
                                            Text(formatDate(item.spentDate))
                                                .font(.system(size: 12))
                                                .foregroundStyle(Theme.mutedText)
                                        }
                                        
                                        Spacer()
                                        
                                        Text(currency.format(cents: item.amountCents))
                                            .font(.system(size: 15, weight: .bold, design: .rounded))
                                            .foregroundStyle(Theme.primaryDark)
                                    }
                                    .padding(14)
                                    
                                    if index < filteredExpenses.count - 1 {
                                        Divider().padding(.leading, 62)
                                    }
                                }
                            }
                            .background(Theme.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .strokeBorder(Theme.cardBorder, lineWidth: 1)
                            )
                            .padding(.horizontal, 16)
                        }
                    }
                }
                
                Spacer()
            }
            .background(Theme.appBackground)
            .presentationDragIndicator(.visible)
        }
    }
}

