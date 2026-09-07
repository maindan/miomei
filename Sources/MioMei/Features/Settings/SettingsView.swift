import SwiftUI

struct SettingsView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(SyncStatusStore.self) private var syncStatusStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            ModuleGradient.perfil.background

            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Configurações").font(MioMeiFont.screenTitle).foregroundStyle(OnGradientText.primary)
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(OnGradientText.primary)
                            .frame(width: 34, height: 34)
                            .glassSurface(.light, cornerRadius: 17)
                    }
                }
                .padding(.top, 12)

                GlassCard {
                    HStack(spacing: 8) {
                        Circle().fill(syncDotColor).frame(width: 8, height: 8)
                        Text(syncStatusLabel)
                            .font(MioMeiFont.metadata)
                            .foregroundStyle(OnGradientText.primary)
                    }
                }

                GlassCard {
                    Text("Perfil, regime tributário, notificações, cronômetro, sincronização e conta chegam na Fase 5 (mio-escopo.md §10, §16).")
                        .font(MioMeiFont.metadata)
                        .foregroundStyle(OnGradientText.secondary)
                }

                DestructiveButton(title: "Sair") {
                    Task { try? await authManager.signOut() }
                }

                Spacer()
            }
            .padding(20)
        }
    }

    private var syncStatusLabel: String {
        switch syncStatusStore.status {
        case .synced: return "Sincronizado"
        case .pending(let count): return "\(count) pendente(s)"
        case .syncing: return "Sincronizando…"
        case .offline: return "Offline"
        case .error(let message): return "Erro: \(message)"
        }
    }

    private var syncDotColor: Color {
        switch syncStatusStore.status {
        case .synced: return Semantic.received
        case .pending: return Semantic.attention
        case .syncing: return .white
        case .offline: return .white.opacity(0.5)
        case .error: return Semantic.overdue
        }
    }
}
