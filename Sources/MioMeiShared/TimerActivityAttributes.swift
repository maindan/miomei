import ActivityKit
import Foundation

/// Compartilhado entre o app e a extensão de widget (Live Activity do
/// cronômetro — mio-escopo.md §7.3). `startedAt` ancora o tempo por timestamp,
/// não por contador em memória, para continuar confiável com o app suspenso.
struct TimerActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var startedAt: Date
        var isPaused: Bool
    }

    var demandId: UUID
    var demandTitle: String
    var contractTitle: String?
}
