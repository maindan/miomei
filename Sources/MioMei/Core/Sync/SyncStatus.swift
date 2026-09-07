import Foundation
import Observation

/// Estado exibido pelo indicador de sincronização (mio-escopo.md §10.1, Guia de
/// Estilo §7 "Status de sincronização").
enum SyncStatus: Equatable {
    case synced
    case pending(count: Int)
    case syncing
    case offline
    case error(String)
}

@Observable
final class SyncStatusStore {
    var status: SyncStatus = .offline
    var lastSuccessfulSyncAt: Date?
}
