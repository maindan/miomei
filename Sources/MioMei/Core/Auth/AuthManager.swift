import Foundation
import Observation
import Supabase
import SwiftData

/// Login via Google/GitHub OAuth (docs/miomei-supabase.md §3, §5) e resolução
/// do estado "autenticado sem onboarding" vs. "autenticado completo", olhando
/// para `Profile.onboardingDone` no SwiftData local.
@Observable
@MainActor
final class AuthManager {
    private(set) var state: AuthState = .loading

    private let supabase: SupabaseClient
    private let modelContext: ModelContext
    private var authChangesTask: Task<Void, Never>?

    init(supabase: SupabaseClient = SupabaseService.shared.client, modelContext: ModelContext) {
        self.supabase = supabase
        self.modelContext = modelContext
    }

    func start() {
        authChangesTask?.cancel()
        authChangesTask = Task { [weak self] in
            guard let self else { return }
            for await (_, session) in self.supabase.auth.authStateChanges {
                self.resolveState(for: session)
            }
        }
    }

    func signIn(with provider: OAuthProviderChoice) async throws {
        let mapped: Provider = provider == .google ? .google : .github
        try await supabase.auth.signInWithOAuth(provider: mapped, redirectTo: AppConfig.oauthRedirectURL)
    }

    func signOut() async throws {
        try await supabase.auth.signOut()
        state = .signedOut
    }

    /// Chamar depois que o onboarding local salva `Profile.onboardingDone = true`.
    func completeOnboarding(userId: UUID) {
        state = .signedIn(userId: userId)
    }

    private func resolveState(for session: Session?) {
        guard let session else {
            state = .signedOut
            return
        }
        let userId = session.user.id
        let descriptor = FetchDescriptor<Profile>(predicate: #Predicate { $0.id == userId })
        let profile = try? modelContext.fetch(descriptor).first
        if profile?.onboardingDone == true {
            state = .signedIn(userId: userId)
        } else {
            state = .awaitingOnboarding(userId: userId)
        }
    }
}
