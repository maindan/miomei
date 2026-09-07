import SwiftUI

/// CTA primário — branco sólido, uma única ação principal por tela (Guia de Estilo §9).
struct PrimaryButton: View {
    let title: String
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView().tint(.black)
                } else {
                    Text(title)
                        .font(.system(.body, weight: .bold))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 58)
        }
        .foregroundStyle(.black)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .disabled(isLoading)
    }
}

/// Botão de provedor OAuth (Google/GitHub) em vidro claro — tela de Login.
struct ProviderButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                Text(title).font(.system(.body, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
        }
        .foregroundStyle(OnGradientText.primary)
        .glassSurface(.light, cornerRadius: 20)
    }
}

/// Botão destrutivo para confirmações de ação de risco (Guia de Estilo §2.5).
struct DestructiveButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(role: .destructive, action: action) {
            Text(title)
                .font(.system(.body, weight: .bold))
                .frame(maxWidth: .infinity)
                .frame(height: 58)
        }
        .foregroundStyle(.white)
        .background(Color.red, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

/// FAB de criação — círculo branco 60px, um por tela, acima da navbar (Guia de Estilo §7).
struct CreateFAB: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.black)
                .frame(width: 60, height: 60)
                .background(Color.white, in: Circle())
                .shadow(color: .black.opacity(0.35), radius: 16, x: 0, y: 10)
        }
    }
}
