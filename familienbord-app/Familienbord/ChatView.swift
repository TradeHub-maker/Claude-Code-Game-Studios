import SwiftUI
import SwiftData

struct ChatView: View {
    @Environment(\.modelContext) private var ctx
    @Query(sort: \ChatMessage.createdAt) private var messages: [ChatMessage]
    @Query(sort: \FamilyMember.name) private var members: [FamilyMember]
    @Query private var shifts: [Shift]
    @AppStorage("meID") private var meID = ""
    @State private var text = ""

    private func name(_ id: UUID) -> String { members.first { $0.id == id }?.name ?? "?" }
    private func send(_ t: String, status: Bool = false) {
        guard let me = UUID(uuidString: meID) else { return }
        ctx.insert(ChatMessage(authorID: me, text: t, isStatus: status))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                List {
                    Section("Wer ist heute wann zu Hause?") {
                        ForEach(members) { m in HStack { Text(m.name).bold().foregroundStyle(m.color); Spacer(); Text(Planner.homeText(for: m.id, on: Date(), shifts: shifts)).font(.footnote).foregroundStyle(.secondary) } }
                    }
                }.frame(maxHeight: 200)
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 6) {
                            ForEach(messages.suffix(100)) { m in
                                let mine = m.authorID.uuidString == meID
                                Group {
                                    if m.isStatus {
                                        Text("\(name(m.authorID)): \(m.text)").font(.footnote.bold()).padding(8).background(.green.opacity(0.2), in: Capsule()).frame(maxWidth: .infinity)
                                    } else {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("\(name(m.authorID)) · \(m.createdAt.formatted(date: .omitted, time: .shortened))").font(.caption2).opacity(0.7)
                                            Text(m.text)
                                        }.padding(10).background(mine ? Color.accentColor : Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
                                        .foregroundStyle(mine ? .white : .primary).frame(maxWidth: .infinity, alignment: mine ? .trailing : .leading)
                                    }
                                }.id(m.id)
                            }
                        }.padding(.horizontal)
                    }
                    .onChange(of: messages.count) { _, _ in if let l = messages.last { proxy.scrollTo(l.id, anchor: .bottom) } }
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack { ForEach(["Bin angekommen", "Bin zu Hause", "Bin unterwegs", "Komme später"], id: \.self) { s in Button(s) { send(s, status: true) }.buttonStyle(.bordered) } }.padding(.horizontal)
                }
                HStack {
                    TextField("Nachricht", text: $text).textFieldStyle(.roundedBorder).onSubmit(sendText)
                    Button("Senden", action: sendText).buttonStyle(.borderedProminent).disabled(text.isEmpty)
                }.padding()
            }
            .navigationTitle("Chat")
            .overlay { if UUID(uuidString: meID) == nil { ContentUnavailableView("Wer bist du?", systemImage: "person.crop.circle", description: Text("Plan, Familie, dann nach links wischen: „Das bin ich“.")) } }
        }
    }
    private func sendText() { send(text); text = "" }
}
