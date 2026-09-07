import SwiftUI

/// Tela de sessão do cronômetro (mio-escopo.md §7.4, Guia de Estilo §7
/// "Cronômetro"). O controle de "lap" do guia não existe no modelo de dados
/// (apenas `started_at`/`ended_at`) e por isso não é implementado aqui.
struct TimerSessionView: View {
    let demandTitle: String
    let startedAt: Date
    let onStop: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            TimerGlow.background.ignoresSafeArea()

            VStack(spacing: 28) {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.down")
                            .foregroundStyle(.black.opacity(0.6))
                            .frame(width: 36, height: 36)
                            .background(.white.opacity(0.4), in: Circle())
                    }
                }

                Text(demandTitle)
                    .font(.system(.title3, weight: .bold))
                    .foregroundStyle(.black.opacity(0.75))

                TimelineView(.periodic(from: startedAt, by: 1)) { context in
                    Text(Int(context.date.timeIntervalSince(startedAt)).hoursMinutesSeconds)
                        .font(.custom("DotGothic16-Regular", size: 52))
                        .kerning(2)
                        .foregroundStyle(.black.opacity(0.85))
                        .numericTabular()
                }

                Spacer()

                Button {
                    onStop()
                    dismiss()
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(.black)
                        .frame(width: 72, height: 72)
                        .background(.white, in: Circle())
                        .shadow(color: .black.opacity(0.2), radius: 14, y: 8)
                }
                .padding(.bottom, 40)
            }
            .padding(24)
        }
    }
}
