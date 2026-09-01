import SwiftUI

public enum Theme {
    // Colors
    public static let appBackground = Color(hex: "#F2F2F7") ?? Color(.systemGroupedBackground)
    public static let cardBackground = Color.white
    public static let cardBorder = Color(hex: "#E5E5EA")?.opacity(0.7) ?? Color(.systemGray5)
    public static let primaryDark = Color(hex: "#1C1C1E") ?? Color.primary
    public static let mutedText = Color(hex: "#8E8E93") ?? Color.secondary
    public static let subtleGray = Color(hex: "#E5E5EA") ?? Color(.systemGray6)
    public static let buttonDark = Color(hex: "#1C1C1E") ?? Color.black
    public static let accentBlue = Color(hex: "#007AFF") ?? Color.blue
    public static let accentGreen = Color(hex: "#34C759") ?? Color.green
    public static let accentRed = Color(hex: "#FF3B30") ?? Color.red
    
    // Spacing & Radii
    public static let cardCornerRadius: CGFloat = 24
    public static let largeCardCornerRadius: CGFloat = 28
    public static let pillCornerRadius: CGFloat = 20
    public static let buttonCornerRadius: CGFloat = 16
    public static let squircleCornerRadius: CGFloat = 14
}

public struct SyncSpendCardModifier: ViewModifier {
    var padding: CGFloat = 16
    var cornerRadius: CGFloat = Theme.cardCornerRadius
    
    public func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Theme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Theme.cardBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 12, x: 0, y: 4)
    }
}

public extension View {
    func syncSpendCard(padding: CGFloat = 16, cornerRadius: CGFloat = Theme.cardCornerRadius) -> some View {
        modifier(SyncSpendCardModifier(padding: padding, cornerRadius: cornerRadius))
    }
}
