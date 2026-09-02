import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: PomodoroSettings

    var body: some View {
        NavigationStack {
            Form {
                Section("Durations") {
                    Stepper(value: $settings.focusDurationMinutes, in: 5...90, step: 5) {
                        labeledRow("Focus", "\(settings.focusDurationMinutes) min")
                    }
                    Stepper(value: $settings.shortBreakDurationMinutes, in: 1...30, step: 1) {
                        labeledRow("Short Break", "\(settings.shortBreakDurationMinutes) min")
                    }
                    Stepper(value: $settings.longBreakDurationMinutes, in: 5...45, step: 5) {
                        labeledRow("Long Break", "\(settings.longBreakDurationMinutes) min")
                    }
                    Stepper(value: $settings.cyclesBeforeLongBreak, in: 2...8, step: 1) {
                        labeledRow("Cycles Before Long Break", "\(settings.cyclesBeforeLongBreak)")
                    }
                }

                Section("Session Flow") {
                    Toggle("Auto-start Next Session", isOn: $settings.autoStartNextSession)
                    if settings.autoStartNextSession {
                        Stepper(value: $settings.autoStartGraceSeconds, in: 3...30, step: 1) {
                            labeledRow("Confirmation Window", "\(settings.autoStartGraceSeconds)s")
                        }
                    }
                }

                Section("Feedback") {
                    Toggle(isOn: $settings.soundEnabled) {
                        Label("Sound", systemImage: "speaker.wave.2.fill")
                    }
                    Toggle(isOn: $settings.hapticsEnabled) {
                        Label("Haptics", systemImage: "iphone.radiowaves.left.and.right")
                    }
                    Toggle(isOn: $settings.notificationsEnabled) {
                        Label("Notifications", systemImage: "bell.fill")
                    }
                }

                Section {
                    Text("Appearance follows your system Light/Dark Mode setting automatically.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Appearance")
                }
            }
            .navigationTitle("Settings")
        }
    }

    private func labeledRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(PomodoroSettings.shared)
}
