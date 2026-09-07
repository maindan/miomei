import Foundation
import SwiftData

@Model
final class Client {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var name: String
    var document: String?
    var email: String?
    var phone: String?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?

    init(
        id: UUID = UUID(),
        userId: UUID,
        name: String,
        document: String? = nil,
        email: String? = nil,
        phone: String? = nil,
        notes: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.document = document
        self.email = email
        self.phone = phone
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }
}
