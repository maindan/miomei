import Foundation
import SwiftData

/// Espelha `public.task` — nomeado `TaskItem` para não colidir com `Swift.Task`.
@Model
final class TaskItem {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var demandId: UUID
    var title: String
    var done: Bool
    var position: Int
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?

    init(
        id: UUID = UUID(),
        userId: UUID,
        demandId: UUID,
        title: String,
        done: Bool = false,
        position: Int = 0,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.demandId = demandId
        self.title = title
        self.done = done
        self.position = position
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }
}
