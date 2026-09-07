import SwiftUI

/// Segmented control customizado — Guia de Estilo §7: trilha escura,
/// aba ativa em branco sólido com texto escuro. Até 4 abas.
struct GlassSegmentedControl<T: Hashable>: View {
    let options: [(value: T, label: String)]
    @Binding var selection: T

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options, id: \.value) { option in
                let isActive = option.value == selection
                Button {
                    withAnimation(.snappy(duration: 0.2)) { selection = option.value }
                } label: {
                    Text(option.label)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(isActive ? .black : .white.opacity(0.75))
                        .frame(maxWidth: .infinity)
                        .frame(height: 34)
                        .background {
                            if isActive {
                                Capsule().fill(Color.white)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.black.opacity(0.28), in: Capsule())
        .overlay(Capsule().strokeBorder(Color.white.opacity(0.14), lineWidth: 1))
    }
}
