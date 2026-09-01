import SwiftUI

public struct ProUpgradeModal: View {
    @Environment(\.dismiss) private var dismiss
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 54, height: 54)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 26))
                    .foregroundStyle(.orange)
            }
            .padding(.top, 8)
            
            VStack(spacing: 6) {
                Text("SyncSpend Pro")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                
                Text("Unlimited cloud sync, smart receipt OCR scan, multi-currency exports, and recurring budgets.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            
            VStack(alignment: .leading, spacing: 14) {
                FeatureRow(icon: "checkmark.circle.fill", text: "Real-time multi-device sync")
                FeatureRow(icon: "checkmark.circle.fill", text: "Unlimited custom categories")
                FeatureRow(icon: "checkmark.circle.fill", text: "CSV and PDF tax export")
            }
            .padding(.vertical, 8)
            
            Button {
                Haptics.notification(.success)
                dismiss()
            } label: {
                Text("Start 7-Day Free Trial")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            
            Button("Maybe Later") {
                dismiss()
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(Color.white.opacity(0.6))
        }
        .padding(24)
        .background(Color(hex: "#1C1C1E") ?? Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .presentationDetents([.fraction(0.65), .medium])
        .presentationDragIndicator(.visible)
    }
}


private struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Theme.accentGreen)
            
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.9))
        }
    }
}
