import SwiftUI
import Combine

/// Holds all user-configurable settings, persisted via `@AppStorage`/UserDefaults.
/// Exposed as an `ObservableObject` so SwiftUI views update live when settings change,
/// and consumed by `PomodoroTimerEngine` for duration/behavior configuration.
final class PomodoroSettings: ObservableObject {

    static let shared = PomodoroSettings()

    // MARK: Durations (minutes)

    @AppStorage("focusDurationMinutes") var focusDurationMinutes: Int = 25 {
        willSet { objectWillChange.send() }
    }
    @AppStorage("shortBreakDurationMinutes") var shortBreakDurationMinutes: Int = 5 {
        willSet { objectWillChange.send() }
    }
    @AppStorage("longBreakDurationMinutes") var longBreakDurationMinutes: Int = 20 {
        willSet { objectWillChange.send() }
    }
    @AppStorage("cyclesBeforeLongBreak") var cyclesBeforeLongBreak: Int = 4 {
        willSet { objectWillChange.send() }
    }

    // MARK: Behavior

    @AppStorage("autoStartNextSession") var autoStartNextSession: Bool = true {
        willSet { objectWillChange.send() }
    }
    /// Seconds given to the user to cancel/adjust before auto-starting the next session.
    @AppStorage("autoStartGraceSeconds") var autoStartGraceSeconds: Int = 8 {
        willSet { objectWillChange.send() }
    }

    // MARK: Feedback

    @AppStorage("soundEnabled") var soundEnabled: Bool = true {
        willSet { objectWillChange.send() }
    }
    @AppStorage("hapticsEnabled") var hapticsEnabled: Bool = true {
        willSet { objectWillChange.send() }
    }
    @AppStorage("notificationsEnabled") var notificationsEnabled: Bool = true {
        willSet { objectWillChange.send() }
    }

    func duration(for session: SessionType) -> TimeInterval {
        switch session {
        case .focus: return TimeInterval(focusDurationMinutes * 60)
        case .shortBreak: return TimeInterval(shortBreakDurationMinutes * 60)
        case .longBreak: return TimeInterval(longBreakDurationMinutes * 60)
        }
    }

    private init() {}
}
