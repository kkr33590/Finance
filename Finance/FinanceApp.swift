import SwiftUI

@main
struct FinanceApp: App {
    @StateObject private var store = FinanceStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
                .tint(FinStyle.neon)
        }
    }
}