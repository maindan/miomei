import SwiftUI

enum AppTab: CaseIterable, Hashable {
    case inicio, atividades, financeiro, agenda

    var moduleGradient: ModuleGradient {
        switch self {
        case .inicio: return .inicio
        case .atividades: return .atividades
        case .financeiro: return .financeiro
        case .agenda: return .financeiro // Agenda usa o gradiente âmbar (mapa de telas §8)
        }
    }

    func symbolName(timerRunning: Bool) -> String {
        switch self {
        case .inicio: return "house"
        case .atividades: return timerRunning ? "timer" : "checklist"
        case .financeiro: return "creditcard"
        case .agenda: return "calendar"
        }
    }
}

/// Navbar flutuante em pílula — Guia de Estilo §7. Configurações e notificações
/// não entram aqui: ficam no topo da tela Início.
struct FloatingTabBar: View {
    @Binding var selection: AppTab
    var isTimerRunning: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                tabButton(tab)
            }
        }
        .padding(7)
        .glassSurface(.light, cornerRadius: 999)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.5), radius: 17, x: 0, y: 18)
        .padding(.bottom, 24)
    }

    private func tabButton(_ tab: AppTab) -> some View {
        let isActive = tab == selection
        return Button {
            selection = tab
        } label: {
            Image(systemName: tab.symbolName(timerRunning: isTimerRunning && tab == .atividades))
                .font(.system(size: 20, weight: .regular))
                .frame(width: 44, height: 44)
                .foregroundStyle(isActive ? selection.moduleGradient.darkestTone : .white.opacity(0.85))
                .background {
                    if isActive {
                        Circle().fill(Color.white)
                    }
                }
        }
        .buttonStyle(.plain)
    }
}
