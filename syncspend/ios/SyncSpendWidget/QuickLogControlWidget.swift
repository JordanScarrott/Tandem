import AppIntents
import SwiftUI
import WidgetKit

/// iOS 18+ Lock Screen Bottom Shortcut & Control Center Widget (e.g. replacing the Flashlight/Torch button).
@available(iOS 18.0, *)
public struct QuickLogControlWidget: ControlWidget {
    public static let kind: String = "com.tandem.syncspend.quick-log-control"
    
    public init() {}
    
    public var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: LogExpenseControlIntent()) {
                Label("Log Expense", systemImage: "plus")
            }
        }
        .displayName("Log Expense")
        .description("Quickly open SyncSpend to record a new expense from your Lock Screen shortcut.")
    }
}

/// AppIntent executed when the Lock Screen Control or Action Button is pressed.
@available(iOS 18.0, *)
public struct LogExpenseControlIntent: AppIntent {
    public static var title: LocalizedStringResource = "Log Expense"
    public static var description = IntentDescription("Opens SyncSpend directly to record an expense.")
    public static var openAppWhenRun: Bool = true
    
    public init() {}
    
    @MainActor
    public func perform() async throws -> some IntentResult {
        // Signal the app to open the new expense sheet
        NotificationCenter.default.post(name: NSNotification.Name("SyncSpend_OpenNewExpenseSheet"), object: nil)
        return .result()
    }
}
