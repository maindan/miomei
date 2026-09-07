import Foundation
import SwiftData

/// Item de linha do orçamento — espelha os objetos da coluna jsonb `budget.items`.
struct BudgetItem: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var description: String
    var quantity: Decimal
    var unitPrice: Decimal

    var total: Decimal { quantity * unitPrice }
}

@Model
final class Budget {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var clientId: UUID?
    var title: String
    var items: [BudgetItem]
    var totalValue: Decimal
    var validUntil: Date?
    var paymentTerms: String?
    var status: BudgetStatus
    var pdfURL: String?
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?

    init(
        id: UUID = UUID(),
        userId: UUID,
        clientId: UUID? = nil,
        title: String,
        items: [BudgetItem] = [],
        totalValue: Decimal = 0,
        validUntil: Date? = nil,
        paymentTerms: String? = nil,
        status: BudgetStatus = .draft,
        pdfURL: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.clientId = clientId
        self.title = title
        self.items = items
        self.totalValue = totalValue
        self.validUntil = validUntil
        self.paymentTerms = paymentTerms
        self.status = status
        self.pdfURL = pdfURL
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }
}
