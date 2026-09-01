import SwiftUI

public struct LoginView: View {
    @State private var authService = AuthService.shared
    @State private var showingErrorAlert = false
    @State private var isGuestLoading = false
    
    public var onGuestLogin: (() -> Void)?
    
    public init(onGuestLogin: (() -> Void)? = nil) {
        self.onGuestLogin = onGuestLogin
    }
    
    public var body: some View {
        ZStack {
            // Background Theme
            Theme.appBackground
                .ignoresSafeArea()
            
            // Subtle Ambient Glows
            VStack {
                Circle()
                    .fill(Color.purple.opacity(0.12))
                    .frame(width: 320, height: 320)
                    .blur(radius: 80)
                    .offset(x: -80, y: -100)
                
                Spacer()
                
                Circle()
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 320, height: 320)
                    .blur(radius: 80)
                    .offset(x: 80, y: 100)
            }
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Hero Branding Section
                VStack(spacing: 16) {
                    ZStack {
                        // Cosmic glowing backdrop
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.9), Color.cyan.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 88, height: 88)
                            .shadow(color: Color.blue.opacity(0.35), radius: 20, x: 0, y: 10)
                        
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .padding(.bottom, 8)
                    
                    VStack(spacing: 6) {
                        Text("SyncSpend")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.primaryDark)
                        
                        Text("Shared finances for modern couples")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Theme.mutedText)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Feature Highlights List
                VStack(spacing: 14) {
                    FeatureRow(
                        icon: "bolt.shield.fill",
                        iconColor: .purple,
                        title: "Real-Time Couple Sync",
                        subtitle: "Instant updates powered by SpacetimeDB Maincloud"
                    )
                    
                    FeatureRow(
                        icon: "percent",
                        iconColor: .blue,
                        title: "Smart Split Ratios",
                        subtitle: "50/50, proportional by income, or custom splits"
                    )
                    
                    FeatureRow(
                        icon: "lock.fill",
                        iconColor: .green,
                        title: "End-to-End Privacy",
                        subtitle: "Server-side row level security isolates personal spending"
                    )
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    if let error = authService.errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            Text(error)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.red)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .padding(.bottom, 4)
                    }
                    
                    // Primary Sign In with SpacetimeAuth
                    Button {
                        Haptics.impact(.medium)
                        Task {
                            do {
                                try await authService.loginWithSpacetimeAuth()
                                try await SpacetimeService.shared.initializeUserProfile()
                            } catch {
                                showingErrorAlert = true
                            }
                        }
                    } label: {
                        HStack(spacing: 10) {
                            if authService.isLoading {
                                ProgressView()
                                    .tint(Theme.buttonForeground)
                            } else {
                                Image(systemName: "person.badge.key.fill")
                                    .font(.system(size: 17, weight: .semibold))
                                Text("Sign In with SpacetimeAuth")
                                    .font(.system(size: 16, weight: .bold))
                            }
                        }
                        .foregroundStyle(Theme.buttonForeground)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Theme.buttonDark)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.buttonCornerRadius, style: .continuous))
                        .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 4)
                    }
                    .disabled(authService.isLoading || isGuestLoading)
                    
                    // Secondary Guest Mode / Demo Access
                    Button {
                        Haptics.selection()
                        isGuestLoading = true
                        Task {
                            do {
                                try await SpacetimeService.shared.ensureIdentity()
                                try await SpacetimeService.shared.initializeUserProfile(displayName: "Guest User")
                                await MainActor.run {
                                    authService.isAuthenticated = true
                                    isGuestLoading = false
                                    onGuestLogin?()
                                }
                            } catch {
                                await MainActor.run {
                                    isGuestLoading = false
                                }
                            }
                        }
                    } label: {
                        HStack {
                            if isGuestLoading {
                                ProgressView()
                                    .tint(Theme.primaryDark)
                            } else {
                                Text("Explore as Guest")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(Theme.primaryDark)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Theme.chipBackground)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.buttonCornerRadius, style: .continuous))
                    }
                    .disabled(authService.isLoading || isGuestLoading)
                    
                    // Terms & Privacy Note
                    Text("By continuing, you agree to Tandem / SyncSpend's Security & Privacy policies.")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(Theme.mutedText)
                        .multilineTextAlignment(.center)
                        .padding(.top, 6)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
        }
    }
}

private struct FeatureRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.primaryDark)
                
                Text(subtitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Theme.mutedText)
            }
            
            Spacer()
        }
        .padding(14)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Theme.cardBorder, lineWidth: 1)
        )
    }
}
