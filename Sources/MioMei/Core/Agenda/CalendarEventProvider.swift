import Foundation
import SwiftData

@MainActor
final class CalendarEventProvider {
    private let modelContext: ModelContext
    private let queueStore: SyncQueueStore
    private let userId: UUID

    init(modelContext: ModelContext, userId: UUID) {
        self.modelContext = modelContext
        self.queueStore = SyncQueueStore(modelContext: modelContext)
        self.userId = userId
    }

    /// Agrega recebimentos previstos, pagamentos/impostos, notas, prazos de
    /// demanda, vencimentos de contrato e lembretes num intervalo (mio-escopo.md §8.1).
    func events(from: Date, to: Date) throws -> [CalendarEvent] {
        var events: [CalendarEvent] = []

        let receivables = try ReceivableRepository(modelContext: modelContext, queueStore: queueStore, userId: userId).all()
        events += receivables
            .filter { $0.dueDate >= from && $0.dueDate < to }
            .map { CalendarEvent(id: "receivable:\($0.id)", source: .receivable, title: $0.receivableDescription ?? "Recebimento", date: $0.dueDate, amount: $0.amount) }

        let payables = try PayableRepository(modelContext: modelContext, queueStore: queueStore, userId: userId).all()
        events += payables
            .filter { $0.dueDate >= from && $0.dueDate < to }
            .map { CalendarEvent(id: "payable:\($0.id)", source: .payable, title: $0.payableDescription ?? "Pagamento", date: $0.dueDate, amount: $0.amount) }

        let invoices = try InvoiceRepository(modelContext: modelContext, queueStore: queueStore, userId: userId).all()
        events += invoices.compactMap { invoice in
            guard let date = invoice.plannedDate ?? invoice.issueDate, date >= from, date < to else { return nil }
            return CalendarEvent(id: "invoice:\(invoice.id)", source: .invoice, title: invoice.number.map { "Nota \($0)" } ?? "Nota fiscal", date: date, amount: invoice.amount)
        }

        let demands = try DemandRepository(modelContext: modelContext, queueStore: queueStore, userId: userId).all()
        events += demands.compactMap { demand in
            guard let deadline = demand.deadline, deadline >= from, deadline < to else { return nil }
            return CalendarEvent(id: "demand:\(demand.id)", source: .demand, title: demand.title, date: deadline, amount: nil)
        }

        let contracts = try ContractRepository(modelContext: modelContext, queueStore: queueStore, userId: userId).all()
        events += contracts.compactMap { contract in
            guard let endDate = contract.endDate, endDate >= from, endDate < to else { return nil }
            return CalendarEvent(id: "contract:\(contract.id)", source: .contract, title: contract.title, date: endDate, amount: contract.estimatedValue)
        }

        let reminders = try ReminderRepository(modelContext: modelContext, queueStore: queueStore, userId: userId).between(from, to)
        events += reminders.map { CalendarEvent(id: "reminder:\($0.id)", source: .reminder, title: $0.title, date: $0.date, amount: nil) }

        return events.sorted { $0.date < $1.date }
    }
}
