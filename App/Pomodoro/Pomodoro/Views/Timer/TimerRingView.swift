import SwiftUI

/// A circular progress ring, in the style of Apple's Activity rings / Clock timer,
/// that animates smoothly as `progress` changes and shows the remaining time
/// in large, jitter-free monospaced digits at its center.
struct TimerRingView: View {
    let progress: Double // 0...1
    let timeRemaining: TimeInterval
    let tint: Color
    let sessionTitle: String

    private let lineWidth: CGFloat = 18

    var body: some View {
        ZStack {
            Circle()
                .stroke(tint.opacity(0.15), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    tint,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.9), value: progress)

            VStack(spacing: 6) {
                Text(sessionTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .accessibilityHidden(true)

                Text(formattedTime)
                    .font(.system(size: 64, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText(countsDown: true))
                    .animation(.default, value: timeRemaining)
            }
        }
        .padding(24)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(sessionTitle) timer")
        .accessibilityValue("\(formattedTime) remaining")
    }

    private var formattedTime: String {
        let total = max(0, Int(timeRemaining.rounded()))
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    TimerRingView(progress: 0.4, timeRemaining: 15 * 60, tint: .accentColor, sessionTitle: "Focus")
        .frame(width: 280, height: 280)
}
