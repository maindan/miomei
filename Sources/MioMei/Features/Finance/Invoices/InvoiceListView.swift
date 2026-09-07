import SwiftUI

struct InvoiceListView: View {
    @Binding var invoices: [Invoice]
    let onMarkIssued: (Invoice) -> Void

    var body: some View {
        if invoices.isEmpty {
            GlassCard {
                Text("Nenhuma nota cadastrada ainda.").font(MioMeiFont.metadata).foregroundStyle(OnGradientText.secondary)
            }
        } else {
            List {
                ForEach(invoices) { invoice in
                    row(invoice)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
                        .swipeActions(edge: .trailing) {
                            if invoice.status != .issued {
                                Button("Emitida") { onMarkIssued(invoice) }.tint(.green)
                            }
                        }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .frame(minHeight: CGFloat(invoices.count) * 72)
            .scrollDisabled(true)
        }
    }

    private func row(_ invoice: Invoice) -> some View {
        GlassListRow(
            title: invoice.number.map { "Nota \($0)" } ?? "Nota fiscal",
            metadata: invoice.plannedDate?.mediumBR
        ) {
            Circle().fill(invoice.status == .issued ? Semantic.received : Semantic.attention)
                .frame(width: 10, height: 10).frame(width: 40)
        } trailing: {
            Text(invoice.amount.brl).font(MioMeiFont.metadata).foregroundStyle(OnGradientText.primary)
        }
    }
}
