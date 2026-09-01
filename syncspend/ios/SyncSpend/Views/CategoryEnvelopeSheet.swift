import SwiftUI

public struct CategoryEnvelopeSheet: View {
    public enum Mode {
        case create
        case edit(CategoryItem)
        
        var title: String {
            switch self {
            case .create: return "New Envelope"
            case .edit: return "Edit Envelope"
            }
        }
        
        var actionButtonTitle: String {
            switch self {
            case .create: return "Create Envelope"
            case .edit: return "Save Changes"
            }
        }
    }
    
    @Environment(\.dismiss) private var dismiss
    private var service = SpacetimeService.shared
    
    public let mode: Mode
    public let currency: CurrencyItem
    public var onSaved: () -> Void
    
    @State private var name: String = ""
    @State private var selectedIcon: String = "cart.fill"
    @State private var selectedColorHex: String = "#3B82F6"
    @State private var budgetInput: String = ""
    @State private var isSubmitting: Bool = false
    @State private var showingArchiveAlert: Bool = false
    @State private var errorMessage: String?
    
    public init(
        mode: Mode = .create,
        currency: CurrencyItem = CurrencyItem.defaultCurrency,
        onSaved: @escaping () -> Void
    ) {
        self.mode = mode
        self.currency = currency
        self.onSaved = onSaved
    }
    
    let availableIcons = [
        "cart.fill", "cup.and.saucer.fill", "fuelpump.fill", "bolt.fill",
        "sparkles", "gift.fill", "airplane", "car.fill", "house.fill",
        "film.fill", "gamecontroller.fill", "cross.case.fill", "book.fill",
        "bag.fill", "tag.fill", "fork.knife", "creditcard.fill", "heart.fill",
        "tshirt.fill", "figure.run", "tram.fill", "laptopcomputer"
    ]
    
    let availableColors = [
        "#10B981", // Emerald
        "#3B82F6", // Blue
        "#8B5CF6", // Purple
        "#EC4899", // Pink
        "#F59E0B", // Amber
        "#EF4444", // Red
        "#06B6D4", // Cyan
        "#6366F1", // Indigo
        "#84CC16", // Lime
        "#64748B"  // Slate
    ]
    
    private var parsedBudgetCents: Int64? {
        let clean = budgetInput
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: ",", with: ".")
        guard !clean.isEmpty, let rands = Double(clean), rands > 0 else {
            return nil
        }
        return Int64(round(rands * 100.0))
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Preview Squircle
                    VStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill((Color(hex: selectedColorHex) ?? Theme.accentBlue).opacity(0.18))
                                .frame(width: 72, height: 72)
                            
