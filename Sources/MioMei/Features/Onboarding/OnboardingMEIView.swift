import SwiftData
import SwiftUI

/// Configuração do MEI/empresa no primeiro acesso (mio-escopo.md §4.2).
struct OnboardingMEIView: View {
    let userId: UUID

    @Environment(\.modelContext) private var modelContext
    @Environment(AuthManager.self) private var authManager

    @State private var companyName = ""
    @State private var tradeName = ""
    @State private var cnpj = ""
    @State private var taxRegime: TaxRegime = .mei
    @State private var cnae = ""
    @State private var openingDate: Date?
    @State private var hasOpeningDate = false
    @State private var commercialEmail = ""
    @State private var pixKey = ""
    @State private var bankInfo = ""
    @State private var defaultTaxRateText = "6"

    @State private var isSaving = false
    @State private var showCNPJError = false

    private var isCNPJValid: Bool {
        CNPJValidator.isValid(cnpj)
    }

    var body: some View {
        ZStack {
            ModuleGradient.perfil.background

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header

                    GlassCard {
                        VStack(alignment: .leading, spacing: 14) {
                            field("Nome empresarial", text: $companyName)
                            field("Nome fantasia", text: $tradeName)

                            VStack(alignment: .leading, spacing: 4) {
                                field("CNPJ", text: cnpjBinding)
                                    .keyboardType(.numberPad)
                                if showCNPJError && !isCNPJValid {
                                    Text("CNPJ inválido")
                                        .font(MioMeiFont.metadata)
                                        .foregroundStyle(Semantic.overdue)
                                }
                            }

                            Picker("Regime tributário", selection: $taxRegime) {
                                Text("MEI").tag(TaxRegime.mei)
                                Text("Simples Nacional").tag(TaxRegime.simples)
                                Text("Outro").tag(TaxRegime.other)
                            }
                            .pickerStyle(.segmented)
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Opcional").sectionLabelStyle().foregroundStyle(OnGradientText.label)
                            field("CNAE principal", text: $cnae)
                            field("E-mail comercial", text: $commercialEmail)
                                .keyboardType(.emailAddress)
                            Toggle("Tenho data de abertura", isOn: $hasOpeningDate)
                                .tint(.white)
                            if hasOpeningDate {
                                DatePicker(
                                    "Data de abertura",
                                    selection: Binding(get: { openingDate ?? .now }, set: { openingDate = $0 }),
                                    displayedComponents: .date
                                )
                            }
                        }
                    }

                    GlassCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Dados bancários / recebimento").sectionLabelStyle().foregroundStyle(OnGradientText.label)
                            field("Chave PIX", text: $pixKey)
                            field("Dados bancários", text: $bankInfo)
                            field("Alíquota de imposto padrão (%)", text: $defaultTaxRateText)
                                .keyboardType(.decimalPad)
                        }
                    }

                    PrimaryButton(title: "Concluir configuração", isLoading: isSaving) {
                        save()
                    }
                    .padding(.top, 4)
                }
                .padding(20)
                .padding(.bottom, 40)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Configure seu MEI").font(MioMeiFont.dayBriefing).foregroundStyle(OnGradientText.primary)
            Text("Esses dados aparecem nos orçamentos e alimentam os alertas de imposto.")
                .font(MioMeiFont.metadata)
                .foregroundStyle(OnGradientText.secondary)
        }
        .padding(.top, 12)
    }

    private var cnpjBinding: Binding<String> {
        Binding(
            get: { cnpj },
            set: { cnpj = CNPJValidator.format($0) }
        )
    }

    private func field(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .foregroundStyle(OnGradientText.primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .glassSurface(.field, cornerRadius: Radius.field)
    }

    private func save() {
        guard isCNPJValid else {
            showCNPJError = true
            return
        }
        isSaving = true

        let profile = Profile(
            id: userId,
            companyName: companyName.isEmpty ? nil : companyName,
            tradeName: tradeName.isEmpty ? nil : tradeName,
            cnpj: cnpj,
            email: commercialEmail.isEmpty ? nil : commercialEmail,
            taxRegime: taxRegime,
            defaultTaxRate: Decimal(string: defaultTaxRateText.replacingOccurrences(of: ",", with: ".")) ?? 0,
            meiAnnualCeiling: nil,
            pixKey: pixKey.isEmpty ? nil : pixKey,
            bankInfo: bankInfo.isEmpty ? nil : bankInfo,
            onboardingDone: true
        )
        modelContext.insert(profile)
        try? modelContext.save()

        authManager.completeOnboarding(userId: userId)
        isSaving = false
    }
}
