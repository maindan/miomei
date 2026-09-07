import Foundation
import Supabase

/// Sync multi-dispositivo (opcional, mio-escopo.md §12, §13): assina mudanças
/// nas tabelas principais via Supabase Realtime e dispara um `syncNow()`
/// quando outro dispositivo grava algo. Implementação simples — um canal só,
/// sem granularidade por tabela; um pull completo (barato, filtrado por
/// `updated_at`) já resolve a reconciliação.
///
/// A API do Realtime mudou entre versões do supabase-swift; se o
/// `xcodegen`/SPM resolver uma versão com assinatura diferente de
/// `postgresChange`/`AnyAction`, ajuste esta função — o resto do app não
/// depende dela (o polling do BGTaskScheduler e o "Sincronizar agora"
/// continuam funcionando sem Realtime).
@MainActor
final class RealtimeSyncMonitor {
    private let supabase: SupabaseService
    private let onRemoteChange: () -> Void
    private var listenTask: Task<Void, Never>?

    init(supabase: SupabaseService, onRemoteChange: @escaping () -> Void) {
        self.supabase = supabase
        self.onRemoteChange = onRemoteChange
    }

    func start() {
        stop()
        listenTask = Task { [weak self] in
            guard let self else { return }
            let channel = supabase.client.channel("miomei-changes")
            let changes = channel.postgresChange(AnyAction.self, schema: "public")
            await channel.subscribe()
            for await _ in changes {
                onRemoteChange()
            }
        }
    }

    func stop() {
        listenTask?.cancel()
        listenTask = nil
    }
}
