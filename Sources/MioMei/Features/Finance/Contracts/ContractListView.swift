import SwiftData
import SwiftUI

struct ContractListView: View {
    @Binding var contracts: [Contract]
    let clients: [Client]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if contracts.isEmpty {
                GlassCard {
                    Text("Nenhum contrato ainda. Toque em + para criar o primeiro.")
                        .font(MioMeiFont.metadata)
                        .foregroundStyle(OnGradientText.secondary)
                }
            } else {
                ForEach(contracts) { contract in
                    NavigationLink(value: contract) {
                        GlassListRow(title: contract.title, metadata: clientName(contract.clientId)) {
                            Image(systemName: contract.type == .pj ? "briefcase" : "bolt")
                                .foregroundStyle(OnGradientText.primary)
                                .frame(width: 40, height: 40)
                        } trailing: {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text((contract.estimatedValue ?? 0).brl)
                                    .font(MioMeiFont.metadata)
                                    .foregroundStyle(OnGradientText.primary)
                                Text(contract.status.rawValue)
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(statusColor(contract.status))
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func clientName(_ clientId: UUID?) -> String? {
        clients.first { $0.id == clientId }?.name
    }

    private func statusColor(_ status: ContractStatus) -> Color {
        switch status {
        case .active: return Semantic.received
        case .suspended: return Semantic.attention
        case .closed: return OnGradientText.secondary
        }
    }
}
