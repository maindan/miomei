import Foundation

// Espelham os enums Postgres de docs/miomei-db-schema.sql. `Codable` para
// serializar no payload JSON da fila de sync; `String` raw value = valor exato
// gravado na coluna do Supabase.

enum TaxRegime: String, Codable, CaseIterable, Identifiable {
    case mei = "MEI"
    case simples = "SIMPLES"
    case other = "OTHER"
    var id: String { rawValue }
}

enum BudgetStatus: String, Codable, CaseIterable, Identifiable {
    case draft = "DRAFT", sent = "SENT", approved = "APPROVED", rejected = "REJECTED", expired = "EXPIRED"
    var id: String { rawValue }
}

enum ContractType: String, Codable, CaseIterable, Identifiable {
    case pj = "PJ", freelance = "FREELANCE"
    var id: String { rawValue }
}

enum ContractStatus: String, Codable, CaseIterable, Identifiable {
    case active = "ACTIVE", closed = "CLOSED", suspended = "SUSPENDED"
    var id: String { rawValue }
}

enum ReceivableStatus: String, Codable, CaseIterable, Identifiable {
    case expected = "EXPECTED", received = "RECEIVED", overdue = "OVERDUE"
    var id: String { rawValue }
}

enum PayableType: String, Codable, CaseIterable, Identifiable {
    case dasMei = "DAS_MEI", invoiceTax = "INVOICE_TAX", other = "OTHER"
    var id: String { rawValue }
}

enum PayableStatus: String, Codable, CaseIterable, Identifiable {
    case pending = "PENDING", paid = "PAID", overdue = "OVERDUE"
    var id: String { rawValue }
}

enum InvoiceStatus: String, Codable, CaseIterable, Identifiable {
    case toIssue = "TO_ISSUE", issued = "ISSUED"
    var id: String { rawValue }
}

enum DemandPriority: String, Codable, CaseIterable, Identifiable {
    case low = "LOW", medium = "MEDIUM", high = "HIGH"
    var id: String { rawValue }
}

enum DemandStatus: String, Codable, CaseIterable, Identifiable {
    case todo = "TODO", inProgress = "IN_PROGRESS", done = "DONE"
    var id: String { rawValue }
}
