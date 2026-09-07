import Foundation
import SwiftData

@Model
final class ContractRenewal {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var contractId: UUID
    var newEndDate: Date
    var addedValue: Decimal?
    var note: String?
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?

    init(
        id: UUID = UUID(),
        userId: UUID,
        contractId: UUID,
        newEndDate: Date,
        addedValue: Decimal? = nil,
        note: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.contractId = contractId
        self.newEndDate = newEndDate
        self.addedValue = addedValue
        self.note = note
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }
}
