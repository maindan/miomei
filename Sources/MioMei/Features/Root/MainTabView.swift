import SwiftUI

struct MainTabView: View {
    @State private var selection: AppTab = .inicio

    var body: some View {
        ZStack(alignment: .bottom) {
            selection.moduleGradient.background

            Group {
                switch selection {
                case .inicio: DashboardView()
                case .atividades: ActivitiesRootView()
                case .financeiro: FinanceRootView()
                case .agenda: AgendaRootView()
                }
            }

            FloatingTabBar(selection: $selection)
        }
    }
}
