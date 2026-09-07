import SwiftUI

struct FinanceRootView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Financeiro").font(MioMeiFont.screenTitle).foregroundStyle(OnGradientText.primary)
                    .padding(.top, 8)

                GlassCard {
                    Text("Clientes, orçamentos, contratos, recebimentos, pagamentos e notas chegam nas Fases 2 e 4 (mio-escopo.md §6, §16).")
                        .font(MioMeiFont.metadata)
                        .foregroundStyle(OnGradientText.secondary)
                }
            }
            .padding(20)
            .padding(.bottom, 100)
        }
    }
}
