```markdown
# Agent Task: Build Iteration 1 of SyncSpend (iOS + SpacetimeDB Backend)

You are tasked with scaffolding, implementing, and validating Iteration 1 of **SyncSpend** — a minimal, high-speed expense tracking iOS app backed directly by SpacetimeDB.

### 🎯 Iteration 1 Definition of Done
By the end of this run, the developer must be able to:
1. Run `spacetime dev` in the terminal to start the live hot-reloading SpacetimeDB engine.
2. Open the iOS project in Xcode and press `Cmd + R` to deploy directly to a physical iPhone.
3. On the phone, enter an expense with:
   - **Amount in ZAR** (entered in Rands, stored as integer minor units / cents in Rust: `i64`).
   - **Note / Merchant Name** (e.g. "Woolworths Food").
   - **Category** ("Groceries", "Dining & Coffee", "Transport / Fuel", "Utilities", "Personal Fun").
   - **Payment Method** ("Apple Pay", "Credit Card", "Debit Card", "Cash").
   - **Spent Date** (iOS DatePicker $\to$ Unix Epoch Milliseconds).
   - **Currency** ("ZAR").
4. Tap **"Log Expense"**, which triggers haptic feedback, writes directly to SpacetimeDB via HTTP/JSON, and instantly displays the saved transaction in the "Recent Activity" feed below the form.

---

## 1. Project Directory Structure to Generate

Generate the following tree in the workspace root:

```text
syncspend/
├── .cursor/
│   └── mcp.json                         # Native SpacetimeDB MCP server config
├── spacetime.json                       # SpacetimeDB dev orchestrator config
├── server/
│   ├── Cargo.toml                       # Rust cdylib package
│   └── src/
│       └── lib.rs                       # Expense table & log_expense reducer
└── ios/
    ├── SyncSpend/
    │   ├── App/
    │   │   └── SyncSpendApp.swift       # App lifecycle & root view
    │   ├── Models/
    │   │   └── Expense.swift            # Client data model & currency formatting
    │   ├── Services/
    │   │   └── SpacetimeService.swift   # HTTP client for SpacetimeDB
    │   └── Views/
    │       └── LogExpenseView.swift     # High-polish SwiftUI UI & Recent list
    └── SyncSpend.xcodeproj              # Xcode project bundle configuration

```

---

## 2. Configuration & Backend Files

### `.cursor/mcp.json`

```json
{
  "mcpServers": {
    "spacetimedb": {
      "command": "spacetime",
      "args": ["mcp"]
    }
  }
}

```

### `spacetime.json`

```json
{
  "name": "syncspend",
  "module-path": "server"
}

```

### `server/Cargo.toml`

```toml
[package]
name = "syncspend-server"
version = "0.1.0"
edition = "2021"

[lib]
crate-type = ["cdylib"]

[dependencies]
spacetimedb = "1.0"

```

### `server/src/lib.rs`

```rust
use spacetimedb::{table, reducer, Identity, Timestamp, ReducerContext};

#[table(name = expense, public)]
pub struct Expense {
    #[primary_key]
    #[auto_inc]
    pub id: u64,
    pub owner: Identity,
    pub amount_cents: i64,      // Stored in minor currency units (ZAR cents)
    pub currency: String,        // e.g. "ZAR"
    pub category: String,
    pub payment_method: String,
    pub note: String,
    pub spent_at_millis: i64,
    pub created_at: Timestamp,
}

#[reducer]
pub fn log_expense(
    ctx: &ReducerContext,
    amount_cents: i64,
    currency: String,
    category: String,
    payment_method: String,
    note: String,
    spent_at_millis: i64,
) -> Result<(), String> {
    if amount_cents <= 0 {
        return Err("Expense amount must be greater than zero".into());
    }

    ctx.db.expense().insert(Expense {
        id: 0,
        owner: ctx.sender,
        amount_cents,
        currency: currency.to_uppercase(),
        category,
        payment_method,
        note,
        spent_at_millis,
        created_at: ctx.timestamp,
    });

    Ok(())
}

```

---

## 3. iOS Client Implementation (Swift & SwiftUI)

### `ios/SyncSpend/Models/Expense.swift`

```swift
import Foundation

public struct ExpenseItem: Identifiable, Codable, Hashable {
    public let id: UInt64
    public let amountCents: Int64
    public let currency: String
    public let category: String
    public let paymentMethod: String
    public let note: String
    public let spentAtMillis: Int64

