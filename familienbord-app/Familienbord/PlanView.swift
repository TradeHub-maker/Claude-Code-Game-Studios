import SwiftUI
import SwiftData

struct PlanView: View {
    @Environment(\.modelContext) private var ctx
    @Query(sort: \FamilyMember.name) private var members: [FamilyMember]
    @Query private var shifts: [Shift]
    @Query(sort: \Event.start) private var events: [Event]
    @Query private var docs: [FamilyDocument]
    @State private var day = Date()
    @State private var sheet: Sheet?
    enum Sheet: String, Identifiable { case event, shift, members; var id: String { rawValue } }

    private func name(_ id: UUID?) -> String { members.first { $0.id == id }?.name ?? "?" }
    private func dayEvents(_ d: Date, for m: UUID? = nil) -> [Event] {
        events.filter { Calendar.current.isDate($0.start, inSameDayAs: d) && (m == nil || $0.memberID == m) }
    }

    private var alerts: [String] {
        var out: [String] = []
        for d in docs.filter({ $0.needsAttention }) {
            let n = d.daysLeft() ?? 0
            out.append(n < 0 ? "Frist überschritten: \(d.title)" : "Frist in \(n) Tg.: \(d.title)")
        }
        for i in 0..<7 {
            guard let d = Calendar.current.date(byAdding: .day, value: i, to: Calendar.current.startOfDay(for: Date())) else { continue }
            for e in dayEvents(d) {
                if e.pickupOpen { out.append("\(d.formatted(.dateTime.weekday().day().month())): Wer holt „\(e.title)“ ab?") }
                else if let c = Planner.pickupConflict(e, shifts: shifts, events: events) {
                    out.append("\(d.formatted(.dateTime.weekday().day().month())): \(name(e.pickupMemberID)) kann „\(e.title)“ nicht abholen (\(c))")
                }
            }
        }
        return out
    }

    var body: some View {
        NavigationStack {
            List {
                if members.isEmpty {
                    Section { Button("Familie einrichten") { sheet = .members } }
                }
                if !alerts.isEmpty {
                    Section("Das braucht Aufmerksamkeit") {
                        ForEach(alerts, id: \.self) { Label($0, systemImage: "exclamationmark.triangle.fill").foregroundStyle(.orange) }
                    }
                }
                Section { DatePicker("Tag", selection: $day, displayedComponents: .date).datePickerStyle(.graphical) }
                ForEach(members) { m in
                    Section {
                        Label(Planner.homeText(for: m.id, on: day, shifts: shifts), systemImage: "house")
                        ForEach(Planner.intervals(for: m.id, on: day, shifts: shifts), id: \.lowerBound) { r in
                            Label("Dienst \(Planner.hhmm(r.lowerBound))–\(Planner.hhmm(r.upperBound))", systemImage: "briefcase").foregroundStyle(.secondary)
                        }
                        ForEach(dayEvents(day, for: m.id)) { e in EventRow(event: e, members: members, conflict: Planner.pickupConflict(e, shifts: shifts, events: events)) }
                            .onDelete { for i in $0 { ctx.delete(dayEvents(day, for: m.id)[i]) } }
                    } header: { HStack { Circle().fill(m.color).frame(width: 10, height: 10); Text(m.name) } }
                }
            }
            .navigationTitle(day.formatted(.dateTime.weekday(.wide).day().month(.wide)))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button { sheet = .members } label: { Image(systemName: "person.2") } }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu { Button("Termin", systemImage: "calendar.badge.plus") { sheet = .event }
                           Button("Dienst", systemImage: "briefcase") { sheet = .shift } } label: { Image(systemName: "plus") }
                }
            }
            .sheet(item: $sheet) { s in
                switch s {
                case .event: EventForm(day: day)
                case .shift: ShiftForm(day: day)
                case .members: MembersView()
                }
            }
        }
    }
}

