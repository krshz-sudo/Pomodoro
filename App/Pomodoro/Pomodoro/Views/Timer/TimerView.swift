import SwiftUI

struct TimerView: View {
    @EnvironmentObject private var engine: PomodoroTimerEngine

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                TimerRingView(
                    progress: engine.progress,
                    timeRemaining: engine.timeRemaining,
                    tint: engine.currentSession.tintColor,
                    sessionTitle: engine.currentSession.title
                )
                .frame(maxWidth: 320, maxHeight: 320)

                sessionCounter

                Spacer()

                SessionControlsView()
                    .padding(.bottom, 24)
            }
            .padding()
            .navigationTitle("Pomodoro")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var sessionCounter: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text("\(engine.completedCyclesToday) completed today")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    TimerView()
        .environmentObject(PomodoroTimerEngine())
}
