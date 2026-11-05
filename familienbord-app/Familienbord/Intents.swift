import AppIntents
import SwiftData

/// Siri: „Hey Siri, etwas auf die Einkaufsliste setzen“. Siri fragt nach dem Artikel.
struct AddShoppingItemIntent: AppIntent {
    static var title: LocalizedStringResource = "Auf die Einkaufsliste setzen"
    static var description = IntentDescription("Setzt einen Artikel auf die gemeinsame Einkaufsliste.")

    @Parameter(title: "Artikel", requestValueDialog: "Was soll auf die Liste?") var item: String
    @Parameter(title: "Geschäft") var store: String?

    @MainActor func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = SharedStore.makeContainer(sync: true)
        let ctx = container.mainContext
        let existing = (try? ctx.fetch(FetchDescriptor<ShoppingItem>())) ?? []
        let (t, s) = ShoppingParser.parse(store.map { "\(item) @\($0)" } ?? item, known: existing)
        ctx.insert(ShoppingItem(title: t, store: s))
        try ctx.save()
        return .result(dialog: "\(t) steht auf der Liste unter \(s).")
    }
}

struct FamilienbordShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: AddShoppingItemIntent(),
                    phrases: ["Etwas auf die Einkaufsliste in \(.applicationName) setzen",
                              "Einkaufsliste in \(.applicationName) ergänzen"],
                    shortTitle: "Einkaufsliste", systemImageName: "cart")
    }
}
