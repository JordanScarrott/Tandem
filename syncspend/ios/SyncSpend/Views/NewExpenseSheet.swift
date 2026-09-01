import SwiftUI

public struct NewExpenseSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = NewExpenseViewModel()
    
    public let categories: [CategoryItem]
    public let currency: CurrencyItem
    public let accountId: String
    public let smartSuggestionsEnabled: Bool
    public let onExpenseSaved: () -> Void
    
    @State private var showingCategoryPicker: Bool = false
    @State private var showingPaymentPicker: Bool = false
    @State private var showingDatePicker: Bool = false
    @State private var showingAddCategory: Bool = false
    
    public init(
        categories: [CategoryItem],
        currency: CurrencyItem,
        accountId: String,
        smartSuggestionsEnabled: Bool,
        onExpenseSaved: @escaping () -> Void
    ) {
        self.categories = categories
        self.currency = currency
        self.accountId = accountId
        self.smartSuggestionsEnabled = smartSuggestionsEnabled
        self.onExpenseSaved = onExpenseSaved
    }
    
    private var selectedCategory: CategoryItem? {
        if let id = viewModel.selectedCategoryId {
            return categories.first(where: { $0.id == id })
        }
        return categories.first
    }
    
    private var formattedDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: viewModel.spentDate)
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Inset Form Container
                    VStack(spacing: 0) {
                        // Title Row
                        HStack {
                            TextField("Title", text: $viewModel.title)
                                .font(.system(size: 16, weight: .regular))
                                .foregroundStyle(Theme.primaryDark)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        
                        Divider()
                        
                        // Amount Row
                        HStack {
                            Text("Amount")
                                .font(.system(size: 15, weight: .regular))
                                .foregroundStyle(Theme.primaryDark)
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Text(currency.code)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Theme.mutedText)
                                
                                TextField("0.00", text: $viewModel.amountInput)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                                    .foregroundStyle(Theme.primaryDark)
                                    .frame(maxWidth: 120)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        
                        Divider()
                        
                        // Category Row
                        Button {
                            showingCategoryPicker = true
                        } label: {
                            HStack {
                                Text("Category")
                                    .font(.system(size: 15, weight: .regular))
                                    .foregroundStyle(Theme.primaryDark)
                                
                                Spacer()
                                
                                HStack(spacing: 6) {
                                    Text(selectedCategory?.name ?? "Select")
                                        .font(.system(size: 15, weight: .regular))
                                        .foregroundStyle(Theme.mutedText)
                                    
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(Theme.mutedText)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        
                        Divider()
                        
                        // Payment Row
                        Button {
                            showingPaymentPicker = true
                        } label: {
                            HStack {
                                Text("Payment")
                                    .font(.system(size: 15, weight: .regular))
                                    .foregroundStyle(Theme.primaryDark)
                                
                                Spacer()
                                
                                HStack(spacing: 6) {
                                    Text(viewModel.selectedPaymentMethod)
                                        .font(.system(size: 15, weight: .regular))
                                        .foregroundStyle(Theme.mutedText)
                                    
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(Theme.mutedText)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        
                        Divider()
                        
                        // Date Row
                        HStack {
                            Text("Date")
                                .font(.system(size: 15, weight: .regular))
                                .foregroundStyle(Theme.primaryDark)
                            
                            Spacer()
                            
                            Button {
                                showingDatePicker = true
                            } label: {
                                Text(formattedDateString)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Theme.primaryDark)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.black.opacity(0.06))
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .background(Theme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .strokeBorder(Theme.cardBorder, lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 2)
                    
                    // Split Mode Selector (Couple / Partner Split)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("SPLIT MODE")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.mutedText)
                            .padding(.horizontal, 4)
                        
                        Picker("Split Mode", selection: $viewModel.selectedSplitMode) {
                            Text("Personal").tag("PERSONAL")
                            Text("50/50 Equal").tag("EQUAL")
                            Text("Proportional").tag("PROPORTIONAL")
                            Text("For Partner").tag("PAID_FOR_PARTNER")
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.horizontal, 2)
                    
                    // Smart Suggestions
                    if smartSuggestionsEnabled {
                        SmartSuggestionsView(
                            currencySymbol: currency.symbol,
                            categories: categories,
                            onSelect: { title, amount, catId in
                                viewModel.applySuggestion(title: title, amountString: amount, categoryId: catId)
                            }
                        )
                    }
                    
                    if let err = viewModel.errorMessage {
                        Text(err)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Theme.accentRed)
                            .padding(.horizontal, 4)
                    }
                }
                .padding(16)
            }
            .background(Theme.appBackground)
            .navigationTitle("New Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Theme.primaryDark)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .strokeBorder(Theme.cardBorder, lineWidth: 1)
                            )
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            let success = await viewModel.saveExpense(
                                currencyCode: currency.code,
                                accountId: accountId
                            )
                            if success {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                onExpenseSaved()
                                dismiss()
                            }
                        }
                    } label: {
                        if viewModel.isSubmitting {
                            ProgressView()
                                .tint(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(Theme.buttonDark)
                                .clipShape(Capsule())
                        } else {
                            Text("Save")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(viewModel.canSave ? Theme.buttonDark : Color.black.opacity(0.2))
                                .clipShape(Capsule())
                        }
                    }
                    .disabled(!viewModel.canSave || viewModel.isSubmitting)
                }
            }
            .sheet(isPresented: $showingCategoryPicker) {
                CategoryPickerSheet(
                    categories: categories,
                    selectedCategoryId: $viewModel.selectedCategoryId,
                    onAddNewCategory: {
                        showingAddCategory = true
                    }
                )
            }
            .sheet(isPresented: $showingPaymentPicker) {
                PaymentMethodPickerSheet(
                    selectedPaymentMethod: $viewModel.selectedPaymentMethod
                )
            }
            .sheet(isPresented: $showingDatePicker) {
                CustomCalendarPicker(selectedDate: $viewModel.spentDate)
                    .presentationDetents([.fraction(0.55), .medium])
            }
            .sheet(isPresented: $showingAddCategory) {
                AddCategorySheet {
                    // Category created
                }
            }
            .onAppear {
                if viewModel.selectedCategoryId == nil {
                    viewModel.selectedCategoryId = categories.first?.id
                }
            }
        }
    }
}
