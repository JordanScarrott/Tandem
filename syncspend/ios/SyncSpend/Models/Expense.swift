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
}
