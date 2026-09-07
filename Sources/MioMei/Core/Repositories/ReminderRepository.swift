import Foundation
import SwiftData

@MainActor
final class ReminderRepository {
    private let repo: LocalRepository<Reminder>
    private let userId: UUID

    init(modelContext: ModelContext, queueStore: SyncQueueStore, userId: UUID) {
        self.repo = LocalRepository(modelContext: modelContext, queueStore: queueStore, entityName: "reminder")
        self.userId = userId
    }

    func all() throws -> [Reminder] {
        try repo.fetch(FetchDescriptor(
            predicate: #Predicate { $0.userId == userId && $0.deletedAt == nil },
            sortBy: [.init(\.date)]
        ))
    }

    func between(_ from: Date, _ to: Date) throws -> [Reminder] {
        try repo.fetch(FetchDescriptor(
            predicate: #Predicate { reminder in
                reminder.userId == userId && reminder.date >= from && reminder.date < to && reminder.deletedAt == nil
            }
        ))
    }

    /// Agenda a notificação local do iOS junto com o lembrete (mio-escopo.md §8.4, §11).
    @discardableResult
    func create(title: String, date: Date, recurrence: String?, note: String?) throws -> Reminder {
        let reminder = Reminder(userId: userId, title: title, date: date, recurrence: recurrence, note: note)
        try repo.create(reminder, row: reminder.asRow)
        LocalNotificationScheduler.schedule(id: reminder.id, title: title, body: note ?? "Lembrete MioMei", at: date)
        return reminder
    }

    func delete(_ reminder: Reminder) throws {
        reminder.deletedAt = .now
        try repo.softDelete(reminder, row: reminder.asRow)
        LocalNotificationScheduler.cancel(id: reminder.id)
    }
}
