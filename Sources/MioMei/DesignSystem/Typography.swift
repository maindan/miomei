import SwiftUI

/// Escala tipográfica — Guia de Estilo §5. SF Pro nativa via `.system`, herdando
/// Dynamic Type. DotGothic16 é a única exceção, reservada aos dígitos do
/// cronômetro em curso (arquivo da fonte ainda não empacotado — ver README).
enum MioMeiFont {
    static func timerRunning() -> Font {
        .custom("DotGothic16-Regular", size: 52, relativeTo: .largeTitle)
    }

    static let highlightValue = Font.system(size: 34, weight: .semibold, design: .default)
    static let screenTitle = Font.system(.title2, design: .default, weight: .bold)
    static let dayBriefing = Font.system(size: 27, weight: .bold, design: .default)
    static let listItem = Font.system(.subheadline, design: .default, weight: .bold)
    static let metadata = Font.system(.caption, design: .default, weight: .semibold)
    static let sectionLabel = Font.system(.caption2, design: .default, weight: .bold)
}

extension Text {
    /// Aplica tabular-nums (equivalente a `.monospacedDigit()`) para valores e datas.
    func numericTabular() -> Text {
        self.monospacedDigit()
    }

    func sectionLabelStyle() -> Text {
        self.font(MioMeiFont.sectionLabel)
            .textCase(.uppercase)
            .kerning(0.7)
    }
}
