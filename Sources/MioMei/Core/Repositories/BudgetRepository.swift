import Foundation
import SwiftData

@MainActor
final class BudgetRepository {
    private let repo: LocalRepository<Budget>
    private let userId: UUID

    init(modelContext: ModelContext, queueStore: SyncQueueStore, userId: UUID) {
        self.repo = LocalRepository(modelContext: modelContext, queueStore: queueStore, entityName: "budget")
        self.userId = userId
    }

    func all() throws -> [Budget] {
        try repo.fetch(FetchDescriptor(
            predicate: #Predicate { $0.userId == userId && $0.deletedAt == nil },
            sortBy: [.init(\.createdAt, order: .reverse)]
        ))
    }

    @discardableResult
    func create(clientId: UUID?, title: String, items: [BudgetItem], validUntil: Date?, paymentTerms: String?) throws -> Budget {
        let total = items.reduce(Decimal(0)) { $0 + $1.total }
        let budget = Budget(userId: userId, clientId: clientId, title: title, items: items, totalValue: total, validUntil: validUntil, paymentTerms: paymentTerms)
        try repo.create(budget, row: budget.asRow)
        return budget
    }

    func update(_ budget: Budget, items: [BudgetItem]) throws {
        budget.items = items
        budget.totalValue = items.reduce(Decimal(0)) { $0 + $1.total }
        budget.updatedAt = .now
        try repo.update(budget, row: budget.asRow)
    }

    func setStatus(_ budget: Budget, status: BudgetStatus) throws {
        budget.status = status
        budget.updatedAt = .now
        try repo.update(budget, row: budget.asRow)
    }

    func attachPDF(_ budget: Budget, url: String) throws {
        budget.pdfURL = url
        budget.updatedAt = .now
        try repo.update(budget, row: budget.asRow)
    }

    /// `valid_until` passou e status ainda `SENT` → `EXPIRED` (mio-escopo.md §6.2).
    func recalculateExpired() throws {
        let candidates = try repo.fetch(FetchDescriptor(
            predicate: #Predicate { $0.userId == userId && $0.status == BudgetStatus.sent && $0.deletedAt == nil }
        ))
        let today = Calendar.current.startOfDay(for: .now)
        for budget in candidates {
            guard let validUntil = budget.validUntil, validUntil < today else { continue }
            budget.status = .expired
            budget.updatedAt = .now
            try repo.update(budget, row: budget.asRow)
        }
    }

    func delete(_ budget: Budget) throws {
        budget.deletedAt = .now
        try repo.softDelete(budget, row: budget.asRow)
    }
}
