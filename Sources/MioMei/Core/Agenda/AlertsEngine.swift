import Foundation
import SwiftData

/// Lógica proativa de alertas do Dashboard e da central de notificações
/// (mio-escopo.md §5, §11). Idempotente: não duplica um alerta já não-lido
/// para a mesma entidade.
@MainActor
final class AlertsEngine {
    private let modelContext: ModelContext
    private let queueStore: SyncQueueStore
    private let userId: UUID
    private let notifications: NotificationRepository

    init(modelContext: ModelContext, userId: UUID) {
        self.modelContext = modelContext
        self.queueStore = SyncQueueStore(modelContext: modelContext)
        self.userId = userId
        self.notifications = NotificationRepository(modelContext: modelContext, queueStore: queueStore, userId: userId)
    }

    func recalculate(profile: Profile?) throws {
        let today = Calendar.current.startOfDay(for: .now)
        let in3Days = Calendar.current.date(byAdding: .day, value: 3, to: today) ?? today
        let in30Days = Calendar.current.date(byAdding: .day, value: 30, to: today) ?? today

        let receivables = try ReceivableRepository(modelContext: modelContext, queueStore: queueStore, userId: userId).all()
        for receivable in receivables where receivable.status == .overdue {
            try notify(
                type: "RECEIVABLE_OVERDUE", entityRef: "receivable:\(receivable.id)",
                title: "Recebimento atrasado", body: receivable.receivableDescription ?? "Um recebimento está atrasado."
            )
        }

        let payables = try PayableRepository(modelContext: modelContext, queueStore: queueStore, userId: userId).all()
        for payable in payables where payable.status == .pending && payable.dueDate <= in3Days {
            try notify(
                type: "PAYABLE_DUE_SOON", entityRef: "payable:\(payable.id)",
                title: "Imposto/pagamento vencendo", body: "Vence em \(payable.dueDate.mediumBR)."
            )
        }

        let invoices = try InvoiceRepository(modelContext: modelContext, queueStore: queueStore, userId: userId).all()
        for invoice in invoices where invoice.status == .toIssue && (invoice.plannedDate ?? .distantFuture) <= today {
            try notify(
                type: "INVOICE_PENDING", entityRef: "invoice:\(invoice.id)",
                title: "Nota fiscal pendente", body: invoice.number.map { "Nota \($0) aguardando emissão." } ?? "Nota aguardando emissão."
            )
        }

        let contracts = try ContractRepository(modelContext: modelContext, queueStore: queueStore, userId: userId).all()
        for contract in contracts where contract.status == .active {
            guard let endDate = contract.endDate, endDate <= in30Days else { continue }
            try notify(
                type: "CONTRACT_RENEWAL", entityRef: "contract:\(contract.id)",
                title: "Contrato vencendo", body: "\(contract.title) vence em \(endDate.mediumBR) sem renovação registrada."
            )
        }

        if let profile, profile.taxRegime == .mei, let ceiling = profile.meiAnnualCeiling, ceiling > 0 {
            let issuedTotal = try InvoiceRepository(modelContext: modelContext, queueStore: queueStore, userId: userId).issuedTotalThisYear()
            if issuedTotal >= ceiling * Decimal(0.8) {
                try notify(
                    type: "MEI_CEILING", entityRef: "profile:mei_ceiling",
                    title: "Perto do teto do MEI", body: "Faturamento do ano já passou de 80% do teto."
                )
            }
        }
    }

    /// Cria o item na central in-app e dispara a notificação local do iOS
    /// correspondente (mio-escopo.md §11) — só na primeira vez que o alerta
    /// aparece, não a cada recálculo.
    private func notify(type: String, entityRef: String, title: String, body: String) throws {
        guard try !notifications.hasUnread(entityRef: entityRef) else { return }
        let notification = try notifications.create(type: type, title: title, body: body, entityRef: entityRef)
        LocalNotificationScheduler.notifyNow(id: notification.id, title: title, body: body)
    }
}
