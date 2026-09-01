import SwiftUI
import UniformTypeIdentifiers

public struct AccountsSheet: View {
    @Binding public var accounts: [AccountItem]
    @Binding public var activeAccountId: String
    public let currency: CurrencyItem
    public let onAddAccount: (String) -> Void
    public let onDeleteAccount: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var authService = AuthService.shared
    @State private var isEditing: Bool = false
    @State private var showingAddAlert: Bool = false
    @State private var showingSignOutAlert: Bool = false
    @State private var newAccountName: String = ""
    @State private var draggedAccountId: String? = nil
    
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
                .fill(Theme.cardBorder)
                .frame(width: 36, height: 4)
                .padding(.top, 8)
            
            // Header Bar
            HStack {
                if isEditing {
                    Button("Cancel") {
                        Haptics.selection()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isEditing = false
                        }
                    }
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(Theme.accentBlue)
                    .buttonStyle(.plain)
                } else {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Theme.primaryDark)
                            .frame(width: 32, height: 32)
                            .background(Theme.chipBackground)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
                
                Text("Accounts")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Theme.primaryDark)
                
                Spacer()
                
                Button(isEditing ? "Done" : "Edit") {
                    Haptics.selection()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isEditing.toggle()
                    }
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.accentBlue)
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            
            // Accounts List
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(Array(accounts.enumerated()), id: \.element.id) { index, acc in
                        let isSelected = activeAccountId == acc.id
                        
                        HStack(spacing: 14) {
                            if isEditing {
                                Button {
                                    Haptics.impact(.medium)
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        onDeleteAccount(acc.id)
                                    }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 22))
                                        .foregroundStyle(Theme.accentRed)
                                }
                                .buttonStyle(.plain)
                                .transition(.scale.combined(with: .opacity))
                            }
                            
                            // Icon Avatar Badge
                            ZStack {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Theme.chipBackground)
                                    .frame(width: 40, height: 40)
                                
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
                                    .frame(width: 32, height: 32)
                                    .contentShape(Rectangle())
                            } else if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(Theme.accentBlue)
                            }
                        }
                        .padding(14)
                        .background(Theme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(isSelected && !isEditing ? Theme.accentBlue.opacity(0.8) : Theme.cardBorder, lineWidth: isSelected && !isEditing ? 1.5 : 1)
                        )
                        .opacity(draggedAccountId == acc.id ? 0.4 : 1.0)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if !isEditing {
                                Haptics.selection()
                                activeAccountId = acc.id
                                dismiss()
                            }
                        }
                        .onDrag {
                            guard isEditing else { return NSItemProvider() }
                            self.draggedAccountId = acc.id
                            return NSItemProvider(object: acc.id as NSString)
                        }
                        .onDrop(of: [.text], delegate: AccountDropDelegate(
                            item: acc,
                            list: $accounts,
                            current: $draggedAccountId
                        ))
                    }
                    
                    // Add Account Button
                    Button {
                        Haptics.impact(.light)
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
                        .background(Theme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(Theme.cardBorder, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    
                    // Active Session & Logout Card
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 38, height: 38)
                                
                                Text(String((authService.currentUserName ?? "U").prefix(1)).uppercased())
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(authService.currentUserName ?? "User Profile")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Theme.primaryDark)
                                
                                Text(authService.currentUserEmail ?? (authService.currentUserIdentity != nil ? "Authenticated" : "Guest Mode"))
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundStyle(Theme.mutedText)
                            }
                            
                            Spacer()
                            
                            Button("Log Out") {
                                showingSignOutAlert = true
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.accentRed)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Theme.accentRed.opacity(0.1))
                            .clipShape(Capsule())
                        }
                        .padding(14)
                        .background(Theme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(Theme.cardBorder, lineWidth: 1)
                        )
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 16)
            }
        }
        .background(Theme.appBackground)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .alert("New Account", isPresented: $showingAddAlert) {
            TextField("Account Name (e.g. Travel)", text: $newAccountName)
            Button("Cancel", role: .cancel) { newAccountName = "" }
            Button("Create") {
                Haptics.notification(.success)
                onAddAccount(newAccountName)
                newAccountName = ""
            }
        }
        .alert("Sign Out", isPresented: $showingSignOutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) {
                Haptics.impact(.medium)
                authService.logout()
                dismiss()
            }
        } message: {
            Text("Are you sure you want to sign out? Your active session will end.")
        }
    }
}

struct AccountDropDelegate: DropDelegate {
    let item: AccountItem
    @Binding var list: [AccountItem]
    @Binding var current: String?
    
    func dropEntered(info: DropInfo) {
        guard let current = current, current != item.id else { return }
        guard let fromIndex = list.firstIndex(where: { $0.id == current }),
              let toIndex = list.firstIndex(where: { $0.id == item.id }) else { return }
        
        if list[toIndex].id != current {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                let moved = list.remove(at: fromIndex)
                list.insert(moved, at: toIndex)
                Haptics.selection()
            }
        }
    }
    
    func performDrop(info: DropInfo) -> Bool {
        self.current = nil
        return true
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}
