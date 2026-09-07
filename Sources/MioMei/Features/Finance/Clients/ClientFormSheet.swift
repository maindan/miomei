import SwiftUI

struct ClientFormSheet: View {
    let onSave: (_ name: String, _ document: String?, _ email: String?, _ phone: String?, _ notes: String?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var document = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var notes = ""

    var body: some View {
        ZStack {
            ModuleGradient.financeiro.background.scrimOverlay()
            BottomSheetScaffold(
                title: "Novo cliente",
                ctaTitle: "Salvar cliente",
                ctaEnabled: !name.isEmpty,
                onSave: {
                    onSave(name, document.isEmpty ? nil : document, email.isEmpty ? nil : email,
                           phone.isEmpty ? nil : phone, notes.isEmpty ? nil : notes)
                    dismiss()
                }
            ) {
                SheetField(placeholder: "Nome", text: $name)
                SheetField(placeholder: "CPF/CNPJ", text: $document)
                SheetField(placeholder: "E-mail", text: $email, keyboardType: .emailAddress)
                SheetField(placeholder: "Telefone", text: $phone, keyboardType: .phonePad)
                SheetField(placeholder: "Observações", text: $notes)
            }
        }
    }
}
