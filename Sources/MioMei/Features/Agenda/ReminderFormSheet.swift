import SwiftUI

struct ReminderFormSheet: View {
    let onSave: (_ title: String, _ date: Date, _ recurrence: String?, _ note: String?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var date = Date.now
    @State private var isRecurring = false
    @State private var recurrenceDay = "5"
    @State private var note = ""

    var body: some View {
        ZStack {
            ModuleGradient.financeiro.background.scrimOverlay()
            BottomSheetScaffold(
                title: "Novo lembrete",
                ctaTitle: "Salvar lembrete",
                ctaEnabled: !title.isEmpty,
                onSave: {
                    let recurrence = isRecurring ? "MONTHLY:\(recurrenceDay)" : nil
                    onSave(title, date, recurrence, note.isEmpty ? nil : note)
                    dismiss()
                }
            ) {
                SheetField(placeholder: "Título", text: $title)
                DatePicker("Data/hora", selection: $date)
                Toggle("Repetir todo mês", isOn: $isRecurring).tint(.white)
                if isRecurring {
                    SheetField(placeholder: "Dia do mês", text: $recurrenceDay, keyboardType: .numberPad)
                }
                SheetField(placeholder: "Nota", text: $note)
            }
        }
        .foregroundStyle(OnGradientText.primary)
    }
}
