import SwiftUI

/// Fundo de tela cheia por módulo — Guia de Estilo MioMei §2.
/// Ângulo 200°, exceto o cronômetro (190°). Uma tela = um gradiente;
/// telas de detalhe herdam o gradiente do módulo de origem.
enum ModuleGradient: Hashable {
    case inicio
    case financeiro
    case atividades
    case contrato
    case perfil
    case cronometro

    private var angleDegrees: Double {
        self == .cronometro ? 190 : 200
    }

    private var stops: [Color] {
        switch self {
        case .inicio:
            return [
                Color(hex: 0x050B1A), Color(hex: 0x0C2350),
                Color(hex: 0x1C68C6), Color(hex: 0x3AA0EE),
            ]
        case .financeiro:
            return [
                Color(hex: 0x17090A), Color(hex: 0x4D1510),
                Color(hex: 0xC1511B), Color(hex: 0xF2962E),
            ]
        case .atividades:
            return [
                Color(hex: 0x0C1512), Color(hex: 0x14322A),
                Color(hex: 0x2D7A53), Color(hex: 0x6FBC7A),
            ]
        case .contrato:
            return [
                Color(hex: 0x120B1C), Color(hex: 0x2C1436),
                Color(hex: 0x7A3358), Color(hex: 0xC96A49),
            ]
        case .perfil:
            return [
                Color(hex: 0x0E0B14), Color(hex: 0x1D1626),
                Color(hex: 0x4A2F45), Color(hex: 0x8A5254),
            ]
        case .cronometro:
            return [
                Color(hex: 0x23090A), Color(hex: 0x6E1F11),
                Color(hex: 0xD9701F), Color(hex: 0xF5A13A),
            ]
        }
    }

    /// Tom mais escuro do gradiente — usado no ícone ativo da navbar (círculo branco).
    var darkestTone: Color {
        switch self {
        case .inicio: return Color(hex: 0x0B1A33)
        case .financeiro: return Color(hex: 0x2A0E08)
        case .atividades: return Color(hex: 0x0A1210)
        case .contrato: return Color(hex: 0x1A0F17)
        case .perfil: return Color(hex: 0x120D18)
        case .cronometro: return Color(hex: 0x2A0C09)
        }
    }

    var background: some View {
        let radians = Angle(degrees: angleDegrees - 90).radians
        let dx = CGFloat(cos(radians))
        let dy = CGFloat(sin(radians))
        return LinearGradient(
            stops: [
                .init(color: stops[0], location: 0),
                .init(color: stops[1], location: 0.32),
                .init(color: stops[2], location: 0.70),
                .init(color: stops[3], location: 1.0),
            ],
            startPoint: UnitPoint(x: 0.5 - dx, y: 0.5 - dy),
            endPoint: UnitPoint(x: 0.5 + dx, y: 0.5 + dy)
        )
        .ignoresSafeArea()
    }
}

/// Fundo radial do cartão de cronômetro em curso (Guia de Estilo §7 "Cronômetro").
enum TimerGlow {
    static var background: some View {
        RadialGradient(
            colors: [
                Color(hex: 0xFF7A12), Color(hex: 0xFF9A2B),
                Color(hex: 0xF7B573), Color(hex: 0xD9DCEC),
                Color(hex: 0xEDF0F7), Color(hex: 0xF8FAFC),
            ],
            center: UnitPoint(x: 0.5, y: 0.46),
            startRadius: 0,
            endRadius: 260
        )
    }
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}
