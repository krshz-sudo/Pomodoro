import SwiftUI
import WidgetKit
#if canImport(ActivityKit)
import ActivityKit

/// NOTE: This file belongs in a separate **Widget Extension** target
/// (File > New > Target > Widget Extension, enable "Include Live Activity"),
/// not the main app target. Add `PomodoroActivityAttributes.swift` to that
/// target's membership too.
struct PomodoroLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: PomodoroActivityAttributes.self) { context in
            // Lock Screen / banner UI
            HStack(spacing: 16) {
                Image(systemName: sessionSymbol(context.state.sessionType))
                    .font(.title2)
                    .foregroundStyle(.tint)

                VStack(alignment: .leading, spacing: 2) {
                    Text(context.attributes.sessionTitle)
                        .font(.headline)
                    Text(context.state.isPaused ? "Paused" : "In progress")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if context.state.isPaused {
                    Text("--:--")
                        .font(.title2.monospacedDigit())
                } else {
                    Text(timerInterval: Date.now...context.state.endDate, countsDown: true)
                        .font(.title2.monospacedDigit())
                        .frame(minWidth: 64)
                }
            }
            .padding()
            .activityBackgroundTint(Color(.systemBackground))
            .activitySystemActionForegroundColor(Color.primary)

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: sessionSymbol(context.state.sessionType))
                        .foregroundStyle(.tint)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.isPaused {
                        Text("Paused")
                    } else {
                        Text(timerInterval: Date.now...context.state.endDate, countsDown: true)
                            .monospacedDigit()
                    }
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.sessionTitle)
                        .font(.caption)
                }
            } compactLeading: {
                Image(systemName: sessionSymbol(context.state.sessionType))
            } compactTrailing: {
                if context.state.isPaused {
                    Text("II")
                } else {
                    Text(timerInterval: Date.now...context.state.endDate, countsDown: true)
                        .monospacedDigit()
                        .frame(width: 40)
                }
            } minimal: {
                Image(systemName: sessionSymbol(context.state.sessionType))
            }
        }
    }

    private func sessionSymbol(_ raw: String) -> String {
        SessionType(rawValue: raw)?.symbolName ?? "timer"
    }
}
#endif
