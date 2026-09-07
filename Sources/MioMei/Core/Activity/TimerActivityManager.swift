import ActivityKit
import Foundation

/// Inicia/atualiza/encerra a Live Activity do cronômetro na Dynamic Island e
/// tela de bloqueio (mio-escopo.md §7.3, §13). Best-effort: falha silenciosa
/// se Live Activities estiverem desabilitadas nas Configurações do sistema.
@MainActor
final class TimerActivityManager {
    static let shared = TimerActivityManager()

    private var currentActivity: Activity<TimerActivityAttributes>?

    func start(demandId: UUID, demandTitle: String, contractTitle: String?, startedAt: Date) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        end()

        let attributes = TimerActivityAttributes(demandId: demandId, demandTitle: demandTitle, contractTitle: contractTitle)
        let state = TimerActivityAttributes.ContentState(startedAt: startedAt, isPaused: false)

        currentActivity = try? Activity.request(
            attributes: attributes,
            content: .init(state: state, staleDate: nil)
        )
    }

    func end() {
        guard let activity = currentActivity else { return }
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        currentActivity = nil
    }
}
