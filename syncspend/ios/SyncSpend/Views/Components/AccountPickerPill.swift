import SwiftUI

public struct AccountPickerPill: View {
    public let accountName: String
    public let action: () -> Void
    
    public init(accountName: String, action: @escaping () -> Void) {
        self.accountName = accountName
        self.action = action
    }
    
    public var body: some View {
        Button {
            Haptics.selection()
            action()
        } label: {
            HStack(spacing: 6) {
                Text(accountName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.primaryDark)
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Theme.mutedText)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Theme.cardBackground.opacity(0.85))
                    .background(.ultraThinMaterial, in: Capsule())
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(Theme.cardBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

