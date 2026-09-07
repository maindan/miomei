import SwiftUI

struct ContractFormSheet: View {
    let clients: [Client]
    let onSave: (Contract.CreateInput) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var type: ContractType = .pj
    @State private var clientId: UUID?
    @State private var title = ""
    @State private var description = ""
    @State private var startDate = Date.now
    @State private var endDate: Date?
    @State private var hasEndDate = false
    @State private var estimatedValueText = ""
    @State private var weeklyHoursText = ""
    @State private var recurrence = ""

    var body: some View {
        ZStack {
            ModuleGradient.contrato.background.scrimOverlay()
            BottomSheetScaffold(
                title: "Novo contrato",
                ctaTitle: "Salvar contrato",
                ctaEnabled: !title.isEmpty,
                onSave: {
                    onSave(Contract.CreateInput(
                        type: type, clientId: clientId, title: title,
                        description: description.isEmpty ? nil : description,
                        startDate: startDate, endDate: hasEndDate ? endDate : nil,
                        estimatedValue: Decimal(string: estimatedValueText.replacingOccurrences(of: ",", with: ".")),
                        weeklyHoursRequirement: type == .pj
                            ? Decimal(string: weeklyHoursText.replacingOccurrences(of: ",", with: "."))
                            : nil,
                        recurrence: type == .pj && !recurrence.isEmpty ? recurrence : nil,
                        paymentMethod: nil
                    ))
                    dismiss()
                }
            ) {
                Picker("Tipo", selection: $type) {
                    Text("PJ").tag(ContractType.pj)
                    Text("Freelance").tag(ContractType.freelance)
                }
                .pickerStyle(.segmented)

                if !clients.isEmpty {
                    Picker("Cliente", selection: $clientId) {
                        Text("Sem cliente").tag(UUID?.none)
                        ForEach(clients) { client in
                            Text(client.name).tag(Optional(client.id))
                        }
                    }
                    .tint(.white)
                }

                SheetField(placeholder: "Título", text: $title)
                SheetField(placeholder: "Descrição", text: $description)

                DatePicker("Início", selection: $startDate, displayedComponents: .date)
                Toggle("Tem data de término", isOn: $hasEndDate).tint(.white)
                if hasEndDate {
                    DatePicker(
                        "Término",
                        selection: Binding(get: { endDate ?? .now }, set: { endDate = $0 }),
                        displayedComponents: .date
                    )
                }

                SheetField(placeholder: "Valor estimado (R$)", text: $estimatedValueText, keyboardType: .decimalPad)

                if type == .pj {
                    SheetField(placeholder: "Horas semanais exigidas (opcional)", text: $weeklyHoursText, keyboardType: .decimalPad)
                    SheetField(placeholder: "Recorrência (ex.: MONTHLY)", text: $recurrence)
                }
            }
        }
        .foregroundStyle(OnGradientText.primary)
    }
}

extension Contract {
    struct CreateInput {
        let type: ContractType
        let clientId: UUID?
        let title: String
        let description: String?
        let startDate: Date?
        let endDate: Date?
        let estimatedValue: Decimal?
        let weeklyHoursRequirement: Decimal?
        let recurrence: String?
        let paymentMethod: String?
    }
}
