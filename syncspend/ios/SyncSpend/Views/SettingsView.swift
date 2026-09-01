import SwiftUI

public struct SettingsView: View {
    @Binding public var currency: CurrencyItem
    @Binding public var startWeekOn: String
    @Binding public var smartSuggestionsEnabled: Bool
    public let accountName: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var viewModel = SettingsViewModel()
    @State private var showingProModal: Bool = false
    @State private var showingCurrencySheet: Bool = false
    
    public init(
        currency: Binding<CurrencyItem>,
        startWeekOn: Binding<String>,
        smartSuggestionsEnabled: Binding<Bool>,
        accountName: String
    ) {
        self._currency = currency
        self._startWeekOn = startWeekOn
        self._smartSuggestionsEnabled = smartSuggestionsEnabled
        self.accountName = accountName
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Pro Cosmic Banner
                    Button {
                        showingProModal = true
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("SyncSpend Pro")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(.white)
                                
                                Text("7 days left in trial")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundStyle(Color.white.opacity(0.7))
                            }
                            
                            Spacer()
                            
                            Text("Upgrade")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Theme.primaryDark)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.white)
                                .clipShape(Capsule())
                                .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 3)
                        }
                        .padding(20)
                        .background(
                            ZStack {
                                Color.black
                                RadialGradient(
                                    gradient: Gradient(colors: [Color.purple.opacity(0.35), Color.clear]),
                                    center: .topTrailing,
                                    startRadius: 20,
                                    endRadius: 200
                                )
                                RadialGradient(
                                    gradient: Gradient(colors: [Color.blue.opacity(0.25), Color.clear]),
                                    center: .bottomLeading,
                                    startRadius: 20,
                                    endRadius: 200
                                )
                            }
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                    
                    // Account Info Card
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.06))
                                .frame(width: 48, height: 48)
                            
                            Text(String(accountName.prefix(1)))
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(Theme.primaryDark)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(accountName)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Theme.primaryDark)
                            
                            Text("Account info, categories and payments")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundStyle(Theme.mutedText)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.mutedText)
                    }
                    .padding(16)
                    .background(Theme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous)
                            .strokeBorder(Theme.cardBorder, lineWidth: 1)
                    )
                    
                    // Preferences Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("PREFERENCES")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.mutedText)
                            .padding(.horizontal, 4)
                        
                        VStack(spacing: 0) {
                            // Currency Row
                            Button {
                                showingCurrencySheet = true
                            } label: {
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .fill(Color.black.opacity(0.05))
                                            .frame(width: 32, height: 32)
                                        Image(systemName: "dollarsign")
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundStyle(Theme.primaryDark)
                                    }
                                    
                                    Text("Currency")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(Theme.primaryDark)
                                    
                                    Spacer()
                                    
                                    Text(currency.code)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(Theme.mutedText)
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(Theme.mutedText)
                                }
                                .padding(16)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            
                            Divider().padding(.leading, 56)
                            
                            // Start Week On Row
                            Button {
                                startWeekOn = startWeekOn == "Sunday" ? "Monday" : "Sunday"
                            } label: {
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .fill(Color.black.opacity(0.05))
                                            .frame(width: 32, height: 32)
                                        Image(systemName: "calendar")
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundStyle(Theme.primaryDark)
                                    }
                                    
                                    Text("Start Week On")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(Theme.primaryDark)
                                    
                                    Spacer()
                                    
                                    Text(startWeekOn)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(Theme.mutedText)
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(Theme.mutedText)
                                }
                                .padding(16)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            
                            Divider().padding(.leading, 56)
                            
                            // Smart Suggestions Toggle Row
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(Color.black.opacity(0.05))
                                        .frame(width: 32, height: 32)
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundStyle(Theme.primaryDark)
                                }
                                
                                Text("Smart Suggestions")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(Theme.primaryDark)
                                
                                Spacer()
                                
                                Toggle("", isOn: $smartSuggestionsEnabled)
                                    .labelsHidden()
                                    .tint(Theme.primaryDark)
                            }
                            .padding(16)
                        }
                        .background(Theme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous)
                                .strokeBorder(Theme.cardBorder, lineWidth: 1)
                        )
                    }
                    
                    // Server Configuration
                    VStack(alignment: .leading, spacing: 8) {
                        Text("SPACETIMEDB SERVER")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.mutedText)
                            .padding(.horizontal, 4)
                        
                        VStack(spacing: 12) {
                            HStack {
                                Text("Host URL")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Theme.primaryDark)
                                Spacer()
                                TextField("Host URL", text: $viewModel.hostURL)
                                    .font(.system(size: 13, design: .monospaced))
                                    .multilineTextAlignment(.trailing)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                            }
                            
                            Divider()
                            
                            HStack {
                                Text("Database")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Theme.primaryDark)
                                Spacer()
                                TextField("Database Name", text: $viewModel.databaseName)
                                    .font(.system(size: 13, design: .monospaced))
                                    .multilineTextAlignment(.trailing)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                            }
                        }
                        .padding(16)
                        .background(Theme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous)
                                .strokeBorder(Theme.cardBorder, lineWidth: 1)
                        )
                    }
                    
                    // App Version Footer
                    Text("SyncSpend iOS 2.4.1 (Build 2026)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.mutedText)
                        .padding(.top, 8)
                }
                .padding(16)
            }
            .background(Theme.appBackground)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 32, height: 32)
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Theme.primaryDark)
                        }
                        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
                    }
                }
            }
            .sheet(isPresented: $showingProModal) {
                ProUpgradeModal()
            }
            .sheet(isPresented: $showingCurrencySheet) {
                NavigationStack {
                    List(CurrencyItem.allCurrencies) { item in
                        Button {
                            currency = item
                            showingCurrencySheet = false
                        } label: {
                            HStack {
                                Text(item.name)
                                    .font(.system(size: 15, weight: currency.code == item.code ? .semibold : .regular))
                                    .foregroundStyle(Theme.primaryDark)
                                Spacer()
                                if currency.code == item.code {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(Theme.primaryDark)
                                }
                            }
                        }
                    }
                    .navigationTitle("Select Currency")
                    .navigationBarTitleDisplayMode(.inline)
                }
                .presentationDetents([.medium])
            }
        }
    }
}
