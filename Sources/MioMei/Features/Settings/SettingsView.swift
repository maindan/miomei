import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthManager.self) private var authManager
    @Environment(SyncStatusStore.self) private var syncStatusStore
    @Environment(\.dismiss) private var dismiss

    @State private var profile: Profile?
    @State private var taxRegime: TaxRegime = .mei
    @State private var defaultTaxRateText = "0"
    @State private var dasDueDayText = "20"
    @State private var meiCeilingText = ""

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
                        HStack(spacing: 8) {
                            Circle().fill(syncDotColor).frame(width: 8, height: 8)
                            Text(syncStatusLabel).font(MioMeiFont.metadata).foregroundStyle(OnGradientText.primary)
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
        try? modelContext.save()
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
