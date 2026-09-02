import SwiftUI

struct SessionControlsView: View {
    @EnvironmentObject private var engine: PomodoroTimerEngine

    var body: some View {
        VStack(spacing: 20) {
            if case .awaitingConfirmation(let next) = engine.state {
                confirmationBanner(next: next)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            HStack(spacing: 32) {
                Button(role: .destructive) {
                    engine.reset()
                } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                        .labelStyle(.iconOnly)
                        .font(.title2)
                        .frame(width: 56, height: 56)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.circle)
                .accessibilityLabel("Reset timer")

                primaryButton

                // Symmetric spacer button keeps the primary button centered.
                Color.clear.frame(width: 56, height: 56)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: isAwaitingConfirmation)
    }

    @ViewBuilder
    private var primaryButton: some View {
        switch engine.state {
        case .running:
            Button {
                engine.pause()
            } label: {
                Label("Pause", systemImage: "pause.fill")
                    .labelStyle(.iconOnly)
                    .font(.title)
                    .frame(width: 84, height: 84)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.circle)
            .accessibilityLabel("Pause timer")

        default:
            Button {
                engine.start()
            } label: {
                Label("Start", systemImage: "play.fill")
                    .labelStyle(.iconOnly)
                    .font(.title)
                    .frame(width: 84, height: 84)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.circle)
            .accessibilityLabel("Start timer")
        }
    }

    private func confirmationBanner(next: SessionType) -> some View {
        HStack {
            Image(systemName: next.symbolName)
                .foregroundStyle(next.tintColor)
            Text("Starting \(next.title.lowercased()) in \(engine.confirmationSecondsRemaining)s")
                .font(.subheadline)
            Spacer()
            Button("Cancel") { engine.cancelAutoStart() }
                .font(.subheadline.weight(.semibold))
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .padding(.horizontal)
    }

    private var isAwaitingConfirmation: Bool {
        if case .awaitingConfirmation = engine.state { return true }
        return false
    }
}

#Preview {
    SessionControlsView()
        .environmentObject(PomodoroTimerEngine())
}
