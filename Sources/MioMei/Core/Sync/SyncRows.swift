import Foundation

// Snapshots Codable enviados como payload da fila de sync — os nomes de campo
// em snake_case espelham as colunas reais das tabelas do Supabase
// (docs/miomei-db-schema.sql), para que o push (Fase futura) possa fazer
// upsert direto sem precisar de outro mapeamento.

struct ProfileRow: Codable {
    let id: UUID
    let company_name: String?
    let trade_name: String?
    let cnpj: String?
    let email: String?
    let tax_regime: TaxRegime
    let default_tax_rate: Decimal
    let das_due_day: Int
    let mei_annual_ceiling: Decimal?
    let pix_key: String?
    let bank_info: String?
    let avatar_url: String?
    let onboarding_done: Bool
    let created_at: Date
    let updated_at: Date
}

extension Profile {
    var asRow: ProfileRow {
        ProfileRow(
            id: id, company_name: companyName, trade_name: tradeName, cnpj: cnpj, email: email,
            tax_regime: taxRegime, default_tax_rate: defaultTaxRate, das_due_day: dasDueDay,
            mei_annual_ceiling: meiAnnualCeiling, pix_key: pixKey, bank_info: bankInfo,
            avatar_url: avatarURL, onboarding_done: onboardingDone, created_at: createdAt, updated_at: updatedAt
        )
    }
}

struct ClientRow: Codable {
    let id: UUID
    let user_id: UUID
    let name: String
    let document: String?
    let email: String?
    let phone: String?
    let notes: String?
    let created_at: Date
    let updated_at: Date
    let deleted_at: Date?
}

extension Client {
    var asRow: ClientRow {
        ClientRow(
            id: id, user_id: userId, name: name, document: document, email: email,
            phone: phone, notes: notes, created_at: createdAt, updated_at: updatedAt,
            deleted_at: deletedAt
        )
    }
}

struct BudgetRow: Codable {
    let id: UUID
    let user_id: UUID
    let client_id: UUID?
    let title: String
    let items: [BudgetItem]
    let total_value: Decimal
    let valid_until: Date?
    let payment_terms: String?
    let status: BudgetStatus
    let pdf_url: String?
    let created_at: Date
    let updated_at: Date
    let deleted_at: Date?
}

extension Budget {
    var asRow: BudgetRow {
        BudgetRow(
            id: id, user_id: userId, client_id: clientId, title: title, items: items,
            total_value: totalValue, valid_until: validUntil, payment_terms: paymentTerms,
            status: status, pdf_url: pdfURL, created_at: createdAt, updated_at: updatedAt,
            deleted_at: deletedAt
        )
    }
}

struct ContractRow: Codable {
    let id: UUID
    let user_id: UUID
    let client_id: UUID?
    let type: ContractType
    let title: String
    let description: String?
    let start_date: Date?
    let end_date: Date?
    let estimated_value: Decimal?
    let weekly_hours_requirement: Decimal?
    let recurrence: String?
    let status: ContractStatus
    let payment_method: String?
    let created_at: Date
    let updated_at: Date
    let deleted_at: Date?
}

extension Contract {
    var asRow: ContractRow {
        ContractRow(
            id: id, user_id: userId, client_id: clientId, type: type, title: title,
            description: contractDescription, start_date: startDate, end_date: endDate,
            estimated_value: estimatedValue, weekly_hours_requirement: weeklyHoursRequirement,
            recurrence: recurrence, status: status, payment_method: paymentMethod,
            created_at: createdAt, updated_at: updatedAt, deleted_at: deletedAt
        )
    }
}

struct ContractRenewalRow: Codable {
    let id: UUID
    let user_id: UUID
    let contract_id: UUID
    let new_end_date: Date
    let added_value: Decimal?
    let note: String?
    let created_at: Date
    let updated_at: Date
    let deleted_at: Date?
}

extension ContractRenewal {
    var asRow: ContractRenewalRow {
        ContractRenewalRow(
            id: id, user_id: userId, contract_id: contractId, new_end_date: newEndDate,
            added_value: addedValue, note: note, created_at: createdAt, updated_at: updatedAt,
            deleted_at: deletedAt
        )
    }
}

struct ReceivableRow: Codable {
    let id: UUID
    let user_id: UUID
    let contract_id: UUID?
    let client_id: UUID?
    let description: String?
    let amount: Decimal
    let due_date: Date
    let status: ReceivableStatus
    let received_at: Date?
    let method: String?
    let created_at: Date
    let updated_at: Date
    let deleted_at: Date?
}

