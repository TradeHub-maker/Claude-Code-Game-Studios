import SwiftUI
import SwiftData

struct MealsView: View {
    @Environment(\.modelContext) private var ctx
    @Query(sort: \MealProposal.day) private var meals: [MealProposal]
    @Query private var items: [ShoppingItem]
    @Query(sort: \FamilyMember.name) private var members: [FamilyMember]
    @AppStorage("meID") private var meID = ""
    @State private var weekOffset = 0
    @State private var addingFor: Date?
    @State private var title = ""
    @State private var ingredients = ""

    private var days: [Date] {
        let cal = Calendar(identifier: .gregorian)
        let monday = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        let start = cal.date(byAdding: .weekOfYear, value: weekOffset, to: monday)!
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack { Button("‹ Woche") { weekOffset -= 1 }; Spacer(); Button("Woche ›") { weekOffset += 1 } }.buttonStyle(.borderless)
                    Text("Schlag Gerichte vor, die Familie stimmt ab. „Festlegen“ legt die Zutaten auf die Einkaufsliste.").font(.footnote).foregroundStyle(.secondary)
                }
                ForEach(days, id: \.self) { d in
                    Section(d.formatted(.dateTime.weekday(.wide).day().month())) {
                        ForEach(meals.filter { Calendar.current.isDate($0.day, inSameDayAs: d) }) { m in
                            VStack(alignment: .leading) {
                                Text(m.title + (m.isChosen ? " (festgelegt)" : "")).bold().foregroundStyle(m.isChosen ? .green : .primary)
                                if !m.ingredients.isEmpty { Text(m.ingredientList.joined(separator: ", ")).font(.footnote).foregroundStyle(.secondary) }
                                HStack {
                                    Button("Dafür (\(m.voterIDs.count))") { toggleVote(m) }.buttonStyle(.bordered)
                                    if !m.isChosen { Button("Festlegen") { choose(m, on: d) }.buttonStyle(.bordered) }
                                }
                                if !m.voterIDs.isEmpty { Text(m.voterIDs.compactMap { id in members.first { $0.id == id }?.name }.joined(separator: ", ")).font(.caption).foregroundStyle(.secondary) }
                            }
                        }
                        .onDelete { idx in
                            let list = meals.filter { Calendar.current.isDate($0.day, inSameDayAs: d) }
                            idx.forEach { remove(list[$0]) }
                        }
                        if addingFor == d {
                            TextField("Gericht", text: $title)
                            TextField("Zutaten (Komma getrennt)", text: $ingredients)
                            Button("Vorschlagen") { ctx.insert(MealProposal(day: d, title: title, ingredients: ingredients)); title = ""; ingredients = ""; addingFor = nil }.disabled(title.isEmpty)
                        } else { Button("+ Gericht vorschlagen") { addingFor = d } }
                    }
                }
            }
            .navigationTitle("Essensplan")
        }
    }

    private func toggleVote(_ m: MealProposal) {
        guard let me = UUID(uuidString: meID) else { return }
        if m.voterIDs.contains(me) { m.voterIDs.removeAll { $0 == me } } else { m.voterIDs.append(me) }
    }
    private func remove(_ m: MealProposal) {
        items.filter { $0.mealID == m.id && !$0.isDone }.forEach(ctx.delete); ctx.delete(m)
    }
    /// Genau ein Gericht pro Tag ist festgelegt; seine Zutaten landen auf der Liste, die der anderen verschwinden.
    private func choose(_ m: MealProposal, on d: Date) {
        for o in meals where Calendar.current.isDate(o.day, inSameDayAs: d) {
            o.isChosen = o.id == m.id
            if o.id != m.id { items.filter { $0.mealID == o.id && !$0.isDone }.forEach(ctx.delete) }
        }
        guard !items.contains(where: { $0.mealID == m.id }) else { return }
        for t in m.ingredientList where !items.contains(where: { !$0.isDone && $0.title.lowercased() == t.lowercased() }) {
            ctx.insert(ShoppingItem(title: t, store: "Supermarkt", mealID: m.id))
        }
    }
}