    public var spentDate: Date {
        Date(timeIntervalSince1970: TimeInterval(spentAtMillis) / 1000.0)
    }

    public var formattedZAR: String {
        let rands = Double(amountCents) / 100.0
        return String(format: "R %.2f", rands)
    }
}

```

### `ios/SyncSpend/Services/SpacetimeService.swift`

```swift
import Foundation

@Observable
public final class SpacetimeService {
    public static let shared = SpacetimeService()

    // Default to local SpacetimeDB dev server or Maincloud
    // Set to your Mac's LAN IP (e.g. "[http://192.168.1.50:3000](http://192.168.1.50:3000)") if testing on physical phone over Wi-Fi
    public var hostURL: String = "http://localhost:3000"
    public var databaseName: String = "syncspend"

    private var authToken: String? {
        get { UserDefaults.standard.string(forKey: "spacetimedb_auth_token") }
        set { UserDefaults.standard.set(newValue, forKey: "spacetimedb_auth_token") }
    }

    private init() {}

    /// Ensures an anonymous identity exists via SpacetimeDB /v1/identity
    public func ensureIdentity() async throws {
        guard authToken == nil else { return }

        guard let url = URL(string: "\(hostURL)/v1/identity") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpRes = response as? HTTPURLResponse, httpRes.statusCode == 200 else {
            print("Running in guest mode without identity server verification.")
            return
        }

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let token = json["token"] as? String {
            self.authToken = token
        }
    }

    /// Invokes the `log_expense` reducer over HTTP
    public func logExpense(
        amountCents: Int64,
        currency: String = "ZAR",
        category: String,
        paymentMethod: String,
        note: String,
        spentDate: Date
    ) async throws {
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
            category,
            paymentMethod,
            note.isEmpty ? category : note,
            spentMillis
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpRes = response as? HTTPURLResponse, (200...299).contains(httpRes.statusCode) else {
            throw NSError(domain: "SpacetimeService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to commit reducer."])
        }
    }

    /// Fetches recent expenses using the SQL endpoint
    public func fetchRecentExpenses() async throws -> [ExpenseItem] {
        guard let url = URL(string: "\(hostURL)/v1/database/\(databaseName)/sql") else {
            return []
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let sqlQuery = "SELECT id, amount_cents, currency, category, payment_method, note, spent_at_millis FROM expense ORDER BY id DESC LIMIT 15;"
        request.httpBody = sqlQuery.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpRes = response as? HTTPURLResponse, httpRes.statusCode == 200 else {
            return []
        }

        // Parse SpacetimeDB JSON tabular response
        guard let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return []
        }

        return jsonArray.compactMap { dict -> ExpenseItem? in
            guard let id = (dict["id"] as? NSNumber)?.uint64Value,
                  let amount = (dict["amount_cents"] as? NSNumber)?.int64Value,
                  let currency = dict["currency"] as? String,
                  let category = dict["category"] as? String,
                  let paymentMethod = dict["payment_method"] as? String,
                  let note = dict["note"] as? String,
                  let spentMillis = (dict["spent_at_millis"] as? NSNumber)?.int64Value else {
                return nil
            }
            return ExpenseItem(
                id: id,
                amountCents: amount,
                currency: currency,
                category: category,
                paymentMethod: paymentMethod,
                note: note,
                spentAtMillis: spentMillis
            )
        }
    }
}

```

### `ios/SyncSpend/Views/LogExpenseView.swift`

```swift
import SwiftUI

public struct LogExpenseView: View {
    @State private var service = SpacetimeService.shared

    // Form State
    @State private var amountInput: String = ""
    @State private var note: String = ""
    @State private var selectedCategory: String = "Groceries"
    @State private var selectedPaymentMethod: String = "Apple Pay"
    @State private var spentDate: Date = Date()
    @State private var isSubmitting: Bool = false
    @State private var recentExpenses: [ExpenseItem] = []
    @State private var errorMessage: String?

    let categories = [
        ("Groceries", "cart.fill"),
        ("Dining & Coffee", "cup.and.saucer.fill"),
        ("Transport / Fuel", "fuelpump.fill"),
        ("Utilities", "bolt.fill"),
        ("Personal Fun", "sparkles")
    ]

    let paymentMethods = ["Apple Pay", "Credit Card", "Debit Card", "Cash"]

