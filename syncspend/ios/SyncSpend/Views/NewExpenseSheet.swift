import SwiftUI

public struct NewExpenseSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = NewExpenseViewModel()
    @FocusState private var isAmountFocused: Bool
    
    public let categories: [CategoryItem]
    public let currency: CurrencyItem
    public let accountId: String
    public let smartSuggestionsEnabled: Bool
    public let onExpenseSaved: () -> Void
    
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
                            TextField("Title (e.g. Lunch with team)", text: $viewModel.title)
                                .font(.system(size: 16, weight: .regular))
                                .foregroundStyle(Theme.primaryDark)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        
                        Divider()
                            .padding(.leading, 16)
                        
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
                                    .focused($isAmountFocused)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Theme.primaryDark)
                                    .frame(maxWidth: 130)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        
                        Divider()
                            .padding(.leading, 16)
                        
                        // Category Row (Native iOS Menu Dropdown)
                        Menu {
                            ForEach(categories) { cat in
                                Button {
                                    Haptics.selection()
                                    viewModel.selectedCategoryId = cat.id
                                } label: {
                                    if viewModel.selectedCategoryId == cat.id {
                                        Label(cat.name, systemImage: "checkmark")
                                    } else {
                                        Text(cat.name)
                                    }
                                }
                            }
                            
                            Divider()
                            
                            Button {
                                showingAddCategory = true
                            } label: {
                                Label("Add Custom Category...", systemImage: "plus")
                            }
                        } label: {
                            HStack {
                                Text("Category")
                                    .font(.system(size: 15, weight: .regular))
                                    .foregroundStyle(Theme.primaryDark)
                                
                                Spacer()
                                
                                HStack(spacing: 6) {
                                    if let cat = selectedCategory {
                                        HStack(spacing: 6) {
                                            Image(systemName: cat.icon)
                                                .font(.system(size: 12))
                                                .foregroundStyle(cat.color)
                                            Text(cat.name)
                                                .font(.system(size: 15, weight: .medium))
                                                .foregroundStyle(Theme.primaryDark)
                                        }
                                    } else {
                                        Text("Select")
                                            .font(.system(size: 15, weight: .regular))
                                            .foregroundStyle(Theme.mutedText)
                                    }
                                    
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(Theme.mutedText)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .contentShape(Rectangle())
                        }
                        
                        Divider()
                            .padding(.leading, 16)
                        
                        // Payment Row (Native iOS Menu Dropdown)
                        Menu {
                            ForEach(DashboardViewModel.defaultPaymentMethods, id: \.self) { method in
                                Button {
                                    Haptics.selection()
                                    viewModel.selectedPaymentMethod = method
                                } label: {
                                    if viewModel.selectedPaymentMethod == method {
                                        Label(method, systemImage: "checkmark")
                                    } else {
                                        Text(method)
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Text("Payment")
                                    .font(.system(size: 15, weight: .regular))
                                    .foregroundStyle(Theme.primaryDark)
                                
                                Spacer()
                                
                                HStack(spacing: 6) {
                                    Text(viewModel.selectedPaymentMethod)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(Theme.primaryDark)
                                    
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(Theme.mutedText)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .contentShape(Rectangle())
                        }
                        
                        Divider()
                            .padding(.leading, 16)
                        
                        // Date Row
                        HStack {
                            Text("Date")
                                .font(.system(size: 15, weight: .regular))
                                .foregroundStyle(Theme.primaryDark)
                            
                            Spacer()
                            
                            Button {
                                isAmountFocused = false
                                showingDatePicker = true
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Theme.mutedText)
                                    
                                    Text(formattedDateString)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(Theme.primaryDark)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Theme.chipBackground)
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
                        .onChange(of: viewModel.selectedSplitMode) { _, _ in
                            Haptics.selection()
                        }
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
            .scrollDismissesKeyboard(.interactively)
            .background(Theme.appBackground)
            .navigationTitle("New Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(Theme.accentBlue)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            let success = await viewModel.saveExpense(
                                currencyCode: currency.code,
                                accountId: accountId
                            )
                            if success {
                                Haptics.notification(.success)
                                onExpenseSaved()
                                dismiss()
                            }
                        }
                    } label: {
                        if viewModel.isSubmitting {
                            ProgressView()
                        } else {
                            Text("Save")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(viewModel.canSave ? Theme.accentBlue : Theme.mutedText)
                        }
                    }
                    .disabled(!viewModel.canSave || viewModel.isSubmitting)
                }
            }
            .presentationDragIndicator(.visible)
            .sheet(isPresented: $showingDatePicker) {
                CustomCalendarPicker(selectedDate: $viewModel.spentDate)
                    .presentationDetents([.fraction(0.6), .medium, .large])
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
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    if viewModel.amountInput.isEmpty {
                        isAmountFocused = true
                    }
                }
            }
        }
    }
}