extension Receivable {
    var asRow: ReceivableRow {
        ReceivableRow(
            id: id, user_id: userId, contract_id: contractId, client_id: clientId,
            description: receivableDescription, amount: amount, due_date: dueDate,
            status: status, received_at: receivedAt, method: method, created_at: createdAt,
            updated_at: updatedAt, deleted_at: deletedAt
        )
    }
}

struct PayableRow: Codable {
    let id: UUID
    let user_id: UUID
    let type: PayableType
    let description: String?
    let amount: Decimal
    let due_date: Date
    let status: PayableStatus
    let paid_at: Date?
    let receipt_url: String?
    let invoice_id: UUID?
    let created_at: Date
    let updated_at: Date
    let deleted_at: Date?
}

extension Payable {
    var asRow: PayableRow {
        PayableRow(
            id: id, user_id: userId, type: type, description: payableDescription,
            amount: amount, due_date: dueDate, status: status, paid_at: paidAt,
            receipt_url: receiptURL, invoice_id: invoiceId, created_at: createdAt,
            updated_at: updatedAt, deleted_at: deletedAt
        )
    }
}

struct InvoiceRow: Codable {
    let id: UUID
    let user_id: UUID
    let contract_id: UUID?
    let client_id: UUID?
    let number: String?
    let amount: Decimal
    let issue_date: Date?
    let planned_date: Date?
    let status: InvoiceStatus
    let created_at: Date
    let updated_at: Date
    let deleted_at: Date?
}

extension Invoice {
    var asRow: InvoiceRow {
        InvoiceRow(
            id: id, user_id: userId, contract_id: contractId, client_id: clientId, number: number,
            amount: amount, issue_date: issueDate, planned_date: plannedDate, status: status,
            created_at: createdAt, updated_at: updatedAt, deleted_at: deletedAt
        )
    }
}

struct ReminderRow: Codable {
    let id: UUID
    let user_id: UUID
    let title: String
    let date: Date
    let recurrence: String?
    let note: String?
    let created_at: Date
    let updated_at: Date
    let deleted_at: Date?
}

extension Reminder {
    var asRow: ReminderRow {
        ReminderRow(
            id: id, user_id: userId, title: title, date: date, recurrence: recurrence,
            note: note, created_at: createdAt, updated_at: updatedAt, deleted_at: deletedAt
        )
    }
}

struct NotificationRow: Codable {
    let id: UUID
    let user_id: UUID
    let type: String
    let title: String
    let body: String?
    let entity_ref: String?
    let read_at: Date?
    let created_at: Date
    let updated_at: Date
    let deleted_at: Date?
}

extension NotificationItem {
    var asRow: NotificationRow {
        NotificationRow(
            id: id, user_id: userId, type: type, title: title, body: body, entity_ref: entityRef,
            read_at: readAt, created_at: createdAt, updated_at: updatedAt, deleted_at: deletedAt
        )
    }
}

struct DemandRow: Codable {
    let id: UUID
    let user_id: UUID
    let contract_id: UUID?
    let title: String
    let description: String?
    let priority: DemandPriority
    let deadline: Date?
    let status: DemandStatus
    let created_at: Date
    let updated_at: Date
    let deleted_at: Date?
}

extension Demand {
    var asRow: DemandRow {
        DemandRow(
            id: id, user_id: userId, contract_id: contractId, title: title,
            description: demandDescription, priority: priority, deadline: deadline,
            status: status, created_at: createdAt, updated_at: updatedAt, deleted_at: deletedAt
        )
    }
}

struct TaskItemRow: Codable {
    let id: UUID
    let user_id: UUID
    let demand_id: UUID
    let title: String
    let done: Bool
    let position: Int
    let created_at: Date
    let updated_at: Date
    let deleted_at: Date?
}

extension TaskItem {
    var asRow: TaskItemRow {
        TaskItemRow(
            id: id, user_id: userId, demand_id: demandId, title: title, done: done,
            position: position, created_at: createdAt, updated_at: updatedAt, deleted_at: deletedAt
        )
    }
}

struct TimeEntryRow: Codable {
    let id: UUID
    let user_id: UUID
    let demand_id: UUID
    let started_at: Date
    let ended_at: Date?
    let duration_seconds: Int?
    let is_manual: Bool
    let created_at: Date
    let updated_at: Date
    let deleted_at: Date?
}

extension TimeEntry {
    var asRow: TimeEntryRow {
        TimeEntryRow(
            id: id, user_id: userId, demand_id: demandId, started_at: startedAt,
            ended_at: endedAt, duration_seconds: durationSeconds, is_manual: isManual,
            created_at: createdAt, updated_at: updatedAt, deleted_at: deletedAt
        )
    }
}
