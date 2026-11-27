import SwiftUI

@main
struct FinanceApp: App {
    @StateObject private var store = FinanceStore()
    @StateObject private var cloud = CloudSync()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(cloud)
                .preferredColorScheme(.dark)
                .tint(FinStyle.neon)
                .task { cloud.attach(store) }
        }
    }
}