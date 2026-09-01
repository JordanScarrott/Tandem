import SwiftUI

public struct SmartSuggestionItem: Identifiable {
    public var id: String { title }
    public let title: String
    public let amount: String
    public let categoryMatchName: String
}

public struct SmartSuggestionsView: View {
    public let currencySymbol: String
    public let categories: [CategoryItem]
    public let onSelect: (String, String, UInt64?) -> Void
    
    public init(
        currencySymbol: String,
        categories: [CategoryItem],
        onSelect: @escaping (String, String, UInt64?) -> Void
    ) {
        self.currencySymbol = currencySymbol
        self.categories = categories
        self.onSelect = onSelect
    }
    
    public let suggestions: [SmartSuggestionItem] = [
        SmartSuggestionItem(title: "Coffee & Snack", amount: "65.00", categoryMatchName: "Dining & Coffee"),
        SmartSuggestionItem(title: "Uber Ride", amount: "120.00", categoryMatchName: "Transport / Fuel"),
        SmartSuggestionItem(title: "Groceries", amount: "450.00", categoryMatchName: "Groceries"),
        SmartSuggestionItem(title: "Personal Fun", amount: "250.00", categoryMatchName: "Personal Fun")
    ]
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12))
                    .foregroundStyle(.orange)
                
                Text("Smart quick tags")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.mutedText)
            }
            .padding(.horizontal, 4)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(suggestions) { item in
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            let matchedCat = categories.first(where: {
                                $0.name.localizedCaseInsensitiveContains(item.categoryMatchName)
                            })
                            onSelect(item.title, item.amount, matchedCat?.id)
                        } label: {
                            Text("+ \(item.title) (\(currencySymbol)\(item.amount))")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Theme.primaryDark)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Theme.cardBackground)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .strokeBorder(Theme.cardBorder, lineWidth: 1)
                                )
                                .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
}
