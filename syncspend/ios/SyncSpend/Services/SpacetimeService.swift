import Foundation
import Observation

@Observable
public final class SpacetimeService {
    public static let shared = SpacetimeService()

    // Default to deployed Maincloud or local SpacetimeDB dev server
    public var hostURL: String = "https://maincloud.spacetimedb.com"
    public var databaseName: String = "ad-guitar-1941"

    public var authToken: String? {
        get { KeychainManager.getAuthToken() }
        set {
            if let val = newValue {
                KeychainManager.saveAuthToken(val)
            }
        }
    }

    public var identity: String? {
        get { KeychainManager.getIdentity() }
        set {
            if let val = newValue {
                KeychainManager.saveIdentity(val)
            }
        }
    }

    private init() {}

    // MARK: - Identity Management

    /// Ensures an identity exists via SpacetimeDB /v1/identity if not already authenticated
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

    // MARK: - Reducers Helper

    private func callReducer(name: String, payload: [Any]) async throws {
        try await ensureIdentity()
        guard let url = URL(string: "\(hostURL)/v1/database/\(databaseName)/call/\(name)") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpRes = response as? HTTPURLResponse, (200...299).contains(httpRes.statusCode) else {
            let errorMsg = String(data: data, encoding: .utf8) ?? "HTTP \((response as? HTTPURLResponse)?.statusCode ?? 0)"
            print("Reducer '\(name)' invocation error: \(errorMsg)")
            throw NSError(domain: "SpacetimeService", code: 1, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }
    }

    // MARK: - Reducers

    /// Initializes user profile if not already initialized
    public func initializeUserProfile(
        displayName: String = "User",
        defaultCurrency: String = "ZAR",
        billingCycleStartDay: UInt8 = 1
    ) async throws {
        try await callReducer(
            name: "initialize_user_profile",
            payload: [displayName, defaultCurrency, billingCycleStartDay]
        )
    }

    /// Creates a new custom category
    public func createCategory(
        name: String,
        icon: String,
        colorHex: String,
        monthlyBudgetCents: Int64?
    ) async throws {
        let budgetParam: [String: Any]
        if let budget = monthlyBudgetCents {
            budgetParam = ["some": budget]
        } else {
            budgetParam = ["none": [] as [Any]]
        }
        try await callReducer(
            name: "create_category",
            payload: [name, icon, colorHex, budgetParam]
        )
    }

    /// Invokes the `log_expense` reducer over HTTP for personal expenses
    public func logExpense(
        amountCents: Int64,
        currency: String = "ZAR",
        categoryId: UInt64,
        paymentMethod: String,
        note: String,
        spentDate: Date
    ) async throws {
        let spentMillis = Int64(spentDate.timeIntervalSince1970 * 1000.0)
        try await callReducer(
            name: "log_expense",
            payload: [amountCents, currency, categoryId, paymentMethod, note, spentMillis]
        )
    }

    /// Invokes the `log_couple_expense` reducer over HTTP for shared couple expenses
    public func logCoupleExpense(
        spaceId: UInt64,
        amountCents: Int64,
        currency: String = "ZAR",
        categoryId: UInt64,
        paymentMethod: String,
        note: String,
        spentDate: Date,
        splitMode: String = "EQUAL"
    ) async throws {
        let spentMillis = Int64(spentDate.timeIntervalSince1970 * 1000.0)
        try await callReducer(
            name: "log_couple_expense",
            payload: [spaceId, amountCents, currency, categoryId, paymentMethod, note, spentMillis, splitMode]
        )
    }

    /// Creates a new couple space
    public func createCoupleSpace(name: String, splitRatioA: UInt8 = 50, splitRatioB: UInt8 = 50) async throws {
        try await callReducer(
            name: "create_couple_space",
            payload: [name, splitRatioA, splitRatioB]
        )
    }

    /// Joins an existing couple space via invite code
    public func joinCoupleSpace(inviteCode: String) async throws {
        try await callReducer(
            name: "join_couple_space",
            payload: [inviteCode]
        )
    }

    /// Soft-deletes an expense record
    public func softDeleteExpense(expenseId: UInt64) async throws {
        try await callReducer(
            name: "soft_delete_expense",
            payload: [expenseId]
        )
    }

    /// Restores a soft-deleted expense record
    public func restoreExpense(expenseId: UInt64) async throws {
        try await callReducer(
            name: "restore_expense",
            payload: [expenseId]
        )
    }

    // MARK: - Server Views Querying

    /// Fetches all active categories for the authenticated user via `my_categories` server view
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

        request.httpBody = "SELECT * FROM my_categories;".data(using: .utf8)

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

            var budgetCents: Int64? = nil
            if let budgetVariant = row[5] as? [Any],
               budgetVariant.count == 2,
               let variantIdx = budgetVariant[0] as? Int, variantIdx == 0,
               let budgetNum = budgetVariant[1] as? NSNumber {
                budgetCents = budgetNum.int64Value
            } else if let budgetNum = row[5] as? NSNumber {
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

    /// Fetches recent active expenses for the authenticated user and their couple space via `my_expenses` view
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

        request.httpBody = "SELECT * FROM my_expenses;".data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpRes = response as? HTTPURLResponse, httpRes.statusCode == 200 else {
            return []
        }

        guard let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
              let firstResult = jsonArray.first,
              let rows = firstResult["rows"] as? [[Any]] else {
            return []
        }

        let items: [ExpenseItem] = rows.compactMap { row -> ExpenseItem? in
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

            // Check space_id: [0, id] for Some, [1, []] for None
            var spaceId: UInt64? = nil
            if row.count > 11 {
                if let spaceVariant = row[11] as? [Any],
                   spaceVariant.count == 2,
                   let variantIdx = spaceVariant[0] as? Int, variantIdx == 0,
                   let sNum = spaceVariant[1] as? NSNumber {
                    spaceId = sNum.uint64Value
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

        return items.sorted(by: { $0.id > $1.id })
    }

    /// Fetches the authenticated user profile via `my_profile` view
    public func fetchUserProfile() async throws -> UserProfileItem? {
        try await ensureIdentity()
        guard let url = URL(string: "\(hostURL)/v1/database/\(databaseName)/sql") else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        request.httpBody = "SELECT * FROM my_profile;".data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpRes = response as? HTTPURLResponse, httpRes.statusCode == 200 else {
            return nil
        }

        guard let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
              let firstResult = jsonArray.first,
              let rows = firstResult["rows"] as? [[Any]],
              let row = rows.first, row.count >= 5 else {
            return nil
        }

        let ident = parseIdentity(from: row[0])
        guard let displayName = row[1] as? String,
              let defaultCurrency = row[2] as? String,
              let billingCycleDay = (row[3] as? NSNumber)?.uint8Value else {
            return nil
        }

        let createdAtMicros = parseTimestampMicros(from: row[4])

        return UserProfileItem(
            identity: ident,
            displayName: displayName,
            defaultCurrency: defaultCurrency,
            billingCycleStartDay: billingCycleDay,
            createdAtMicros: createdAtMicros
        )
    }

    /// Fetches the authenticated user's couple space via `my_couple_space` view
    public func fetchCoupleSpace() async throws -> CoupleSpaceItem? {
        try await ensureIdentity()
        guard let url = URL(string: "\(hostURL)/v1/database/\(databaseName)/sql") else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        request.httpBody = "SELECT * FROM my_couple_space;".data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpRes = response as? HTTPURLResponse, httpRes.statusCode == 200 else {
            return nil
        }

        guard let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
              let firstResult = jsonArray.first,
              let rows = firstResult["rows"] as? [[Any]],
              let row = rows.first, row.count >= 7 else {
            return nil
        }

        guard let id = (row[0] as? NSNumber)?.uint64Value,
              let name = row[1] as? String else {
            return nil
        }

        let partnerA = parseIdentity(from: row[2])
        let partnerB = parseIdentity(from: row[3])
        let ratioA = (row[4] as? NSNumber)?.uint8Value ?? 50
        let ratioB = (row[5] as? NSNumber)?.uint8Value ?? 50
        let createdAtMicros = parseTimestampMicros(from: row[6])

        return CoupleSpaceItem(
            id: id,
            name: name,
            partnerA: partnerA,
            partnerB: partnerB,
            splitRatioA: ratioA,
            splitRatioB: ratioB,
            createdAtMicros: createdAtMicros
        )
    }

    // MARK: - Parsing Helpers

    private func parseIdentity(from value: Any) -> String {
        if let arr = value as? [String], let first = arr.first {
            return first
        } else if let arr = value as? [Any], let first = arr.first as? String {
            return first
        } else if let str = value as? String {
            return str
        }
        return ""
    }

    private func parseTimestampMicros(from value: Any) -> Int64 {
        if let num = value as? NSNumber {
            return num.int64Value
        } else if let arr = value as? [NSNumber], let first = arr.first {
            return first.int64Value
        } else if let arr = value as? [Any], let firstNum = arr.first as? NSNumber {
            return firstNum.int64Value
        }
        return Int64(Date().timeIntervalSince1970 * 1_000_000.0)
    }
}