struct EventRow: View {
    @Bindable var event: Event
    let members: [FamilyMember]
    let conflict: String?
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("\(event.start.formatted(date: .omitted, time: .shortened))–\(event.end.formatted(date: .omitted, time: .shortened))").monospacedDigit().bold()
                Text(event.title)
            }
            HStack {
                Picker("Abholung", selection: Binding(get: { event.pickupOpen ? "open" : (event.pickupMemberID?.uuidString ?? "") },
                                                      set: { v in event.pickupOpen = v == "open"; event.pickupMemberID = UUID(uuidString: v) })) {
                    Text("Keine Abholung").tag("")
                    Text("Abholung offen").tag("open")
                    ForEach(members.filter { !$0.isChild }) { Text("Holt ab: \($0.name)").tag($0.id.uuidString) }
                }.pickerStyle(.menu).labelsHidden()
                if let conflict { Text("Überschneidung: \(conflict)").font(.caption).padding(4).background(.red.opacity(0.15), in: Capsule()).foregroundStyle(.red) }
            }
        }
    }
}

struct EventForm: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \FamilyMember.name) private var members: [FamilyMember]
    let day: Date
    @State private var title = ""
    @State private var memberID: UUID?
    @State private var start: Date
    @State private var end: Date
    @State private var pickupID: UUID?
    @State private var pickupOpen = false
    @State private var weekly = false
    init(day: Date) {
        self.day = day
        let c = Calendar.current
        _start = State(initialValue: c.date(bySettingHour: 16, minute: 0, second: 0, of: day) ?? day)
        _end = State(initialValue: c.date(bySettingHour: 17, minute: 30, second: 0, of: day) ?? day)
    }
    var body: some View {
        NavigationStack {
            Form {
                TextField("Was (z. B. Fußballtraining)", text: $title)
                MemberPicker(title: "Für wen", selection: $memberID)
                DatePicker("Von", selection: $start)
                DatePicker("Bis", selection: $end, displayedComponents: .hourAndMinute)
                Toggle("Abholung noch offen", isOn: $pickupOpen)
                if !pickupOpen { MemberPicker(title: "Holt ab", selection: $pickupID, allowNone: "Keine Abholung") }
                Toggle("Jede Woche (8 Wochen)", isOn: $weekly)
            }
            .navigationTitle("Termin")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Sichern", action: save).disabled(title.isEmpty || (memberID ?? members.first?.id) == nil) }
            }
            .onAppear { if memberID == nil { memberID = members.first?.id } }
        }
    }
    private func save() {
        guard let mid = memberID ?? members.first?.id else { return }
        let c = Calendar.current
        let endTime = c.dateComponents([.hour, .minute], from: end)
        for w in 0..<(weekly ? 8 : 1) {
            guard let s = c.date(byAdding: .weekOfYear, value: w, to: start),
                  let e = c.date(bySettingHour: endTime.hour ?? 0, minute: endTime.minute ?? 0, second: 0, of: s) else { continue }
            ctx.insert(Event(title: title, memberID: mid, start: s, end: e, pickupMemberID: pickupOpen ? nil : pickupID, pickupOpen: pickupOpen))
        }
        dismiss()
    }
}

