import Foundation
import SwiftData

@MainActor
final class PayableRepository {
    private let repo: LocalRepository<Payable>
    private let userId: UUID

    init(modelContext: ModelContext, queueStore: SyncQueueStore, userId: UUID) {
        self.repo = LocalRepository(modelContext: modelContext, queueStore: queueStore, entityName: "payable")
        self.userId = userId
    }

    func all() throws -> [Payable] {
        try repo.fetch(FetchDescriptor(
            predicate: #Predicate { $0.userId == userId && $0.deletedAt == nil },
            sortBy: [.init(\.dueDate)]
        ))
    }

    @discardableResult
    func create(type: PayableType, description: String?, amount: Decimal, dueDate: Date) throws -> Payable {
        let payable = Payable(userId: userId, type: type, payableDescription: description, amount: amount, dueDate: dueDate)
        try repo.create(payable, row: payable.asRow)
        return payable
    }

    func markPaid(_ payable: Payable) throws {
        payable.status = .paid
        payable.paidAt = .now
        payable.updatedAt = .now
        try repo.update(payable, row: payable.asRow)
    }

    /// `due_date` passou sem pagamento → `OVERDUE` (mio-escopo.md §9).
    func recalculateOverdue() throws {
        let candidates = try repo.fetch(FetchDescriptor(
            predicate: #Predicate { $0.userId == userId && $0.status == PayableStatus.pending && $0.deletedAt == nil }
        ))
        let today = Calendar.current.startOfDay(for: .now)
        for payable in candidates where payable.dueDate < today {
            payable.status = .overdue
            payable.updatedAt = .now
            try repo.update(payable, row: payable.asRow)
        }
    }

    /// Recebimento marcado como recebido → gera imposto a pagar pela alíquota
    /// do perfil (mio-escopo.md §9).
    @discardableResult
    func createTax(onAmount amount: Decimal, taxRate: Decimal, dueDate: Date) throws -> Payable? {
        guard taxRate > 0 else { return nil }
        let taxAmount = amount * taxRate / 100
        return try create(type: .invoiceTax, description: "Imposto sobre recebimento", amount: taxAmount, dueDate: dueDate)
    }

    /// Regime MEI → garante um DAS-MEI pendente para o mês corrente, vencendo
    /// no dia configurado no perfil (mio-escopo.md §4.3, §9).
    func ensureCurrentMonthDASMEI(profile: Profile) throws {
        guard profile.taxRegime == .mei else { return }

        let calendar = Calendar.current
        let now = Date.now
        var dueComponents = calendar.dateComponents([.year, .month], from: now)
        dueComponents.day = profile.dasDueDay
        guard let dueDate = calendar.date(from: dueComponents) else { return }

        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) ?? now

        let existing = try repo.fetch(FetchDescriptor(
            predicate: #Predicate { payable in
                payable.userId == userId &&
                payable.type == PayableType.dasMei &&
                payable.dueDate >= monthStart &&
                payable.dueDate < monthEnd &&
                payable.deletedAt == nil
            }
        ))
        guard existing.isEmpty else { return }

        try create(type: .dasMei, description: "DAS-MEI", amount: 0, dueDate: dueDate)
    }

    func delete(_ payable: Payable) throws {
        payable.deletedAt = .now
        try repo.softDelete(payable, row: payable.asRow)
    }
}
