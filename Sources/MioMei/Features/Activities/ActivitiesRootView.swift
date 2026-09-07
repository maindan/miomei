import SwiftData
import SwiftUI

struct ActivitiesRootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthManager.self) private var authManager
    @Environment(TimerStatusStore.self) private var timerStatusStore

    @State private var demands: [Demand] = []
    @State private var contracts: [Contract] = []
    @State private var progressByDemand: [UUID: Double] = [:]
    @State private var activeEntry: TimeEntry?
    @State private var showCreate = false
    @State private var showSession = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ModuleGradient.atividades.background

                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        topBar

                        if let activeEntry, let activeDemand = demands.first(where: { $0.id == activeEntry.demandId }) {
                            ActiveTimerCard(
                                demandTitle: activeDemand.title,
                                startedAt: activeEntry.startedAt,
                                onOpenSession: { showSession = true },
                                onStop: { stopTimer(activeEntry) }
                            )
                        }

                        if demands.isEmpty {
                            GlassCard {
                                Text("Nenhuma demanda ainda. Toque em + para criar a primeira.")
                                    .font(MioMeiFont.metadata)
                                    .foregroundStyle(OnGradientText.secondary)
                            }
                        } else {
                            ForEach(demands) { demand in
                                NavigationLink(value: demand) {
                                    DemandCardRow(
                                        demand: demand,
                                        contractTitle: contracts.first { $0.id == demand.contractId }?.title,
                                        progress: progressByDemand[demand.id] ?? 0,
                                        isTimerActive: activeEntry?.demandId == demand.id,
                                        onPlay: { togglePlay(demand) }
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 100)
                }

                CreateFAB { showCreate = true }
                    .padding(.trailing, 20)
                    .padding(.bottom, 24)
            }
            .navigationDestination(for: Demand.self) { DemandDetailView(demand: $0) }
        }
        .sheet(isPresented: $showCreate) {
            DemandFormSheet(contracts: contracts) { contractId, title, description, priority, deadline in
                try? demandRepository()?.create(
                    contractId: contractId, title: title, description: description, priority: priority, deadline: deadline
                )
                reload()
            }
        }
        .sheet(isPresented: $showSession) {
            if let activeEntry, let activeDemand = demands.first(where: { $0.id == activeEntry.demandId }) {
                TimerSessionView(demandTitle: activeDemand.title, startedAt: activeEntry.startedAt) {
                    stopTimer(activeEntry)
                }
            }
        }
        .onAppear(perform: reload)
    }

    private var topBar: some View {
        HStack {
            Text("Atividades").font(MioMeiFont.screenTitle).foregroundStyle(OnGradientText.primary)
            Spacer()
            NavigationLink {
                HoursView()
            } label: {
                Image(systemName: "chart.bar")
                    .foregroundStyle(OnGradientText.primary)
                    .frame(width: 40, height: 40)
                    .glassSurface(.light, cornerRadius: 20)
            }
        }
        .padding(.top, 8)
    }

    private func togglePlay(_ demand: Demand) {
        guard let repository = timeEntryRepository() else { return }
        if activeEntry?.demandId == demand.id, let activeEntry {
            stopTimer(activeEntry)
        } else {
            try? repository.start(demandId: demand.id)
            TimerActivityManager.shared.start(
                demandId: demand.id, demandTitle: demand.title,
                contractTitle: contracts.first { $0.id == demand.contractId }?.title, startedAt: .now
            )
            reload()
        }
    }

    private func stopTimer(_ entry: TimeEntry) {
        try? timeEntryRepository()?.stop(entry)
        TimerActivityManager.shared.end()
        reload()
    }

    private func demandRepository() -> DemandRepository? {
        guard let userId = authManager.currentUserId else { return nil }
        return DemandRepository(modelContext: modelContext, queueStore: SyncQueueStore(modelContext: modelContext), userId: userId)
    }

    private func timeEntryRepository() -> TimeEntryRepository? {
        guard let userId = authManager.currentUserId else { return nil }
        return TimeEntryRepository(modelContext: modelContext, queueStore: SyncQueueStore(modelContext: modelContext), userId: userId)
    }

    private func contractRepository() -> ContractRepository? {
        guard let userId = authManager.currentUserId else { return nil }
        return ContractRepository(modelContext: modelContext, queueStore: SyncQueueStore(modelContext: modelContext), userId: userId)
    }

    private func reload() {
        guard let demandRepo = demandRepository() else { return }
        demands = (try? demandRepo.all()) ?? []
        contracts = (try? contractRepository()?.all()) ?? []
        activeEntry = try? timeEntryRepository()?.activeEntry()
        timerStatusStore.isRunning = activeEntry != nil

        var progress: [UUID: Double] = [:]
        for demand in demands {
            progress[demand.id] = (try? demandRepo.progress(for: demand.id)) ?? 0
        }
        progressByDemand = progress
    }
}
