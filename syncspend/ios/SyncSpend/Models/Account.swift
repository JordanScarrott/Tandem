import Foundation

public struct AccountItem: Identifiable, Hashable, Codable {
    public let id: String
    public var name: String
    public var icon: String // "person.fill", "briefcase.fill", "airplane"
    public var balanceCents: Int64
    public var isDefault: Bool
    
    public init(id: String, name: String, icon: String, balanceCents: Int64 = 0, isDefault: Bool = false) {
        self.id = id
        self.name = name
        self.icon = icon
        self.balanceCents = balanceCents
        self.isDefault = isDefault
    }
    
    public static let defaultAccounts: [AccountItem] = [
        AccountItem(id: "acc-personal", name: "Personal", icon: "person.fill", balanceCents: 147500, isDefault: true),
        AccountItem(id: "acc-business", name: "Business", icon: "briefcase.fill", balanceCents: 832000, isDefault: false),
        AccountItem(id: "acc-savings", name: "Savings & Trip", icon: "airplane", balanceCents: 2450000, isDefault: false)
    ]
}
