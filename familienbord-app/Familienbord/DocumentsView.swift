import SwiftUI
import SwiftData
import UserNotifications

struct DocumentsView: View {
    @Environment(\.modelContext) private var ctx
    @Query private var docs: [FamilyDocument]
    @State private var title = ""
    @State private var category = "Sonstiges"
    @State private var hasDeadline = true
    @State private var deadline = Date()
    @State private var remind = 14
    @State private var note = ""
    static let categories = ["Impfpass und Gesundheit", "Schule und Kita", "Versicherung", "Garantie", "Vertrag", "Behörde", "Sonstiges"]

    var body: some View {
        NavigationStack {
            List {
                Section("Neu ablegen") {
                    TextField("z. B. U9-Vorsorge Kind 1", text: $title)
                    Picker("Art", selection: $category) { ForEach(Self.categories, id: \.self) { Text($0) } }
                    Toggle("Mit Frist", isOn: $hasDeadline)
                    if hasDeadline {
                        DatePicker("Frist", selection: $deadline, displayedComponents: .date)
                        Stepper("Erinnerung \(remind) Tage vorher", value: $remind, in: 0...365)
                    }
                    TextField("Notiz oder Ablageort", text: $note)
                    Button("Speichern") { save() }.disabled(title.isEmpty)
                }
                Section("Dokumente") {
                    ForEach(docs.sorted { ($0.deadline ?? .distantFuture) < ($1.deadline ?? .distantFuture) }) { d in
                        VStack(alignment: .leading) {
                            HStack { Text(d.title).bold(); Spacer(); status(d) }
                            Text([d.category, d.deadline?.formatted(date: .numeric, time: .omitted), d.note].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · ")).font(.footnote).foregroundStyle(.secondary)
                        }
                    }
                    .onDelete { idx in let l = docs.sorted { ($0.deadline ?? .distantFuture) < ($1.deadline ?? .distantFuture) }; idx.forEach { ctx.delete(l[$0]) } }
                }
            }
            .navigationTitle("Dokumente")
        }
    }

    @ViewBuilder private func status(_ d: FamilyDocument) -> some View {
        if let n = d.daysLeft() {
            Text(n < 0 ? "seit \(-n) Tg. überfällig" : "in \(n) Tg.").font(.caption.bold()).padding(.horizontal, 8).padding(.vertical, 2)
                .background((n < 0 ? Color.red : d.needsAttention ? Color.orange : Color.green).opacity(0.2), in: Capsule())
        }
    }

    private func save() {
        let d = FamilyDocument(title: title, category: category, deadline: hasDeadline ? deadline : nil, remindDays: remind, note: note)
        ctx.insert(d)
        if hasDeadline { scheduleReminder(d) }
        title = ""; note = ""
    }

    /// Lokale Erinnerung `remindDays` vor der Frist um 9 Uhr. Gilt nur auf diesem Gerät.
    private func scheduleReminder(_ d: FamilyDocument) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { ok, _ in
            guard ok, let dl = d.deadline, let fire = Calendar.current.date(byAdding: .day, value: -d.remindDays, to: dl) else { return }
            var c = Calendar.current.dateComponents([.year, .month, .day], from: fire); c.hour = 9
            let content = UNMutableNotificationContent(); content.title = "Frist: \(d.title)"; content.body = "Läuft am \(dl.formatted(date: .long, time: .omitted)) ab."
            UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: d.id.uuidString, content: content, trigger: UNCalendarNotificationTrigger(dateMatching: c, repeats: false)))
        }
    }
}
