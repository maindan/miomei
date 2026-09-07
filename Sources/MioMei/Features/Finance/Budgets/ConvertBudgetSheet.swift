import SwiftUI

/// Ao aprovar um orçamento, oferece converter em Contrato/Freelance e gerar o
/// cronograma de recebimentos (mio-escopo.md §6.2).
struct ConvertBudgetSheet: View {
    let budget: Budget
    let onConvert: (_ type: ContractType, _ installments: Int, _ firstDueDate: Date) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var type: ContractType = .freelance
    @State private var installmentsText = "1"
    @State private var firstDueDate = Date.now

    var body: some View {
        ZStack {
            ModuleGradient.contrato.background.scrimOverlay()
            BottomSheetScaffold(title: "Converter orçamento", ctaTitle: "Converter e gerar recebimentos", onSave: {
                onConvert(type, Int(installmentsText) ?? 1, firstDueDate)
                dismiss()
            }) {
                Text("\(budget.title) — \(budget.totalValue.brl)")
                    .font(MioMeiFont.metadata)
                    .foregroundStyle(OnGradientText.secondary)

                Picker("Tipo", selection: $type) {
                    Text("Freelance").tag(ContractType.freelance)
                    Text("PJ").tag(ContractType.pj)
                }
                .pickerStyle(.segmented)

                SheetField(placeholder: "Nº de parcelas do recebimento", text: $installmentsText, keyboardType: .numberPad)
                DatePicker("Primeiro vencimento", selection: $firstDueDate, displayedComponents: .date)
            }
        }
        .foregroundStyle(OnGradientText.primary)
    }
}
