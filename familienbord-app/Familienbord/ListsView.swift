import SwiftUI
import SwiftData

struct ListsView: View {
    @Environment(\.modelContext) private var ctx
    @Query(sort: \ShoppingItem.createdAt) private var items: [ShoppingItem]
    @Query private var todos: [TodoItem]
    @Query(sort: \FamilyMember.name) private var members: [FamilyMember]
    @AppStorage("meID") private var meID = ""
    @State private var text = ""
    @State private var todoText = ""
    @State private var todoWho: UUID?
    @State private var onlyMine = false

    private var stores: [String] { Array(Set(items.filter { !$0.isDone }.map(\.store))).sorted() }

    var body: some View {
        NavigationStack {
            List {
                Section("Einkaufsliste") {
                    HStack {
                        TextField("Milch @Drogerie", text: $text).onSubmit(add)
                        Button("Hinzufügen", action: add).disabled(text.isEmpty)
                    }
                }
                ForEach(stores, id: \.self) { s in
                    Section(s) {
                        ForEach(items.filter { $0.store == s && !$0.isDone }) { i in
                            Button { i.isDone = true } label: { Label(i.title, systemImage: "circle") }.tint(.primary)
                        }
                    }
                }
                if items.contains(where: \.isDone) {
                    Section("Erledigt") {
                        ForEach(items.filter(\.isDone)) { i in
                            Button { i.isDone = false } label: { Label(i.title, systemImage: "checkmark.circle.fill").strikethrough() }.tint(.secondary)
                        }
                        Button("Erledigte löschen", role: .destructive) { items.filter(\.isDone).forEach(ctx.delete) }
                    }
                }
                Section("Aufgaben mit Zuständigkeit") {
                    TextField("Wer holt Kind 2 ab?", text: $todoText)
                    MemberPicker(title: "Zuständig", selection: $todoWho, allowNone: "Offen")
                    Button("Aufgabe anlegen") { ctx.insert(TodoItem(title: todoText, assigneeID: todoWho)); todoText = "" }.disabled(todoText.isEmpty)
                    Toggle("Nur meine", isOn: $onlyMine)
                    ForEach(todos.filter { !onlyMine || $0.assigneeID?.uuidString == meID }.sorted { !$0.isDone && $1.isDone }) { t in
                        HStack {
                            Button { t.isDone.toggle() } label: { Image(systemName: t.isDone ? "checkmark.circle.fill" : "circle") }.buttonStyle(.plain)
                            Text(t.title).strikethrough(t.isDone)
                            Spacer()
                            if let a = members.first(where: { $0.id == t.assigneeID }) { Text(a.name).font(.caption).padding(.horizontal, 8).background(a.color.opacity(0.25), in: Capsule()) }
                            else if let me = UUID(uuidString: meID) { Button("Ich") { t.assigneeID = me }.buttonStyle(.bordered) }
                        }
                    }
                    .onDelete { idx in idx.forEach { ctx.delete(todos[$0]) } }
                }
            }
            .navigationTitle("Listen")
        }
    }

    private func add() {
        let (t, s) = ShoppingParser.parse(text, known: items)
        guard !t.isEmpty else { return }
        ctx.insert(ShoppingItem(title: t, store: s)); text = ""
    }
}

enum ShoppingParser {
    /// "Milch @Drogerie" -> ("Milch", "Drogerie"); ohne @ wird das zuletzt genutzte Geschäft des Artikels verwendet.
    static func parse(_ raw: String, known: [ShoppingItem]) -> (String, String) {
        let s = raw.trimmingCharacters(in: .whitespaces)
        if let r = s.range(of: " @") {
            let store = String(s[r.upperBound...]).trimmingCharacters(in: .whitespaces)
            return (String(s[..<r.lowerBound]).trimmingCharacters(in: .whitespaces), store.prefix(1).uppercased() + store.dropFirst())
        }
        let prior = known.last { $0.title.lowercased() == s.lowercased() }
        return (s, prior?.store ?? "Supermarkt")
    }
}
