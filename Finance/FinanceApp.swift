import SwiftUI

@main
struct FinanceApp: App {
    @StateObject private var store = FinanceStore()
    @StateObject private var cloud = CloudSync()

    init() {
        FinFont.register()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(cloud)
                .font(FinFont.body)
                .preferredColorScheme(.dark)
                .tint(FinStyle.neon)
                .task { cloud.attach(store) }
        }
    }
}