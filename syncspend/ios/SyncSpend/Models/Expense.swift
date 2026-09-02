import Foundation

public struct ExpenseItem: Identifiable, Codable, Hashable {
    public let id: UInt64
    public let amountCents: Int64
    public let currency: String
    public let categoryId: UInt64
    public let paymentMethod: String
    public let note: String
    public let spentAtMillis: Int64
    public let deletedAtMillis: Int64?
    public let spaceId: UInt64?
    public let splitMode: String?
    public let accountId: String?

    public var isDeleted: Bool {
        deletedAtMillis != nil
    }

    public var spentDate: Date {
        Date(timeIntervalSince1970: TimeInterval(spentAtMillis) / 1000.0)
    }

    public var formattedZAR: String {
        let rands = Double(amountCents) / 100.0
        return String(format: "R %.2f", rands)
    }
    
    public func formattedAmount(currencySymbol: String = "R") -> String {
        let amount = Double(amountCents) / 100.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = " "
        formatter.decimalSeparator = ","
        
        let formattedNumber = formatter.string(from: NSNumber(value: amount)) ?? String(format: "%.2f", amount)
        return "\(currencySymbol) \(formattedNumber)"
    }

    public init(
        id: UInt64,
        amountCents: Int64,
        currency: String = "ZAR",
        categoryId: UInt64,
        paymentMethod: String,
        note: String,
        spentAtMillis: Int64,
        deletedAtMillis: Int64? = nil,
        spaceId: UInt64? = nil,
        splitMode: String? = "PERSONAL",
        accountId: String? = "acc-personal"
    ) {
        self.id = id
        self.amountCents = amountCents
        self.currency = currency
        self.categoryId = categoryId
        self.paymentMethod = paymentMethod
        self.note = note
        self.spentAtMillis = spentAtMillis
        self.deletedAtMillis = deletedAtMillis
        self.spaceId = spaceId
        self.splitMode = splitMode
        self.accountId = accountId
    }

    public static func parse(from row: [Any]) -> ExpenseItem? {
        guard row.count >= 8,
              let id = (row[0] as? NSNumber)?.uint64Value,
              let amount = (row[2] as? NSNumber)?.int64Value,
              let currency = row[3] as? String,
              let categoryId = (row[4] as? NSNumber)?.uint64Value,
              let paymentMethod = row[5] as? String,
              let note = row[6] as? String,
              let spentMillis = (row[7] as? NSNumber)?.int64Value else {
            return nil
        }

        // Check deleted_at: [0, [micros]] or [0, micros] for Some, [1, []] for None
        var deletedMillis: Int64? = nil
        if row.count > 10,
           let delVariant = row[10] as? [Any],
           delVariant.count == 2,
           let variantIdx = (delVariant[0] as? NSNumber)?.intValue ?? (delVariant[0] as? Int), variantIdx == 0 {
            if let microsArr = delVariant[1] as? [NSNumber], let micros = microsArr.first {
                deletedMillis = micros.int64Value / 1000
            } else if let microsNum = delVariant[1] as? NSNumber {
                deletedMillis = microsNum.int64Value / 1000
            }
        }

        // Check space_id: [0, id] for Some, [1, []] for None
        var spaceId: UInt64? = nil
        if row.count > 11 {
            if let spaceVariant = row[11] as? [Any],
               spaceVariant.count == 2,
               let variantIdx = (spaceVariant[0] as? NSNumber)?.intValue ?? (spaceVariant[0] as? Int), variantIdx == 0 {
                if let sNum = spaceVariant[1] as? NSNumber {
                    spaceId = sNum.uint64Value
                } else if let sArr = spaceVariant[1] as? [NSNumber], let sNum = sArr.first {
                    spaceId = sNum.uint64Value
                }
            } else if let sNum = row[11] as? NSNumber {
                spaceId = sNum.uint64Value
            }
        }

        // Check split_mode
        var splitMode: String = "PERSONAL"
        if row.count > 12, let sm = row[12] as? String {
            splitMode = sm
        }

        let accountId = spaceId != nil ? "acc-couple" : "acc-personal"

        return ExpenseItem(
            id: id,
            amountCents: amount,
            currency: currency,
            categoryId: categoryId,
            paymentMethod: paymentMethod,
            note: note,
            spentAtMillis: spentMillis,
            deletedAtMillis: deletedMillis,
            spaceId: spaceId,
            splitMode: splitMode,
            accountId: accountId
        )
    }
}
