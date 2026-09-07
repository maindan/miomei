import Foundation

// Snapshots Codable enviados como payload da fila de sync — os nomes de campo
// em snake_case espelham as colunas reais das tabelas do Supabase
// (docs/miomei-db-schema.sql), para que o push (Fase futura) possa fazer
// upsert direto sem precisar de outro mapeamento.

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
