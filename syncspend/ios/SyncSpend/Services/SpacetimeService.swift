import Foundation
import Observation

@Observable
public final class SpacetimeService: NSObject, SpacetimeWebSocketDelegate {
    public static let shared = SpacetimeService()

    // Default to deployed Maincloud or local SpacetimeDB dev server
    public var hostURL: String = "https://maincloud.spacetimedb.com" {
        didSet {
            wsClient.hostURL = hostURL
        }
    }
    public var databaseName: String = "ad-guitar-1941" {
        didSet {
            wsClient.databaseName = databaseName
        }
    }

    public let wsClient: SpacetimeWebSocketClient
    public var liveConnectionState: WebSocketConnectionState = .disconnected

    // Event hooks for reactive ViewModel listeners
    public var onLiveExpenseInsert: ((ExpenseItem) -> Void)?
    public var onLiveExpenseDelete: ((UInt64) -> Void)?
    public var onLiveCategoryUpdate: (([CategoryItem]) -> Void)?
    public var onLiveInitialHydration: (([CategoryItem], [ExpenseItem]) -> Void)?

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

    override private init() {
        self.wsClient = SpacetimeWebSocketClient(hostURL: "https://maincloud.spacetimedb.com", databaseName: "ad-guitar-1941")
        super.init()
        self.wsClient.delegate = self
    }

    // MARK: - Live WebSocket Subscription Management

    public func startLiveSubscription() {
        wsClient.hostURL = hostURL
        wsClient.databaseName = databaseName
        wsClient.connect(authToken: authToken)
    }

    public func stopLiveSubscription() {
        wsClient.disconnect()
    }

    // MARK: - SpacetimeWebSocketDelegate

    public func webSocketDidReceiveIdentity(identity: String, token: String) {
        self.identity = identity
        self.authToken = token
    }

    public func webSocketDidApplySubscription(rows: [String: [[Any]]]) {
        var parsedCategories: [CategoryItem] = []
        if let catRows = rows["my_categories"] {
            parsedCategories = catRows.compactMap { CategoryItem.parse(from: $0) }
        }

        var parsedExpenses: [ExpenseItem] = []
        if let expRows = rows["my_expenses"] {
            parsedExpenses = expRows.compactMap { ExpenseItem.parse(from: $0) }
                .sorted(by: { $0.spentAtMillis > $1.spentAtMillis })
        }

        DispatchQueue.main.async { [weak self] in
            self?.onLiveInitialHydration?(parsedCategories, parsedExpenses)
        }
    }

    public func webSocketDidReceiveTransaction(update: TransactionUpdateMessage) {
        DispatchQueue.main.async { [weak self] in
            for tableUpdate in update.tableUpdates {
                if tableUpdate.tableName == "expense" {
                    for op in tableUpdate.operations {
                        switch op {
                        case .insert(let row):
                            if let item = ExpenseItem.parse(from: row) {
                                self?.onLiveExpenseInsert?(item)
                            }
                        case .delete(let row):
                            if let id = (row.first as? NSNumber)?.uint64Value {
                                self?.onLiveExpenseDelete?(id)
                            }
                        }
                    }
                }
            }
        }
    }

    public func webSocketStateDidChange(to state: WebSocketConnectionState) {
        DispatchQueue.main.async { [weak self] in
            self?.liveConnectionState = state
        }
    }

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

    /// Updates user profile display name and payday anchor
    public func updateUserProfile(
        displayName: String,
        billingCycleStartDay: UInt8
    ) async throws {
        try await callReducer(
            name: "update_user_profile",
            payload: [displayName, billingCycleStartDay]
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

    /// Updates an existing category envelope
    public func updateCategory(
        categoryId: UInt64,
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
            name: "update_category",
            payload: [categoryId, name, icon, colorHex, budgetParam]
        )
    }

    /// Archives a category envelope (preserves historical records, hides from active envelope pickers)
    public func archiveCategory(categoryId: UInt64) async throws {
        try await callReducer(
            name: "archive_category",
            payload: [categoryId]
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

    /// Invokes the `update_expense` reducer over HTTP to update an existing expense record
    public func updateExpense(
        expenseId: UInt64,
        amountCents: Int64,
        currency: String = "ZAR",
        categoryId: UInt64,
        paymentMethod: String,
        note: String,
        spentDate: Date,
        splitMode: String = "PERSONAL"
    ) async throws {
        let spentMillis = Int64(spentDate.timeIntervalSince1970 * 1000.0)
        try await callReducer(
            name: "update_expense",
            payload: [expenseId, amountCents, currency, categoryId, paymentMethod, note, spentMillis, splitMode]
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

        return rows.compactMap { CategoryItem.parse(from: $0) }
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

        let items: [ExpenseItem] = rows.compactMap { ExpenseItem.parse(from: $0) }
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
