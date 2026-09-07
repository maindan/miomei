import SwiftUI

struct AgendaRootView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Agenda").font(MioMeiFont.screenTitle).foregroundStyle(OnGradientText.primary)
                    .padding(.top, 8)

                GlassCard {
                    Text("Calendário unificado e lembretes chegam na Fase 5 (mio-escopo.md §8, §16).")
                        .font(MioMeiFont.metadata)
                        .foregroundStyle(OnGradientText.secondary)
                }
            }
            .padding(20)
            .padding(.bottom, 100)
        }
    }
}
