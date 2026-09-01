import SwiftUI

public struct ManageEnvelopesSheet: View {
    @Environment(\.dismiss) private var dismiss
    private var service = SpacetimeService.shared
    
    @State private var categories: [CategoryItem] = []
    @State private var isLoading: Bool = true
    @State private var editingCategory: CategoryItem? = nil
    @State private var showingCreateCategory: Bool = false
    
    public let currency: CurrencyItem
    public var onUpdated: () -> Void
    
    public init(
        currency: CurrencyItem = CurrencyItem.defaultCurrency,
        onUpdated: @escaping () -> Void = {}
    ) {
        self.currency = currency
        self.onUpdated = onUpdated
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if isLoading {
                        ProgressView()
                            .padding(.top, 40)
                    } else if categories.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "tray")
                                .font(.system(size: 40))
                                .foregroundStyle(Theme.mutedText)
                            Text("No category envelopes found")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Theme.primaryDark)
                        }
                        .padding(.top, 40)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(categories) { cat in
                                Button {
                                    Haptics.impact(.light)
                                    editingCategory = cat
                                } label: {
                                    HStack(spacing: 12) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .fill(cat.color.opacity(0.18))
                                                .frame(width: 36, height: 36)
                                            
                                            Image(systemName: cat.icon)
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundStyle(cat.color)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(cat.name)
                                                .font(.system(size: 15, weight: .semibold))
                                                .foregroundStyle(Theme.primaryDark)
                                            
                                            if let budget = cat.monthlyBudgetCents {
                                                let rands = Double(budget) / 100.0
                                                Text("Monthly cap: \(currency.symbol) \(String(format: "%.0f", rands))")
                                                    .font(.system(size: 12, weight: .medium))
                                                    .foregroundStyle(Theme.accentGreen)
                                            } else {
                                                Text("Flexible envelope")
                                                    .font(.system(size: 12, weight: .medium))
                                                    .foregroundStyle(Theme.mutedText)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "pencil.circle.fill")
                                            .font(.system(size: 20))
                                            .foregroundStyle(Theme.mutedText)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                
                                if cat.id != categories.last?.id {
                                    Divider()
                                        .padding(.leading, 64)
                                }
                            }
                        }
                        .background(Theme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous)
                                .strokeBorder(Theme.cardBorder, lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.02), radius: 8, x: 0, y: 2)
                    }
                    
                    // Add New Envelope Action Button
                    Button {
                        Haptics.impact(.medium)
                        showingCreateCategory = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16, weight: .bold))
                            Text("Create New Envelope")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Theme.primaryDark)
                        .foregroundStyle(Theme.buttonForeground)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.buttonCornerRadius, style: .continuous))
                    }
                    .padding(.top, 8)
                }
                .padding(16)
            }
            .background(Theme.appBackground)
            .navigationTitle("Category Envelopes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.accentBlue)
                }
            }
            .task {
                await load()
            }
            .sheet(item: $editingCategory) { cat in
                CategoryEnvelopeSheet(mode: .edit(cat), currency: currency) {
                    Task {
                        await load()
                        onUpdated()
                    }
                }
            }
            .sheet(isPresented: $showingCreateCategory) {
                CategoryEnvelopeSheet(mode: .create, currency: currency) {
                    Task {
                        await load()
                        onUpdated()
                    }
                }
            }
        }
    }
    
    private func load() async {
        isLoading = true
        do {
            let fetched = try await service.fetchCategories()
            self.categories = fetched
        } catch {
            print("Failed to fetch categories: \(error)")
        }
        isLoading = false
    }
}
