import Foundation

public struct UserProfileItem: Identifiable, Codable, Hashable {
    public var id: String { identity }
    public let identity: String
    public let displayName: String
    public let defaultCurrency: String
    public let billingCycleStartDay: UInt8
    public let createdAtMicros: Int64

    public var createdDate: Date {
        Date(timeIntervalSince1970: TimeInterval(createdAtMicros) / 1_000_000.0)
    }

    public init(
        identity: String,
        displayName: String,
        defaultCurrency: String = "ZAR",
        billingCycleStartDay: UInt8 = 1,
        createdAtMicros: Int64 = Int64(Date().timeIntervalSince1970 * 1_000_000.0)
    ) {
        self.identity = identity
        self.displayName = displayName
        self.defaultCurrency = defaultCurrency
        self.billingCycleStartDay = billingCycleStartDay
        self.createdAtMicros = createdAtMicros
    }
}
