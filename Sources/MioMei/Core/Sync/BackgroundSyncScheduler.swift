import BackgroundTasks
import Foundation

/// Sync periódico via BGTaskScheduler (mio-escopo.md §12, §13). Registrar em
/// `application(_:didFinishLaunchingWithOptions:)` ou no `.backgroundTask`
/// modifier da `App`, antes do app terminar de lançar.
enum BackgroundSyncScheduler {
    static let taskIdentifier = "com.projexsystem.miomei.sync"

    static func register(syncEngine: @escaping () -> SyncEngine) {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier, using: nil) { task in
            guard let processingTask = task as? BGProcessingTask else {
                task.setTaskCompleted(success: false)
                return
            }
            handle(processingTask, syncEngine: syncEngine())
        }
    }

    static func scheduleNext() {
        let request = BGProcessingTaskRequest(identifier: taskIdentifier)
        request.requiresNetworkConnectivity = true
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }

    private static func handle(_ task: BGProcessingTask, syncEngine: SyncEngine) {
        scheduleNext()
        let work = Task {
            await syncEngine.syncNow()
            task.setTaskCompleted(success: true)
        }
        task.expirationHandler = {
            work.cancel()
        }
    }
}
