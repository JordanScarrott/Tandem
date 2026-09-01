import Foundation

public struct CurrencyItem: Identifiable, Hashable, Codable {
    public var id: String { code }
    public let code: String
    public let symbol: String
    public let name: String
    
    public init(code: String, symbol: String, name: String) {
        self.code = code
        self.symbol = symbol
        self.name = name
    }
    
    public static let defaultCurrency = CurrencyItem(code: "ZAR", symbol: "R", name: "South African Rand (ZAR)")
    
    public static let allCurrencies: [CurrencyItem] = [
        CurrencyItem(code: "ZAR", symbol: "R", name: "South African Rand (ZAR)"),
        CurrencyItem(code: "USD", symbol: "$", name: "US Dollar ($)"),
        CurrencyItem(code: "EUR", symbol: "€", name: "Euro (€)"),
        CurrencyItem(code: "GBP", symbol: "£", name: "British Pound (£)"),
        CurrencyItem(code: "JPY", symbol: "¥", name: "Japanese Yen (¥)"),
        CurrencyItem(code: "CAD", symbol: "$", name: "Canadian Dollar ($)"),
        CurrencyItem(code: "AUD", symbol: "$", name: "Australian Dollar ($)")
    ]
    
    public func format(cents: Int64) -> String {
        let amount = Double(cents) / 100.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = " "
        formatter.decimalSeparator = ","
        
        let formattedNumber = formatter.string(from: NSNumber(value: amount)) ?? String(format: "%.2f", amount)
        return "\(symbol) \(formattedNumber)"
    }
}
