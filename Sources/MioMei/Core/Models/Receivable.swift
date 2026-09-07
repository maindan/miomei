import Foundation
import SwiftData

@Model
final class Receivable {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var contractId: UUID?
    var clientId: UUID?
    var receivableDescription: String?
    var amount: Decimal
    var dueDate: Date
    var status: ReceivableStatus
    var receivedAt: Date?
    var method: String?
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?

    init(
        id: UUID = UUID(),
        userId: UUID,
        contractId: UUID? = nil,
        clientId: UUID? = nil,
        receivableDescription: String? = nil,
        amount: Decimal = 0,
        dueDate: Date,
        status: ReceivableStatus = .expected,
        receivedAt: Date? = nil,
        method: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.contractId = contractId
        self.clientId = clientId
        self.receivableDescription = receivableDescription
        self.amount = amount
        self.dueDate = dueDate
        self.status = status
        self.receivedAt = receivedAt
        self.method = method
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }
}
