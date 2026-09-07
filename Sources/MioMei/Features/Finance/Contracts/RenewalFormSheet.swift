import SwiftUI

struct RenewalFormSheet: View {
    let currentEndDate: Date?
    let onSave: (_ newEndDate: Date, _ addedValue: Decimal?, _ note: String?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var newEndDate: Date
    @State private var addedValueText = ""
    @State private var note = ""

    init(currentEndDate: Date?, onSave: @escaping (Date, Decimal?, String?) -> Void) {
        self.currentEndDate = currentEndDate
        self.onSave = onSave
        _newEndDate = State(initialValue: currentEndDate ?? .now)
    }

    var body: some View {
        ZStack {
            ModuleGradient.contrato.background.scrimOverlay()
            BottomSheetScaffold(
                title: "Renovar contrato",
                ctaTitle: "Confirmar renovação",
                onSave: {
                    let added = Decimal(string: addedValueText.replacingOccurrences(of: ",", with: "."))
                    onSave(newEndDate, added, note.isEmpty ? nil : note)
                    dismiss()
                }
            ) {
                DatePicker("Novo término", selection: $newEndDate, displayedComponents: .date)
                SheetField(placeholder: "Valor adicionado (opcional)", text: $addedValueText, keyboardType: .decimalPad)
                SheetField(placeholder: "Observação", text: $note)
            }
        }
        .foregroundStyle(OnGradientText.primary)
    }
}
