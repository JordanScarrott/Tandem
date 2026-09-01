import Foundation
import Observation

@Observable
public final class SpacetimeService {
    public static let shared = SpacetimeService()

    // Default to deployed Maincloud or local SpacetimeDB dev server
    public var hostURL: String = "https://maincloud.spacetimedb.com"
    public var databaseName: String = "ad-guitar-1941"

    public var authToken: String? {
        get { UserDefaults.standard.string(forKey: "spacetimedb_auth_token") }
        set { UserDefaults.standard.set(newValue, forKey: "spacetimedb_auth_token") }
    }

    public var identity: String? {
        get { UserDefaults.standard.string(forKey: "spacetimedb_identity") }
        set { UserDefaults.standard.set(newValue, forKey: "spacetimedb_identity") }
    }

    private init() {}

    /// Ensures an anonymous identity exists via SpacetimeDB /v1/identity
    public func ensureIdentity() async throws {
        guard authToken == nil || identity == nil else { return }

        guard let url = URL(string: "\(hostURL)/v1/identity") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpRes = response as? HTTPURLResponse, httpRes.statusCode == 200 else {
            print("Running in guest mode without identity server verification.")
            return
        }

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let token = json["token"] as? String {
                self.authToken = token
            }
            if let ident = json["identity"] as? String {
                self.identity = ident
            }
        }
    }

    /// Initializes user profile if not already initialized
    public func initializeUserProfile(
        displayName: String = "User",
        defaultCurrency: String = "ZAR",
        billingCycleStartDay: UInt8 = 1
    ) async throws {
        try await ensureIdentity()
        guard let url = URL(string: "\(hostURL)/v1/database/\(databaseName)/call/initialize_user_profile") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let payload: [Any] = [displayName, defaultCurrency, billingCycleStartDay]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpRes = response as? HTTPURLResponse, (200...299).contains(httpRes.statusCode) else {
            let errorMsg = String(data: data, encoding: .utf8) ?? "HTTP \( (response as? HTTPURLResponse)?.statusCode ?? 0 )"
            print("Failed to initialize profile: \(errorMsg)")
            throw NSError(domain: "SpacetimeService", code: 1, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }
    }

    /// Fetches all active categories for the user
    public func fetchCategories() async throws -> [CategoryItem] {
        try await ensureIdentity()
        guard let url = URL(string: "\(hostURL)/v1/database/\(databaseName)/sql") else {
            return []
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        request.httpBody = "SELECT * FROM category;".data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpRes = response as? HTTPURLResponse, httpRes.statusCode == 200 else {
            let errorMsg = String(data: data, encoding: .utf8) ?? ""
            print("Failed to fetch categories: HTTP \((response as? HTTPURLResponse)?.statusCode ?? 0) \(errorMsg)")
            return []
        }

        // SpacetimeDB returns `[{"schema": ..., "rows": [[...], ...]}]`
        guard let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
              let firstResult = jsonArray.first,
              let rows = firstResult["rows"] as? [[Any]] else {
            return []
        }

        let myIdent = identity ?? ""

        return rows.compactMap { row -> CategoryItem? in
            guard row.count >= 7,
                  let id = (row[0] as? NSNumber)?.uint64Value,
                  let name = row[2] as? String,
                  let icon = row[3] as? String,
                  let colorHex = row[4] as? String else {
                return nil
            }

            let isArchived = (row[6] as? Bool) ?? false
            if isArchived { return nil }

            // Check owner identity if available
            if !myIdent.isEmpty,
               let ownerArray = row[1] as? [String],
               let ownerHex = ownerArray.first {
                let cleanOwner = ownerHex.replacingOccurrences(of: "0x", with: "").lowercased()
                let cleanMy = myIdent.replacingOccurrences(of: "0x", with: "").lowercased()
                if cleanOwner != cleanMy {
                    return nil
                }
            }

            var budgetCents: Int64? = nil
            if let budgetVariant = row[5] as? [Any],
               budgetVariant.count == 2,
               let variantIdx = budgetVariant[0] as? Int, variantIdx == 0,
               let budgetNum = budgetVariant[1] as? NSNumber {
                budgetCents = budgetNum.int64Value
            }

            return CategoryItem(
                id: id,
                name: name,
                icon: icon,
                colorHex: colorHex,
                monthlyBudgetCents: budgetCents,
                isArchived: isArchived
            )
        }
    }

    /// Creates a new custom category
    public func createCategory(
        name: String,
        icon: String,
        colorHex: String,
        monthlyBudgetCents: Int64?
    ) async throws {
        try await ensureIdentity()
        guard let url = URL(string: "\(hostURL)/v1/database/\(databaseName)/call/create_category") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let budgetParam: [String: Any]
        if let budget = monthlyBudgetCents {
            budgetParam = ["some": budget]
        } else {
            budgetParam = ["none": [] as [Any]]
        }
        let payload: [Any] = [name, icon, colorHex, budgetParam]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpRes = response as? HTTPURLResponse, (200...299).contains(httpRes.statusCode) else {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Failed to create category"
            print("Create category error: \(errorMsg)")
            throw NSError(domain: "SpacetimeService", code: 2, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }
    }

    /// Invokes the `log_expense` reducer over HTTP
    public func logExpense(
        amountCents: Int64,
        currency: String = "ZAR",
        categoryId: UInt64,
        paymentMethod: String,
        note: String,
        spentDate: Date
    ) async throws {
        try await ensureIdentity()
        let spentMillis = Int64(spentDate.timeIntervalSince1970 * 1000.0)
        guard let url = URL(string: "\(hostURL)/v1/database/\(databaseName)/call/log_expense") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let payload: [Any] = [
            amountCents,
            currency,
            categoryId,
            paymentMethod,
            note,
            spentMillis
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpRes = response as? HTTPURLResponse, (200...299).contains(httpRes.statusCode) else {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Failed to log expense"
            print("Log expense error: \(errorMsg)")
            throw NSError(domain: "SpacetimeService", code: 3, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }
    }

    /// Soft-deletes an expense record
    public func softDeleteExpense(expenseId: UInt64) async throws {
        try await ensureIdentity()
        guard let url = URL(string: "\(hostURL)/v1/database/\(databaseName)/call/soft_delete_expense") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let payload: [Any] = [expenseId]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpRes = response as? HTTPURLResponse, (200...299).contains(httpRes.statusCode) else {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Failed to delete"
            throw NSError(domain: "SpacetimeService", code: 4, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }
    }

    /// Restores a soft-deleted expense record
    public func restoreExpense(expenseId: UInt64) async throws {
        try await ensureIdentity()
        guard let url = URL(string: "\(hostURL)/v1/database/\(databaseName)/call/restore_expense") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let payload: [Any] = [expenseId]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpRes = response as? HTTPURLResponse, (200...299).contains(httpRes.statusCode) else {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Failed to restore"
            throw NSError(domain: "SpacetimeService", code: 5, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }
    }

    /// Fetches recent active expenses using the SQL endpoint
    public func fetchRecentExpenses() async throws -> [ExpenseItem] {
        try await ensureIdentity()
        guard let url = URL(string: "\(hostURL)/v1/database/\(databaseName)/sql") else {
            return []
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        request.httpBody = "SELECT * FROM expense;".data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpRes = response as? HTTPURLResponse, httpRes.statusCode == 200 else {
            return []
        }

        guard let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
              let firstResult = jsonArray.first,
              let rows = firstResult["rows"] as? [[Any]] else {
            return []
        }

        let myIdent = identity ?? ""

        let items: [ExpenseItem] = rows.compactMap { row -> ExpenseItem? in
            guard row.count >= 10,
                  let id = (row[0] as? NSNumber)?.uint64Value,
                  let amount = (row[2] as? NSNumber)?.int64Value,
                  let currency = row[3] as? String,
                  let categoryId = (row[4] as? NSNumber)?.uint64Value,
                  let paymentMethod = row[5] as? String,
                  let note = row[6] as? String,
                  let spentMillis = (row[7] as? NSNumber)?.int64Value else {
                return nil
            }

            // Check owner identity if available
            if !myIdent.isEmpty,
               let ownerArray = row[1] as? [String],
               let ownerHex = ownerArray.first {
                let cleanOwner = ownerHex.replacingOccurrences(of: "0x", with: "").lowercased()
                let cleanMy = myIdent.replacingOccurrences(of: "0x", with: "").lowercased()
                if cleanOwner != cleanMy {
                    return nil
                }
            }

            // Check deleted_at: [0, [micros]] for Some, [1, []] for None
            var deletedMillis: Int64? = nil
            if row.count > 10,
               let delVariant = row[10] as? [Any],
               delVariant.count == 2,
               let variantIdx = delVariant[0] as? Int, variantIdx == 0 {
                if let microsArr = delVariant[1] as? [NSNumber], let micros = microsArr.first {
                    deletedMillis = micros.int64Value / 1000
                } else if let microsNum = delVariant[1] as? NSNumber {
                    deletedMillis = microsNum.int64Value / 1000
                }
            }

            // If deleted, filter out of recent list
            if deletedMillis != nil {
                return nil
            }

            return ExpenseItem(
                id: id,
                amountCents: amount,
                currency: currency,
                categoryId: categoryId,
                paymentMethod: paymentMethod,
                note: note,
                spentAtMillis: spentMillis,
                deletedAtMillis: deletedMillis
            )
        }

        return items.sorted(by: { $0.id > $1.id })
    }
}
