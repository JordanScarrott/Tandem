import SwiftUI
import UIKit

public enum Theme {
    // Adaptive Semantic Colors
    public static let appBackground = Color(uiColor: .systemGroupedBackground)
    public static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground)
    public static let tertiaryBackground = Color(uiColor: .tertiarySystemGroupedBackground)
    public static let cardBorder = Color(uiColor: .separator).opacity(0.35)
    public static let primaryDark = Color(uiColor: .label)
    public static let mutedText = Color(uiColor: .secondaryLabel)
    public static let subtleGray = Color(uiColor: .systemGray5)
    public static let chipBackground = Color(uiColor: .tertiarySystemFill)
    public static let buttonDark = Color(uiColor: .label)
    public static let buttonForeground = Color(uiColor: .systemBackground)
    public static let accentBlue = Color.blue
    public static let accentGreen = Color.green
    public static let accentRed = Color.red
    
    // Spacing & Radii
    public static let cardCornerRadius: CGFloat = 24
    public static let largeCardCornerRadius: CGFloat = 28
    public static let pillCornerRadius: CGFloat = 20
    public static let buttonCornerRadius: CGFloat = 16
    public static let squircleCornerRadius: CGFloat = 14
}

public enum Haptics {
    public static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
    
    public static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
    
    public static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
}

public struct SyncSpendCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
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
            .shadow(
                color: colorScheme == .dark ? Color.black.opacity(0.35) : Color.black.opacity(0.04),
                radius: colorScheme == .dark ? 8 : 12,
                x: 0,
                y: colorScheme == .dark ? 2 : 4
            )
    }
}

public extension View {
    func syncSpendCard(padding: CGFloat = 16, cornerRadius: CGFloat = Theme.cardCornerRadius) -> some View {
        modifier(SyncSpendCardModifier(padding: padding, cornerRadius: cornerRadius))
    }
}

