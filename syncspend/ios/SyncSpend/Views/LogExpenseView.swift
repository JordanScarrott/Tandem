import SwiftUI

public struct LogExpenseView: View {
    @State private var service = SpacetimeService.shared

    // Form State
    @State private var amountInput: String = ""
    @State private var note: String = ""
    @State private var selectedCategoryId: UInt64?
    @State private var selectedPaymentMethod: String = "Apple Pay"
    @State private var spentDate: Date = Date()
    @State private var isSubmitting: Bool = false

    // Data State
    @State private var categories: [CategoryItem] = []
    @State private var recentExpenses: [ExpenseItem] = []
    @State private var errorMessage: String?

    // Sheets & Undo State
    @State private var showingAddCategory: Bool = false
    @State private var lastDeletedExpense: ExpenseItem?
    @State private var undoTimer: Timer?
    @State private var undoTimeRemaining: Double = 5.0
    @State private var showingUndoBar: Bool = false

    let paymentMethods = ["Apple Pay", "Credit Card", "Debit Card", "Cash"]

    private var parsedCents: Int64 {
        guard let rands = Double(amountInput.replacingOccurrences(of: ",", with: ".")) else { return 0 }
        return Int64(round(rands * 100.0))
    }

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 20) {
                        // Host Config (Collapsible)
                        DisclosureGroup("Server Configuration") {
                            VStack(spacing: 8) {
                                TextField("Host URL", text: $service.hostURL)
                                    .font(.caption)
                                    .textFieldStyle(.roundedBorder)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                                TextField("Database Name", text: $service.databaseName)
                                    .font(.caption)
                                    .textFieldStyle(.roundedBorder)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)

                        // 1. ZAR Amount Hero Input
                        VStack(spacing: 6) {
                            Text("ZAR AMOUNT")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.secondary)

                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("R")
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundStyle(.secondary)

                                TextField("0.00", text: $amountInput)
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.leading)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.horizontal, 40)
                        }
                        .padding(.vertical, 8)

                        // 2. Note / Merchant Field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("NOTE / MERCHANT")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.secondary)
                            TextField("e.g. Woolworths, Shell, Steers", text: $note)
                                .padding(12)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal)

                        // 3. Dynamic Category Selector
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("CATEGORY")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Button {
                                    showingAddCategory = true
                                } label: {
                                    Label("New", systemImage: "plus.circle.fill")
                                        .font(.caption.weight(.semibold))
                                }
                            }
                            .padding(.horizontal)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(categories) { cat in
                                        let isSelected = selectedCategoryId == cat.id
                                        Button {
                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                            selectedCategoryId = cat.id
                                        } label: {
                                            HStack(spacing: 6) {
                                                Image(systemName: cat.icon)
                                                Text(cat.name)
                                                if let budget = cat.formattedBudget {
                                                    Text("(\(budget))")
                                                        .font(.caption2)
                                                        .opacity(0.8)
                                                }
                                            }
                                            .font(.subheadline.weight(.medium))
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(isSelected ? cat.color : Color(.secondarySystemBackground))
                                            .foregroundStyle(isSelected ? .white : .primary)
                                            .clipShape(Capsule())
                                            .overlay(
                                                Capsule()
                                                    .strokeBorder(cat.color.opacity(isSelected ? 0 : 0.3), lineWidth: 1)
                                            )
                                        }
                                    }

                                    // Add Category quick capsule button
                                    Button {
                                        showingAddCategory = true
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: "plus")
                                            Text("Custom")
                                        }
                                        .font(.subheadline.weight(.medium))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color(.tertiarySystemBackground))
                                        .foregroundStyle(.secondary)
                                        .clipShape(Capsule())
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }

                        // 4. Payment Method & Date
                        VStack(spacing: 14) {
                            Picker("Payment Method", selection: $selectedPaymentMethod) {
                                ForEach(paymentMethods, id: \.self) { method in
                                    Text(method).tag(method)
                                }
                            }
                            .pickerStyle(.segmented)

                            DatePicker("Date", selection: $spentDate, displayedComponents: [.date, .hourAndMinute])
                                .font(.subheadline)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)

                        // 5. Submit Button
                        Button {
                            submitExpense()
                        } label: {
                            HStack {
                                if isSubmitting {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Log Expense")
                                        .font(.headline.weight(.semibold))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(canSubmit ? Color.accentColor : Color(.systemGray4))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .disabled(!canSubmit || isSubmitting)
                        .padding(.horizontal)

                        if let err = errorMessage {
                            Text(err)
                                .font(.footnote)
                                .foregroundStyle(.red)
                        }

                        Divider()
                            .padding(.vertical, 8)

                        // 6. Recent Activity List with Swipe-to-Delete
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Recent Transactions")
                                    .font(.headline)
                                Spacer()
                                Text("Swipe to delete")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                Button("Refresh") {
                                    Task { await refreshAll() }
                                }
                                .font(.caption)
                            }
                            .padding(.horizontal)

                            if recentExpenses.isEmpty {
                                Text("No expenses logged yet.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal)
                                    .padding(.vertical, 12)
                            } else {
                                ForEach(recentExpenses) { item in
                                    let cat = categoryFor(id: item.categoryId)
                                    HStack(spacing: 12) {
                                        ZStack {
                                            Circle()
                                                .fill(cat?.color.opacity(0.15) ?? Color.gray.opacity(0.15))
                                                .frame(width: 38, height: 38)
                                            Image(systemName: cat?.icon ?? "tag.fill")
                                                .foregroundStyle(cat?.color ?? .gray)
                                                .font(.subheadline)
                                        }

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.note.isEmpty ? (cat?.name ?? "Expense") : item.note)
                                                .font(.subheadline.weight(.semibold))
                                            Text("\(cat?.name ?? "Uncategorized") • \(item.paymentMethod)")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }

                                        Spacer()

                                        VStack(alignment: .trailing, spacing: 2) {
                                            Text(item.formattedZAR)
                                                .font(.subheadline.weight(.bold))
                                            Text(item.spentDate.formatted(date: .numeric, time: .shortened))
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                    .background(Color(.systemBackground))
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            deleteExpense(item)
                                        } label: {
                                            Label("Delete", systemImage: "trash.fill")
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.bottom, 80)
                }

                // Floating Undo Bar
                if showingUndoBar, let deleted = lastDeletedExpense {
                    HStack(spacing: 12) {
                        Image(systemName: "trash.fill")
                            .foregroundStyle(.red)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Deleted \(deleted.formattedZAR)")
                                .font(.subheadline.weight(.semibold))
                            Text(deleted.note.isEmpty ? "Expense" : deleted.note)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button {
                            undoDelete(deleted)
                        } label: {
                            Text("UNDO")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(Color.accentColor)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(Color.accentColor.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("SyncSpend")
            .sheet(isPresented: $showingAddCategory) {
                AddCategorySheet {
                    Task { await loadCategories() }
                }
            }
            .task {
                try? await service.ensureIdentity()
                await refreshAll()
            }
        }
    }

    private var canSubmit: Bool {
        parsedCents > 0 && selectedCategoryId != nil
    }

    private func categoryFor(id: UInt64) -> CategoryItem? {
        categories.first(where: { $0.id == id })
    }

    private func submitExpense() {
        guard let catId = selectedCategoryId, parsedCents > 0 else { return }
        isSubmitting = true
        errorMessage = nil
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        Task {
            do {
                let currentCategory = categoryFor(id: catId)
                let noteText = note.trimmingCharacters(in: .whitespaces).isEmpty
                    ? (currentCategory?.name ?? "Expense")
                    : note.trimmingCharacters(in: .whitespaces)

                try await service.logExpense(
                    amountCents: parsedCents,
                    currency: "ZAR",
                    categoryId: catId,
                    paymentMethod: selectedPaymentMethod,
                    note: noteText,
                    spentDate: spentDate
                )
                amountInput = ""
                note = ""
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                await loadRecent()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSubmitting = false
        }
    }

    private func deleteExpense(_ item: ExpenseItem) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation {
            recentExpenses.removeAll(where: { $0.id == item.id })
            lastDeletedExpense = item
            showingUndoBar = true
        }

        undoTimer?.invalidate()
        undoTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
            withAnimation {
                showingUndoBar = false
                lastDeletedExpense = nil
            }
        }

        Task {
            do {
                try await service.softDeleteExpense(expenseId: item.id)
            } catch {
                print("Failed to soft delete: \(error)")
                await loadRecent()
            }
        }
    }

    private func undoDelete(_ item: ExpenseItem) {
        undoTimer?.invalidate()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        withAnimation {
            showingUndoBar = false
        }

        Task {
            do {
                try await service.restoreExpense(expenseId: item.id)
                await loadRecent()
            } catch {
                print("Failed to restore expense: \(error)")
            }
        }
    }

    private func refreshAll() async {
        await loadCategories()
        await loadRecent()
    }

    private func loadCategories() async {
        do {
            var fetched = try await service.fetchCategories()
            if fetched.isEmpty {
                try await service.initializeUserProfile()
                fetched = try await service.fetchCategories()
            }
            categories = fetched
            if selectedCategoryId == nil || !categories.contains(where: { $0.id == selectedCategoryId }) {
                selectedCategoryId = categories.first?.id
            }
        } catch {
            print("Failed to load categories: \(error)")
        }
    }

    private func loadRecent() async {
        do {
            recentExpenses = try await service.fetchRecentExpenses()
        } catch {
            print("Failed to fetch recent expenses: \(error)")
        }
    }
}
