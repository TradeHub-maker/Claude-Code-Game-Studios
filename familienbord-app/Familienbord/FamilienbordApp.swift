import SwiftUI
import SwiftData

@main
struct FamilienbordApp: App {
    let container = SharedStore.makeContainer(sync: true)
    var body: some Scene {
        WindowGroup { ContentView() }
            .modelContainer(container)
    }
}
