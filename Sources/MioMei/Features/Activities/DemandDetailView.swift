import SwiftData
import SwiftUI

struct DemandDetailView: View {
    let demand: Demand

    @Environment(\.modelContext) private var modelContext
    @Environment(AuthManager.self) private var authManager
    @Environment(TimerStatusStore.self) private var timerStatusStore

    @State private var tasks: [TaskItem] = []
    @State private var sessions: [TimeEntry] = []
    @State private var activeEntry: TimeEntry?
    @State private var newTaskTitle = ""

    private var isTimerActiveHere: Bool { activeEntry?.demandId == demand.id }

    var body: some View {
        ZStack(alignment: .bottom) {
            ModuleGradient.atividades.background

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(demand.title).font(MioMeiFont.screenTitle).foregroundStyle(OnGradientText.primary)
                        if let description = demand.demandDescription {
                            Text(description).font(MioMeiFont.metadata).foregroundStyle(OnGradientText.secondary)
                        }
                    }
                    .padding(.top, 8)

                    Text("Tarefas").sectionLabelStyle().foregroundStyle(OnGradientText.label)
                    GlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(tasks) { task in
                                Button {
                                    try? demandRepository()?.toggleTask(task)
                                    reload()
                                } label: {
                                    HStack {
                                        Image(systemName: task.done ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(task.done ? Semantic.received : OnGradientText.secondary)
                                        Text(task.title)
                                            .strikethrough(task.done)
                                            .foregroundStyle(task.done ? OnGradientText.secondary : OnGradientText.primary)
                                        Spacer()
                                    }
                                }
                                .buttonStyle(.plain)
                            }

                            HStack {
                                TextField("Nova tarefa", text: $newTaskTitle)
                                    .foregroundStyle(OnGradientText.primary)
                                Button("Adicionar") {
                                    guard !newTaskTitle.isEmpty else { return }
                                    try? demandRepository()?.addTask(demandId: demand.id, title: newTaskTitle, position: tasks.count)
                                    newTaskTitle = ""
                                    reload()
                                }
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(OnGradientText.primary)
                            }
                        }
                    }

                    Text("Sessões").sectionLabelStyle().foregroundStyle(OnGradientText.label)
                    if sessions.isEmpty {
                        GlassCard {
                            Text("Nenhuma sessão registrada ainda.").font(MioMeiFont.metadata).foregroundStyle(OnGradientText.secondary)
                        }
                    } else {
                        ForEach(sessions) { session in
                            GlassListRow(
                                title: (session.durationSeconds ?? 0).hoursAndMinutes,
                                metadata: session.startedAt.mediumBR
                            ) {
                                Image(systemName: session.isManual ? "pencil" : "timer")
                                    .foregroundStyle(OnGradientText.primary).frame(width: 40)
                            } trailing: { EmptyView() }
                        }
                    }
                }
                .padding(20)
                .padding(.bottom, 100)
            }

            timerBar
        }
        .onAppear(perform: reload)
    }

    private var timerBar: some View {
        Button {
            toggleTimer()
        } label: {
            HStack {
                Image(systemName: isTimerActiveHere ? "stop.fill" : "play.fill")
                Text(isTimerActiveHere ? "Parar cronômetro" : "Iniciar cronômetro")
                    .font(.system(size: 15, weight: .bold))
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
        }
        .background(Color.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
    }

    private func toggleTimer() {
        guard let repository = timeEntryRepository() else { return }
        if isTimerActiveHere {
            if let activeEntry { try? repository.stop(activeEntry) }
            TimerActivityManager.shared.end()
        } else {
            try? repository.start(demandId: demand.id)
            TimerActivityManager.shared.start(
                demandId: demand.id, demandTitle: demand.title, contractTitle: nil, startedAt: .now
            )
        }
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

    private func reload() {
        tasks = (try? demandRepository()?.tasks(for: demand.id)) ?? []
        sessions = (try? timeEntryRepository()?.entries(for: demand.id)) ?? []
        activeEntry = try? timeEntryRepository()?.activeEntry()
        timerStatusStore.isRunning = activeEntry != nil
    }
}
