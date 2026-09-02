import SwiftUI

public enum AppRoute: Equatable {
    case newExpense
}

@main
struct SyncSpendApp: App {
    @State private var authService = AuthService.shared
    @State private var requestedRoute: AppRoute? = nil

    var body: some Scene {
        WindowGroup {
            Group {
                if authService.isAuthenticated {
                    MainDashboardView(requestedRoute: $requestedRoute)
                } else {
                    LoginView()
                }
            }
            .animation(.easeInOut(duration: 0.3), value: authService.isAuthenticated)
            .onOpenURL { url in
                handleIncomingURL(url)
            }
        }
    }

    private func handleIncomingURL(_ url: URL) {
        let host = url.host ?? url.path.replacingOccurrences(of: "/", with: "")
        if host == "log-expense" || host == "new-expense" || host == "quick-log" {
            requestedRoute = .newExpense
            NotificationCenter.default.post(name: NSNotification.Name("SyncSpend_OpenNewExpenseSheet"), object: nil)
        }
    }
}
