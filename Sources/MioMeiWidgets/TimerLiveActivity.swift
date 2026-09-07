import ActivityKit
import SwiftUI
import WidgetKit

/// Live Activity do cronômetro — Dynamic Island + tela de bloqueio, acento
/// verde (Atividades) sobre material escuro (mio-escopo.md §7.3).
struct TimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerActivityAttributes.self) { context in
            lockScreenView(context)
                .activityBackgroundTint(Color(red: 0.05, green: 0.08, blue: 0.07))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "timer")
                        .foregroundStyle(Color(red: 0.44, green: 0.74, blue: 0.48))
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: context.state.startedAt...Date.distantFuture, countsDown: false)
                        .monospacedDigit()
                        .foregroundStyle(.white)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.attributes.demandTitle)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
            } compactLeading: {
                Image(systemName: "timer").foregroundStyle(Color(red: 0.44, green: 0.74, blue: 0.48))
            } compactTrailing: {
                Text(timerInterval: context.state.startedAt...Date.distantFuture, countsDown: false)
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .frame(width: 46)
            } minimal: {
                Image(systemName: "timer").foregroundStyle(Color(red: 0.44, green: 0.74, blue: 0.48))
            }
        }
    }

    private func lockScreenView(_ context: ActivityViewContext<TimerActivityAttributes>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(context.attributes.demandTitle)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                if let contractTitle = context.attributes.contractTitle {
                    Text(contractTitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            Spacer()
            Text(timerInterval: context.state.startedAt...Date.distantFuture, countsDown: false)
                .font(.title3.monospacedDigit().weight(.semibold))
                .foregroundStyle(.white)
        }
        .padding(16)
    }
}
