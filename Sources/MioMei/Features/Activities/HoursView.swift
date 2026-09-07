import Charts
import SwiftData
import SwiftUI

/// Controle de horas — diária/semanal/mensal + cruzamento com exigência de
/// contrato (mio-escopo.md §7.3, §7.4).
struct HoursView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthManager.self) private var authManager

    @State private var weekStart: Date = Calendar.mondayStart(of: .now)
    @State private var entries: [TimeEntry] = []
    @State private var demands: [Demand] = []
    @State private var contracts: [Contract] = []
    @State private var reportURL: URL?

    private var weekEnd: Date { Calendar.current.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart }
    private var monthStart: Date { Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: .now)) ?? .now }
    private var monthEnd: Date { Calendar.current.date(byAdding: .month, value: 1, to: monthStart) ?? .now }

    var body: some View {
        ZStack {
            ModuleGradient.atividades.background

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Horas").font(MioMeiFont.screenTitle).foregroundStyle(OnGradientText.primary)
                        Spacer()
                        exportButton
                    }
                    .padding(.top, 8)

                    weekSelector

                    GlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Total da semana").font(MioMeiFont.metadata).foregroundStyle(OnGradientText.secondary)
                            Text(weeklyTotalSeconds.hoursAndMinutes)
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundStyle(OnGradientText.primary)
                                .numericTabular()

                            Chart(dailyTotals, id: \.day) { item in
                                BarMark(x: .value("Dia", item.day, unit: .day), y: .value("Horas", item.hours))
                                    .foregroundStyle(.white.opacity(item.isToday ? 1 : 0.28))
                                    .cornerRadius(6)
                            }
                            .frame(height: 120)
                            .chartXAxis {
                                AxisMarks(values: .stride(by: .day)) { _ in
                                    AxisValueLabel(format: .dateTime.weekday(.narrow))
                                        .foregroundStyle(OnGradientText.secondary)
                                }
                            }
                            .chartYAxis(.hidden)
                        }
                    }

                    if !contractProgress.isEmpty {
                        Text("Progresso semanal por contrato").sectionLabelStyle().foregroundStyle(OnGradientText.label)
                        ForEach(contractProgress, id: \.contract.id) { item in
                            GlassCard {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text(item.contract.title).font(MioMeiFont.listItem).foregroundStyle(OnGradientText.primary)
                                        Spacer()
                                        Text("\(item.registeredHours.formatted())h / \(item.requiredHours.formatted())h")
                                            .font(MioMeiFont.metadata)
                                            .foregroundStyle(OnGradientText.secondary)
                                            .numericTabular()
                                    }
                                    ProgressView(value: min(item.ratio, 1))
                                        .tint(item.color)
                                        .frame(height: 6)
                                }
                            }
                        }
                    }

                    Text("Consolidado do mês por contrato").sectionLabelStyle().foregroundStyle(OnGradientText.label)
                    if monthlyByContract.isEmpty {
                        GlassCard {
                            Text("Sem horas registradas este mês.").font(MioMeiFont.metadata).foregroundStyle(OnGradientText.secondary)
                        }
                    } else {
                        ForEach(monthlyByContract, id: \.title) { item in
                            GlassListRow(title: item.title, metadata: nil) {
                                Image(systemName: "briefcase").foregroundStyle(OnGradientText.primary).frame(width: 40)
                            } trailing: {
                                Text(item.seconds.hoursAndMinutes).font(MioMeiFont.metadata).foregroundStyle(OnGradientText.primary)
                            }
                        }
                    }
                }
                .padding(20)
                .padding(.bottom, 60)
            }
        }
        .onAppear(perform: reload)
    }

    @ViewBuilder
    private var exportButton: some View {
        if let reportURL {
            ShareLink(item: reportURL) {
                Image(systemName: "square.and.arrow.up")
                    .foregroundStyle(OnGradientText.primary)
                    .frame(width: 34, height: 34)
                    .glassSurface(.light, cornerRadius: 17)
            }
        } else {
            Button {
                let csv = HoursReportGenerator.csv(entries: entries, demands: demands, contracts: contracts)
                reportURL = HoursReportGenerator.writeTemporaryFile(data: csv, suggestedName: "horas-\(weekStart.shortBR)")
            } label: {
                Image(systemName: "doc.text")
                    .foregroundStyle(OnGradientText.primary)
                    .frame(width: 34, height: 34)
                    .glassSurface(.light, cornerRadius: 17)
            }
        }
    }

    private var weekSelector: some View {
        HStack {
            Button { shiftWeek(by: -1) } label: { chevron("chevron.left") }
            Spacer()
            Text("\(weekStart.shortBR) – \(Calendar.current.date(byAdding: .day, value: 6, to: weekStart)!.shortBR)")
                .font(MioMeiFont.metadata)
                .foregroundStyle(OnGradientText.primary)
            Spacer()
            Button { shiftWeek(by: 1) } label: { chevron("chevron.right") }
        }
        .padding(.horizontal, 4)
    }

    private func chevron(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .foregroundStyle(OnGradientText.primary)
            .frame(width: 34, height: 34)
            .glassSurface(.light, cornerRadius: 17)
    }

    private func shiftWeek(by weeks: Int) {
        weekStart = Calendar.current.date(byAdding: .day, value: weeks * 7, to: weekStart) ?? weekStart
        reportURL = nil
        reload()
    }

    private var weeklyTotalSeconds: Int { entries.totalDurationSeconds }

    private var dailyTotals: [(day: Date, hours: Double, isToday: Bool)] {
        let calendar = Calendar.current
        return (0..<7).map { offset in
            let day = calendar.date(byAdding: .day, value: offset, to: weekStart) ?? weekStart
            let dayEntries = entries.filter { calendar.isDate($0.startedAt, inSameDayAs: day) }
            return (day, Double(dayEntries.totalDurationSeconds) / 3600, calendar.isDateInToday(day))
        }
    }

    private struct ContractProgress {
        let contract: Contract
        let registeredHours: Decimal
        let requiredHours: Decimal
        var ratio: Double {
            guard requiredHours > 0 else { return 0 }
            return Double(truncating: NSDecimalNumber(decimal: registeredHours / requiredHours))
        }
        var color: Color {
            switch ratio {
            case 0.9...: return Semantic.received
            case 0.5..<0.9: return Semantic.attention
            default: return Semantic.overdue
            }
        }
    }

    private var contractProgress: [ContractProgress] {
        contracts.compactMap { contract in
            guard let required = contract.weeklyHoursRequirement, required > 0 else { return nil }
            let contractDemandIds = Set(demands.filter { $0.contractId == contract.id }.map(\.id))
            let seconds = entries.filter { contractDemandIds.contains($0.demandId) }.totalDurationSeconds
            let hours = Decimal(seconds) / 3600
            return ContractProgress(contract: contract, registeredHours: hours, requiredHours: required)
        }
    }

    private var monthlyByContract: [(title: String, seconds: Int)] {
        let monthEntries = (try? timeEntryRepository()?.allEntries(from: monthStart, to: monthEnd)) ?? []
        let demandToContract = Dictionary(uniqueKeysWithValues: demands.map { ($0.id, $0.contractId) })
        var totals: [UUID?: Int] = [:]
        for entry in monthEntries {
            let contractId = demandToContract[entry.demandId] ?? nil
            totals[contractId, default: 0] += entry.durationSeconds ?? Int(Date.now.timeIntervalSince(entry.startedAt))
        }
        return totals.map { key, seconds in
            (title: contracts.first { $0.id == key }?.title ?? "Sem contrato", seconds: seconds)
        }.sorted { $0.seconds > $1.seconds }
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
        demands = (try? demandRepository()?.all()) ?? []
        contracts = (try? contractRepository()?.all()) ?? []
        entries = (try? timeEntryRepository()?.allEntries(from: weekStart, to: weekEnd)) ?? []
    }
}

extension Calendar {
    static func mondayStart(of date: Date) -> Date {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: components) ?? date
    }
}
