import SwiftUI
import UIKit

/// Camadas de Liquid Glass — Guia de Estilo §3. A renderização delega ao
/// material nativo do sistema (refração, realce dinâmico, adaptação claro/escuro);
/// os tons abaixo são o tint de referência do guia sobre esse material, não um
/// blur simulado manualmente.
enum GlassLayer {
    case light   // destaque, linha de lista, timer ativo, navbar
    case dark    // blocos de dados, valores, timelines, calendário
    case sheet   // bottom sheet / modal
    case field   // inputs e sub-blocos dentro de um cartão

    var material: Material {
        switch self {
        case .light: return .ultraThinMaterial
        case .dark: return .regularMaterial
        case .sheet: return .thickMaterial
        case .field: return .ultraThinMaterial
        }
    }

    var tint: Color {
        switch self {
        case .light: return .white.opacity(0.16)
        case .dark: return .black.opacity(0.32)
        case .sheet: return Color(hex: 0x140807, alpha: 0.72)
        case .field: return .white.opacity(0.10)
        }
    }

    var borderColor: Color {
        switch self {
        case .light: return .white.opacity(0.24)
        case .dark: return .white.opacity(0.14)
        case .sheet: return .white.opacity(0.20)
        case .field: return .white.opacity(0.16)
        }
    }
}

enum Radius {
    static let card: CGFloat = 30
    static let listRow: CGFloat = 24
    static let field: CGFloat = 19
    static let sheetTop: CGFloat = 40
    static let device: CGFloat = 44
}

struct GlassSurface: ViewModifier {
    let layer: GlassLayer
    var cornerRadius: CGFloat
    var borderWidth: CGFloat = 1

    func body(content: Content) -> some View {
        content
            .background(layer.material, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(layer.tint)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(layer.borderColor, lineWidth: borderWidth)
            )
    }
}

/// Alça de topo do bottom sheet (44×4px, Guia de Estilo §7).
struct SheetTopCorners: Shape {
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: Radius.sheetTop, height: Radius.sheetTop)
        )
        return Path(path.cgPath)
    }
}

extension View {
    func glassSurface(_ layer: GlassLayer, cornerRadius: CGFloat = Radius.card) -> some View {
        modifier(GlassSurface(layer: layer, cornerRadius: cornerRadius))
    }

    /// Scrim opaco atrás de sheets/modais (Guia de Estilo §2.5, §7).
    func scrimOverlay() -> some View {
        self.background(Color(hex: 0x0A0403, alpha: 0.55).ignoresSafeArea())
    }
}
