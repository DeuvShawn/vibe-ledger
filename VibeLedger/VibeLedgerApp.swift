import SwiftUI
import SwiftData

@main
struct VibeLedgerApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(for: Transaction.self)
        .windowResizability(.automatic)
    }
}
