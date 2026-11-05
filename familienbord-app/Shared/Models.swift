import Foundation
import SwiftData

// CloudKit-Regeln: jede Eigenschaft hat einen Standardwert, keine unique-Constraints,
// Verweise zwischen Objekten laufen über UUIDs statt über Relationships.

@Model final class FamilyMember {
    var id: UUID = UUID()
    var name: String = ""
    var isChild: Bool = false
    var colorIndex: Int = 0
    init(name: String, isChild: Bool, colorIndex: Int) {
        self.name = name; self.isChild = isChild; self.colorIndex = colorIndex
    }
}

/// Ein Diensttag. `startMinute`/`endMinute` in Minuten ab 0 Uhr; Ende <= Beginn heißt Nachtdienst über Mitternacht.
@Model final class Shift {
    var id: UUID = UUID()
    var memberID: UUID = UUID()
    var day: Date = Date()          // Beginn des Kalendertags
    var kind: String = "Früh"       // Früh, Spät, Nacht, Tag, Frei, Eigene
    var startMinute: Int = 360
    var endMinute: Int = 840
    init(memberID: UUID, day: Date, kind: String, startMinute: Int, endMinute: Int) {
        self.memberID = memberID; self.day = Calendar.current.startOfDay(for: day)
        self.kind = kind; self.startMinute = startMinute; self.endMinute = endMinute
    }
    var isFree: Bool { kind == "Frei" }
    static let presets: [(String, Int, Int)] = [("Früh", 360, 840), ("Spät", 840, 1320), ("Nacht", 1320, 360), ("Tag", 480, 960), ("Frei", 0, 0)]
}

@Model final class Event {
    var id: UUID = UUID()
    var title: String = ""
    var memberID: UUID = UUID()
    var start: Date = Date()
    var end: Date = Date()
    var pickupMemberID: UUID?
    var pickupOpen: Bool = false
    init(title: String, memberID: UUID, start: Date, end: Date, pickupMemberID: UUID? = nil, pickupOpen: Bool = false) {
        self.title = title; self.memberID = memberID; self.start = start; self.end = end
        self.pickupMemberID = pickupMemberID; self.pickupOpen = pickupOpen
    }
}

@Model final class ShoppingItem {
    var id: UUID = UUID()
    var title: String = ""
    var store: String = "Supermarkt"
    var isDone: Bool = false
    var mealID: UUID?
    var createdAt: Date = Date()
    init(title: String, store: String = "Supermarkt", mealID: UUID? = nil) {
        self.title = title; self.store = store; self.mealID = mealID
    }
}

@Model final class TodoItem {
    var id: UUID = UUID()
    var title: String = ""
    var assigneeID: UUID?
    var due: Date?
    var isDone: Bool = false
    init(title: String, assigneeID: UUID? = nil, due: Date? = nil) {
        self.title = title; self.assigneeID = assigneeID; self.due = due
    }
}

@Model final class MealProposal {
    var id: UUID = UUID()
    var day: Date = Date()
    var title: String = ""
    var ingredients: String = ""
    var voterIDs: [UUID] = []
    var isChosen: Bool = false
    init(day: Date, title: String, ingredients: String) {
        self.day = Calendar.current.startOfDay(for: day); self.title = title; self.ingredients = ingredients
    }
    var ingredientList: [String] {
        ingredients.split(whereSeparator: { ",;\n".contains($0) }).map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }
}

@Model final class Chore {
    var id: UUID = UUID()
    var title: String = ""
    var points: Int = 5
    var assigneeID: UUID?
    var isDone: Bool = false
    var isPaid: Bool = false
    init(title: String, points: Int, assigneeID: UUID?) {
        self.title = title; self.points = points; self.assigneeID = assigneeID
    }
}

@Model final class FamilyDocument {
    var id: UUID = UUID()
    var title: String = ""
    var category: String = "Sonstiges"
    var deadline: Date?
    var remindDays: Int = 14
    var note: String = ""
    init(title: String, category: String, deadline: Date?, remindDays: Int, note: String) {
        self.title = title; self.category = category; self.deadline = deadline; self.remindDays = remindDays; self.note = note
    }
    /// Tage bis zur Frist; negativ = überfällig.
    func daysLeft(from now: Date = Date()) -> Int? {
        guard let deadline else { return nil }
        return Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: now), to: Calendar.current.startOfDay(for: deadline)).day
    }
    var needsAttention: Bool { if let d = daysLeft() { return d <= remindDays } else { return false } }
}

@Model final class ChatMessage {
    var id: UUID = UUID()
    var authorID: UUID = UUID()
    var text: String = ""
    var isStatus: Bool = false
    var createdAt: Date = Date()
    init(authorID: UUID, text: String, isStatus: Bool = false) {
        self.authorID = authorID; self.text = text; self.isStatus = isStatus
    }
}
