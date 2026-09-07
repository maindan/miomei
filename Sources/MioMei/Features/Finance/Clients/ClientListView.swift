import SwiftData
import SwiftUI

struct ClientListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthManager.self) private var authManager

    @State private var clients: [Client] = []
    @State private var showCreate = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ModuleGradient.financeiro.background

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Clientes").font(MioMeiFont.screenTitle).foregroundStyle(OnGradientText.primary)
                        .padding(.top, 8)

                    if clients.isEmpty {
                        GlassCard {
                            Text("Nenhum cliente ainda. Toque em + para cadastrar o primeiro.")
                                .font(MioMeiFont.metadata)
                                .foregroundStyle(OnGradientText.secondary)
                        }
                    } else {
                        ForEach(clients) { client in
                            NavigationLink(value: client) {
                                GlassListRow(title: client.name, metadata: client.document) {
                                    initialsAvatar(client.name)
                                } trailing: {
                                    Image(systemName: "chevron.right").foregroundStyle(OnGradientText.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(20)
                .padding(.bottom, 100)
            }

            CreateFAB { showCreate = true }
                .padding(.trailing, 20)
                .padding(.bottom, 24)
        }
        .sheet(isPresented: $showCreate) {
            ClientFormSheet { name, document, email, phone, notes in
                try? repository()?.create(name: name, document: document, email: email, phone: phone, notes: notes)
                reload()
            }
        }
        .onAppear(perform: reload)
    }

    private func initialsAvatar(_ name: String) -> some View {
        let initials = name.split(separator: " ").prefix(2).compactMap(\.first).map(String.init).joined()
        return Text(initials.uppercased())
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(.black)
            .frame(width: 40, height: 40)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func repository() -> ClientRepository? {
        guard let userId = authManager.currentUserId else { return nil }
        return ClientRepository(modelContext: modelContext, queueStore: SyncQueueStore(modelContext: modelContext), userId: userId)
    }

    private func reload() {
        clients = (try? repository()?.all()) ?? []
    }
}
