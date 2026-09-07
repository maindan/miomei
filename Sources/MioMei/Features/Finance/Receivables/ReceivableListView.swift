import SwiftData
import SwiftUI

/// Usa `List` (não `ScrollView`+`VStack`) porque `.swipeActions` só funciona
/// dentro de uma lista — o chrome padrão é escondido para manter o visual glass.
struct ReceivableListView: View {
    @Binding var receivables: [Receivable]
    let onMarkReceived: (Receivable) -> Void

    var body: some View {
        if receivables.isEmpty {
            GlassCard {
                Text("Nenhum recebimento cadastrado ainda.")
                    .font(MioMeiFont.metadata)
                    .foregroundStyle(OnGradientText.secondary)
            }
        } else {
            List {
                ForEach(receivables) { receivable in
                    row(receivable)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
                        .swipeActions(edge: .trailing) {
                            if receivable.status != .received {
                                Button("Recebido") { onMarkReceived(receivable) }.tint(.green)
                            }
                        }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .frame(minHeight: CGFloat(receivables.count) * 72)
            .scrollDisabled(true)
        }
    }

    private func row(_ receivable: Receivable) -> some View {
        GlassListRow(
            title: receivable.receivableDescription ?? "Recebimento",
            metadata: receivable.dueDate.mediumBR
        ) {
            statusDot(receivable.status)
        } trailing: {
            Text(receivable.amount.brl).font(MioMeiFont.metadata).foregroundStyle(OnGradientText.primary)
        }
    }

    private func statusDot(_ status: ReceivableStatus) -> some View {
        let color: Color = switch status {
        case .received: Semantic.received
        case .expected: Semantic.info
        case .overdue: Semantic.overdue
        }
        return Circle().fill(color).frame(width: 10, height: 10).frame(width: 40)
    }
}
