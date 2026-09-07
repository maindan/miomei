import Foundation
import SwiftData

@MainActor
final class ClientRepository {
    private let repo: LocalRepository<Client>
    private let userId: UUID

    init(modelContext: ModelContext, queueStore: SyncQueueStore, userId: UUID) {
        self.repo = LocalRepository(modelContext: modelContext, queueStore: queueStore, entityName: "client")
        self.userId = userId
    }

    func all() throws -> [Client] {
        try repo.fetch(FetchDescriptor(
            predicate: #Predicate { $0.userId == userId && $0.deletedAt == nil },
            sortBy: [.init(\.name)]
        ))
    }

    @discardableResult
    func create(name: String, document: String?, email: String?, phone: String?, notes: String?) throws -> Client {
        let client = Client(userId: userId, name: name, document: document, email: email, phone: phone, notes: notes)
        try repo.create(client, row: client.asRow)
        return client
    }

    func update(_ client: Client) throws {
        client.updatedAt = .now
        try repo.update(client, row: client.asRow)
    }

    func delete(_ client: Client) throws {
        client.deletedAt = .now
        try repo.softDelete(client, row: client.asRow)
    }
}
