import Foundation
import SwiftData

/// Espelha `public.notification` — nomeado `NotificationItem` para não colidir
/// com `Foundation.Notification`.
@Model
final class NotificationItem {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    /// Ex.: "RECEIVABLE_OVERDUE".
    var type: String
    var title: String
    var body: String?
    /// Ex.: "receivable:<uuid>" — leva à entidade de origem.
    var entityRef: String?
    var readAt: Date?
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?

    init(
        id: UUID = UUID(),
        userId: UUID,
        type: String,
        title: String,
        body: String? = nil,
        entityRef: String? = nil,
        readAt: Date? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.type = type
        self.title = title
        self.body = body
        self.entityRef = entityRef
        self.readAt = readAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }
}
