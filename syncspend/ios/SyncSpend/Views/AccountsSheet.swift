import SwiftUI

public struct AccountsSheet: View {
    @Binding public var accounts: [AccountItem]
    @Binding public var activeAccountId: String
    public let currency: CurrencyItem
    public let onAddAccount: (String) -> Void
    public let onDeleteAccount: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var isEditing: Bool = false
    @State private var showingAddAlert: Bool = false
    @State private var newAccountName: String = ""
    
    public init(
        accounts: Binding<[AccountItem]>,
        activeAccountId: Binding<String>,
        currency: CurrencyItem,
        onAddAccount: @escaping (String) -> Void,
        onDeleteAccount: @escaping (String) -> Void
    ) {
        self._accounts = accounts
        self._activeAccountId = activeAccountId
        self.currency = currency
        self.onAddAccount = onAddAccount
        self.onDeleteAccount = onDeleteAccount
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            // Drag Indicator
            Capsule()
                .fill(Color.black.opacity(0.15))
                .frame(width: 36, height: 4)
                .padding(.top, 8)
            
            // Header
            HStack {
                if isEditing {
                    Button("Cancel") {
                        withAnimation { isEditing = false }
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.primaryDark)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.06))
                    .clipShape(Capsule())
                } else {
                    Button {
                        dismiss()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.06))
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Theme.primaryDark)
                        }
                    }
                }
                
                Spacer()
                
                Text("Accounts")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.primaryDark)
                
                Spacer()
                
                Button(isEditing ? "Done" : "Edit") {
                    withAnimation { isEditing.toggle() }
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.primaryDark)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.06))
                .clipShape(Capsule())
            }
            .padding(.horizontal, 8)
            
            // Accounts List
            VStack(spacing: 10) {
                ForEach(accounts) { acc in
                    let isSelected = activeAccountId == acc.id
                    
                    HStack(spacing: 14) {
                        if isEditing {
                            Button {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                onDeleteAccount(acc.id)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundStyle(Theme.accentRed)
                            }
                            .transition(.scale)
                        }
                        
                        // Icon Avatar Badge
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.white)
                                .frame(width: 40, height: 40)
                                .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
                            
                            Image(systemName: acc.icon)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Theme.primaryDark)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(acc.name)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Theme.primaryDark)
                            
                            Text(currency.format(cents: acc.balanceCents))
                                .font(.system(size: 12, weight: .regular))
                                .foregroundStyle(Theme.mutedText)
                        }
                        
                        Spacer()
                        
                        if isEditing {
                            Image(systemName: "line.3.horizontal")
                                .font(.system(size: 16))
                                .foregroundStyle(Theme.mutedText)
                        } else if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(Theme.primaryDark)
                        }
                    }
                    .padding(14)
                    .background(Color.black.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(isSelected && !isEditing ? Color.black.opacity(0.12) : Color.clear, lineWidth: 1.5)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if !isEditing {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            activeAccountId = acc.id
                            dismiss()
                        }
                    }
                }
                
                // Add Account Button
                Button {
                    showingAddAlert = true
                } label: {
                    HStack {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Add Account")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(Theme.primaryDark)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color.black.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(Theme.appBackground)
        .presentationDetents([.medium, .large])
        .alert("New Account", isPresented: $showingAddAlert) {
            TextField("Account Name (e.g. Travel)", text: $newAccountName)
            Button("Cancel", role: .cancel) { newAccountName = "" }
            Button("Create") {
                onAddAccount(newAccountName)
                newAccountName = ""
            }
        }
    }
}
