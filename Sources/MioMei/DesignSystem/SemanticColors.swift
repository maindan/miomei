import SwiftUI

/// Cores semânticas — Guia de Estilo §4. Colorem texto, ponto ou barra de
/// progresso; nunca o fundo inteiro de um cartão (única exceção: `overdueCardBackground`).
enum Semantic {
    static let received = Color(hex: 0x8FE6AC)   // recebido · meta atingida
    static let attention = Color(hex: 0xFFCF5C)  // atenção · a vencer
    static let overdue = Color(hex: 0xFF9C8A)    // atrasado · risco de meta
    static let info = Color(hex: 0x9FD0FF)       // nota fiscal · informativo

    static let overdueCardBackground = Color(hex: 0x78140A, alpha: 0.45)
    static let overdueCardBorder = Color(hex: 0xFF9682, alpha: 0.35)
}

/// Texto sobre gradiente — Guia de Estilo §4.
enum OnGradientText {
    static let primary = Color.white
    static let secondary = Color.white.opacity(0.6)
    static let label = Color.white.opacity(0.5)
}
