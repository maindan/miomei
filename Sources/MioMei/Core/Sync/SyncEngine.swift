import Foundation
import Supabase
import SwiftData

/// Orquestra push (fila local → Supabase) e pull (Supabase → SwiftData). Um
/// item só sai da fila após confirmação de gravação (mio-escopo.md §12, §10.1).
@MainActor
final class SyncEngine {
    private let modelContext: ModelContext
    private let queueStore: SyncQueueStore
    private let statusStore: SyncStatusStore
    private let connectivity: ConnectivityMonitor
    private let supabase: SupabaseService

    init(
        modelContext: ModelContext,
        queueStore: SyncQueueStore,
        statusStore: SyncStatusStore,
        connectivity: ConnectivityMonitor,
        supabase: SupabaseService
    ) {
        self.modelContext = modelContext
        self.queueStore = queueStore
        self.statusStore = statusStore
        self.connectivity = connectivity
        self.supabase = supabase
    }

    /// Ciclo completo (push + pull) disparado pelo botão "Sincronizar agora"
    /// ou pelo agendamento em segundo plano.
    func syncNow() async {
        guard connectivity.isConnected else {
            statusStore.status = .offline
            return
        }
        statusStore.status = .syncing
        do {
            try await pushPending()
            try await pullChanges()
            let remaining = try queueStore.pendingCount()
            if remaining > 0 {
                statusStore.status = .pending(count: remaining)
            } else {
                statusStore.status = .synced
                statusStore.lastSuccessfulSyncAt = .now
            }
        } catch {
            statusStore.status = .error(error.localizedDescription)
        }
    }

    // MARK: - Push

    /// Envia a fila de `PendingMutation` ao Supabase. Como o app é
    /// soft-delete, create/update/delete usam todos o mesmo upsert por `id`
    /// — o próprio payload já carrega `deleted_at` quando for o caso.
    /// Falhas individuais ficam na fila (com `attempts`/`lastError`) em vez
    /// de abortar o lote inteiro.
    private func pushPending() async throws {
        let pending = try queueStore.allPending()
        guard !pending.isEmpty else { return }
        statusStore.status = .pending(count: pending.count)

        for mutation in pending {
            do {
                let json = try JSONDecoder().decode(AnyJSON.self, from: mutation.payload)
                try await supabase.client.from(mutation.entityName).upsert(json).execute()
                try queueStore.remove(mutation)
            } catch {
                mutation.attempts += 1
                mutation.lastError = error.localizedDescription
                try? modelContext.save()
            }
        }
    }

    // MARK: - Pull

    /// Busca `updated_at > última_sync` em cada tabela e aplica localmente
    /// (upsert por `id`; `deleted_at` do servidor é copiado como soft delete).
    private func pullChanges() async throws {
        let since = statusStore.lastSuccessfulSyncAt ?? .distantPast

        try await pullProfile()
        try await pullClients(since: since)
        try await pullContracts(since: since)
        try await pullContractRenewals(since: since)
        try await pullReceivables(since: since)
        try await pullPayables(since: since)
        try await pullInvoices(since: since)
        try await pullBudgets(since: since)
        try await pullDemands(since: since)
        try await pullTasks(since: since)
        try await pullTimeEntries(since: since)
        try await pullReminders(since: since)
        try await pullNotifications(since: since)

        try modelContext.save()
    }

    private func fetchRows<R: Decodable>(table: String, since: Date) async throws -> [R] {
        let sinceString = ISO8601DateFormatter().string(from: since)
        return try await supabase.client
            .from(table)
            .select()
            .gt("updated_at", value: sinceString)
            .execute()
            .value
    }

