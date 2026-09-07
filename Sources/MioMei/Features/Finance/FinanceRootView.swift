import SwiftData
import SwiftUI

enum FinanceSection: String, CaseIterable {
    case receivables = "Receber"
    case payables = "Pagar"
    case notes = "Notas"
    case contracts = "Contratos"
}

struct FinanceRootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthManager.self) private var authManager

    @State private var section: FinanceSection = .receivables
    @State private var contracts: [Contract] = []
    @State private var receivables: [Receivable] = []
    @State private var payables: [Payable] = []
    @State private var invoices: [Invoice] = []
    @State private var clients: [Client] = []
    @State private var profile: Profile?

    @State private var showCreateContract = false
    @State private var showCreateReceivable = false
    @State private var showCreatePayable = false
    @State private var showCreateInvoice = false
    @State private var pendingTaxPrompt: Receivable?
    @State private var pendingInvoicePrompt: Receivable?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ModuleGradient.financeiro.background

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        topBar

                        GlassSegmentedControl(
                            options: FinanceSection.allCases.map { ($0, $0.rawValue) },
                            selection: $section
                        )

                        switch section {
                        case .contracts:
                            ContractListView(contracts: $contracts, clients: clients)
                        case .receivables:
                            ReceivableListView(receivables: $receivables, onMarkReceived: markReceived)
                        case .payables:
                            PayableListView(payables: $payables, onMarkPaid: markPaid)
                        case .notes:
                            InvoiceListView(invoices: $invoices, onMarkIssued: markIssued)
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 100)
                }

                CreateFAB { createTapped() }
                    .padding(.trailing, 20)
                    .padding(.bottom, 24)
            }
            .navigationDestination(for: Client.self) { ClientDetailView(client: $0) }
            .navigationDestination(for: Contract.self) { ContractDetailView(contract: $0) }
            .navigationDestination(for: Budget.self) { BudgetDetailView(budget: $0) }
        }
        .sheet(isPresented: $showCreateContract) {
            ContractFormSheet(clients: clients) { input in
                try? contractRepository()?.create(input)
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
        .sheet(isPresented: $showCreateInvoice) {
            InvoiceFormSheet(contracts: contracts, clients: clients) { contractId, clientId, number, amount, plannedDate in
                try? invoiceRepository()?.create(contractId: contractId, clientId: clientId, number: number, amount: amount, plannedDate: plannedDate)
                reload()
            }
        }
        .sheet(item: $pendingInvoicePrompt) { receivable in
            InvoiceFormSheet(
                contracts: contracts, clients: clients,
                prefillClientId: receivable.clientId, prefillContractId: receivable.contractId,
                prefillAmount: receivable.amount
            ) { contractId, clientId, number, amount, plannedDate in
                try? invoiceRepository()?.create(contractId: contractId, clientId: clientId, number: number, amount: amount, plannedDate: plannedDate)
                reload()
            }
        }
        .alert("Gerar imposto sobre este recebimento?", isPresented: Binding(
            get: { pendingTaxPrompt != nil },
            set: { if !$0 { pendingTaxPrompt = nil } }
        )) {
            Button("Agora não", role: .cancel) { pendingTaxPrompt = nil }
            Button("Gerar") {
                if let receivable = pendingTaxPrompt, let profile {
                    try? payableRepository()?.createTax(
                        onAmount: receivable.amount, taxRate: profile.defaultTaxRate, dueDate: receivable.dueDate
                    )
                    reload()
                }
                pendingTaxPrompt = nil
            }
        } message: {
            Text("Usa a alíquota padrão do seu perfil.")
        }
        .onAppear(perform: reload)
    }

    private var topBar: some View {
        HStack {
            Text("Financeiro").font(MioMeiFont.screenTitle).foregroundStyle(OnGradientText.primary)
            Spacer()
            NavigationLink {
                BudgetListView()
            } label: {
                Image(systemName: "doc.text")
                    .foregroundStyle(OnGradientText.primary)
                    .frame(width: 40, height: 40)
                    .glassSurface(.light, cornerRadius: 20)
            }
            NavigationLink {
                ClientListView()
            } label: {
                Image(systemName: "person.2")
                    .foregroundStyle(OnGradientText.primary)
                    .frame(width: 40, height: 40)
                    .glassSurface(.light, cornerRadius: 20)
            }
        }
        .padding(.top, 8)
    }

    private func createTapped() {
        switch section {
        case .contracts: showCreateContract = true
        case .receivables: showCreateReceivable = true
        case .payables: showCreatePayable = true
        case .notes: showCreateInvoice = true
        }
    }

    /// Ao marcar como recebido, sugere registrar nota + gerar imposto sobre o
    /// valor (mio-escopo.md §6.4, §9).
    private func markReceived(_ receivable: Receivable) {
        try? receivableRepository()?.markReceived(receivable)
        reload()
        pendingInvoicePrompt = receivable
        if let rate = profile?.defaultTaxRate, rate > 0 {
            pendingTaxPrompt = receivable
        }
    }

    private func markPaid(_ payable: Payable) {
        try? payableRepository()?.markPaid(payable)
        reload()
    }

    private func markIssued(_ invoice: Invoice) {
        try? invoiceRepository()?.markIssued(invoice)
        reload()
    }

    private func contractRepository() -> ContractRepository? {
        guard let userId = authManager.currentUserId else { return nil }
        return ContractRepository(modelContext: modelContext, queueStore: SyncQueueStore(modelContext: modelContext), userId: userId)
    }

    private func receivableRepository() -> ReceivableRepository? {
        guard let userId = authManager.currentUserId else { return nil }
        return ReceivableRepository(modelContext: modelContext, queueStore: SyncQueueStore(modelContext: modelContext), userId: userId)
    }

    private func payableRepository() -> PayableRepository? {
        guard let userId = authManager.currentUserId else { return nil }
        return PayableRepository(modelContext: modelContext, queueStore: SyncQueueStore(modelContext: modelContext), userId: userId)
    }

    private func invoiceRepository() -> InvoiceRepository? {
        guard let userId = authManager.currentUserId else { return nil }
        return InvoiceRepository(modelContext: modelContext, queueStore: SyncQueueStore(modelContext: modelContext), userId: userId)
    }

    private func clientRepository() -> ClientRepository? {
        guard let userId = authManager.currentUserId else { return nil }
        return ClientRepository(modelContext: modelContext, queueStore: SyncQueueStore(modelContext: modelContext), userId: userId)
    }

    private func reload() {
        guard let userId = authManager.currentUserId else { return }
        profile = try? modelContext.fetch(FetchDescriptor<Profile>(predicate: #Predicate { $0.id == userId })).first

        try? receivableRepository()?.recalculateOverdue()
        try? payableRepository()?.recalculateOverdue()
        if let profile { try? payableRepository()?.ensureCurrentMonthDASMEI(profile: profile) }

        clients = (try? clientRepository()?.all()) ?? []
        contracts = (try? contractRepository()?.all()) ?? []
        receivables = (try? receivableRepository()?.all()) ?? []
        payables = (try? payableRepository()?.all()) ?? []
        invoices = (try? invoiceRepository()?.all()) ?? []
    }
}
