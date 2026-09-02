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

    public static func parse(from row: [Any]) -> CategoryItem? {
        guard row.count >= 7,
              let id = (row[0] as? NSNumber)?.uint64Value,
              let name = row[2] as? String,
              let icon = row[3] as? String,
              let colorHex = row[4] as? String else {
            return nil
        }

        let isArchived = (row[6] as? Bool) ?? false
        if isArchived { return nil }

        var budgetCents: Int64? = nil
        if let budgetVariant = row[5] as? [Any],
           budgetVariant.count == 2,
           let variantIdx = (budgetVariant[0] as? NSNumber)?.intValue ?? (budgetVariant[0] as? Int), variantIdx == 0,
           let budgetNum = budgetVariant[1] as? NSNumber {
            budgetCents = budgetNum.int64Value
        } else if let budgetNum = row[5] as? NSNumber {
            budgetCents = budgetNum.int64Value
        }

        var spaceId: UInt64? = nil
        if row.count > 7 {
            if let spaceVariant = row[7] as? [Any],
               spaceVariant.count == 2,
               let variantIdx = (spaceVariant[0] as? NSNumber)?.intValue ?? (spaceVariant[0] as? Int), variantIdx == 0,
               let sNum = spaceVariant[1] as? NSNumber {
                spaceId = sNum.uint64Value
            } else if let sNum = row[7] as? NSNumber {
                spaceId = sNum.uint64Value
            }
        }

        return CategoryItem(
            id: id,
            name: name,
            icon: icon,
            colorHex: colorHex,
            monthlyBudgetCents: budgetCents,
            isArchived: isArchived,
            spaceId: spaceId
        )
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
    
    public static func fromHex(_ hex: String, default defaultColor: Color = .blue) -> Color {
        Color(hex: hex) ?? defaultColor
    }
}
