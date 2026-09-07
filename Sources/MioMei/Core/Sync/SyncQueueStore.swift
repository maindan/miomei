import Foundation
import SwiftData

/// Enfileira mutações locais para envio posterior ao Supabase. Repositórios de
/// cada entidade (Fase 2+) chamam `enqueue` a cada create/update/delete local.
@MainActor
final class SyncQueueStore {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func enqueue<T: Encodable>(
        entityName: String,
        recordId: UUID,
        operation: MutationOperation,
        record: T
    ) throws {
        let payload = try JSONEncoder.miomei.encode(record)
        let mutation = PendingMutation(
            entityName: entityName,
            recordId: recordId,
            operation: operation,
            payload: payload
        )
        modelContext.insert(mutation)
        try modelContext.save()
    }

    func pendingCount() throws -> Int {
        try modelContext.fetchCount(FetchDescriptor<PendingMutation>())
    }

    func allPending() throws -> [PendingMutation] {
        try modelContext.fetch(FetchDescriptor<PendingMutation>(sortBy: [.init(\.createdAt)]))
    }

    func remove(_ mutation: PendingMutation) throws {
        modelContext.delete(mutation)
        try modelContext.save()
    }
}

extension JSONEncoder {
    static let miomei: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
}

extension JSONDecoder {
    static let miomei: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
