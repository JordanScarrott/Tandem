import Foundation
import SwiftUI

public struct CategoryItem: Identifiable, Codable, Hashable {
    public let id: UInt64
    public let name: String
    public let icon: String
    public let colorHex: String
    public let monthlyBudgetCents: Int64?
    public let isArchived: Bool
    public let spaceId: UInt64?

    public var color: Color {
        Color(hex: colorHex) ?? .accentColor
    }

    public var formattedBudget: String? {
        guard let budget = monthlyBudgetCents else { return nil }
        let rands = Double(budget) / 100.0
        return String(format: "R %.0f", rands)
    }

    public init(
        id: UInt64,
        name: String,
        icon: String,
        colorHex: String,
        monthlyBudgetCents: Int64? = nil,
        isArchived: Bool = false,
        spaceId: UInt64? = nil
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.monthlyBudgetCents = monthlyBudgetCents
        self.isArchived = isArchived
        self.spaceId = spaceId
    }
}

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let length = hexSanitized.count
        let r, g, b, a: Double
        if length == 6 {
            r = Double((rgb & 0xFF0000) >> 16) / 255.0
            g = Double((rgb & 0x00FF00) >> 8) / 255.0
            b = Double(rgb & 0x0000FF) / 255.0
            a = 1.0
        } else if length == 8 {
            r = Double((rgb & 0xFF000000) >> 24) / 255.0
            g = Double((rgb & 0x00FF0000) >> 16) / 255.0
            b = Double((rgb & 0x0000FF00) >> 8) / 255.0
            a = Double(rgb & 0x000000FF) / 255.0
        } else {
            return nil
        }

        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
