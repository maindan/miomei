import Foundation

extension Decimal {
    /// "R$ 1.234,50" — símbolo à esquerda, número à direita (Guia de Estilo §5).
    var brl: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: self as NSDecimalNumber) ?? "R$ 0,00"
    }
}

extension Date {
    var shortBR: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM"
        return formatter.string(from: self)
    }

    var mediumBR: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter.string(from: self)
    }
}
