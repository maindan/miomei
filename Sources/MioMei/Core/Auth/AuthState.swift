import Foundation

enum AuthState: Equatable {
    case loading
    case signedOut
    case awaitingOnboarding(userId: UUID)
    case signedIn(userId: UUID)
}

enum OAuthProviderChoice {
    case google, github
}
