import SwiftData

/// Fonte única da lista de `@Model` persistidos localmente — usada pelo
/// `ModelContainer` do app e pelos previews/testes.
enum MioMeiSchema {
    static let models: [any PersistentModel.Type] = [
        Profile.self,
        Client.self,
        Budget.self,
        Contract.self,
        ContractRenewal.self,
        Receivable.self,
        Payable.self,
        Invoice.self,
        Demand.self,
        TaskItem.self,
        TimeEntry.self,
        Reminder.self,
        NotificationItem.self,
        PendingMutation.self,
    ]

    static func makeContainer(inMemory: Bool = false) -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        do {
            return try ModelContainer(for: Schema(models), configurations: [configuration])
        } catch {
            fatalError("Não foi possível criar o ModelContainer do MioMei: \(error)")
        }
    }
}
