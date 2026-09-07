import SwiftData
import SwiftUI

/// Central de notificações in-app (mio-escopo.md §11).
struct NotificationCenterView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthManager.self) private var authManager
    @Environment(\.dismiss) private var dismiss

    @State private var items: [NotificationItem] = []

    var body: some View {
        ZStack {
            ModuleGradient.perfil.background

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Notificações").font(MioMeiFont.screenTitle).foregroundStyle(OnGradientText.primary)
                    Spacer()
                    if !items.isEmpty {
                        Button("Limpar") { clearAll() }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(OnGradientText.secondary)
                    }
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(OnGradientText.primary)
                            .frame(width: 34, height: 34)
                            .glassSurface(.light, cornerRadius: 17)
                    }
                }
                .padding(.top, 12)

                if items.isEmpty {
                    GlassCard {
                        Text("Nenhuma notificação por aqui.").font(MioMeiFont.metadata).foregroundStyle(OnGradientText.secondary)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(items) { item in
                                Button { markRead(item) } label: {
                                    GlassListRow(title: item.title, metadata: item.body) {
                                        Circle()
                                            .fill(item.readAt == nil ? Semantic.attention : OnGradientText.secondary)
                                            .frame(width: 8, height: 8)
                                            .frame(width: 40)
                                    } trailing: {
                                        Text(item.createdAt.shortBR).font(.system(size: 10, weight: .semibold)).foregroundStyle(OnGradientText.secondary)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
        .onAppear(perform: reload)
    }

    private func notificationRepository() -> NotificationRepository? {
        guard let userId = authManager.currentUserId else { return nil }
        return NotificationRepository(modelContext: modelContext, queueStore: SyncQueueStore(modelContext: modelContext), userId: userId)
    }

    private func markRead(_ item: NotificationItem) {
        try? notificationRepository()?.markRead(item)
        reload()
    }

    private func clearAll() {
        try? notificationRepository()?.clearAll()
        reload()
    }

    private func reload() {
        items = (try? notificationRepository()?.all()) ?? []
    }
}