    private func pullProfile() async throws {
        guard let userId = try? modelContext.fetch(FetchDescriptor<Profile>()).first?.id else { return }
        let rows: [ProfileRow] = try await supabase.client
            .from("profile").select().eq("id", value: userId.uuidString).execute().value
        guard let row = rows.first else { return }

        if let existing = try modelContext.fetch(FetchDescriptor<Profile>(predicate: #Predicate { $0.id == row.id })).first {
            existing.companyName = row.company_name
            existing.tradeName = row.trade_name
            existing.cnpj = row.cnpj
            existing.email = row.email
            existing.taxRegime = row.tax_regime
            existing.defaultTaxRate = row.default_tax_rate
            existing.dasDueDay = row.das_due_day
            existing.meiAnnualCeiling = row.mei_annual_ceiling
            existing.pixKey = row.pix_key
            existing.bankInfo = row.bank_info
            existing.avatarURL = row.avatar_url
            existing.onboardingDone = row.onboarding_done
            existing.updatedAt = row.updated_at
        }
    }

    private func pullClients(since: Date) async throws {
        let rows: [ClientRow] = try await fetchRows(table: "client", since: since)
        for row in rows {
            if let existing = try modelContext.fetch(FetchDescriptor<Client>(predicate: #Predicate { $0.id == row.id })).first {
                existing.name = row.name
                existing.document = row.document
                existing.email = row.email
                existing.phone = row.phone
                existing.notes = row.notes
                existing.updatedAt = row.updated_at
                existing.deletedAt = row.deleted_at
            } else {
                modelContext.insert(Client(
                    id: row.id, userId: row.user_id, name: row.name, document: row.document, email: row.email,
                    phone: row.phone, notes: row.notes, createdAt: row.created_at, updatedAt: row.updated_at,
                    deletedAt: row.deleted_at
                ))
            }
        }
    }

    private func pullContracts(since: Date) async throws {
        let rows: [ContractRow] = try await fetchRows(table: "contract", since: since)
        for row in rows {
            if let existing = try modelContext.fetch(FetchDescriptor<Contract>(predicate: #Predicate { $0.id == row.id })).first {
                existing.clientId = row.client_id
                existing.type = row.type
                existing.title = row.title
                existing.contractDescription = row.description
                existing.startDate = row.start_date
                existing.endDate = row.end_date
                existing.estimatedValue = row.estimated_value
                existing.weeklyHoursRequirement = row.weekly_hours_requirement
                existing.recurrence = row.recurrence
                existing.status = row.status
                existing.paymentMethod = row.payment_method
                existing.updatedAt = row.updated_at
                existing.deletedAt = row.deleted_at
            } else {
                modelContext.insert(Contract(
                    id: row.id, userId: row.user_id, clientId: row.client_id, type: row.type, title: row.title,
                    contractDescription: row.description, startDate: row.start_date, endDate: row.end_date,
                    estimatedValue: row.estimated_value, weeklyHoursRequirement: row.weekly_hours_requirement,
                    recurrence: row.recurrence, status: row.status, paymentMethod: row.payment_method,
                    createdAt: row.created_at, updatedAt: row.updated_at, deletedAt: row.deleted_at
                ))
            }
        }
    }

    private func pullContractRenewals(since: Date) async throws {
        let rows: [ContractRenewalRow] = try await fetchRows(table: "contract_renewal", since: since)
        for row in rows {
            if let existing = try modelContext.fetch(FetchDescriptor<ContractRenewal>(predicate: #Predicate { $0.id == row.id })).first {
                existing.newEndDate = row.new_end_date
                existing.addedValue = row.added_value
                existing.note = row.note
                existing.updatedAt = row.updated_at
                existing.deletedAt = row.deleted_at
            } else {
                modelContext.insert(ContractRenewal(
                    id: row.id, userId: row.user_id, contractId: row.contract_id, newEndDate: row.new_end_date,
                    addedValue: row.added_value, note: row.note, createdAt: row.created_at,
                    updatedAt: row.updated_at, deletedAt: row.deleted_at
                ))
            }
        }
    }

    private func pullReceivables(since: Date) async throws {
        let rows: [ReceivableRow] = try await fetchRows(table: "receivable", since: since)
        for row in rows {
            if let existing = try modelContext.fetch(FetchDescriptor<Receivable>(predicate: #Predicate { $0.id == row.id })).first {
                existing.contractId = row.contract_id
                existing.clientId = row.client_id
                existing.receivableDescription = row.description
                existing.amount = row.amount
                existing.dueDate = row.due_date
                existing.status = row.status
                existing.receivedAt = row.received_at
                existing.method = row.method
                existing.updatedAt = row.updated_at
                existing.deletedAt = row.deleted_at
            } else {
                modelContext.insert(Receivable(
                    id: row.id, userId: row.user_id, contractId: row.contract_id, clientId: row.client_id,
                    receivableDescription: row.description, amount: row.amount, dueDate: row.due_date,
                    status: row.status, receivedAt: row.received_at, method: row.method,
                    createdAt: row.created_at, updatedAt: row.updated_at, deletedAt: row.deleted_at
                ))
            }
        }
    }

    private func pullPayables(since: Date) async throws {
        let rows: [PayableRow] = try await fetchRows(table: "payable", since: since)
        for row in rows {
            if let existing = try modelContext.fetch(FetchDescriptor<Payable>(predicate: #Predicate { $0.id == row.id })).first {
                existing.type = row.type
                existing.payableDescription = row.description
                existing.amount = row.amount
                existing.dueDate = row.due_date
                existing.status = row.status
                existing.paidAt = row.paid_at
                existing.receiptURL = row.receipt_url
                existing.invoiceId = row.invoice_id
                existing.updatedAt = row.updated_at
                existing.deletedAt = row.deleted_at
            } else {
                modelContext.insert(Payable(
                    id: row.id, userId: row.user_id, type: row.type, payableDescription: row.description,
                    amount: row.amount, dueDate: row.due_date, status: row.status, paidAt: row.paid_at,
                    receiptURL: row.receipt_url, invoiceId: row.invoice_id, createdAt: row.created_at,
                    updatedAt: row.updated_at, deletedAt: row.deleted_at
                ))
            }
        }
    }

    private func pullInvoices(since: Date) async throws {
        let rows: [InvoiceRow] = try await fetchRows(table: "invoice", since: since)
        for row in rows {
            if let existing = try modelContext.fetch(FetchDescriptor<Invoice>(predicate: #Predicate { $0.id == row.id })).first {
                existing.contractId = row.contract_id
                existing.clientId = row.client_id
                existing.number = row.number
                existing.amount = row.amount
                existing.issueDate = row.issue_date
                existing.plannedDate = row.planned_date
                existing.status = row.status
                existing.updatedAt = row.updated_at
                existing.deletedAt = row.deleted_at
            } else {
                modelContext.insert(Invoice(
                    id: row.id, userId: row.user_id, contractId: row.contract_id, clientId: row.client_id,
                    number: row.number, amount: row.amount, issueDate: row.issue_date, plannedDate: row.planned_date,
                    status: row.status, createdAt: row.created_at, updatedAt: row.updated_at, deletedAt: row.deleted_at
                ))
            }
        }
    }

    private func pullBudgets(since: Date) async throws {
        let rows: [BudgetRow] = try await fetchRows(table: "budget", since: since)
        for row in rows {
            if let existing = try modelContext.fetch(FetchDescriptor<Budget>(predicate: #Predicate { $0.id == row.id })).first {
                existing.clientId = row.client_id
                existing.title = row.title
                existing.items = row.items
                existing.totalValue = row.total_value
                existing.validUntil = row.valid_until
                existing.paymentTerms = row.payment_terms
                existing.status = row.status
                existing.pdfURL = row.pdf_url
                existing.updatedAt = row.updated_at
                existing.deletedAt = row.deleted_at
            } else {
                modelContext.insert(Budget(
                    id: row.id, userId: row.user_id, clientId: row.client_id, title: row.title, items: row.items,
                    totalValue: row.total_value, validUntil: row.valid_until, paymentTerms: row.payment_terms,
                    status: row.status, pdfURL: row.pdf_url, createdAt: row.created_at, updatedAt: row.updated_at,
                    deletedAt: row.deleted_at
                ))
            }
        }
    }

    private func pullDemands(since: Date) async throws {
        let rows: [DemandRow] = try await fetchRows(table: "demand", since: since)
        for row in rows {
            if let existing = try modelContext.fetch(FetchDescriptor<Demand>(predicate: #Predicate { $0.id == row.id })).first {
                existing.contractId = row.contract_id
                existing.title = row.title
                existing.demandDescription = row.description
                existing.priority = row.priority
                existing.deadline = row.deadline
                existing.status = row.status
                existing.updatedAt = row.updated_at
                existing.deletedAt = row.deleted_at
            } else {
                modelContext.insert(Demand(
                    id: row.id, userId: row.user_id, contractId: row.contract_id, title: row.title,
                    demandDescription: row.description, priority: row.priority, deadline: row.deadline,
                    status: row.status, createdAt: row.created_at, updatedAt: row.updated_at, deletedAt: row.deleted_at
                ))
            }
        }
    }

    private func pullTasks(since: Date) async throws {
        let rows: [TaskItemRow] = try await fetchRows(table: "task", since: since)
        for row in rows {
            if let existing = try modelContext.fetch(FetchDescriptor<TaskItem>(predicate: #Predicate { $0.id == row.id })).first {
                existing.title = row.title
                existing.done = row.done
                existing.position = row.position
                existing.updatedAt = row.updated_at
                existing.deletedAt = row.deleted_at
            } else {
                modelContext.insert(TaskItem(
                    id: row.id, userId: row.user_id, demandId: row.demand_id, title: row.title, done: row.done,
                    position: row.position, createdAt: row.created_at, updatedAt: row.updated_at, deletedAt: row.deleted_at
                ))
            }
        }
    }

    private func pullTimeEntries(since: Date) async throws {
        let rows: [TimeEntryRow] = try await fetchRows(table: "time_entry", since: since)
        for row in rows {
            if let existing = try modelContext.fetch(FetchDescriptor<TimeEntry>(predicate: #Predicate { $0.id == row.id })).first {
                existing.startedAt = row.started_at
                existing.endedAt = row.ended_at
                existing.durationSeconds = row.duration_seconds
                existing.isManual = row.is_manual
                existing.updatedAt = row.updated_at
                existing.deletedAt = row.deleted_at
            } else {
                modelContext.insert(TimeEntry(
                    id: row.id, userId: row.user_id, demandId: row.demand_id, startedAt: row.started_at,
                    endedAt: row.ended_at, durationSeconds: row.duration_seconds, isManual: row.is_manual,
                    createdAt: row.created_at, updatedAt: row.updated_at, deletedAt: row.deleted_at
                ))
            }
        }
    }

    private func pullReminders(since: Date) async throws {
        let rows: [ReminderRow] = try await fetchRows(table: "reminder", since: since)
        for row in rows {
            if let existing = try modelContext.fetch(FetchDescriptor<Reminder>(predicate: #Predicate { $0.id == row.id })).first {
                existing.title = row.title
                existing.date = row.date
                existing.recurrence = row.recurrence
                existing.note = row.note
                existing.updatedAt = row.updated_at
                existing.deletedAt = row.deleted_at
            } else {
                modelContext.insert(Reminder(
                    id: row.id, userId: row.user_id, title: row.title, date: row.date, recurrence: row.recurrence,
                    note: row.note, createdAt: row.created_at, updatedAt: row.updated_at, deletedAt: row.deleted_at
                ))
            }
        }
    }

    private func pullNotifications(since: Date) async throws {
        let rows: [NotificationRow] = try await fetchRows(table: "notification", since: since)
        for row in rows {
            if let existing = try modelContext.fetch(FetchDescriptor<NotificationItem>(predicate: #Predicate { $0.id == row.id })).first {
                existing.type = row.type
                existing.title = row.title
                existing.body = row.body
                existing.entityRef = row.entity_ref
                existing.readAt = row.read_at
                existing.updatedAt = row.updated_at
                existing.deletedAt = row.deleted_at
            } else {
                modelContext.insert(NotificationItem(
                    id: row.id, userId: row.user_id, type: row.type, title: row.title, body: row.body,
                    entityRef: row.entity_ref, readAt: row.read_at, createdAt: row.created_at,
                    updatedAt: row.updated_at, deletedAt: row.deleted_at
                ))
            }
        }
    }
}
