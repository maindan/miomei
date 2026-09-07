import Foundation
import SwiftData

@Model
final class Payable {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var type: PayableType
    var payableDescription: String?
    var amount: Decimal
    var dueDate: Date
    var status: PayableStatus
    var paidAt: Date?
    var receiptURL: String?
    var invoiceId: UUID?
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?

    init(
        id: UUID = UUID(),
        userId: UUID,
        type: PayableType = .other,
        payableDescription: String? = nil,
        amount: Decimal = 0,
        dueDate: Date,
        status: PayableStatus = .pending,
        paidAt: Date? = nil,
        receiptURL: String? = nil,
        invoiceId: UUID? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.type = type
        self.payableDescription = payableDescription
        self.amount = amount
        self.dueDate = dueDate
        self.status = status
        self.paidAt = paidAt
        self.receiptURL = receiptURL
        self.invoiceId = invoiceId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }
}
