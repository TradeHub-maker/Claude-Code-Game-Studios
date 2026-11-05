import SwiftUI
import SwiftData

struct ChoresView: View {
    @Environment(\.modelContext) private var ctx
    @Query private var chores: [Chore]
    @Query(sort: \FamilyMember.name) private var members: [FamilyMember]
    @AppStorage("rate") private var rate = 0.10        // € pro Punkt, pro Gerät; für die ganze Familie in einer späteren Version
    @State private var title = ""
    @State private var points = 5
    @State private var who: UUID?

    private func open(_ id: UUID) -> Int { chores.filter { $0.assigneeID == id && $0.isDone && !$0.isPaid }.reduce(0) { $0 + $1.points } }
    private func pending(_ id: UUID) -> Int { chores.filter { $0.assigneeID == id && !$0.isDone }.reduce(0) { $0 + $1.points } }

    var body: some View {
        NavigationStack {
            List {
                Section("Punktestand") {
                    ForEach(members.filter(\.isChild)) { k in
                        VStack(alignment: .leading) {
                            HStack { Text(k.name).bold(); Spacer(); Text("\(open(k.id)) Pkt.").font(.title2.bold()).monospacedDigit() }
                            Text((Double(open(k.id)) * rate).formatted(.currency(code: "EUR")) + " Taschengeld · \(pending(k.id)) Punkte noch offen").font(.footnote).foregroundStyle(.secondary)
                            ProgressView(value: Double(open(k.id)), total: Double(max(open(k.id) + pending(k.id), 1))).tint(k.color)
                            if open(k.id) > 0 { Button("Auszahlen") { chores.filter { $0.assigneeID == k.id && $0.isDone && !$0.isPaid }.forEach { $0.isPaid = true } }.buttonStyle(.bordered) }
                        }
                    }
                    Stepper("Wert pro Punkt: \(rate.formatted(.currency(code: "EUR")))", value: $rate, in: 0...5, step: 0.05)
                }
                Section("Neue Aufgabe") {
                    TextField("Spülmaschine ausräumen", text: $title)
                    Stepper("Punkte: \(points)", value: $points, in: 1...100)
                    MemberPicker(title: "Wer", selection: $who, allowNone: "Alle")
                    Button("Anlegen") { ctx.insert(Chore(title: title, points: points, assigneeID: who)); title = "" }.disabled(title.isEmpty)
                }
                Section("Aufgaben") {
                    ForEach(chores.filter { !$0.isPaid }.sorted { !$0.isDone && $1.isDone }) { c in
                        HStack {
                            Button { c.isDone.toggle() } label: { Image(systemName: c.isDone ? "checkmark.circle.fill" : "circle") }.buttonStyle(.plain)
                            Text(c.title).strikethrough(c.isDone)
                            Spacer()
                            Text(members.first { $0.id == c.assigneeID }?.name ?? "Alle").font(.caption).foregroundStyle(.secondary)
                            Text("\(c.points) Pkt.").font(.caption.bold()).padding(.horizontal, 6).background(.green.opacity(0.2), in: Capsule())
                        }
                    }
                    .onDelete { idx in let l = chores.filter { !$0.isPaid }.sorted { !$0.isDone && $1.isDone }; idx.forEach { ctx.delete(l[$0]) } }
                }
            }
            .navigationTitle("Aufgaben")
        }
    }
}
