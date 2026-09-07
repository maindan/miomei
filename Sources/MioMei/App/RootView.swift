import SwiftUI

struct RootView: View {
    @Environment(AuthManager.self) private var authManager

    var body: some View {
        switch authManager.state {
        case .loading:
            ModuleGradient.inicio.background
        case .signedOut:
            LoginView()
        case .awaitingOnboarding(let userId):
            OnboardingMEIView(userId: userId)
        case .signedIn:
            MainTabView()
        }
    }
}
