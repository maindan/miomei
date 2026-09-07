import SwiftData
import SwiftUI

struct PayableListView: View {
    @Binding var payables: [Payable]
    let onMarkPaid: (Payable) -> Void

    var body: some View {
        if payables.isEmpty {
            GlassCard {
                Text("Nenhum pagamento cadastrado ainda.")
                    .font(MioMeiFont.metadata)
                    .foregroundStyle(OnGradientText.secondary)
            }
        } else {
            List {
                ForEach(payables) { payable in
                    row(payable)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
                        .swipeActions(edge: .trailing) {
                            if payable.status != .paid {
                                Button("Pago") { onMarkPaid(payable) }.tint(.green)
                            }
                        }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .frame(minHeight: CGFloat(payables.count) * 72)
            .scrollDisabled(true)
        }
    }

    private func row(_ payable: Payable) -> some View {
        GlassListRow(
            title: payable.payableDescription ?? typeLabel(payable.type),
            metadata: payable.dueDate.mediumBR
        ) {
            statusDot(payable.status)
        } trailing: {
            Text(payable.amount.brl).font(MioMeiFont.metadata).foregroundStyle(OnGradientText.primary)
        }
    }

    private func typeLabel(_ type: PayableType) -> String {
        switch type {
        case .dasMei: return "DAS-MEI"
        case .invoiceTax: return "Imposto sobre nota"
        case .other: return "Pagamento"
        }
    }

    private func statusDot(_ status: PayableStatus) -> some View {
        let color: Color = switch status {
        case .paid: Semantic.received
        case .pending: Semantic.attention
        case .overdue: Semantic.overdue
        }
        return Circle().fill(color).frame(width: 10, height: 10).frame(width: 40)
    }
}
