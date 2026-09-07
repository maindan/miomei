import Foundation
import SwiftData

@MainActor
final class ContractRepository {
    private let repo: LocalRepository<Contract>
    private let renewalRepo: LocalRepository<ContractRenewal>
    private let userId: UUID

    init(modelContext: ModelContext, queueStore: SyncQueueStore, userId: UUID) {
        self.repo = LocalRepository(modelContext: modelContext, queueStore: queueStore, entityName: "contract")
        self.renewalRepo = LocalRepository(modelContext: modelContext, queueStore: queueStore, entityName: "contract_renewal")
        self.userId = userId
    }

    func all() throws -> [Contract] {
        try repo.fetch(FetchDescriptor(
            predicate: #Predicate { $0.userId == userId && $0.deletedAt == nil },
            sortBy: [.init(\.createdAt, order: .reverse)]
        ))
    }

    func renewals(for contractId: UUID) throws -> [ContractRenewal] {
        try renewalRepo.fetch(FetchDescriptor(
            predicate: #Predicate { $0.contractId == contractId && $0.deletedAt == nil },
            sortBy: [.init(\.newEndDate, order: .reverse)]
        ))
    }

    @discardableResult
    func create(
        type: ContractType,
        clientId: UUID?,
        title: String,
        description: String?,
        startDate: Date?,
        endDate: Date?,
        estimatedValue: Decimal?,
        weeklyHoursRequirement: Decimal?,
        recurrence: String?,
        paymentMethod: String?
    ) throws -> Contract {
        let contract = Contract(
            userId: userId, clientId: clientId, type: type, title: title,
            contractDescription: description, startDate: startDate, endDate: endDate,
            estimatedValue: estimatedValue, weeklyHoursRequirement: weeklyHoursRequirement,
            recurrence: recurrence, paymentMethod: paymentMethod
        )
        try repo.create(contract, row: contract.asRow)
        return contract
    }

    @discardableResult
    func create(_ input: Contract.CreateInput) throws -> Contract {
        try create(
            type: input.type, clientId: input.clientId, title: input.title,
            description: input.description, startDate: input.startDate, endDate: input.endDate,
            estimatedValue: input.estimatedValue, weeklyHoursRequirement: input.weeklyHoursRequirement,
            recurrence: input.recurrence, paymentMethod: input.paymentMethod
        )
    }

    func update(_ contract: Contract) throws {
        contract.updatedAt = .now
        try repo.update(contract, row: contract.asRow)
    }

    func close(_ contract: Contract) throws {
        contract.status = .closed
        try update(contract)
    }

    /// Estende o prazo do contrato e registra o histórico de renovação
    /// (mio-escopo.md §6.3): o prazo vigente passa a ser o da última renovação.
    @discardableResult
    func renew(_ contract: Contract, newEndDate: Date, addedValue: Decimal?, note: String?) throws -> ContractRenewal {
        let renewal = ContractRenewal(
            userId: userId, contractId: contract.id, newEndDate: newEndDate,
            addedValue: addedValue, note: note
        )
        try renewalRepo.create(renewal, row: renewal.asRow)

        contract.endDate = newEndDate
        if let addedValue {
            contract.estimatedValue = (contract.estimatedValue ?? 0) + addedValue
        }
        try update(contract)
        return renewal
    }
}
