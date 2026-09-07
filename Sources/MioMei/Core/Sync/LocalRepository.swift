import Foundation
import SwiftData

/// CRUD local (SwiftData) + enfileiramento na fila de sync — reaproveitado por
/// todos os repositórios de entidade (mio-escopo.md §12).
@MainActor
final class LocalRepository<Model: LocalEntity> {
    private let modelContext: ModelContext
    private let queueStore: SyncQueueStore
    private let entityName: String

    init(modelContext: ModelContext, queueStore: SyncQueueStore, entityName: String) {
        self.modelContext = modelContext
        self.queueStore = queueStore
        self.entityName = entityName
    }

    func create(_ model: Model, row: some Encodable) throws {
        modelContext.insert(model)
        try modelContext.save()
        try queueStore.enqueue(entityName: entityName, recordId: model.id, operation: .create, record: row)
    }

    func update(_ model: Model, row: some Encodable) throws {
        try modelContext.save()
        try queueStore.enqueue(entityName: entityName, recordId: model.id, operation: .update, record: row)
    }

    func softDelete(_ model: Model, row: some Encodable) throws {
        try modelContext.save()
        try queueStore.enqueue(entityName: entityName, recordId: model.id, operation: .delete, record: row)
    }

    func fetch(_ descriptor: FetchDescriptor<Model>) throws -> [Model] {
        try modelContext.fetch(descriptor)
    }
}
