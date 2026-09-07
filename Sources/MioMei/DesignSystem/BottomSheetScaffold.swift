import SwiftUI

/// Chrome padrão de bottom sheet — alça, título, fechar, CTA no rodapé
/// (Guia de Estilo §7 "Bottom sheet / modal").
struct BottomSheetScaffold<Content: View>: View {
    let title: String
    let ctaTitle: String
    var isSaving: Bool = false
    var ctaEnabled: Bool = true
    let onSave: () -> Void
    let content: Content

    @Environment(\.dismiss) private var dismiss

    init(
        title: String,
        ctaTitle: String,
        isSaving: Bool = false,
        ctaEnabled: Bool = true,
        onSave: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.ctaTitle = ctaTitle
        self.isSaving = isSaving
        self.ctaEnabled = ctaEnabled
        self.onSave = onSave
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.white.opacity(0.3))
                .frame(width: 44, height: 4)
                .padding(.top, 10)

            HStack {
                Text(title).font(.system(.title3, weight: .bold)).foregroundStyle(OnGradientText.primary)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(OnGradientText.primary)
                        .frame(width: 34, height: 34)
                        .glassSurface(.light, cornerRadius: 17)
                }
            }
            .padding(.top, 16)
            .padding(.horizontal, 20)

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    content
                }
                .padding(20)
            }

            PrimaryButton(title: ctaTitle, isLoading: isSaving) {
                onSave()
            }
            .disabled(!ctaEnabled)
            .opacity(ctaEnabled ? 1 : 0.5)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(GlassLayer.sheet.tint)
        .background(GlassLayer.sheet.material)
        .clipShape(SheetTopCorners())
        .overlay(
            SheetTopCorners()
                .stroke(GlassLayer.sheet.borderColor, lineWidth: 1)
        )
        .ignoresSafeArea(edges: .bottom)
    }
}

/// Campo de texto em vidro interno — usado nos formulários de criação/edição.
struct SheetField: View {
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(keyboardType)
            .foregroundStyle(OnGradientText.primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .glassSurface(.field, cornerRadius: Radius.field)
    }
}
