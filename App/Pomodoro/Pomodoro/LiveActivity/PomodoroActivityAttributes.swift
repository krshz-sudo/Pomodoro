import Foundation
#if canImport(ActivityKit)
import ActivityKit

/// Shared between the main app target and the Widget Extension target.
/// Add this file to BOTH targets' membership in Xcode (File Inspector ->
/// Target Membership) so ActivityKit types match on both sides.
struct PomodoroActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        /// Raw value of `SessionType` (focus / shortBreak / longBreak).
        var sessionType: String
        /// The wall-clock time the current session ends. Using a Date lets the
        /// Lock Screen/Dynamic Island countdown text tick down natively without
        /// the app needing to push per-second updates.
        var endDate: Date
        var isPaused: Bool
    }

    /// Static, non-changing data for the life of the Activity.
    var sessionTitle: String
}
#endif
