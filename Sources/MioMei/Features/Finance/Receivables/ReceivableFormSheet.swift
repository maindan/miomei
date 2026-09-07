import SwiftUI

struct ReceivableFormSheet: View {
    let contracts: [Contract]
    let clients: [Client]
    let onSave: (Receivable.CreateInput) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var description = ""
    @State private var amountText = ""
    @State private var dueDate = Date.now
    @State private var contractId: UUID?
    @State private var clientId: UUID?
    @State private var installmentsText = "1"
    @State private var method = ""

    var body: some View {
        ZStack {
            ModuleGradient.financeiro.background.scrimOverlay()
            BottomSheetScaffold(
                title: "Novo recebimento",
                ctaTitle: "Salvar recebimento",
                ctaEnabled: !amountText.isEmpty,
                onSave: {
                    onSave(Receivable.CreateInput(
                        description: description.isEmpty ? nil : description,
                        amount: Decimal(string: amountText.replacingOccurrences(of: ",", with: ".")) ?? 0,
                        dueDate: dueDate,
                        contractId: contractId,
                        clientId: clientId ?? contracts.first(where: { $0.id == contractId })?.clientId,
                        installments: Int(installmentsText) ?? 1,
                        method: method.isEmpty ? nil : method
                    ))
                    dismiss()
                }
            ) {
                SheetField(placeholder: "Descrição", text: $description)
                SheetField(placeholder: "Valor total (R$)", text: $amountText, keyboardType: .decimalPad)
                DatePicker("Primeira data prevista", selection: $dueDate, displayedComponents: .date)

                if !contracts.isEmpty {
                    Picker("Contrato", selection: $contractId) {
                        Text("Avulso").tag(UUID?.none)
                        ForEach(contracts) { contract in
                            Text(contract.title).tag(Optional(contract.id))
                        }
                    }
                    .tint(.white)
                }

                if !clients.isEmpty {
                    Picker("Cliente", selection: $clientId) {
                        Text("Sem cliente").tag(UUID?.none)
                        ForEach(clients) { client in
                            Text(client.name).tag(Optional(client.id))
                        }
                    }
                    .tint(.white)
                }

                SheetField(placeholder: "Nº de parcelas", text: $installmentsText, keyboardType: .numberPad)
                SheetField(placeholder: "Forma de recebimento", text: $method)
            }
        }
        .foregroundStyle(OnGradientText.primary)
    }
}

extension Receivable {
    struct CreateInput {
        let description: String?
        let amount: Decimal
        let dueDate: Date
        let contractId: UUID?
        let clientId: UUID?
        let installments: Int
        let method: String?
    }
}
