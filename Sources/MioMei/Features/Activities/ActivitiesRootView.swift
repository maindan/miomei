import SwiftUI

struct ActivitiesRootView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Atividades").font(MioMeiFont.screenTitle).foregroundStyle(OnGradientText.primary)
                    .padding(.top, 8)

                GlassCard {
                    Text("Demandas, tarefas, cronômetro e Live Activity chegam na Fase 3 (mio-escopo.md §7, §16).")
                        .font(MioMeiFont.metadata)
                        .foregroundStyle(OnGradientText.secondary)
                }
            }
            .padding(20)
            .padding(.bottom, 100)
        }
    }
}
