import SwiftUI

/// Cronômetro em curso no topo da lista de Atividades (mio-escopo.md §7.3, §14).
struct ActiveTimerCard: View {
    let demandTitle: String
    let startedAt: Date
    let onOpenSession: () -> Void
    let onStop: () -> Void

    var body: some View {
        Button(action: onOpenSession) {
            HStack(spacing: 14) {
                Image(systemName: "timer")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.black)
                    .frame(width: 44, height: 44)
                    .background(Color.white, in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(demandTitle)
                        .font(MioMeiFont.listItem)
                        .foregroundStyle(OnGradientText.primary)
                        .lineLimit(1)
                    TimelineView(.periodic(from: startedAt, by: 1)) { context in
                        Text(Int(context.date.timeIntervalSince(startedAt)).hoursMinutesSeconds)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(OnGradientText.secondary)
                            .numericTabular()
                    }
                }

                Spacer()

                Button(action: onStop) {
                    Image(systemName: "stop.fill")
                        .foregroundStyle(OnGradientText.primary)
                        .frame(width: 40, height: 40)
                        .glassSurface(.light, cornerRadius: 20)
                }
            }
            .padding(14)
            .glassSurface(.light, cornerRadius: Radius.card)
        }
        .buttonStyle(.plain)
    }
}
