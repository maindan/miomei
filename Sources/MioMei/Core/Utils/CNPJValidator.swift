import Foundation

/// Validação de formato + dígitos verificadores de CNPJ (mio-escopo.md §4.2, §4.3).
enum CNPJValidator {
    static func isValid(_ rawInput: String) -> Bool {
        let digits = rawInput.filter(\.isNumber)
        guard digits.count == 14 else { return false }

        let numbers = digits.compactMap { $0.wholeNumberValue }
        guard numbers.count == 14, Set(numbers).count > 1 else { return false }

        let firstCheck = checkDigit(for: Array(numbers[0..<12]))
        guard firstCheck == numbers[12] else { return false }

        let secondCheck = checkDigit(for: Array(numbers[0..<13]))
        guard secondCheck == numbers[13] else { return false }

        return true
    }

    static func format(_ rawInput: String) -> String {
        let digits = String(rawInput.filter(\.isNumber).prefix(14))
        var result = ""
        for (index, character) in digits.enumerated() {
            switch index {
            case 2, 5: result.append(".")
            case 8: result.append("/")
            case 12: result.append("-")
            default: break
            }
            result.append(character)
        }
        return result
    }

    /// Algoritmo padrão: pesos decrescentes de 2 a 9 (repetindo), módulo 11.
    private static func checkDigit(for base: [Int]) -> Int {
        let weightsCount = base.count + 1
        var weights: [Int] = []
        var weight = 2
        for _ in 0..<weightsCount {
            weights.insert(weight, at: 0)
            weight = weight == 9 ? 2 : weight + 1
        }
        weights.removeFirst()

        let sum = zip(base, weights).reduce(0) { $0 + $1.0 * $1.1 }
        let remainder = sum % 11
        return remainder < 2 ? 0 : 11 - remainder
    }
}
