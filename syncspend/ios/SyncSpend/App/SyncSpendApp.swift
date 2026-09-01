import SwiftUI

@main
struct SyncSpendApp: App {
    @State private var authService = AuthService.shared

    var body: some Scene {
        WindowGroup {
            Group {
                if authService.isAuthenticated {
                    MainDashboardView()
                } else {
                    LoginView()
                }
            }
            .animation(.easeInOut(duration: 0.3), value: authService.isAuthenticated)
        }
    }
}
