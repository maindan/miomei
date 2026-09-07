import SwiftData
import SwiftUI

@main
struct MioMeiApp: App {
    private let container: ModelContainer
    private let syncEngine: SyncEngine

    @State private var authManager: AuthManager
    @State private var connectivity = ConnectivityMonitor()
    @State private var syncStatusStore = SyncStatusStore()

    init() {
        let container = MioMeiSchema.makeContainer()
        self.container = container

        let context = container.mainContext
        let queueStore = SyncQueueStore(modelContext: context)
        let connectivity = ConnectivityMonitor()
        let statusStore = SyncStatusStore()
        let engine = SyncEngine(
            queueStore: queueStore,
            statusStore: statusStore,
            connectivity: connectivity,
            supabase: SupabaseService.shared
        )

        _authManager = State(initialValue: AuthManager(modelContext: context))
        _connectivity = State(initialValue: connectivity)
        _syncStatusStore = State(initialValue: statusStore)
        self.syncEngine = engine

        BackgroundSyncScheduler.register(syncEngine: { engine })
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(authManager)
                .environment(connectivity)
                .environment(syncStatusStore)
                .modelContainer(container)
                .preferredColorScheme(.dark)
                .onOpenURL { url in
                    Task { try? await SupabaseService.shared.client.auth.session(from: url) }
                }
                .task {
                    authManager.start()
                    connectivity.start()
                    await syncEngine.syncNow()
                    BackgroundSyncScheduler.scheduleNext()
                }
        }
    }
}
