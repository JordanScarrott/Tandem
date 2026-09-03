import SwiftUI

public struct NewExpenseSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = NewExpenseViewModel()
    @FocusState private var isAmountFocused: Bool
    
    public let categories: [CategoryItem]
    public let currency: CurrencyItem
    public let accountId: String
    public let smartSuggestionsEnabled: Bool
    public let expenseToEdit: ExpenseItem?
    public let onExpenseSaved: () -> Void
    public let onExpenseDeleted: ((ExpenseItem) -> Void)?
    
    @State private var showingDatePicker: Bool = false
    @State private var showingAddCategory: Bool = false
    @State private var showingDeleteConfirmation: Bool = false
    
    public init(
        categories: [CategoryItem],
        currency: CurrencyItem,
        accountId: String,
        smartSuggestionsEnabled: Bool,
        expenseToEdit: ExpenseItem? = nil,
        onExpenseSaved: @escaping () -> Void,
        onExpenseDeleted: ((ExpenseItem) -> Void)? = nil
    ) {
        self.categories = categories
        self.currency = currency
        self.accountId = accountId
        self.smartSuggestionsEnabled = smartSuggestionsEnabled
        self.expenseToEdit = expenseToEdit
        self.onExpenseSaved = onExpenseSaved
        self.onExpenseDeleted = onExpenseDeleted
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
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 16) {
                        // 1. Hero Amount & Note Card
                        VStack(spacing: 12) {
                            // Amount Entry Header
                            VStack(spacing: 4) {
                                Text("AMOUNT")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(Theme.mutedText)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                HStack(alignment: .firstTextBaseline, spacing: 6) {
                                    Text(currency.symbol)
                                        .font(.system(size: 28, weight: .bold, design: .rounded))
                                        .foregroundStyle(Theme.mutedText)
                                    
                                    TextField("0.00", text: $viewModel.amountInput)
                                        .focused($isAmountFocused)
                                        .keyboardType(.decimalPad)
                                        .font(.system(size: 40, weight: .bold, design: .rounded))
                                        .foregroundStyle(Theme.primaryDark)
                                        .minimumScaleFactor(0.7)
                                }
                            }
                            
                            Divider()
                            
                            // Note Field Immediately Below
                            HStack(spacing: 10) {
                                Image(systemName: "pencil.line")
                                    .font(.system(size: 15))
                                    .foregroundStyle(Theme.mutedText)
                                
                                let placeholderText = "Note (defaults to \(selectedCategory?.name ?? "category"))"
                                TextField(placeholderText, text: $viewModel.title)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(Theme.primaryDark)
                                
                                if !viewModel.title.isEmpty {
                                    Button {
                                        viewModel.title = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(Theme.mutedText)
                                    }
                                }
                            }
                            .padding(.vertical, 2)
                        }
                        .padding(18)
                        .background(Theme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous)
                                .strokeBorder(Theme.cardBorder, lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 2)
                        
                        // 2. Dual Wheel Rollers (Category & Payment Method)
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("QUICK ENVELOPE & PAYMENT SELECTION")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(Theme.mutedText)
                                
                                Spacer()
                                
                                Button {
                                    showingAddCategory = true
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 12))
                                        Text("New Envelope")
                                            .font(.system(size: 12, weight: .semibold))
                                    }
                                    .foregroundStyle(Theme.accentBlue)
                                }
                            }
                            .padding(.horizontal, 4)
                            
                            HStack(spacing: 8) {
                                // Category Wheel Column
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 6) {
                                        if let cat = selectedCategory {
                                            Image(systemName: cat.icon)
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundStyle(cat.color)
                                        }
                                        Text("Category")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundStyle(Theme.primaryDark)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.top, 8)
                                    
                                    Picker("Category", selection: $viewModel.selectedCategoryId) {
                                        ForEach(categories) { cat in
                                            HStack(spacing: 8) {
                                                Image(systemName: cat.icon)
                                                    .foregroundStyle(cat.color)
                                                Text(cat.name)
                                                    .font(.system(size: 14, weight: .medium))
                                            }
                                            .tag(Optional(cat.id))
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(height: 110)
                                    .clipped()
                                    .onChange(of: viewModel.selectedCategoryId) { _, _ in
                                        Haptics.selection()
                                    }
                                }
                                .background(Theme.tertiaryBackground.opacity(0.6))
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                
                                // Payment Method Wheel Column
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "creditcard.fill")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundStyle(Theme.accentBlue)
                                        Text("Payment")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundStyle(Theme.primaryDark)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.top, 8)
                                    
                                    Picker("Payment Method", selection: $viewModel.selectedPaymentMethod) {
                                        ForEach(DashboardViewModel.defaultPaymentMethods, id: \.self) { method in
                                            Text(method)
                                                .font(.system(size: 14, weight: .medium))
                                                .tag(method)
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(height: 110)
                                    .clipped()
                                    .onChange(of: viewModel.selectedPaymentMethod) { _, _ in
                                        Haptics.selection()
                                    }
                                }
                                .background(Theme.tertiaryBackground.opacity(0.6))
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                        }
                        .padding(14)
                        .background(Theme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous)
                                .strokeBorder(Theme.cardBorder, lineWidth: 1)
                        )
                        
                        // 3. Date & Split Mode Row
                        VStack(spacing: 12) {
                            HStack {
                                HStack(spacing: 8) {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 14))
                                        .foregroundStyle(Theme.accentBlue)
                                    Text("Date")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(Theme.primaryDark)
                                }
                                
                                Spacer()
                                
                                Button {
                                    isAmountFocused = false
                                    showingDatePicker = true
                                } label: {
                                    HStack(spacing: 6) {
                                        Text(formattedDateString)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(Theme.primaryDark)
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundStyle(Theme.mutedText)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Theme.chipBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                            
                            Divider()
                            
                            // Split Mode Segment
                            VStack(alignment: .leading, spacing: 6) {
                                Text("SPLIT MODE")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(Theme.mutedText)
                                
                                Picker("Split Mode", selection: $viewModel.selectedSplitMode) {
                                    Text("Personal").tag("PERSONAL")
                                    Text("50/50 Equal").tag("EQUAL")
                                    Text("Proportional").tag("PROPORTIONAL")
                                    Text("Partner").tag("PAID_FOR_PARTNER")
                                }
                                .pickerStyle(.segmented)
                                .onChange(of: viewModel.selectedSplitMode) { _, _ in
                                    Haptics.selection()
                                }
                            }
                        }
                        .padding(14)
                        .background(Theme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous)
                                .strokeBorder(Theme.cardBorder, lineWidth: 1)
                        )
                        
                        // 4. Smart Suggestions (if enabled)
                        if smartSuggestionsEnabled && !viewModel.isEditing {
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

                        if viewModel.isEditing {
                            Button(role: .destructive) {
                                Haptics.impact(.medium)
                                showingDeleteConfirmation = true
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text("Delete Expense")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Theme.accentRed.opacity(0.1))
                                .foregroundStyle(Theme.accentRed)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 4)
                        }
                        
                        // Bottom spacer to ensure scrolling clears the fixed bottom action button
                        Spacer()
                            .frame(height: 80)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
                .scrollDismissesKeyboard(.interactively)
                
                // 5. Thumb-Reachable Floating / Docked Confirmation CTA
                VStack(spacing: 0) {
                    Divider()
                    
                    HStack {
                        Button {
                            submitExpense()
                        } label: {
                            HStack(spacing: 8) {
                                if viewModel.isSubmitting {
                                    ProgressView()
                                        .tint(Theme.buttonForeground)
                                } else {
                                    Image(systemName: viewModel.isEditing ? "checkmark.circle.fill" : "plus.circle.fill")
                                        .font(.system(size: 18, weight: .bold))
                                    
                                    if viewModel.parsedCents > 0 {
                                        Text(viewModel.isEditing ? "Save Changes • \(viewModel.formattedAmount(currencySymbol: currency.symbol))" : "Add Expense • \(viewModel.formattedAmount(currencySymbol: currency.symbol))")
                                            .font(.system(size: 16, weight: .bold))
                                    } else {
                                        Text(viewModel.isEditing ? "Save Changes" : "Enter Amount to Log")
                                            .font(.system(size: 16, weight: .bold))
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(viewModel.canSave ? Theme.primaryDark : Theme.primaryDark.opacity(0.4))
                            .foregroundStyle(Theme.buttonForeground)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.buttonCornerRadius, style: .continuous))
                            .shadow(color: Color.black.opacity(viewModel.canSave ? 0.15 : 0), radius: 8, x: 0, y: 4)
                        }
                        .disabled(!viewModel.canSave || viewModel.isSubmitting)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Theme.cardBackground.ignoresSafeArea())
                }
            }
            .background(Theme.appBackground)
            .navigationTitle(viewModel.isEditing ? "Edit Expense" : "Rapid Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(Theme.accentBlue)
                }

                if viewModel.isEditing {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            Haptics.impact(.medium)
                            showingDeleteConfirmation = true
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Theme.accentRed)
                        }
                    }
                }
            }
            .presentationDragIndicator(.visible)
            .sheet(isPresented: $showingDatePicker) {
                CustomCalendarPicker(selectedDate: $viewModel.spentDate)
                    .presentationDetents([.fraction(0.6), .medium, .large])
            }
            .sheet(isPresented: $showingAddCategory) {
                AddCategorySheet {
                    // Category added
                }
            }
            .confirmationDialog(
                "Delete Expense?",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Expense", role: .destructive) {
                    deleteCurrentExpense()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to remove this expense? You can undo this action.")
            }
            .onAppear {
                if let expense = expenseToEdit {
                    viewModel.populate(with: expense)
                } else {
                    viewModel.reconcileSelectedCategory(with: categories)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        if viewModel.amountInput.isEmpty {
                            isAmountFocused = true
                        }
                    }
                }
            }
        }
    }
    
    private func submitExpense() {
        Haptics.impact(.medium)
        Task {
            let success = await viewModel.saveExpense(
                categories: categories,
                currencyCode: currency.code,
                accountId: accountId
            )
            if success {
                Haptics.notification(.success)
                onExpenseSaved()
                dismiss()
            }
        }
    }

    private func deleteCurrentExpense() {
        guard let expense = expenseToEdit else { return }
        Haptics.notification(.warning)
        if let onExpenseDeleted = onExpenseDeleted {
            onExpenseDeleted(expense)
            dismiss()
        } else {
            Task {
                let success = await viewModel.deleteExpense()
                if success {
                    dismiss()
                }
            }
        }
    }
}
