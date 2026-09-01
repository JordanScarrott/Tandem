import Foundation

public struct CoupleSpaceItem: Identifiable, Codable, Hashable {
    public let id: UInt64
    public let name: String
    public let partnerA: String
    public let partnerB: String
    public let splitRatioA: UInt8
    public let splitRatioB: UInt8
    public let createdAtMicros: Int64

    public var isPartnerBJoined: Bool {
        let cleanB = partnerB.replacingOccurrences(of: "0x", with: "").trimmingCharacters(in: .whitespaces)
        return !cleanB.isEmpty && !cleanB.allSatisfy({ $0 == "0" })
    }

    public var createdDate: Date {
        Date(timeIntervalSince1970: TimeInterval(createdAtMicros) / 1_000_000.0)
    }

    public init(
        id: UInt64,
        name: String,
        partnerA: String,
        partnerB: String = "",
        splitRatioA: UInt8 = 50,
        splitRatioB: UInt8 = 50,
        createdAtMicros: Int64 = Int64(Date().timeIntervalSince1970 * 1_000_000.0)
    ) {
        self.id = id
        self.name = name
        self.partnerA = partnerA
        self.partnerB = partnerB
        self.splitRatioA = splitRatioA
        self.splitRatioB = splitRatioB
        self.createdAtMicros = createdAtMicros
    }
}
