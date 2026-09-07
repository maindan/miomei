import Foundation
import SwiftData

/// Central de notificações in-app (mio-escopo.md §11).
@MainActor
final class NotificationRepository {
    private let repo: LocalRepository<NotificationItem>
    private let userId: UUID

    init(modelContext: ModelContext, queueStore: SyncQueueStore, userId: UUID) {
        self.repo = LocalRepository(modelContext: modelContext, queueStore: queueStore, entityName: "notification")
        self.userId = userId
    }

    func all() throws -> [NotificationItem] {
        try repo.fetch(FetchDescriptor(
            predicate: #Predicate { $0.userId == userId && $0.deletedAt == nil },
            sortBy: [.init(\.createdAt, order: .reverse)]
        ))
    }

    func unreadCount() throws -> Int {
        try repo.fetch(FetchDescriptor(
            predicate: #Predicate { $0.userId == userId && $0.readAt == nil && $0.deletedAt == nil }
        )).count
    }

    /// Evita duplicar o mesmo alerta a cada recálculo: já existe notificação
    /// não lida para essa entidade?
    func hasUnread(entityRef: String) throws -> Bool {
        try repo.fetch(FetchDescriptor(
            predicate: #Predicate { $0.userId == userId && $0.entityRef == entityRef && $0.readAt == nil && $0.deletedAt == nil }
        )).first != nil
    }

    @discardableResult
    func create(type: String, title: String, body: String?, entityRef: String?) throws -> NotificationItem {
        let notification = NotificationItem(userId: userId, type: type, title: title, body: body, entityRef: entityRef)
        try repo.create(notification, row: notification.asRow)
        return notification
    }

    func markRead(_ notification: NotificationItem) throws {
        notification.readAt = .now
        notification.updatedAt = .now
        try repo.update(notification, row: notification.asRow)
    }

    func clearAll() throws {
        for notification in try all() {
            notification.deletedAt = .now
            try repo.softDelete(notification, row: notification.asRow)
        }
    }
}
