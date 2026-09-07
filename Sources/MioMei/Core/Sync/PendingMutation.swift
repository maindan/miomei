import Foundation
import SwiftData

enum MutationOperation: String, Codable {
    case create, update, delete
}

/// Fila local de mutações ainda não confirmadas pelo Supabase — a fonte de
/// verdade de "pendente vs. sincronizado" (mio-escopo.md §10.1, §12).
@Model
final class PendingMutation {
    @Attribute(.unique) var id: UUID
    /// Nome da tabela Supabase de destino, ex.: "receivable".
    var entityName: String
    var recordId: UUID
    var operation: MutationOperation
    /// Snapshot JSON codificado do registro no momento da mutação.
    var payload: Data
    var createdAt: Date
    var attempts: Int
    var lastError: String?

    init(
        id: UUID = UUID(),
        entityName: String,
        recordId: UUID,
        operation: MutationOperation,
        payload: Data,
        createdAt: Date = .now,
        attempts: Int = 0,
        lastError: String? = nil
    ) {
        self.id = id
        self.entityName = entityName
        self.recordId = recordId
        self.operation = operation
        self.payload = payload
        self.createdAt = createdAt
        self.attempts = attempts
        self.lastError = lastError
    }
}
