import WidgetKit
import SwiftUI
import SwiftData

struct Entry: TimelineEntry {
    let date: Date
    let items: [String]
    let openCount: Int
    let nextEvent: String?
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> Entry { Entry(date: .now, items: ["Milch", "Brot"], openCount: 2, nextEvent: nil) }
    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) { completion(load()) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        completion(Timeline(entries: [load()], policy: .after(Date().addingTimeInterval(900))))
    }
    /// Das Widget liest dieselbe Datenbank über die App Group, ohne selbst mit iCloud zu synchronisieren.
    private func load() -> Entry {
        let ctx = ModelContext(SharedStore.makeContainer(sync: false))
        let items = ((try? ctx.fetch(FetchDescriptor<ShoppingItem>(sortBy: [SortDescriptor(\.createdAt)]))) ?? []).filter { !$0.isDone }
        let events = ((try? ctx.fetch(FetchDescriptor<Event>(sortBy: [SortDescriptor(\.start)]))) ?? []).filter { $0.end > Date() }
        let next = events.first.map { "\($0.start.formatted(date: .omitted, time: .shortened)) \($0.title)" }
        return Entry(date: .now, items: items.prefix(4).map(\.title), openCount: items.count, nextEvent: next)
    }
}

struct WidgetView: View {
    let entry: Entry
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Einkauf (\(entry.openCount))").font(.headline)
            if entry.items.isEmpty { Text("Nichts offen").foregroundStyle(.secondary) }
            ForEach(entry.items, id: \.self) { Text("• \($0)").font(.footnote) }
            Spacer(minLength: 0)
            if let e = entry.nextEvent { Text("Als Nächstes: \(e)").font(.caption).foregroundStyle(.secondary) }
        }.frame(maxWidth: .infinity, alignment: .leading).containerBackground(.fill.tertiary, for: .widget)
    }
}

@main struct FamilienbordWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "FamilienbordWidget", provider: Provider()) { WidgetView(entry: $0) }
            .configurationDisplayName("Einkaufsliste")
            .description("Offene Artikel und der nächste Termin.")
            .supportedFamilies([.systemSmall, .systemMedium])
    }
}
