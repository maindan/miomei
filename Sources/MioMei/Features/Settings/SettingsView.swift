import SwiftData
import SwiftUI
import UIKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthManager.self) private var authManager
    @Environment(SyncStatusStore.self) private var syncStatusStore
    @Environment(ConnectivityMonitor.self) private var connectivity
    @Environment(\.dismiss) private var dismiss

    @State private var profile: Profile?
    @State private var taxRegime: TaxRegime = .mei
    @State private var defaultTaxRateText = "0"
    @State private var dasDueDayText = "20"
    @State private var meiCeilingText = ""
    @State private var pendingCount = 0
    @State private var isSyncing = false
    @State private var syncFeedback: String?

    var body: some View {
        ZStack {
            ModuleGradient.perfil.background

            ScrollView {
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

                    Text("Sincronização").sectionLabelStyle().foregroundStyle(OnGradientText.label)
                    GlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 8) {
                                if isSyncing {
                                    ProgressView().tint(.white).controlSize(.small)
                                } else {
                                    Circle().fill(syncDotColor).frame(width: 8, height: 8)
                                }
                                Text(syncStatusLabel).font(MioMeiFont.metadata).foregroundStyle(OnGradientText.primary)
                                Spacer()
                                if pendingCount > 0 {
                                    Text("\(pendingCount) pendente(s)")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(OnGradientText.secondary)
                                }
                            }

                            if let lastSync = syncStatusStore.lastSuccessfulSyncAt {
                                Text("Última sincronização: \(lastSync.formatted(.relative(presentation: .named)))")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(OnGradientText.secondary)
                            }

                            if let syncFeedback {
                                Text(syncFeedback)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(syncFeedback.hasPrefix("Erro") || syncFeedback.hasPrefix("Sem") ? Semantic.overdue : Semantic.received)
                            }

                            Button {
                                Task { await syncNow() }
                            } label: {
                                Text(isSyncing ? "Sincronizando…" : "Sincronizar agora")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(.black)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                            }
                            .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .disabled(isSyncing)
                        }
                    }

                    Text("Regime tributário e impostos").sectionLabelStyle().foregroundStyle(OnGradientText.label)
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Picker("Regime", selection: $taxRegime) {
                                Text("MEI").tag(TaxRegime.mei)
                                Text("Simples Nacional").tag(TaxRegime.simples)
                                Text("Outro").tag(TaxRegime.other)
                            }
                            .pickerStyle(.segmented)

                            settingsField("Alíquota padrão (%)", text: $defaultTaxRateText, keyboardType: .decimalPad)

                            if taxRegime == .mei {
                                settingsField("Dia de vencimento do DAS", text: $dasDueDayText, keyboardType: .numberPad)
                                settingsField("Teto anual MEI (R$)", text: $meiCeilingText, keyboardType: .decimalPad)
                            }

                            PrimaryButton(title: "Salvar") { save() }
                        }
                    }

                    Text("Conta").sectionLabelStyle().foregroundStyle(OnGradientText.label)
                    DestructiveButton(title: "Sair") {
                        Task { try? await authManager.signOut() }
                    }
                }
                .padding(20)
                .padding(.bottom, 40)
            }
        }
        .onAppear(perform: load)
    }

    private func settingsField(_ placeholder: String, text: Binding<String>, keyboardType: UIKeyboardType) -> some View {
        TextField(placeholder, text: text)
            .keyboardType(keyboardType)
            .foregroundStyle(OnGradientText.primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .glassSurface(.field, cornerRadius: Radius.field)
    }

    private func load() {
        guard let userId = authManager.currentUserId else { return }
        profile = try? modelContext.fetch(FetchDescriptor<Profile>(predicate: #Predicate { $0.id == userId })).first
        pendingCount = (try? SyncQueueStore(modelContext: modelContext).pendingCount()) ?? 0
        guard let profile else { return }
        taxRegime = profile.taxRegime
        defaultTaxRateText = "\(profile.defaultTaxRate)"
        dasDueDayText = "\(profile.dasDueDay)"
        meiCeilingText = profile.meiAnnualCeiling.map { "\($0)" } ?? ""
    }

    private func save() {
        guard let profile else { return }
        profile.taxRegime = taxRegime
        profile.defaultTaxRate = Decimal(string: defaultTaxRateText.replacingOccurrences(of: ",", with: ".")) ?? 0
        profile.dasDueDay = Int(dasDueDayText) ?? 20
        profile.meiAnnualCeiling = Decimal(string: meiCeilingText.replacingOccurrences(of: ",", with: "."))
        profile.updatedAt = .now
        let queueStore = SyncQueueStore(modelContext: modelContext)
        try? LocalRepository<Profile>(modelContext: modelContext, queueStore: queueStore, entityName: "profile").update(profile, row: profile.asRow)
        pendingCount = (try? queueStore.pendingCount()) ?? 0
    }

    /// Botão "Sincronizar agora" (mio-escopo.md §10.1): força push+pull e dá
    /// retorno explícito de conclusão/erro.
    private func syncNow() async {
        guard connectivity.isConnected else {
            syncFeedback = "Sem conexão — sincroniza automaticamente quando a rede voltar."
            return
        }
        isSyncing = true
        syncFeedback = nil
        let engine = SyncEngine(
            modelContext: modelContext,
            queueStore: SyncQueueStore(modelContext: modelContext),
            statusStore: syncStatusStore,
            connectivity: connectivity,
            supabase: SupabaseService.shared
        )
        await engine.syncNow()
        isSyncing = false
        pendingCount = (try? SyncQueueStore(modelContext: modelContext).pendingCount()) ?? 0

        switch syncStatusStore.status {
        case .synced:
            syncFeedback = "Tudo sincronizado"
            #if canImport(UIKit)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            #endif
        case .error(let message):
            syncFeedback = "Erro: \(message)"
        default:
            break
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
