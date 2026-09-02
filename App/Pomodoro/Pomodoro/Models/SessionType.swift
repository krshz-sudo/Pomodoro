import SwiftUI

/// The type of session currently active in the Pomodoro cycle.
enum SessionType: String, Codable, CaseIterable, Equatable {
    case focus
    case shortBreak
    case longBreak

    var title: String {
        switch self {
        case .focus: return "Focus"
        case .shortBreak: return "Short Break"
        case .longBreak: return "Long Break"
        }
    }

    var symbolName: String {
        switch self {
        case .focus: return "target"
        case .shortBreak: return "cup.and.saucer.fill"
        case .longBreak: return "leaf.fill"
        }
    }

    var tintColor: Color {
        switch self {
        case .focus: return .accentColor
        case .shortBreak: return .teal
        case .longBreak: return .indigo
        }
    }
}

/// The state of the timer engine's internal state machine.
enum TimerState: Equatable {
    case idle
    case running
    case paused
    /// A brief confirmation window before the next session auto-starts.
    /// The associated value is the session that is about to begin.
    case awaitingConfirmation(next: SessionType)
    case completed
}