                            Image(systemName: selectedIcon)
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(Color(hex: selectedColorHex) ?? Theme.accentBlue)
                        }
                        
                        Text(name.isEmpty ? "Envelope Name" : name)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Theme.primaryDark)
                        
                        if let budget = parsedBudgetCents {
                            let rands = Double(budget) / 100.0
                            Text("Monthly Budget: \(currency.symbol) \(String(format: "%.0f", rands))")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Theme.accentGreen)
                        } else {
                            Text("Flexible Envelope (No Limit)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Theme.mutedText)
                        }
                    }
                    .padding(.top, 8)
                    
                    // Name & Budget Input Card
                    VStack(spacing: 0) {
                        // Envelope Name
                        VStack(alignment: .leading, spacing: 6) {
                            Text("ENVELOPE NAME")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Theme.mutedText)
                            
                            TextField("e.g. Groceries, Coffee, Rent", text: $name)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(Theme.primaryDark)
                        }
                        .padding(16)
                        
                        Divider()
                            .padding(.leading, 16)
                        
                        // Monthly Budget Cap
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("MONTHLY BUDGET CAP")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(Theme.mutedText)
                                Spacer()
                                Text("Optional")
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundStyle(Theme.mutedText)
                            }
                            
                            HStack(spacing: 6) {
                                Text(currency.symbol)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(Theme.mutedText)
                                
                                TextField("e.g. 5000", text: $budgetInput)
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .keyboardType(.decimalPad)
                                    .foregroundStyle(Theme.primaryDark)
                            }
                        }
                        .padding(16)
                    }
                    .background(Theme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous)
                            .strokeBorder(Theme.cardBorder, lineWidth: 1)
                    )
                    
                    // Icon Picker Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("SELECT ICON")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Theme.mutedText)
                            .padding(.horizontal, 4)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 6), spacing: 12) {
                            ForEach(availableIcons, id: \.self) { icon in
                                let isSelected = selectedIcon == icon
                                let accentCol = Color(hex: selectedColorHex) ?? Theme.accentBlue
                                
                                Button {
                                    Haptics.impact(.light)
                                    selectedIcon = icon
                                } label: {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(isSelected ? accentCol : Theme.tertiaryBackground)
                                            .frame(height: 44)
                                        
                                        Image(systemName: icon)
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundStyle(isSelected ? .white : Theme.primaryDark)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(16)
                    .background(Theme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous)
                            .strokeBorder(Theme.cardBorder, lineWidth: 1)
                    )
                    
                    // Color Picker Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("SELECT COLOR")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Theme.mutedText)
                            .padding(.horizontal, 4)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 12) {
                            ForEach(availableColors, id: \.self) { colorHex in
                                let isSelected = selectedColorHex == colorHex
                                let col = Color(hex: colorHex) ?? .blue
                                
                                Button {
                                    Haptics.impact(.light)
                                    selectedColorHex = colorHex
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(col)
                                            .frame(width: 42, height: 42)
                                        
                                        if isSelected {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundStyle(.white)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(16)
                    .background(Theme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous)
                            .strokeBorder(Theme.cardBorder, lineWidth: 1)
                    )
                    
                    if let err = errorMessage {
                        Text(err)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Theme.accentRed)
                    }
                    
                    // Primary Action Button
                    Button {
                        save()
                    } label: {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .tint(Theme.buttonForeground)
                                    .padding(.trailing, 6)
                            }
                            Text(mode.actionButtonTitle)
                                .font(.system(size: 16, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(name.trimmingCharacters(in: .whitespaces).isEmpty ? Theme.primaryDark.opacity(0.4) : Theme.primaryDark)
                        .foregroundStyle(Theme.buttonForeground)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.buttonCornerRadius, style: .continuous))
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isSubmitting)
                    
                    // Archive Button for Edit Mode
                    if case .edit = mode {
                        Button {
                            showingArchiveAlert = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "archivebox.fill")
                                    .font(.system(size: 14))
                                Text("Archive Envelope")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundStyle(Theme.accentRed)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                        }
                    }
                }
                .padding(16)
            }
            .background(Theme.appBackground)
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(Theme.accentBlue)
                }
            }
            .alert("Archive Envelope?", isPresented: $showingArchiveAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Archive", role: .destructive) {
                    archive()
                }
            } message: {
                Text("This envelope will be hidden from your active dashboard. Existing transactions will remain intact.")
            }
            .onAppear {
                if case .edit(let category) = mode {
                    name = category.name
                    selectedIcon = category.icon
                    selectedColorHex = category.colorHex
                    if let budget = category.monthlyBudgetCents {
                        let rands = Double(budget) / 100.0
                        budgetInput = String(format: "%.0f", rands)
                    }
                }
            }
        }
    }
    
    private func save() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        Haptics.impact(.medium)
        isSubmitting = true
        errorMessage = nil
        
        Task {
            do {
                switch mode {
                case .create:
                    try await service.createCategory(
                        name: name.trimmingCharacters(in: .whitespaces),
                        icon: selectedIcon,
                        colorHex: selectedColorHex,
                        monthlyBudgetCents: parsedBudgetCents
                    )
                case .edit(let category):
                    try await service.updateCategory(
                        categoryId: category.id,
                        name: name.trimmingCharacters(in: .whitespaces),
                        icon: selectedIcon,
                        colorHex: selectedColorHex,
                        monthlyBudgetCents: parsedBudgetCents
                    )
                }
                Haptics.notification(.success)
                onSaved()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                isSubmitting = false
                Haptics.notification(.error)
            }
        }
    }
    
    private func archive() {
        guard case .edit(let category) = mode else { return }
        Haptics.impact(.medium)
        isSubmitting = true
        
        Task {
            do {
                try await service.archiveCategory(categoryId: category.id)
                Haptics.notification(.success)
                onSaved()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                isSubmitting = false
                Haptics.notification(.error)
            }
        }
    }
}
