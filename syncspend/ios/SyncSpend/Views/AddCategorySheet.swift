import SwiftUI

public struct AddCategorySheet: View {
    @Environment(\.dismiss) private var dismiss
    private var service = SpacetimeService.shared

    @State private var name: String = ""
    @State private var selectedIcon: String = "tag.fill"
    @State private var selectedColorHex: String = "#3B82F6"
    @State private var budgetInput: String = ""
    @State private var isSubmitting: Bool = false
    @State private var errorMessage: String?

    var onCategoryCreated: () -> Void

    public init(onCategoryCreated: @escaping () -> Void) {
        self.onCategoryCreated = onCategoryCreated
    }

    let availableIcons = [
        "cart.fill", "cup.and.saucer.fill", "fuelpump.fill", "bolt.fill",
        "sparkles", "gift.fill", "airplane", "car.fill", "house.fill",
        "film.fill", "gamecontroller.fill", "cross.case.fill", "book.fill",
        "bag.fill", "tag.fill", "fork.knife", "creditcard.fill"
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
        guard !budgetInput.trimmingCharacters(in: .whitespaces).isEmpty,
              let rands = Double(budgetInput.replacingOccurrences(of: ",", with: ".")) else {
            return nil
        }
        return Int64(round(rands * 100.0))
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("Category Details") {
                    TextField("Category Name", text: $name)
                        .autocorrectionDisabled()

                    HStack {
                        Text("Monthly Budget")
                        Spacer()
                        Text("R")
                            .foregroundStyle(.secondary)
                        TextField("Optional", text: $budgetInput)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 100)
                    }
                }

                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(availableIcons, id: \.self) { icon in
                            let isSelected = selectedIcon == icon
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                selectedIcon = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.title3)
                                    .frame(width: 44, height: 44)
                                    .background(isSelected ? Color(hex: selectedColorHex) ?? .accentColor : Color(.secondarySystemBackground))
                                    .foregroundStyle(isSelected ? .white : .primary)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(availableColors, id: \.self) { colorHex in
                            let isSelected = selectedColorHex == colorHex
                            let col = Color(hex: colorHex) ?? .blue
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                selectedColorHex = colorHex
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(col)
                                        .frame(width: 40, height: 40)
                                    if isSelected {
                                        Image(systemName: "checkmark")
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(.white)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                if let err = errorMessage {
                    Section {
                        Text(err)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        saveCategory()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isSubmitting)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func saveCategory() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isSubmitting = true
        errorMessage = nil

        Task {
            do {
                try await service.createCategory(
                    name: name.trimmingCharacters(in: .whitespaces),
                    icon: selectedIcon,
                    colorHex: selectedColorHex,
                    monthlyBudgetCents: parsedBudgetCents
                )
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onCategoryCreated()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                isSubmitting = false
            }
        }
    }
}
