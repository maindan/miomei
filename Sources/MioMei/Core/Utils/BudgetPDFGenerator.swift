import Foundation
import UIKit

/// Gera o PDF do orçamento com dados da empresa e do cliente, para
/// compartilhar via share sheet do iOS (mio-escopo.md §6.2).
enum BudgetPDFGenerator {
    static func generate(budget: Budget, clientName: String?, profile: Profile?) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter, 72dpi
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        return renderer.pdfData { context in
            context.beginPage()
            var y: CGFloat = 40

            draw(profile?.tradeName ?? profile?.companyName ?? "MioMei", at: &y, font: .boldSystemFont(ofSize: 22))
            if let cnpj = profile?.cnpj { draw("CNPJ: \(cnpj)", at: &y, font: .systemFont(ofSize: 11), color: .darkGray) }
            if let email = profile?.email { draw(email, at: &y, font: .systemFont(ofSize: 11), color: .darkGray) }
            y += 16

            draw(budget.title, at: &y, font: .boldSystemFont(ofSize: 18))
            if let clientName { draw("Cliente: \(clientName)", at: &y, font: .systemFont(ofSize: 13)) }
            if let validUntil = budget.validUntil {
                draw("Validade: \(validUntil.mediumBR)", at: &y, font: .systemFont(ofSize: 13))
            }
            if let terms = budget.paymentTerms {
                draw("Condições de pagamento: \(terms)", at: &y, font: .systemFont(ofSize: 13))
            }
            y += 16

            draw("Itens", at: &y, font: .boldSystemFont(ofSize: 14))
            for item in budget.items {
                let line = "\(item.description) — \(item.quantity.formatted()) x \(item.unitPrice.brl) = \(item.total.brl)"
                draw(line, at: &y, font: .systemFont(ofSize: 12))
            }
            y += 12

            draw("Total: \(budget.totalValue.brl)", at: &y, font: .boldSystemFont(ofSize: 16))

            if let pixKey = profile?.pixKey {
                y += 20
                draw("PIX: \(pixKey)", at: &y, font: .systemFont(ofSize: 12), color: .darkGray)
            }
        }
    }

    private static func draw(_ text: String, at y: inout CGFloat, font: UIFont, color: UIColor = .black) {
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        let rect = CGRect(x: 40, y: y, width: 532, height: 500)
        (text as NSString).draw(in: rect, withAttributes: attributes)
        y += font.lineHeight + 8
    }

    /// Salva em arquivo temporário para o `ShareLink` do SwiftUI.
    static func writeTemporaryFile(data: Data, suggestedName: String) -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(suggestedName).pdf")
        try? data.write(to: url)
        return url
    }
}
