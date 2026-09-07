import SwiftUI

struct LoginView: View {
    @Environment(AuthManager.self) private var authManager
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            ModuleGradient.inicio.background

            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 8) {
                    Text("MioMei")
                        .font(.system(size: 40, weight: .heavy))
                        .foregroundStyle(OnGradientText.primary)
                    Text("Gestão PJ/MEI em um só lugar")
                        .font(.system(.subheadline, weight: .medium))
                        .foregroundStyle(OnGradientText.secondary)
                }

                Spacer()

                VStack(spacing: 12) {
                    if let errorMessage {
                        Text(errorMessage)
                            .font(MioMeiFont.metadata)
                            .foregroundStyle(Semantic.overdue)
                    }

                    ProviderButton(title: "Continuar com Google", systemImage: "globe") {
                        signIn(with: .google)
                    }
                    ProviderButton(title: "Continuar com GitHub", systemImage: "chevron.left.forwardslash.chevron.right") {
                        signIn(with: .github)
                    }
                }
                .disabled(isLoading)
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
    }

    private func signIn(with provider: OAuthProviderChoice) {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await authManager.signIn(with: provider)
            } catch {
                errorMessage = "Não foi possível entrar. Tente novamente."
            }
            isLoading = false
        }
    }
}
