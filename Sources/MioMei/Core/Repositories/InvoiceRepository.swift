import Foundation
import SwiftData

@MainActor
final class InvoiceRepository {
    private let repo: LocalRepository<Invoice>
    private let userId: UUID

    init(modelContext: ModelContext, queueStore: SyncQueueStore, userId: UUID) {
        self.repo = LocalRepository(modelContext: modelContext, queueStore: queueStore, entityName: "invoice")
        self.userId = userId
    }

    func all() throws -> [Invoice] {
        try repo.fetch(FetchDescriptor(
            predicate: #Predicate { $0.userId == userId && $0.deletedAt == nil },
            sortBy: [.init(\.plannedDate)]
        ))
    }

    /// Total faturado no ano corrente (notas emitidas) — usado no alerta de teto MEI.
    func issuedTotalThisYear() throws -> Decimal {
        let calendar = Calendar.current
        let yearStart = calendar.date(from: calendar.dateComponents([.year], from: .now)) ?? .now
        let issued = try repo.fetch(FetchDescriptor(
            predicate: #Predicate { $0.userId == userId && $0.status == InvoiceStatus.issued && $0.deletedAt == nil }
        ))
        return issued.filter { ($0.issueDate ?? .distantPast) >= yearStart }.reduce(0) { $0 + $1.amount }
    }

    @discardableResult
    func create(contractId: UUID?, clientId: UUID?, number: String?, amount: Decimal, plannedDate: Date?) throws -> Invoice {
        let invoice = Invoice(userId: userId, contractId: contractId, clientId: clientId, number: number, amount: amount, plannedDate: plannedDate)
        try repo.create(invoice, row: invoice.asRow)
        return invoice
    }

    /// Emitir a nota: alimenta o faturamento anual (mio-escopo.md §6.6, §9).
    func markIssued(_ invoice: Invoice) throws {
        invoice.status = .issued
        invoice.issueDate = .now
        invoice.updatedAt = .now
        try repo.update(invoice, row: invoice.asRow)
    }

    func delete(_ invoice: Invoice) throws {
        invoice.deletedAt = .now
        try repo.softDelete(invoice, row: invoice.asRow)
    }
}
