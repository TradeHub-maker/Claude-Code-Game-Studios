import SwiftUI
import SwiftData

let memberColors: [Color] = [.blue, .pink, .green, .orange, .purple, .teal]

extension FamilyMember { var color: Color { memberColors[colorIndex % memberColors.count] } }

struct ContentView: View {
    @Query private var docs: [FamilyDocument]
    var body: some View {
        TabView {
            PlanView().tabItem { Label("Plan", systemImage: "calendar") }
            ListsView().tabItem { Label("Listen", systemImage: "checklist") }
            MealsView().tabItem { Label("Essen", systemImage: "fork.knife") }
            ChoresView().tabItem { Label("Aufgaben", systemImage: "star") }
            DocumentsView().tabItem { Label("Dokumente", systemImage: "doc.text") }
                .badge(docs.filter { $0.needsAttention }.count)
            ChatView().tabItem { Label("Chat", systemImage: "bubble.left.and.bubble.right") }
        }
    }
}

/// Auswahl einer Person; gibt die UUID zurück.
struct MemberPicker: View {
    let title: String
    @Binding var selection: UUID?
    var allowNone: String? = nil
    @Query(sort: \FamilyMember.name) private var members: [FamilyMember]
    var body: some View {
        Picker(title, selection: $selection) {
            if let none = allowNone { Text(none).tag(UUID?.none) }
            ForEach(members) { Text($0.name).tag(UUID?.some($0.id)) }
        }
    }
}

/// Wer bin ich? Wird pro Gerät gespeichert.
struct MeStore {
    static func me(_ members: [FamilyMember], id: String) -> FamilyMember? { members.first { $0.id.uuidString == id } }
}

struct MembersView: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \FamilyMember.name) private var members: [FamilyMember]
    @AppStorage("meID") private var meID = ""
    @State private var name = ""
    @State private var isChild = false
    var body: some View {
        NavigationStack {
            Form {
                Section("Familie") {
                    ForEach(members) { m in
                        HStack {
                            Circle().fill(m.color).frame(width: 12, height: 12)
                            TextField("Name", text: Binding(get: { m.name }, set: { m.name = $0 }))
                            Text(m.isChild ? "Kind" : "Erwachsen").foregroundStyle(.secondary).font(.caption)
                            if meID == m.id.uuidString { Image(systemName: "person.fill.checkmark") }
                        }
                        .swipeActions { Button("Das bin ich") { meID = m.id.uuidString }.tint(.accentColor) }
                    }
                    .onDelete { for i in $0 { ctx.delete(members[i]) } }
                }
                Section("Hinzufügen") {
                    TextField("Vorname", text: $name)
                    Toggle("Kind", isOn: $isChild)
                    Button("Hinzufügen") {
                        ctx.insert(FamilyMember(name: name, isChild: isChild, colorIndex: members.count)); name = ""
                    }.disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                Section { Text("Nach links wischen, um festzulegen, wer du auf diesem Gerät bist.").font(.footnote).foregroundStyle(.secondary) }
            }
            .navigationTitle("Familie")
            .toolbar { Button("Fertig") { dismiss() } }
        }
    }
}
