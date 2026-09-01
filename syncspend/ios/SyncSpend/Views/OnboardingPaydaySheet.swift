import SwiftUI

public struct OnboardingPaydaySheet: View {
    public var onCompleted: () -> Void
    
    @State private var displayName: String = ""
    @State private var selectedPayday: UInt8 = 25
    @State private var isSubmitting: Bool = false
    @State private var errorMessage: String?
    
    private let authService = AuthService.shared
    private let spacetimeService = SpacetimeService.shared
    
    public init(onCompleted: @escaping () -> Void) {
        self.onCompleted = onCompleted
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Emblem & Welcome
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue.opacity(0.85), Color.purple.opacity(0.85)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 64, height: 64)
                                .shadow(color: Color.purple.opacity(0.3), radius: 12, x: 0, y: 6)
                            
                            Image(systemName: "envelope.badge.shield.half.filled")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        .padding(.top, 8)
                        
                        Text("Welcome to Tandem")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(Theme.primaryDark)
                        
                        Text("Set your monthly payday anchor to start budgeting with zero-rollover category envelopes.")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(Theme.mutedText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }
                    
                    // Name Input Card
                    VStack(alignment: .leading, spacing: 8) {
                        Text("YOUR NAME")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Theme.mutedText)
                            .padding(.horizontal, 4)
                        
                        HStack(spacing: 12) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(Theme.mutedText)
                            
