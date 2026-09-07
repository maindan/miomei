import Foundation

/// Orquestra push (fila local → Supabase) e pull (Supabase → SwiftData). Um
/// item só sai da fila após confirmação de gravação (mio-escopo.md §12, §10.1).
///
/// Fase 1 deixa a arquitetura pronta; a implementação por entidade chega junto
/// dos repositórios de cada módulo (push real em Fase 2, pull real quando os
/// endpoints do Supabase forem consumidos por tela).
@MainActor
final class SyncEngine {
    private let queueStore: SyncQueueStore
    private let statusStore: SyncStatusStore
    private let connectivity: ConnectivityMonitor
    private let supabase: SupabaseService

    init(
        queueStore: SyncQueueStore,
        statusStore: SyncStatusStore,
        connectivity: ConnectivityMonitor,
        supabase: SupabaseService
    ) {
        self.queueStore = queueStore
        self.statusStore = statusStore
        self.connectivity = connectivity
        self.supabase = supabase
    }

    /// Ciclo completo (push + pull) disparado pelo botão "Sincronizar agora"
    /// ou pelo agendamento em segundo plano.
    func syncNow() async {
        guard connectivity.isConnected else {
            statusStore.status = .offline
            return
        }
        statusStore.status = .syncing
        do {
            try await pushPending()
            try await pullChanges()
            statusStore.status = .synced
            statusStore.lastSuccessfulSyncAt = .now
        } catch {
            statusStore.status = .error(error.localizedDescription)
        }
    }

    /// Envia a fila de `PendingMutation` ao Supabase (upsert por `id`,
    /// respeitando `updated_at`). TODO Fase 2: implementar por tabela.
    private func pushPending() async throws {
        let pending = try queueStore.allPending()
        guard !pending.isEmpty else { return }
        statusStore.status = .pending(count: pending.count)
        // TODO Fase 2+: para cada mutação, fazer upsert na tabela `entityName`
        // via supabase.client.from(entityName).upsert(...), e só então
        // queueStore.remove(mutation).
    }

    /// Busca registros com `updated_at > última_sync` e aplica `deleted_at`.
    /// TODO Fase 2: implementar por tabela conforme os repositórios existirem.
    private func pullChanges() async throws {}
}
