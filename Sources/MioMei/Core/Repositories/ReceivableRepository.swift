import Foundation
import SwiftData

@MainActor
final class ReceivableRepository {
    private let repo: LocalRepository<Receivable>
    private let userId: UUID

    init(modelContext: ModelContext, queueStore: SyncQueueStore, userId: UUID) {
        self.repo = LocalRepository(modelContext: modelContext, queueStore: queueStore, entityName: "receivable")
        self.userId = userId
    }

    func all() throws -> [Receivable] {
        try repo.fetch(FetchDescriptor(
            predicate: #Predicate { $0.userId == userId && $0.deletedAt == nil },
            sortBy: [.init(\.dueDate)]
        ))
    }

    func totalReceived(contractId: UUID) throws -> Decimal {
        let receivedStatus = ReceivableStatus.received
        let received = try repo.fetch(FetchDescriptor(
            predicate: #Predicate { $0.contractId == contractId && $0.status == receivedStatus && $0.deletedAt == nil }
        ))
        return received.reduce(0) { $0 + $1.amount }
    }

    /// Gera N parcelas a partir do total e do número de parcelas informado
    /// (mio-escopo.md §6.4), uma por mês a partir de `firstDueDate`.
    func createInstallments(
        contractId: UUID?,
        clientId: UUID?,
        description: String?,
        totalAmount: Decimal,
        installments: Int,
        firstDueDate: Date,
        method: String?
    ) throws {
        let count = max(installments, 1)
        let perInstallment = totalAmount / Decimal(count)
        let calendar = Calendar.current

        for index in 0..<count {
            let dueDate = calendar.date(byAdding: .month, value: index, to: firstDueDate) ?? firstDueDate
            let installmentDescription = count > 1 ? "\(description ?? "Recebimento") (\(index + 1)/\(count))" : description
            let receivable = Receivable(
                userId: userId, contractId: contractId, clientId: clientId,
                receivableDescription: installmentDescription, amount: perInstallment, dueDate: dueDate,
                method: method
            )
            try repo.create(receivable, row: receivable.asRow)
        }
    }

    func create(_ input: Receivable.CreateInput) throws {
        try createInstallments(
            contractId: input.contractId, clientId: input.clientId, description: input.description,
            totalAmount: input.amount, installments: input.installments, firstDueDate: input.dueDate,
            method: input.method
        )
    }

    /// Não gera o imposto nem a nota diretamente — quem orquestra as duas
    /// sugestões (mio-escopo.md §6.4, §9) é a tela que chama este método.
    @discardableResult
    func markReceived(_ receivable: Receivable) throws -> Receivable {
        receivable.status = .received
        receivable.receivedAt = .now
        receivable.updatedAt = .now
        try repo.update(receivable, row: receivable.asRow)
        return receivable
    }

    /// `due_date` passou e status ainda `EXPECTED` → `OVERDUE` (mio-escopo.md §9).
    func recalculateOverdue() throws {
        let expectedStatus = ReceivableStatus.expected
        let candidates = try repo.fetch(FetchDescriptor(
            predicate: #Predicate { $0.userId == userId && $0.status == expectedStatus && $0.deletedAt == nil }
        ))
        let today = Calendar.current.startOfDay(for: .now)
        for receivable in candidates where receivable.dueDate < today {
            receivable.status = .overdue
            receivable.updatedAt = .now
            try repo.update(receivable, row: receivable.asRow)
        }
    }

    func delete(_ receivable: Receivable) throws {
        receivable.deletedAt = .now
        try repo.softDelete(receivable, row: receivable.asRow)
    }
}