                            TextField("What should we call you?", text: $displayName)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Theme.primaryDark)
                                .autocorrectionDisabled()
                            
                            if !displayName.isEmpty {
                                Button {
                                    displayName = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(Theme.mutedText)
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
                    }
                    
                    // Payday Anchor Selector Card
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("PAYDAY ANCHOR")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Theme.mutedText)
                            
                            Spacer()
                            
                            Text("Every \(ordinal(Int(selectedPayday)))")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Theme.accentBlue)
                        }
                        .padding(.horizontal, 4)
                        
                        VStack(spacing: 14) {
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(Theme.accentBlue.opacity(0.12))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: "calendar")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(Theme.accentBlue)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Payday: \(ordinal(Int(selectedPayday))) of every month")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(Theme.primaryDark)
                                    Text("Envelopes reset cleanly on this day")
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundStyle(Theme.mutedText)
                                }
                                
                                Spacer()
                            }
                            
                            // Horizontal Day Pill Selector (1 to 28)
                            ScrollViewReader { proxy in
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(1...28, id: \.self) { day in
                                            let isSelected = selectedPayday == UInt8(day)
                                            Button {
                                                Haptics.selection()
                                                selectedPayday = UInt8(day)
                                            } label: {
                                                VStack(spacing: 2) {
                                                    Text("\(day)")
                                                        .font(.system(size: 16, weight: isSelected ? .bold : .medium))
                                                    Text(ordinalSuffix(day))
                                                        .font(.system(size: 9, weight: isSelected ? .semibold : .regular))
                                                }
                                                .frame(width: 44, height: 48)
                                                .background(isSelected ? Theme.primaryDark : Theme.tertiaryBackground)
                                                .foregroundStyle(isSelected ? Theme.buttonForeground : Theme.primaryDark)
                                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                        .strokeBorder(isSelected ? Color.clear : Theme.cardBorder, lineWidth: 1)
                                                )
                                            }
                                            .buttonStyle(.plain)
                                            .id(day)
                                        }
                                    }
                                    .padding(.vertical, 2)
                                }
                                .onAppear {
                                    proxy.scrollTo(Int(selectedPayday), anchor: .center)
                                }
                            }
                            
                            Text("Clamped between 1st and 28th to guarantee consistent monthly cycle calculations (including February).")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundStyle(Theme.mutedText)
                                .padding(.top, 2)
                        }
                        .padding(16)
                        .background(Theme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous)
                                .strokeBorder(Theme.cardBorder, lineWidth: 1)
                        )
                    }
                    
                    // Starter Envelopes Preview Card
                    VStack(alignment: .leading, spacing: 8) {
                        Text("STARTER ENVELOPES (AUTO-SEEDED)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Theme.mutedText)
                            .padding(.horizontal, 4)
                        
                        VStack(spacing: 8) {
                            StarterEnvelopeRow(icon: "cart.fill", name: "Groceries", budget: "R 6,000 / mo", color: "#10B981")
                            StarterEnvelopeRow(icon: "cup.and.saucer.fill", name: "Dining & Coffee", budget: "R 2,500 / mo", color: "#F59E0B")
                            StarterEnvelopeRow(icon: "fuelpump.fill", name: "Transport / Fuel", budget: "R 2,000 / mo", color: "#3B82F6")
                            StarterEnvelopeRow(icon: "bolt.fill", name: "Utilities", budget: "Flexible", color: "#8B5CF6")
                            StarterEnvelopeRow(icon: "sparkles", name: "Personal Fun", budget: "R 1,500 / mo", color: "#EC4899")
                        }
                        .padding(16)
                        .background(Theme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous)
                                .strokeBorder(Theme.cardBorder, lineWidth: 1)
                        )
                    }
                    
                    if let err = errorMessage {
                        Text(err)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Theme.accentRed)
                            .padding(.horizontal)
                    }
                    
                    // Action CTAs
                    VStack(spacing: 12) {
                        Button {
                            submitOnboarding(isSkip: false)
                        } label: {
                            HStack {
                                if isSubmitting {
                                    ProgressView()
                                        .tint(Theme.buttonForeground)
                                        .padding(.trailing, 6)
                                }
                                Text("Start Budgeting")
                                    .font(.system(size: 16, weight: .bold))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Theme.primaryDark)
                            .foregroundStyle(Theme.buttonForeground)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.buttonCornerRadius, style: .continuous))
                        }
                        .disabled(isSubmitting)
                        
                        Button {
                            submitOnboarding(isSkip: true)
                        } label: {
                            Text("Skip for now (Default to 1st)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Theme.mutedText)
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                        }
                        .disabled(isSubmitting)
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            .background(Theme.appBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled(true)
            .onAppear {
                if let name = authService.currentUserName, !name.isEmpty {
                    displayName = name
                }
            }
        }
    }
    
    private func submitOnboarding(isSkip: Bool) {
        Haptics.impact(.medium)
        isSubmitting = true
        errorMessage = nil
        
        let finalName: String
        let finalDay: UInt8
        
        if isSkip {
            finalName = "You"
            finalDay = 1
        } else {
            let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
            finalName = trimmed.isEmpty ? (authService.currentUserName ?? "You") : trimmed
            finalDay = selectedPayday
        }
        
        Task {
            do {
                try await spacetimeService.initializeUserProfile(
                    displayName: finalName,
                    defaultCurrency: "ZAR",
                    billingCycleStartDay: finalDay
                )
                // If the profile was previously seeded, update it to reflect the chosen values
                try? await spacetimeService.updateUserProfile(
                    displayName: finalName,
                    billingCycleStartDay: finalDay
                )
                
                await MainActor.run {
                    isSubmitting = false
                    Haptics.notification(.success)
                    onCompleted()
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = "Failed to initialize profile: \(error.localizedDescription)"
                    Haptics.notification(.error)
                }
            }
        }
    }
    
    private func ordinal(_ n: Int) -> String {
        "\(n)\(ordinalSuffix(n))"
    }
    
    private func ordinalSuffix(_ n: Int) -> String {
        let ones = n % 10
        let tens = (n / 10) % 10
        if tens == 1 {
            return "th"
        }
        switch ones {
        case 1: return "st"
        case 2: return "nd"
        case 3: return "rd"
        default: return "th"
        }
    }
}

private struct StarterEnvelopeRow: View {
    let icon: String
    let name: String
    let budget: String
    let color: String
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill((Color(hex: color) ?? .blue).opacity(0.15))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(hex: color) ?? .blue)
            }
            
            Text(name)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.primaryDark)
            
            Spacer()
            
            Text(budget)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.mutedText)
        }
    }
}
