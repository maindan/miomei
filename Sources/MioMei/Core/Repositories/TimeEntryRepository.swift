import Foundation
import SwiftData

@MainActor
final class TimeEntryRepository {
    private let repo: LocalRepository<TimeEntry>
    private let userId: UUID

    init(modelContext: ModelContext, queueStore: SyncQueueStore, userId: UUID) {
        self.repo = LocalRepository(modelContext: modelContext, queueStore: queueStore, entityName: "time_entry")
        self.userId = userId
    }

    /// Sessão aberta do usuário (`ended_at == nil`), no máximo uma por vez
    /// (mio-escopo.md §7.3, §9).
    func activeEntry() throws -> TimeEntry? {
        try repo.fetch(FetchDescriptor(
            predicate: #Predicate { $0.userId == userId && $0.endedAt == nil && $0.deletedAt == nil }
        )).first
    }

    func entries(for demandId: UUID) throws -> [TimeEntry] {
        try repo.fetch(FetchDescriptor(
            predicate: #Predicate { $0.demandId == demandId && $0.deletedAt == nil },
            sortBy: [.init(\.startedAt, order: .reverse)]
        ))
    }

    func allEntries(from: Date, to: Date) throws -> [TimeEntry] {
        try repo.fetch(FetchDescriptor(
            predicate: #Predicate { entry in
                entry.userId == userId && entry.startedAt >= from && entry.startedAt < to && entry.deletedAt == nil
            }
        ))
    }

    /// Iniciar em outra demanda encerra o cronômetro anterior (regra única-sessão).
    @discardableResult
    func start(demandId: UUID) throws -> TimeEntry {
        if let active = try activeEntry() {
            try stop(active)
        }
        let entry = TimeEntry(userId: userId, demandId: demandId, startedAt: .now)
        try repo.create(entry, row: entry.asRow)
        return entry
    }

    func stop(_ entry: TimeEntry) throws {
        let endedAt = Date.now
        entry.endedAt = endedAt
        entry.durationSeconds = Int(endedAt.timeIntervalSince(entry.startedAt))
        entry.updatedAt = .now
        try repo.update(entry, row: entry.asRow)
    }

    @discardableResult
    func addManualEntry(demandId: UUID, startedAt: Date, endedAt: Date) throws -> TimeEntry {
        let entry = TimeEntry(
            userId: userId, demandId: demandId, startedAt: startedAt, endedAt: endedAt,
            durationSeconds: Int(endedAt.timeIntervalSince(startedAt)), isManual: true
        )
        try repo.create(entry, row: entry.asRow)
        return entry
    }

    func delete(_ entry: TimeEntry) throws {
        entry.deletedAt = .now
        try repo.softDelete(entry, row: entry.asRow)
    }
}

extension Array where Element == TimeEntry {
    /// Soma segundos já fechados; sessão em aberto conta pelo tempo decorrido até agora.
    var totalDurationSeconds: Int {
        reduce(0) { total, entry in
            total + (entry.durationSeconds ?? Int(Date.now.timeIntervalSince(entry.startedAt)))
        }
    }
}
