import Foundation
import SwiftData

/// A single completed Pomodoro session, persisted with SwiftData.
/// Used to power the Stats tab (daily focus time, streaks, weekly chart).
@Model
final class SessionRecord {
    var id: UUID
    var date: Date
    var sessionTypeRaw: String
    var durationSeconds: Int
    var completed: Bool

    var sessionType: SessionType {
        get { SessionType(rawValue: sessionTypeRaw) ?? .focus }
        set { sessionTypeRaw = newValue.rawValue }
    }

    init(date: Date = .now, sessionType: SessionType, durationSeconds: Int, completed: Bool = true) {
        self.id = UUID()
        self.date = date
        self.sessionTypeRaw = sessionType.rawValue
        self.durationSeconds = durationSeconds
        self.completed = completed
    }
}

extension SessionRecord {
    /// Convenience: only completed focus sessions count toward Pomodoro stats.
    static func focusPredicate() -> Predicate<SessionRecord> {
        #Predicate<SessionRecord> { record in
            record.sessionTypeRaw == "focus" && record.completed == true
        }
    }
}
