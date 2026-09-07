import Foundation
import SwiftData

/// Modelos locais identificáveis por UUID gerado no cliente — requisito para
/// entrar na fila de sincronização (`LocalRepository`).
protocol LocalEntity: PersistentModel {
    var id: UUID { get }
}

extension Client: LocalEntity {}
extension Budget: LocalEntity {}
extension Contract: LocalEntity {}
extension ContractRenewal: LocalEntity {}
extension Receivable: LocalEntity {}
extension Payable: LocalEntity {}
extension Invoice: LocalEntity {}
extension Demand: LocalEntity {}
extension TaskItem: LocalEntity {}
extension TimeEntry: LocalEntity {}
extension Reminder: LocalEntity {}
extension NotificationItem: LocalEntity {}
