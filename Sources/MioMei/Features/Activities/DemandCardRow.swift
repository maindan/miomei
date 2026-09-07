import SwiftUI

struct DemandCardRow: View {
    let demand: Demand
    let contractTitle: String?
    let progress: Double
    let isTimerActive: Bool
    let onPlay: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Button(action: onPlay) {
                Image(systemName: isTimerActive ? "pause.fill" : "play.fill")
                    .foregroundStyle(.black)
                    .frame(width: 40, height: 40)
                    .background(Color.white, in: Circle())
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 6) {
                Text(demand.title)
                    .font(MioMeiFont.listItem)
                    .foregroundStyle(OnGradientText.primary)
                    .lineLimit(1)

                if let contractTitle {
                    Text(contractTitle)
                        .font(MioMeiFont.metadata)
                        .foregroundStyle(OnGradientText.secondary)
                }

                ProgressView(value: progress)
                    .tint(.white)
                    .frame(height: 6)
            }

            Spacer(minLength: 4)

            priorityBadge
        }
        .padding(14)
        .glassSurface(.light, cornerRadius: Radius.listRow)
    }

    private var priorityBadge: some View {
        let color: Color = switch demand.priority {
        case .high: Semantic.overdue
        case .medium: Semantic.attention
        case .low: Semantic.info
        }
        return Circle().fill(color).frame(width: 8, height: 8)
    }
}