struct ShiftForm: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \FamilyMember.name) private var members: [FamilyMember]
    let day: Date
    @State private var memberID: UUID?
    @State private var from: Date
    @State private var to: Date
    @State private var kind = "Früh"
    @State private var importText = ""
    @State private var importResult = ""
    init(day: Date) { self.day = day; _from = State(initialValue: day); _to = State(initialValue: day) }

    var body: some View {
        NavigationStack {
            Form {
                MemberPicker(title: "Wessen Dienst", selection: $memberID)
                Section("Schicht eintragen") {
                    DatePicker("Von", selection: $from, displayedComponents: .date)
                    DatePicker("Bis", selection: $to, in: from..., displayedComponents: .date)
                    Picker("Schicht", selection: $kind) { ForEach(Shift.presets, id: \.0) { Text($0.0).tag($0.0) } }
                    Button("Speichern") { saveRange() }
                }
                Section("Dienstplan importieren") {
                    Text("Eine Zeile pro Tag, z. B. „09.11.2026 Früh“, „10.11. Spät“, „11.11. 07:30-15:45“, „12.11. Frei“.").font(.footnote).foregroundStyle(.secondary)
                    TextEditor(text: $importText).frame(minHeight: 110)
                    Button("Importieren") { runImport() }
                    if !importResult.isEmpty { Text(importResult).font(.footnote) }
                }
            }
            .navigationTitle("Dienstplan")
            .toolbar { Button("Fertig") { dismiss() } }
            .onAppear { if memberID == nil { memberID = members.first?.id } }
        }
    }

    /// Ersetzt einen vorhandenen Eintrag derselben Person am selben Tag.
    private func put(_ mid: UUID, _ d: Date, _ kind: String, _ s: Int, _ e: Int) {
        let d0 = Calendar.current.startOfDay(for: d)
        let old = (try? ctx.fetch(FetchDescriptor<Shift>())) ?? []
        old.filter { $0.memberID == mid && $0.day == d0 }.forEach { ctx.delete($0) }
        ctx.insert(Shift(memberID: mid, day: d0, kind: kind, startMinute: s, endMinute: e))
    }
    private func saveRange() {
        guard let mid = memberID ?? members.first?.id, let p = Shift.presets.first(where: { $0.0 == kind }) else { return }
        var d = Calendar.current.startOfDay(for: from)
        let last = Calendar.current.startOfDay(for: to)
        var n = 0
        while d <= last && n < 62 { put(mid, d, p.0, p.1, p.2); d = Calendar.current.date(byAdding: .day, value: 1, to: d)!; n += 1 }
        importResult = "\(n) Tag(e) gespeichert"
    }
    private func runImport() {
        guard let mid = memberID ?? members.first?.id else { return }
        var ok = 0, bad = 0
        for raw in importText.split(separator: "\n") {
            if let r = Self.parseLine(String(raw)) { put(mid, r.day, r.kind, r.start, r.end); ok += 1 } else { bad += 1 }
        }
        importResult = "\(ok) Tage importiert" + (bad > 0 ? ", \(bad) Zeilen nicht erkannt" : "")
    }

    static func parseLine(_ line: String) -> (day: Date, kind: String, start: Int, end: Int)? {
        let cal = Calendar.current
        var comps = DateComponents()
        var rest = line
        if let m = line.range(of: #"\d{4}-\d{2}-\d{2}"#, options: .regularExpression) {
            let p = line[m].split(separator: "-").compactMap { Int($0) }
            comps = DateComponents(year: p[0], month: p[1], day: p[2]); rest.removeSubrange(m)
        } else if let m = line.range(of: #"\d{1,2}\.\d{1,2}\.(\d{4}|\d{2})?"#, options: .regularExpression) {
            let p = line[m].split(separator: ".", omittingEmptySubsequences: true).compactMap { Int($0) }
            var y = p.count > 2 ? p[2] : cal.component(.year, from: Date()); if y < 100 { y += 2000 }
            comps = DateComponents(year: y, month: p[1], day: p[0]); rest.removeSubrange(m)
        } else { return nil }
        guard let day = cal.date(from: comps) else { return nil }
        let l = rest.lowercased()
        if l.contains("frei") || l.contains("urlaub") { return (day, "Frei", 0, 0) }
        if let m = rest.range(of: #"(\d{1,2})[:.]?(\d{2})?\s*[-–]\s*(\d{1,2})[:.]?(\d{2})?"#, options: .regularExpression) {
            let nums = rest[m].split(whereSeparator: { !$0.isNumber }).compactMap { Int($0) }
            if nums.count == 4 { return (day, "Eigene", nums[0] * 60 + nums[1], nums[2] * 60 + nums[3]) }
            if nums.count == 2 { return (day, "Eigene", nums[0] * 60, nums[1] * 60) }
        }
        for (k, key) in [("Früh", "früh"), ("Früh", "frueh"), ("Spät", "spät"), ("Spät", "spaet"), ("Nacht", "nacht"), ("Tag", "tag")] where l.contains(key) {
            let p = Shift.presets.first { $0.0 == k }!
            return (day, p.0, p.1, p.2)
        }
        return nil
    }
}
