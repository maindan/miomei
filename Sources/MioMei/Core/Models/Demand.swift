import Foundation
import SwiftData

@Model
final class Demand {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var contractId: UUID?
    var title: String
    var demandDescription: String?
    var priority: DemandPriority
    var deadline: Date?
    var status: DemandStatus
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?

    init(
        id: UUID = UUID(),
        userId: UUID,
        contractId: UUID? = nil,
        title: String,
        demandDescription: String? = nil,
        priority: DemandPriority = .medium,
        deadline: Date? = nil,
        status: DemandStatus = .todo,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.contractId = contractId
        self.title = title
        self.demandDescription = demandDescription
        self.priority = priority
        self.deadline = deadline
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }
}
