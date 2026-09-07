import SwiftData
import SwiftUI

struct ClientDetailView: View {
    let client: Client

    @Environment(\.modelContext) private var modelContext
    @Environment(AuthManager.self) private var authManager

    @State private var contracts: [Contract] = []
    @State private var pendingReceivables: [Receivable] = []
    @State private var totalInvoiced: Decimal = 0

    var body: some View {
        ZStack {
            ModuleGradient.financeiro.background

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(client.name).font(MioMeiFont.screenTitle).foregroundStyle(OnGradientText.primary)
                        if let document = client.document {
                            Text(document).font(MioMeiFont.metadata).foregroundStyle(OnGradientText.secondary)
                        }
                    }
                    .padding(.top, 8)

                    GlassCard {
                        HStack {
                            statBlock("Já faturado", totalInvoiced.brl)
                            Divider().overlay(Color.white.opacity(0.14))
                            statBlock("A receber", pendingReceivables.reduce(Decimal(0)) { $0 + $1.amount }.brl)
                        }
                    }

                    Text("Contratos").sectionLabelStyle().foregroundStyle(OnGradientText.label)
                    if contracts.isEmpty {
                        GlassCard {
                            Text("Nenhum contrato ainda.").font(MioMeiFont.metadata).foregroundStyle(OnGradientText.secondary)
                        }
                    } else {
                        ForEach(contracts) { contract in
                            NavigationLink(value: contract) {
                                GlassListRow(title: contract.title, metadata: contract.status.rawValue) {
                                    Image(systemName: contract.type == .pj ? "briefcase" : "bolt")
                                        .foregroundStyle(OnGradientText.primary)
                                        .frame(width: 40, height: 40)
                                } trailing: {
                                    Text((contract.estimatedValue ?? 0).brl).font(MioMeiFont.metadata).foregroundStyle(OnGradientText.primary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Text("Recebimentos pendentes").sectionLabelStyle().foregroundStyle(OnGradientText.label)
                    if pendingReceivables.isEmpty {
                        GlassCard {
                            Text("Nada pendente.").font(MioMeiFont.metadata).foregroundStyle(OnGradientText.secondary)
                        }
                    } else {
                        ForEach(pendingReceivables) { receivable in
                            GlassListRow(title: receivable.receivableDescription ?? "Recebimento", metadata: receivable.dueDate.shortBR) {
                                Text(receivable.dueDate.shortBR).font(MioMeiFont.metadata).foregroundStyle(OnGradientText.secondary)
                                    .frame(width: 40)
                            } trailing: {
                                Text(receivable.amount.brl).font(MioMeiFont.metadata).foregroundStyle(OnGradientText.primary)
                            }
                        }
                    }
                }
                .padding(20)
                .padding(.bottom, 60)
            }
        }
        .onAppear(perform: load)
    }

    private func statBlock(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(MioMeiFont.metadata).foregroundStyle(OnGradientText.secondary)
            Text(value).font(.system(size: 20, weight: .semibold)).foregroundStyle(OnGradientText.primary).numericTabular()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func load() {
        guard let userId = authManager.currentUserId else { return }
        let queueStore = SyncQueueStore(modelContext: modelContext)
        let clientId = client.id

        contracts = (try? ContractRepository(modelContext: modelContext, queueStore: queueStore, userId: userId).all()
            .filter { $0.clientId == clientId }) ?? []

        let receivableRepo = ReceivableRepository(modelContext: modelContext, queueStore: queueStore, userId: userId)
        let allReceivables = (try? receivableRepo.all().filter { $0.clientId == clientId }) ?? []
        pendingReceivables = allReceivables.filter { $0.status != .received }
        totalInvoiced = allReceivables.filter { $0.status == .received }.reduce(0) { $0 + $1.amount }
    }
}
