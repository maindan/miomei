import Foundation
import SwiftData

@Model
final class Invoice {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var contractId: UUID?
    var clientId: UUID?
    var number: String?
    var amount: Decimal
    var issueDate: Date?
    var plannedDate: Date?
    var status: InvoiceStatus
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?

    init(
        id: UUID = UUID(),
        userId: UUID,
        contractId: UUID? = nil,
        clientId: UUID? = nil,
        number: String? = nil,
        amount: Decimal = 0,
        issueDate: Date? = nil,
        plannedDate: Date? = nil,
        status: InvoiceStatus = .toIssue,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.contractId = contractId
        self.clientId = clientId
        self.number = number
        self.amount = amount
        self.issueDate = issueDate
        self.plannedDate = plannedDate
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }
}
