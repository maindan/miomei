import Foundation
import SwiftData

@MainActor
final class DemandRepository {
    private let repo: LocalRepository<Demand>
    private let taskRepo: LocalRepository<TaskItem>
    private let userId: UUID

    init(modelContext: ModelContext, queueStore: SyncQueueStore, userId: UUID) {
        self.repo = LocalRepository(modelContext: modelContext, queueStore: queueStore, entityName: "demand")
        self.taskRepo = LocalRepository(modelContext: modelContext, queueStore: queueStore, entityName: "task")
        self.userId = userId
    }

    func all() throws -> [Demand] {
        try repo.fetch(FetchDescriptor(
            predicate: #Predicate { $0.userId == userId && $0.deletedAt == nil },
            sortBy: [.init(\.createdAt, order: .reverse)]
        ))
    }

    func tasks(for demandId: UUID) throws -> [TaskItem] {
        try taskRepo.fetch(FetchDescriptor(
            predicate: #Predicate { $0.demandId == demandId && $0.deletedAt == nil },
            sortBy: [.init(\.position)]
        ))
    }

    /// Progresso da demanda = % de tarefas concluídas (mio-escopo.md §7.2).
    func progress(for demandId: UUID) throws -> Double {
        let items = try tasks(for: demandId)
        guard !items.isEmpty else { return 0 }
        return Double(items.filter(\.done).count) / Double(items.count)
    }

    @discardableResult
    func create(
        contractId: UUID?, title: String, description: String?, priority: DemandPriority, deadline: Date?
    ) throws -> Demand {
        let demand = Demand(
            userId: userId, contractId: contractId, title: title,
            demandDescription: description, priority: priority, deadline: deadline
        )
        try repo.create(demand, row: demand.asRow)
        return demand
    }

    func update(_ demand: Demand) throws {
        demand.updatedAt = .now
        try repo.update(demand, row: demand.asRow)
    }

    func setStatus(_ demand: Demand, status: DemandStatus) throws {
        demand.status = status
        try update(demand)
    }

    @discardableResult
    func addTask(demandId: UUID, title: String, position: Int) throws -> TaskItem {
        let task = TaskItem(userId: userId, demandId: demandId, title: title, position: position)
        try taskRepo.create(task, row: task.asRow)
        return task
    }

    func toggleTask(_ task: TaskItem) throws {
        task.done.toggle()
        task.updatedAt = .now
        try taskRepo.update(task, row: task.asRow)
    }

    func deleteTask(_ task: TaskItem) throws {
        task.deletedAt = .now
        try taskRepo.softDelete(task, row: task.asRow)
    }

    func delete(_ demand: Demand) throws {
        demand.deletedAt = .now
        try repo.softDelete(demand, row: demand.asRow)
    }
}
