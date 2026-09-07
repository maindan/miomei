import SwiftData
import SwiftUI

struct ContractDetailView: View {
    let contract: Contract

    @Environment(\.modelContext) private var modelContext
    @Environment(AuthManager.self) private var authManager

    @State private var received: Decimal = 0
    @State private var renewals: [ContractRenewal] = []
    @State private var showRenewalSheet = false
    @State private var showCloseConfirmation = false

    private var estimated: Decimal { contract.estimatedValue ?? 0 }
    private var remaining: Decimal { estimated - received }

    var body: some View {
        ZStack {
            ModuleGradient.contrato.background

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(contract.title).font(MioMeiFont.screenTitle).foregroundStyle(OnGradientText.primary)
                        Text(contract.type == .pj ? "Contrato PJ" : "Freelance")
                            .font(MioMeiFont.metadata).foregroundStyle(OnGradientText.secondary)
                    }
                    .padding(.top, 8)

                    GlassCard {
                        HStack {
                            statBlock("Estimado", estimated.brl)
                            Divider().overlay(Color.white.opacity(0.14))
                            statBlock("Recebido", received.brl)
                            Divider().overlay(Color.white.opacity(0.14))
                            statBlock("A receber", remaining.brl)
                        }
                    }

                    if let weeklyHours = contract.weeklyHoursRequirement {
                        GlassCard {
                            Text("Exigência: \(weeklyHours.formatted())h/semana — cruzamento com horas chega na Fase 3.")
                                .font(MioMeiFont.metadata)
                                .foregroundStyle(OnGradientText.secondary)
                        }
                    }

                    if let endDate = contract.endDate {
                        GlassCard {
                            HStack {
                                Text("Vigência até \(endDate.mediumBR)")
                                    .font(MioMeiFont.metadata)
                                    .foregroundStyle(OnGradientText.primary)
                                Spacer()
                                Button("Renovar") { showRenewalSheet = true }
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.black)
                                    .padding(.horizontal, 14).padding(.vertical, 8)
                                    .background(Color.white, in: Capsule())
                            }
                        }
                    }

                    if !renewals.isEmpty {
                        Text("Renovações").sectionLabelStyle().foregroundStyle(OnGradientText.label)
                        ForEach(renewals) { renewal in
                            GlassListRow(
                                title: "Até \(renewal.newEndDate.mediumBR)",
                                metadata: renewal.note
                            ) {
                                Image(systemName: "arrow.clockwise").foregroundStyle(OnGradientText.primary).frame(width: 40)
                            } trailing: {
                                if let addedValue = renewal.addedValue {
                                    Text("+\(addedValue.brl)").font(MioMeiFont.metadata).foregroundStyle(Semantic.received)
                                }
                            }
                        }
                    }

                    if contract.status != .closed {
                        DestructiveButton(title: "Encerrar contrato") { showCloseConfirmation = true }
                            .padding(.top, 8)
                    }
                }
                .padding(20)
                .padding(.bottom, 60)
            }
        }
        .sheet(isPresented: $showRenewalSheet) {
            RenewalFormSheet(currentEndDate: contract.endDate) { newEndDate, addedValue, note in
                try? contractRepository()?.renew(contract, newEndDate: newEndDate, addedValue: addedValue, note: note)
                load()
            }
        }
        .alert("Encerrar contrato?", isPresented: $showCloseConfirmation) {
            Button("Cancelar", role: .cancel) {}
            Button("Encerrar", role: .destructive) {
                try? contractRepository()?.close(contract)
            }
        } message: {
            Text("Recebimentos pendentes deste contrato não são apagados.")
        }
        .onAppear(perform: load)
    }

    private func statBlock(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(MioMeiFont.metadata).foregroundStyle(OnGradientText.secondary)
            Text(value).font(.system(size: 15, weight: .semibold)).foregroundStyle(OnGradientText.primary).numericTabular()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func contractRepository() -> ContractRepository? {
        guard let userId = authManager.currentUserId else { return nil }
        return ContractRepository(modelContext: modelContext, queueStore: SyncQueueStore(modelContext: modelContext), userId: userId)
    }

    private func load() {
        guard let userId = authManager.currentUserId else { return }
        let queueStore = SyncQueueStore(modelContext: modelContext)
        received = (try? ReceivableRepository(modelContext: modelContext, queueStore: queueStore, userId: userId).totalReceived(contractId: contract.id)) ?? 0
        renewals = (try? contractRepository()?.renewals(for: contract.id)) ?? []
    }
}
