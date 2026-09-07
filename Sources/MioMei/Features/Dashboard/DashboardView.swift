import SwiftUI

struct DashboardView: View {
    @State private var showSettings = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                topBar

                GlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Dashboard").font(MioMeiFont.screenTitle).foregroundStyle(OnGradientText.primary)
                        Text("Resumo financeiro, saúde dos contratos, produtividade da semana e alertas chegam na Fase 5 (mio-escopo.md §5, §16).")
                            .font(MioMeiFont.metadata)
                            .foregroundStyle(OnGradientText.secondary)
                    }
                }
            }
            .padding(20)
            .padding(.bottom, 100)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }

    private var topBar: some View {
        HStack {
            Text("Início").font(MioMeiFont.screenTitle).foregroundStyle(OnGradientText.primary)
            Spacer()
            HStack(spacing: 10) {
                topBarIcon("bell") {}
                topBarIcon("gearshape") { showSettings = true }
            }
        }
        .padding(.top, 8)
    }

    private func topBarIcon(_ systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .foregroundStyle(OnGradientText.primary)
                .frame(width: 40, height: 40)
                .glassSurface(.light, cornerRadius: 20)
        }
    }
}
