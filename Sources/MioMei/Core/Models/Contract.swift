import Foundation
import SwiftData

@Model
final class Contract {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var clientId: UUID?
    var type: ContractType
    var title: String
    var contractDescription: String?
    var startDate: Date?
    var endDate: Date?
    var estimatedValue: Decimal?
    var weeklyHoursRequirement: Decimal?
    var recurrence: String?
    var status: ContractStatus
    var paymentMethod: String?
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?

    init(
        id: UUID = UUID(),
        userId: UUID,
        clientId: UUID? = nil,
        type: ContractType,
        title: String,
        contractDescription: String? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil,
        estimatedValue: Decimal? = nil,
        weeklyHoursRequirement: Decimal? = nil,
        recurrence: String? = nil,
        status: ContractStatus = .active,
        paymentMethod: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.clientId = clientId
        self.type = type
        self.title = title
        self.contractDescription = contractDescription
        self.startDate = startDate
        self.endDate = endDate
        self.estimatedValue = estimatedValue
        self.weeklyHoursRequirement = weeklyHoursRequirement
        self.recurrence = recurrence
        self.status = status
        self.paymentMethod = paymentMethod
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }
}
