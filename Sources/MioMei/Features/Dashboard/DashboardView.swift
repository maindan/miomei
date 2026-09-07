import SwiftData
import SwiftUI

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthManager.self) private var authManager

    @State private var profile: Profile?
    @State private var clients: [Client] = []
    @State private var contracts: [Contract] = []
    @State private var receivables: [Receivable] = []
    @State private var payables: [Payable] = []
    @State private var demands: [Demand] = []
    @State private var weekEntries: [TimeEntry] = []
    @State private var activeEntry: TimeEntry?
    @State private var upcomingEvents: [CalendarEvent] = []
    @State private var alerts: [NotificationItem] = []
    @State private var unreadCount = 0

    @State private var showSettings = false
    @State private var showNotifications = false
    @State private var showCreateBudget = false
    @State private var showCreateContract = false
    @State private var showCreateDemand = false
    @State private var showCreateReceivable = false
    @State private var showCreatePayable = false

    private var monthReceivables: [Receivable] {
        let calendar = Calendar.current
        return receivables.filter { calendar.isDate($0.dueDate, equalTo: .now, toGranularity: .month) }
    }

    private var monthPayables: [Payable] {
        let calendar = Calendar.current
        return payables.filter { calendar.isDate($0.dueDate, equalTo: .now, toGranularity: .month) }
    }

    private var toReceive: Decimal { monthReceivables.filter { $0.status != .received }.reduce(0) { $0 + $1.amount } }
    private var received: Decimal { monthReceivables.filter { $0.status == .received }.reduce(0) { $0 + $1.amount } }
    private var toPay: Decimal { monthPayables.filter { $0.status != .paid }.reduce(0) { $0 + $1.amount } }
    private var projectedBalance: Decimal { received + toReceive - toPay }

    private var activeContracts: [Contract] { contracts.filter { $0.status == .active } }
    private var contractsEndingSoon: [Contract] {
        let in30Days = Calendar.current.date(byAdding: .day, value: 30, to: .now) ?? .now
        return activeContracts.filter { ($0.endDate ?? .distantFuture) <= in30Days }
    }

    private var weeklySeconds: Int { weekEntries.totalDurationSeconds }
    private var demandsInProgress: [Demand] { demands.filter { $0.status == .inProgress } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                topBar

                GlassCard {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Bom dia".uppercased()).sectionLabelStyle().foregroundStyle(OnGradientText.label)
                        Text(profile?.tradeName ?? profile?.companyName ?? "Como está sua operação hoje?")
                            .font(MioMeiFont.dayBriefing)
                            .foregroundStyle(OnGradientText.primary)
                    }
                }

                Text("Financeiro do mês").sectionLabelStyle().foregroundStyle(OnGradientText.label)
                GlassCard {
                    VStack(spacing: 10) {
                        HStack {
                            statBlock("A receber", toReceive.brl)
                            statBlock("Recebido", received.brl)
                        }
                        HStack {
                            statBlock("A pagar", toPay.brl)
                            statBlock("Saldo projetado", projectedBalance.brl)
                        }
                    }
                }

                Text("Saúde dos contratos").sectionLabelStyle().foregroundStyle(OnGradientText.label)
                GlassCard {
                    HStack {
                        statBlock("Ativos", "\(activeContracts.count)")
                        statBlock("Vencendo ≤30d", "\(contractsEndingSoon.count)")
                    }
                }

                Text("Produtividade da semana").sectionLabelStyle().foregroundStyle(OnGradientText.label)
                GlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            statBlock("Horas na semana", weeklySeconds.hoursAndMinutes)
                            statBlock("Demandas em andamento", "\(demandsInProgress.count)")
                        }
                        if activeEntry != nil {
                            HStack {
                                Image(systemName: "timer").foregroundStyle(Semantic.received)
                                Text("Cronômetro em curso").font(MioMeiFont.metadata).foregroundStyle(OnGradientText.secondary)
                            }
                        }
                    }
                }

                if !alerts.isEmpty {
                    Text("Alertas").sectionLabelStyle().foregroundStyle(OnGradientText.label)
                    ForEach(alerts.prefix(3)) { alert in
                        GlassListRow(title: alert.title, metadata: alert.body) {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(Semantic.overdue).frame(width: 40)
                        } trailing: { EmptyView() }
                    }
                }

                Text("Próximas obrigações (7 dias)").sectionLabelStyle().foregroundStyle(OnGradientText.label)
                if upcomingEvents.isEmpty {
                    GlassCard {
                        Text("Nada previsto para os próximos 7 dias.").font(MioMeiFont.metadata).foregroundStyle(OnGradientText.secondary)
                    }
                } else {
                    ForEach(upcomingEvents.prefix(5)) { event in
                        GlassListRow(title: event.title, metadata: event.date.mediumBR) {
                            Image(systemName: event.source.systemImage).foregroundStyle(event.source.color).frame(width: 40)
                        } trailing: {
                            if let amount = event.amount {
                                Text(amount.brl).font(MioMeiFont.metadata).foregroundStyle(OnGradientText.primary)
                            } else {
                                EmptyView()
                            }
                        }
                    }
                }

                Text("Atalhos rápidos").sectionLabelStyle().foregroundStyle(OnGradientText.label)
                quickActions
            }
            .padding(20)
            .padding(.bottom, 100)
        }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showNotifications) { NotificationCenterView() }
        .sheet(isPresented: $showCreateBudget) {
            BudgetFormSheet(clients: clients) { clientId, title, items, validUntil, terms in
                try? budgetRepository()?.create(clientId: clientId, title: title, items: items, validUntil: validUntil, paymentTerms: terms)
                reload()
            }
        }
        .sheet(isPresented: $showCreateContract) {
            ContractFormSheet(clients: clients) { input in
                try? contractRepository()?.create(input)
                reload()
            }
        }
        .sheet(isPresented: $showCreateDemand) {
            DemandFormSheet(contracts: contracts) { contractId, title, description, priority, deadline in
                try? demandRepository()?.create(contractId: contractId, title: title, description: description, priority: priority, deadline: deadline)
                reload()
            }
        }
        .sheet(isPresented: $showCreateReceivable) {
            ReceivableFormSheet(contracts: contracts, clients: clients) { input in
                try? receivableRepository()?.create(input)
                reload()
            }
        }
        .sheet(isPresented: $showCreatePayable) {
            PayableFormSheet { type, description, amount, dueDate in
                try? payableRepository()?.create(type: type, description: description, amount: amount, dueDate: dueDate)
                reload()
            }
        }
        .onAppear(perform: reload)
        .task { await LocalNotificationScheduler.requestAuthorizationIfNeeded() }
    }

    private var topBar: some View {
        HStack {
            Text("Início").font(MioMeiFont.screenTitle).foregroundStyle(OnGradientText.primary)
            Spacer()
            HStack(spacing: 10) {
                topBarIcon("bell", badge: unreadCount) { showNotifications = true }
                topBarIcon("gearshape", badge: 0) { showSettings = true }
            }
        }
        .padding(.top, 8)
    }

    private func topBarIcon(_ systemName: String, badge: Int, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: systemName)
                    .foregroundStyle(OnGradientText.primary)
                    .frame(width: 40, height: 40)
                    .glassSurface(.light, cornerRadius: 20)
                if badge > 0 {
                    Circle().fill(Semantic.overdue).frame(width: 9, height: 9)
                        .offset(x: -2, y: 2)
                }
            }
        }
    }

    private func statBlock(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(MioMeiFont.metadata).foregroundStyle(OnGradientText.secondary)
            Text(value).font(.system(size: 17, weight: .semibold)).foregroundStyle(OnGradientText.primary).numericTabular()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var quickActions: some View {
        VStack(spacing: 8) {
            quickActionRow("Novo orçamento", "doc.text") { showCreateBudget = true }
            quickActionRow("Novo contrato", "briefcase") { showCreateContract = true }
            quickActionRow("Nova demanda", "checklist") { showCreateDemand = true }
            quickActionRow("Registrar recebimento", "arrow.down.circle") { showCreateReceivable = true }
            quickActionRow("Registrar pagamento de imposto", "arrow.up.circle") { showCreatePayable = true }
        }
    }

    private func quickActionRow(_ title: String, _ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon).foregroundStyle(OnGradientText.primary).frame(width: 24)
                Text(title).font(MioMeiFont.metadata).foregroundStyle(OnGradientText.primary)
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(OnGradientText.secondary)
            }
            .padding(14)
            .glassSurface(.light, cornerRadius: Radius.listRow)
        }
        .buttonStyle(.plain)
    }

    private func contractRepository() -> ContractRepository? {
        guard let userId = authManager.currentUserId else { return nil }
        return ContractRepository(modelContext: modelContext, queueStore: SyncQueueStore(modelContext: modelContext), userId: userId)
    }

    private func demandRepository() -> DemandRepository? {
        guard let userId = authManager.currentUserId else { return nil }
        return DemandRepository(modelContext: modelContext, queueStore: SyncQueueStore(modelContext: modelContext), userId: userId)
    }

    private func receivableRepository() -> ReceivableRepository? {
        guard let userId = authManager.currentUserId else { return nil }
        return ReceivableRepository(modelContext: modelContext, queueStore: SyncQueueStore(modelContext: modelContext), userId: userId)
    }

    private func payableRepository() -> PayableRepository? {
        guard let userId = authManager.currentUserId else { return nil }
        return PayableRepository(modelContext: modelContext, queueStore: SyncQueueStore(modelContext: modelContext), userId: userId)
    }

    private func budgetRepository() -> BudgetRepository? {
        guard let userId = authManager.currentUserId else { return nil }
        return BudgetRepository(modelContext: modelContext, queueStore: SyncQueueStore(modelContext: modelContext), userId: userId)
    }

    private func clientRepository() -> ClientRepository? {
        guard let userId = authManager.currentUserId else { return nil }
        return ClientRepository(modelContext: modelContext, queueStore: SyncQueueStore(modelContext: modelContext), userId: userId)
    }

    private func timeEntryRepository() -> TimeEntryRepository? {
        guard let userId = authManager.currentUserId else { return nil }
        return TimeEntryRepository(modelContext: modelContext, queueStore: SyncQueueStore(modelContext: modelContext), userId: userId)
    }

    private func notificationRepository() -> NotificationRepository? {
        guard let userId = authManager.currentUserId else { return nil }
        return NotificationRepository(modelContext: modelContext, queueStore: SyncQueueStore(modelContext: modelContext), userId: userId)
    }

    private func reload() {
        guard let userId = authManager.currentUserId else { return }
        profile = try? modelContext.fetch(FetchDescriptor<Profile>(predicate: #Predicate { $0.id == userId })).first

        try? receivableRepository()?.recalculateOverdue()
        try? payableRepository()?.recalculateOverdue()
        try? budgetRepository()?.recalculateExpired()
        if let profile { try? payableRepository()?.ensureCurrentMonthDASMEI(profile: profile) }

        clients = (try? clientRepository()?.all()) ?? []
        contracts = (try? contractRepository()?.all()) ?? []
        receivables = (try? receivableRepository()?.all()) ?? []
        payables = (try? payableRepository()?.all()) ?? []
        demands = (try? demandRepository()?.all()) ?? []
        activeEntry = try? timeEntryRepository()?.activeEntry()

        let weekStart = Calendar.mondayStart(of: .now)
        let weekEnd = Calendar.current.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart
        weekEntries = (try? timeEntryRepository()?.allEntries(from: weekStart, to: weekEnd)) ?? []

        let sevenDaysOut = Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? .now
        let provider = CalendarEventProvider(modelContext: modelContext, userId: userId)
        upcomingEvents = ((try? provider.events(from: .now, to: sevenDaysOut)) ?? [])
            .filter { [.receivable, .payable, .invoice].contains($0.source) }

        try? AlertsEngine(modelContext: modelContext, userId: userId).recalculate(profile: profile)
        alerts = ((try? notificationRepository()?.all()) ?? []).filter { $0.readAt == nil }
        unreadCount = alerts.count
    }
}