    private var parsedCents: Int64 {
        guard let rands = Double(amountInput.replacingOccurrences(of: ",", with: ".")) else { return 0 }
        return Int64(round(rands * 100.0))
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Host Config (Collapsible)
                    DisclosureGroup("Server Configuration") {
                        TextField("Host URL", text: $service.hostURL)
                            .font(.caption)
                            .textFieldStyle(.roundedBorder)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                    // 1. ZAR Amount Hero Input
                    VStack(spacing: 6) {
                        Text("ZAR AMOUNT")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("R")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundStyle(.secondary)

                            TextField("0.00", text: $amountInput)
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.leading)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.horizontal, 40)
                    }
                    .padding(.vertical, 8)

                    // 2. Note / Merchant Field
                    VStack(alignment: .leading, spacing: 6) {
                        Text("NOTE / MERCHANT")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.secondary)
                        TextField("e.g. Woolworths, Shell, Steers", text: $note)
                            .padding(12)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)

                    // 3. Category Selector
                    VStack(alignment: .leading, spacing: 8) {
                        Text("CATEGORY")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(categories, id: \.0) { cat in
                                    let isSelected = selectedCategory == cat.0
                                    Button {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        selectedCategory = cat.0
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: cat.1)
                                            Text(cat.0)
                                        }
                                        .font(.subheadline.weight(.medium))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
                                        .foregroundStyle(isSelected ? .white : .primary)
                                        .clipShape(Capsule())
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // 4. Payment Method & Date
                    VStack(spacing: 14) {
                        Picker("Payment Method", selection: $selectedPaymentMethod) {
                            ForEach(paymentMethods, id: \.self) { method in
                                Text(method).tag(method)
                            }
                        }
                        .pickerStyle(.segmented)

                        DatePicker("Date", selection: $spentDate, displayedComponents: [.date, .hourAndMinute])
                            .font(.subheadline)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    // 5. Submit Button
                    Button {
                        submitExpense()
                    } label: {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Log Expense")
                                    .font(.headline.weight(.semibold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(parsedCents > 0 ? Color.accentColor : Color(.systemGray4))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .disabled(parsedCents == 0 || isSubmitting)
                    .padding(.horizontal)

                    if let err = errorMessage {
                        Text(err)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    Divider()
                        .padding(.vertical, 8)

                    // 6. Recent Activity (Immediate Verification)
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Recent Transactions")
                                .font(.headline)
                            Spacer()
                            Button("Refresh") {
                                Task { await loadRecent() }
                            }
                            .font(.caption)
                        }
                        .padding(.horizontal)

                        if recentExpenses.isEmpty {
                            Text("No expenses logged yet.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal)
                        } else {
                            ForEach(recentExpenses) { item in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.note)
                                            .font(.subheadline.weight(.semibold))
                                        Text("\(item.category) • \(item.paymentMethod)")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text(item.formattedZAR)
                                            .font(.subheadline.weight(.bold))
                                        Text(item.spentDate.formatted(date: .numeric, time: .shortened))
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
                .padding(.bottom, 24)
            }
            .navigationTitle("SyncSpend (ZAR)")
            .task {
                try? await service.ensureIdentity()
                await loadRecent()
            }
        }
    }

    private func submitExpense() {
        guard parsedCents > 0 else { return }
        isSubmitting = true
        errorMessage = nil
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        Task {
            do {
                try await service.logExpense(
                    amountCents: parsedCents,
                    currency: "ZAR",
                    category: selectedCategory,
                    paymentMethod: selectedPaymentMethod,
                    note: note,
                    spentDate: spentDate
                )
                amountInput = ""
                note = ""
                await loadRecent()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSubmitting = false
        }
    }

    private func loadRecent() async {
        do {
            recentExpenses = try await service.fetchRecentExpenses()
        } catch {
            print("Failed to fetch recent expenses: \(error)")
        }
    }
}

```

### `ios/SyncSpend/App/SyncSpendApp.swift`

```swift
import SwiftUI

@main
struct SyncSpendApp: App {
    var body: some Scene {
        WindowGroup {
            LogExpenseView()
        }
    }
}

```

---

## 4. Execution & Validation Instructions

1. **Start SpacetimeDB:**
```bash
cd syncspend
spacetime dev

```


2. **Open Xcode & Run:**
* Open `ios/SyncSpend.xcodeproj` in Xcode.
* Set team signing to your Personal Apple ID in **Signing & Capabilities**.
* Select your physical iPhone and press `Cmd + R`.
* In the app's "Server Configuration" disclosure group, ensure the host points to your Mac's LAN IP (or `http://localhost:3000` if on simulator).


3. **Log your first expense in Rands** and verify that it renders immediately in the "Recent Transactions" feed.

```

```