import SwiftData
import SwiftUI

struct BudgetListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthManager.self) private var authManager

    @State private var budgets: [Budget] = []
    @State private var clients: [Client] = []
    @State private var showCreate = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ModuleGradient.financeiro.background

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Orçamentos").font(MioMeiFont.screenTitle).foregroundStyle(OnGradientText.primary)
                        .padding(.top, 8)

                    if budgets.isEmpty {
                        GlassCard {
                            Text("Nenhum orçamento ainda. Toque em + para criar o primeiro.")
                                .font(MioMeiFont.metadata)
                                .foregroundStyle(OnGradientText.secondary)
                        }
                    } else {
                        ForEach(budgets) { budget in
                            NavigationLink(value: budget) {
                                GlassListRow(title: budget.title, metadata: clientName(budget.clientId)) {
                                    statusDot(budget.status)
                                } trailing: {
                                    Text(budget.totalValue.brl).font(MioMeiFont.metadata).foregroundStyle(OnGradientText.primary)
                                }
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
        .sheet(isPresented: $showCreate) {
            BudgetFormSheet(clients: clients) { clientId, title, items, validUntil, paymentTerms in
                try? budgetRepository()?.create(clientId: clientId, title: title, items: items, validUntil: validUntil, paymentTerms: paymentTerms)
                reload()
            }
        }
        .onAppear(perform: reload)
    }

    private func clientName(_ clientId: UUID?) -> String? {
        clients.first { $0.id == clientId }?.name
    }

    private func statusDot(_ status: BudgetStatus) -> some View {
        let color: Color = switch status {
        case .draft: OnGradientText.secondary
        case .sent: Semantic.info
        case .approved: Semantic.received
        case .rejected, .expired: Semantic.overdue
        }
        return Circle().fill(color).frame(width: 10, height: 10).frame(width: 40)
    }

    private func budgetRepository() -> BudgetRepository? {
        guard let userId = authManager.currentUserId else { return nil }
        return BudgetRepository(modelContext: modelContext, queueStore: SyncQueueStore(modelContext: modelContext), userId: userId)
    }

    private func clientRepository() -> ClientRepository? {
        guard let userId = authManager.currentUserId else { return nil }
        return ClientRepository(modelContext: modelContext, queueStore: SyncQueueStore(modelContext: modelContext), userId: userId)
    }

    private func reload() {
        try? budgetRepository()?.recalculateExpired()
        budgets = (try? budgetRepository()?.all()) ?? []
        clients = (try? clientRepository()?.all()) ?? []
    }
}
