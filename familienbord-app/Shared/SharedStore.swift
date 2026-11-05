import Foundation
import SwiftData

/// Eine Datenbank für App, Widget und Siri. Die App synchronisiert über iCloud (CloudKit),
/// Widget und Intents lesen dieselbe Datei über die App Group.
enum SharedStore {
    static let appGroup = "group.de.example.familienbord"      // anpassen, siehe project.yml
    static let cloudContainer = "iCloud.de.example.familienbord"

    static let schema = Schema([FamilyMember.self, Shift.self, Event.self, ShoppingItem.self, TodoItem.self,
                                MealProposal.self, Chore.self, FamilyDocument.self, ChatMessage.self])

    static func makeContainer(sync: Bool) -> ModelContainer {
        let config = ModelConfiguration(schema: schema,
                                        groupContainer: .identifier(appGroup),
                                        cloudKitDatabase: sync ? .private(cloudContainer) : .none)
        do { return try ModelContainer(for: schema, configurations: [config]) }
        catch { fatalError("Datenbank konnte nicht geöffnet werden: \(error)") }
    }
}

/// Reine Planungslogik, ohne UI, damit sie sich per Unit-Test prüfen lässt.
enum Planner {
    static func intervals(for memberID: UUID, on day: Date, shifts: [Shift]) -> [Range<Int>] {
        let cal = Calendar.current
        let d0 = cal.startOfDay(for: day)
        var out: [Range<Int>] = []
        for s in shifts where s.memberID == memberID && !s.isFree && s.startMinute != s.endMinute {
            if s.day == d0 { out.append(s.startMinute..<(s.endMinute > s.startMinute ? s.endMinute : 1440)) }
            else if s.endMinute < s.startMinute, s.endMinute > 0, let prev = cal.date(byAdding: .day, value: -1, to: d0), s.day == prev {
                out.append(0..<s.endMinute)
            }
        }
        return out.sorted { $0.lowerBound < $1.lowerBound }
    }

    static func minutes(_ date: Date) -> Int {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }

    static func hhmm(_ m: Int) -> String { String(format: "%02d:%02d", (m / 60) % 24 + (m == 1440 ? 24 : 0), m % 60) }

    static func homeText(for memberID: UUID, on day: Date, shifts: [Shift]) -> String {
        let work = intervals(for: memberID, on: day, shifts: shifts)
        let d0 = Calendar.current.startOfDay(for: day)
        if work.isEmpty {
            let free = shifts.contains { $0.memberID == memberID && $0.day == d0 && $0.isFree }
            return free ? "Frei, den ganzen Tag zu Hause" : "Kein Dienst eingetragen"
        }
        var free: [Range<Int>] = [], cur = 0
        for w in work { if w.lowerBound - cur >= 30 { free.append(cur..<w.lowerBound) }; cur = max(cur, w.upperBound) }
        if 1440 - cur >= 30 { free.append(cur..<1440) }
        if free.isEmpty { return "Den ganzen Tag im Dienst" }
        return "Zu Hause " + free.map { "\(hhmm($0.lowerBound))–\(hhmm($0.upperBound))" }.joined(separator: ", ")
    }

    /// Grund, warum die Abholperson nicht kann (30 Minuten nach Terminende), sonst nil.
    static func pickupConflict(_ e: Event, shifts: [Shift], events: [Event]) -> String? {
        guard let p = e.pickupMemberID else { return nil }
        let a = minutes(e.end), b = a + 30
        let day = Calendar.current.startOfDay(for: e.end)
        if intervals(for: p, on: day, shifts: shifts).contains(where: { $0.lowerBound < b && a < $0.upperBound }) { return "Dienst" }
        let busy = events.contains { o in
            o.id != e.id && o.memberID == p && Calendar.current.isDate(o.start, inSameDayAs: e.end)
                && minutes(o.start) < b && a < minutes(o.end)
        }
        return busy ? "eigener Termin" : nil
    }
}
