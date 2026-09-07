import SwiftUI

struct PayableFormSheet: View {
    let onSave: (_ type: PayableType, _ description: String?, _ amount: Decimal, _ dueDate: Date) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var type: PayableType = .other
    @State private var description = ""
    @State private var amountText = ""
    @State private var dueDate = Date.now

    var body: some View {
        ZStack {
            ModuleGradient.financeiro.background.scrimOverlay()
            BottomSheetScaffold(
                title: "Novo pagamento",
                ctaTitle: "Salvar pagamento",
                ctaEnabled: !amountText.isEmpty,
                onSave: {
                    onSave(type, description.isEmpty ? nil : description,
                           Decimal(string: amountText.replacingOccurrences(of: ",", with: ".")) ?? 0, dueDate)
                    dismiss()
                }
            ) {
                Picker("Tipo", selection: $type) {
                    Text("DAS-MEI").tag(PayableType.dasMei)
                    Text("Imposto de nota").tag(PayableType.invoiceTax)
                    Text("Outro").tag(PayableType.other)
                }
                .pickerStyle(.segmented)

                SheetField(placeholder: "Descrição", text: $description)
                SheetField(placeholder: "Valor (R$)", text: $amountText, keyboardType: .decimalPad)
                DatePicker("Vencimento", selection: $dueDate, displayedComponents: .date)
            }
        }
        .foregroundStyle(OnGradientText.primary)
    }
}
