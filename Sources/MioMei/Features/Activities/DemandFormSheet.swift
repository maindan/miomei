import SwiftUI

struct DemandFormSheet: View {
    let contracts: [Contract]
    let onSave: (_ contractId: UUID?, _ title: String, _ description: String?, _ priority: DemandPriority, _ deadline: Date?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var priority: DemandPriority = .medium
    @State private var contractId: UUID?
    @State private var hasDeadline = false
    @State private var deadline = Date.now

    var body: some View {
        ZStack {
            ModuleGradient.atividades.background.scrimOverlay()
            BottomSheetScaffold(
                title: "Nova demanda",
                ctaTitle: "Salvar demanda",
                ctaEnabled: !title.isEmpty,
                onSave: {
                    onSave(contractId, title, description.isEmpty ? nil : description, priority, hasDeadline ? deadline : nil)
                    dismiss()
                }
            ) {
                SheetField(placeholder: "Título", text: $title)
                SheetField(placeholder: "Descrição", text: $description)

                Picker("Prioridade", selection: $priority) {
                    Text("Baixa").tag(DemandPriority.low)
                    Text("Média").tag(DemandPriority.medium)
                    Text("Alta").tag(DemandPriority.high)
                }
                .pickerStyle(.segmented)

                if !contracts.isEmpty {
                    Picker("Contrato", selection: $contractId) {
                        Text("Sem contrato").tag(UUID?.none)
                        ForEach(contracts) { contract in
                            Text(contract.title).tag(Optional(contract.id))
                        }
                    }
                    .tint(.white)
                }

                Toggle("Tem prazo", isOn: $hasDeadline).tint(.white)
                if hasDeadline {
                    DatePicker("Prazo", selection: $deadline)
                }
            }
        }
        .foregroundStyle(OnGradientText.primary)
    }
}
