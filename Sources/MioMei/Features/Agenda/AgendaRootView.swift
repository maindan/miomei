import SwiftData
import SwiftUI

/// Agenda — projeção temporal de tudo que tem data no sistema (mio-escopo.md §8).
/// Padrão mobile: faixa semanal + lista de eventos do dia selecionado.
struct AgendaRootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthManager.self) private var authManager

    @State private var selectedDate = Date.now
    @State private var weekEvents: [CalendarEvent] = []
    @State private var activeFilters: Set<CalendarEventSource> = []
    @State private var showCreateReminder = false
    @State private var selectedEvent: CalendarEvent?

    private var weekStart: Date { Calendar.mondayStart(of: selectedDate) }

    private var dayEvents: [CalendarEvent] {
        let calendar = Calendar.current
        return weekEvents
            .filter { calendar.isDate($0.date, inSameDayAs: selectedDate) }
            .filter { activeFilters.isEmpty || activeFilters.contains($0.source) }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ModuleGradient.financeiro.background

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Agenda").font(MioMeiFont.screenTitle).foregroundStyle(OnGradientText.primary)
                        .padding(.top, 8)

                    weekStrip

                    filterChips

                    if dayEvents.isEmpty {
                        GlassCard {
                            Text("Nada por aqui neste dia.").font(MioMeiFont.metadata).foregroundStyle(OnGradientText.secondary)
                        }
                    } else {
                        ForEach(dayEvents) { event in
                            Button { selectedEvent = event } label: {
                                GlassListRow(title: event.title, metadata: event.source.label) {
                                    Capsule().fill(event.source.color).frame(width: 4, height: 34)
                                } trailing: {
                                    if let amount = event.amount {
                                        Text(amount.brl).font(MioMeiFont.metadata).foregroundStyle(OnGradientText.primary)
                                    } else {
                                        Image(systemName: event.source.systemImage).foregroundStyle(event.source.color)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(20)
                .padding(.bottom, 100)
            }

            CreateFAB { showCreateReminder = true }
                .padding(.trailing, 20)
                .padding(.bottom, 24)
        }
        .sheet(isPresented: $showCreateReminder) {
            ReminderFormSheet { title, date, recurrence, note in
                try? reminderRepository()?.create(title: title, date: date, recurrence: recurrence, note: note)
                reload()
            }
        }
        .sheet(item: $selectedEvent) { event in
            CalendarEventDetailSheet(event: event)
        }
        .onAppear(perform: reload)
        .onChange(of: weekStart) { reload() }
        .task { await LocalNotificationScheduler.requestAuthorizationIfNeeded() }
    }

    private var weekStrip: some View {
        HStack(spacing: 8) {
            ForEach(0..<7, id: \.self) { offset in
                let day = Calendar.current.date(byAdding: .day, value: offset, to: weekStart) ?? weekStart
                dayChip(day)
            }
        }
    }

    private func dayChip(_ day: Date) -> some View {
        let isSelected = Calendar.current.isDate(day, inSameDayAs: selectedDate)
        let hasEvents = weekEvents.contains { Calendar.current.isDate($0.date, inSameDayAs: day) }
        return Button { selectedDate = day } label: {
            VStack(spacing: 4) {
                Text(day.formatted(.dateTime.weekday(.narrow))).font(.system(size: 10, weight: .bold))
                Text(day.formatted(.dateTime.day())).font(.system(size: 13, weight: .bold)).numericTabular()
                Circle().fill(hasEvents ? Color.white.opacity(isSelected ? 0 : 0.6) : .clear).frame(width: 4, height: 4)
            }
            .foregroundStyle(isSelected ? .black : OnGradientText.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.white)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(CalendarEventSource.allCases, id: \.self) { source in
                    let isActive = activeFilters.contains(source)
                    Button {
                        if isActive { activeFilters.remove(source) } else { activeFilters.insert(source) }
                    } label: {
                        Text(source.label)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(isActive ? .black : OnGradientText.primary)
                            .padding(.horizontal, 12).padding(.vertical, 7)
                            .background(isActive ? Color.white : Color.white.opacity(0.12), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func reminderRepository() -> ReminderRepository? {
        guard let userId = authManager.currentUserId else { return nil }
        return ReminderRepository(modelContext: modelContext, queueStore: SyncQueueStore(modelContext: modelContext), userId: userId)
    }

    private func reload() {
        guard let userId = authManager.currentUserId else { return }
        let weekEnd = Calendar.current.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart
        let provider = CalendarEventProvider(modelContext: modelContext, userId: userId)
        weekEvents = (try? provider.events(from: weekStart, to: weekEnd)) ?? []
    }
}

private struct CalendarEventDetailSheet: View {
    let event: CalendarEvent
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Capsule().fill(Color.white.opacity(0.3)).frame(width: 44, height: 4).padding(.top, 10)

            HStack {
                Image(systemName: event.source.systemImage).foregroundStyle(event.source.color)
                Text(event.source.label).font(.system(size: 12, weight: .bold)).foregroundStyle(OnGradientText.secondary)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(event.title).font(.system(.title3, weight: .bold)).foregroundStyle(OnGradientText.primary)
                Text(event.date.mediumBR).font(MioMeiFont.metadata).foregroundStyle(OnGradientText.secondary)
                if let amount = event.amount {
                    Text(amount.brl).font(.system(size: 20, weight: .semibold)).foregroundStyle(OnGradientText.primary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()
        }
        .padding(20)
        .presentationDetents([.medium])
        .background(GlassLayer.sheet.tint)
        .background(GlassLayer.sheet.material)
    }
}
