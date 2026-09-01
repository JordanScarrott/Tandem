import SwiftUI

public struct CategoryPickerSheet: View {
    public let categories: [CategoryItem]
    @Binding public var selectedCategoryId: UInt64?
    public let onAddNewCategory: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    public init(
        categories: [CategoryItem],
        selectedCategoryId: Binding<UInt64?>,
        onAddNewCategory: @escaping () -> Void
    ) {
        self.categories = categories
        self._selectedCategoryId = selectedCategoryId
        self.onAddNewCategory = onAddNewCategory
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Select Category")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Theme.primaryDark)
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Theme.chipBackground)
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Theme.primaryDark)
                    }
                }
            }
            .padding(16)
            
            Divider()
            
            // Category List
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(categories) { cat in
                        let isSelected = selectedCategoryId == cat.id
                        
                        Button {
                            Haptics.impact(.light)
                            selectedCategoryId = cat.id
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(cat.color.opacity(0.15))
                                        .frame(width: 32, height: 32)
                                    
                                    Image(systemName: cat.icon)
                                        .font(.system(size: 15))
                                        .foregroundStyle(cat.color)
                                }
                                
                                Text(cat.name)
                                    .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                                    .foregroundStyle(Theme.primaryDark)
                                
                                Spacer()
                                
                                if isSelected {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(Theme.accentBlue)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        
                        Divider()
                            .padding(.leading, 60)
                    }
                    
                    // Add Category Action Row
                    Button {
                        dismiss()
                        onAddNewCategory()
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Theme.chipBackground)
                                    .frame(width: 32, height: 32)
                                
                                Image(systemName: "plus")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(Theme.primaryDark)
                            }
                            
                            Text("New Category")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Theme.primaryDark)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

