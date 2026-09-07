import SwiftUI

/// Cartão translúcido genérico — Guia de Estilo §6/§7 (raio 30, padding 14/18/20).
struct GlassCard<Content: View>: View {
    let layer: GlassLayer
    var padding: CGFloat = 18
    @ViewBuilder let content: Content

    init(layer: GlassLayer = .dark, padding: CGFloat = 18, @ViewBuilder content: () -> Content) {
        self.layer = layer
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .glassSurface(layer, cornerRadius: Radius.card)
    }
}

/// Linha de lista (recebimento, evento, demanda) — Guia de Estilo §7.
struct GlassListRow<Leading: View, Trailing: View>: View {
    let title: String
    let metadata: String?
    @ViewBuilder let leading: Leading
    @ViewBuilder let trailing: Trailing

    init(
        title: String,
        metadata: String? = nil,
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.metadata = metadata
        self.leading = leading()
        self.trailing = trailing()
    }

    var body: some View {
        HStack(spacing: 12) {
            leading
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(MioMeiFont.listItem)
                    .foregroundStyle(OnGradientText.primary)
                if let metadata {
                    Text(metadata)
                        .font(MioMeiFont.metadata)
                        .foregroundStyle(OnGradientText.secondary)
                }
            }
            Spacer(minLength: 8)
            trailing
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .glassSurface(.light, cornerRadius: Radius.listRow)
    }
}
