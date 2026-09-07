import SwiftUI

struct BudgetFormSheet: View {
    let clients: [Client]
    let onSave: (_ clientId: UUID?, _ title: String, _ items: [BudgetItem], _ validUntil: Date?, _ paymentTerms: String?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var clientId: UUID?
    @State private var items: [BudgetItem] = [BudgetItem(description: "", quantity: 1, unitPrice: 0)]
    @State private var hasValidUntil = true
    @State private var validUntil = Calendar.current.date(byAdding: .day, value: 15, to: .now) ?? .now
    @State private var paymentTerms = ""

    private var total: Decimal { items.reduce(0) { $0 + $1.total } }

    var body: some View {
        ZStack {
            ModuleGradient.financeiro.background.scrimOverlay()
            BottomSheetScaffold(
                title: "Novo orçamento",
                ctaTitle: "Salvar orçamento (\(total.brl))",
                ctaEnabled: !title.isEmpty && !items.isEmpty,
                onSave: {
                    onSave(clientId, title, items.filter { !$0.description.isEmpty }, hasValidUntil ? validUntil : nil, paymentTerms.isEmpty ? nil : paymentTerms)
                    dismiss()
                }
            ) {
                SheetField(placeholder: "Título", text: $title)

                if !clients.isEmpty {
                    Picker("Cliente", selection: $clientId) {
                        Text("Sem cliente").tag(UUID?.none)
                        ForEach(clients) { client in
                            Text(client.name).tag(Optional(client.id))
                        }
                    }
                    .tint(.white)
                }

                Text("Itens").sectionLabelStyle().foregroundStyle(OnGradientText.label)
                ForEach($items) { $item in
                    itemRow($item)
                }
                Button {
                    items.append(BudgetItem(description: "", quantity: 1, unitPrice: 0))
                } label: {
                    Label("Adicionar item", systemImage: "plus.circle")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(OnGradientText.primary)

                Toggle("Tem validade", isOn: $hasValidUntil).tint(.white)
                if hasValidUntil {
                    DatePicker("Válido até", selection: $validUntil, displayedComponents: .date)
                }
                SheetField(placeholder: "Condições de pagamento", text: $paymentTerms)
            }
        }
        .foregroundStyle(OnGradientText.primary)
    }

    private func itemRow(_ item: Binding<BudgetItem>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                SheetField(placeholder: "Descrição", text: item.description)
                if items.count > 1 {
                    Button {
                        items.removeAll { $0.id == item.wrappedValue.id }
                    } label: {
                        Image(systemName: "trash").foregroundStyle(Semantic.overdue)
                    }
                }
            }
            HStack(spacing: 10) {
                SheetField(placeholder: "Qtd", text: quantityText(item), keyboardType: .decimalPad)
                SheetField(placeholder: "Valor unitário", text: unitPriceText(item), keyboardType: .decimalPad)
            }
        }
        .padding(.bottom, 6)
    }

    private func quantityText(_ item: Binding<BudgetItem>) -> Binding<String> {
        Binding(
            get: { "\(item.wrappedValue.quantity)" },
            set: { item.wrappedValue.quantity = Decimal(string: $0.replacingOccurrences(of: ",", with: ".")) ?? 0 }
        )
    }

    private func unitPriceText(_ item: Binding<BudgetItem>) -> Binding<String> {
        Binding(
            get: { "\(item.wrappedValue.unitPrice)" },
            set: { item.wrappedValue.unitPrice = Decimal(string: $0.replacingOccurrences(of: ",", with: ".")) ?? 0 }
        )
    }
}
