import SwiftUI

struct InvoiceFormSheet: View {
    let contracts: [Contract]
    let clients: [Client]
    var prefillClientId: UUID? = nil
    var prefillContractId: UUID? = nil
    var prefillAmount: Decimal? = nil
    let onSave: (_ contractId: UUID?, _ clientId: UUID?, _ number: String?, _ amount: Decimal, _ plannedDate: Date?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var contractId: UUID?
    @State private var clientId: UUID?
    @State private var number = ""
    @State private var amountText = ""
    @State private var plannedDate = Date.now

    var body: some View {
        ZStack {
            ModuleGradient.financeiro.background.scrimOverlay()
            BottomSheetScaffold(
                title: "Nova nota fiscal",
                ctaTitle: "Salvar nota",
                ctaEnabled: !amountText.isEmpty,
                onSave: {
                    onSave(contractId, clientId, number.isEmpty ? nil : number,
                           Decimal(string: amountText.replacingOccurrences(of: ",", with: ".")) ?? 0, plannedDate)
                    dismiss()
                }
            ) {
                if !clients.isEmpty {
                    Picker("Cliente", selection: $clientId) {
                        Text("Sem cliente").tag(UUID?.none)
                        ForEach(clients) { Text($0.name).tag(Optional($0.id)) }
                    }
                    .tint(.white)
                }
                if !contracts.isEmpty {
                    Picker("Contrato", selection: $contractId) {
                        Text("Avulso").tag(UUID?.none)
                        ForEach(contracts) { Text($0.title).tag(Optional($0.id)) }
                    }
                    .tint(.white)
                }
                SheetField(placeholder: "Número (opcional)", text: $number)
                SheetField(placeholder: "Valor (R$)", text: $amountText, keyboardType: .decimalPad)
                DatePicker("Data prevista de emissão", selection: $plannedDate, displayedComponents: .date)
            }
        }
        .foregroundStyle(OnGradientText.primary)
        .onAppear {
            clientId = prefillClientId
            contractId = prefillContractId
            if let prefillAmount { amountText = "\(prefillAmount)" }
        }
    }
}
