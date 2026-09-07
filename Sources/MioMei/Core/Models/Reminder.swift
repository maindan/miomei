import Foundation
import SwiftData

@Model
final class Reminder {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var title: String
    var date: Date
    /// Ex.: "MONTHLY:5" — recorrência mensal no dia 5.
    var recurrence: String?
    var note: String?
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?

    init(
        id: UUID = UUID(),
        userId: UUID,
        title: String,
        date: Date,
        recurrence: String? = nil,
        note: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.date = date
        self.recurrence = recurrence
        self.note = note
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }
}
