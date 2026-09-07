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
    private static let lastSyncDefaultsKey = "com.projexsystem.miomei.lastSuccessfulSyncAt"

    var status: SyncStatus = .offline

    /// Persistido em `UserDefaults` — sem isso, todo relançamento do app
    /// esqueceria a última sincronização e faria um pull completo (ainda
    /// correto, só menos eficiente).
    var lastSuccessfulSyncAt: Date? {
        didSet {
            UserDefaults.standard.set(lastSuccessfulSyncAt, forKey: Self.lastSyncDefaultsKey)
        }
    }

    init() {
        lastSuccessfulSyncAt = UserDefaults.standard.object(forKey: Self.lastSyncDefaultsKey) as? Date
    }
}
