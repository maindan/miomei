import SwiftUI

/// Tela de abertura: fundo preto com o wordmark "miomei." se desenhando no centro.
/// Fica sobre o `RootView` até a animação terminar, independente do estado de auth
/// (que já começa a carregar por baixo, em paralelo).
struct SplashView: View {
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            MiomeiLogo(width: 220, onComplete: onComplete)
        }
    }
}

#if DEBUG
#Preview("SplashView") {
    SplashView(onComplete: {})
}
#endif
