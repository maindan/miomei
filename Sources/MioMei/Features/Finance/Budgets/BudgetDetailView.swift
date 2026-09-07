import SwiftData
import SwiftUI

struct BudgetDetailView: View {
    let budget: Budget

    @Environment(\.modelContext) private var modelContext
    @Environment(AuthManager.self) private var authManager

    @State private var clientName: String?
    @State private var profile: Profile?
    @State private var showConvert = false
    @State private var pdfURL: URL?

    var body: some View {
        ZStack {
            ModuleGradient.financeiro.background

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(budget.title).font(MioMeiFont.screenTitle).foregroundStyle(OnGradientText.primary)
                        if let clientName {
                            Text(clientName).font(MioMeiFont.metadata).foregroundStyle(OnGradientText.secondary)
                        }
                    }
                    .padding(.top, 8)

                    GlassCard {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(budget.items) { item in
                                HStack {
                                    Text(item.description).font(MioMeiFont.metadata).foregroundStyle(OnGradientText.primary)
                                    Spacer()
                                    Text(item.total.brl).font(MioMeiFont.metadata).foregroundStyle(OnGradientText.secondary)
                                }
                            }
                            Divider().overlay(Color.white.opacity(0.14))
                            HStack {
                                Text("Total").font(.system(size: 15, weight: .bold)).foregroundStyle(OnGradientText.primary)
                                Spacer()
                                Text(budget.totalValue.brl).font(.system(size: 15, weight: .bold)).foregroundStyle(OnGradientText.primary)
                            }
                        }
                    }

                    if let validUntil = budget.validUntil {
                        Text("Válido até \(validUntil.mediumBR)").font(MioMeiFont.metadata).foregroundStyle(OnGradientText.secondary)
                    }

                    actionButtons

                    if let pdfURL {
                        ShareLink(item: pdfURL) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Compartilhar PDF").font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundStyle(OnGradientText.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .glassSurface(.light, cornerRadius: 20)
                        }
                    } else {
                        Button {
                            generatePDF()
                        } label: {
                            HStack {
                                Image(systemName: "doc.richtext")
                                Text("Gerar PDF").font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundStyle(OnGradientText.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .glassSurface(.light, cornerRadius: 20)
                        }
                    }
                }
                .padding(20)
                .padding(.bottom, 60)
            }
        }
        .sheet(isPresented: $showConvert) {
            ConvertBudgetSheet(budget: budget) { type, installments, firstDueDate in
                convert(type: type, installments: installments, firstDueDate: firstDueDate)
            }
        }
        .onAppear(perform: load)
    }

    @ViewBuilder
    private var actionButtons: some View {
        switch budget.status {
        case .draft:
            PrimaryButton(title: "Marcar como enviado") { setStatus(.sent) }
        case .sent:
            PrimaryButton(title: "Aprovar") { setStatus(.approved); showConvert = true }
            DestructiveButton(title: "Recusar") { setStatus(.rejected) }
        case .approved:
            PrimaryButton(title: "Converter em contrato") { showConvert = true }
        case .rejected, .expired:
            EmptyView()
        }
    }

    private func setStatus(_ status: BudgetStatus) {
        try? budgetRepository()?.setStatus(budget, status: status)
    }

    private func convert(type: ContractType, installments: Int, firstDueDate: Date) {
        guard let userId = authManager.currentUserId else { return }
        let queueStore = SyncQueueStore(modelContext: modelContext)
        let contract = try? ContractRepository(modelContext: modelContext, queueStore: queueStore, userId: userId).create(
            type: type, clientId: budget.clientId, title: budget.title, description: nil,
            startDate: .now, endDate: nil, estimatedValue: budget.totalValue,
            weeklyHoursRequirement: nil, recurrence: nil, paymentMethod: nil
        )
        try? ReceivableRepository(modelContext: modelContext, queueStore: queueStore, userId: userId).createInstallments(
            contractId: contract?.id, clientId: budget.clientId, description: budget.title,
            totalAmount: budget.totalValue, installments: installments, firstDueDate: firstDueDate, method: nil
        )
    }

    private func generatePDF() {
        let data = BudgetPDFGenerator.generate(budget: budget, clientName: clientName, profile: profile)
        pdfURL = BudgetPDFGenerator.writeTemporaryFile(data: data, suggestedName: budget.title)
    }

    private func budgetRepository() -> BudgetRepository? {
        guard let userId = authManager.currentUserId else { return nil }
        return BudgetRepository(modelContext: modelContext, queueStore: SyncQueueStore(modelContext: modelContext), userId: userId)
    }

    private func load() {
        guard let userId = authManager.currentUserId else { return }
        profile = try? modelContext.fetch(FetchDescriptor<Profile>(predicate: #Predicate { $0.id == userId })).first
        if let clientId = budget.clientId {
            clientName = try? modelContext.fetch(FetchDescriptor<Client>(predicate: #Predicate { $0.id == clientId })).first?.name
        }
    }
}
