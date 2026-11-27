import SwiftUI

// @main marks where the app starts. WindowGroup shows the first screen.
@main
struct FinanceApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .tint(Theme.accent)
                .preferredColorScheme(.dark)
        }
    }
}