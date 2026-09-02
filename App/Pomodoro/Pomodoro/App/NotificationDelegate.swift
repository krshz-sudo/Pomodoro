import UserNotifications

/// Registers the "Start Break" / "Skip" actionable notification buttons described
/// in the spec, and routes taps back into the app. The engine itself is reached
/// via NotificationCenter since UNUserNotificationCenterDelegate isn't a SwiftUI
/// environment object.
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    static let startBreakActionID = "START_BREAK_ACTION"
    static let skipActionID = "SKIP_ACTION"

    func registerCategories() {
        let startBreak = UNNotificationAction(
            identifier: Self.startBreakActionID,
            title: "Start Break",
            options: [.foreground]
        )
        let skip = UNNotificationAction(
            identifier: Self.skipActionID,
            title: "Skip",
            options: []
        )

        let breakCategory = UNNotificationCategory(
            identifier: "SESSION_END_BREAK",
            actions: [startBreak, skip],
            intentIdentifiers: [],
            options: []
        )
        let focusCategory = UNNotificationCategory(
            identifier: "SESSION_END_FOCUS",
            actions: [
                UNNotificationAction(identifier: Self.startBreakActionID, title: "Start Focus", options: [.foreground]),
                skip
            ],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([breakCategory, focusCategory])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        switch response.actionIdentifier {
        case Self.startBreakActionID:
            NotificationCenter.default.post(name: .pomodoroStartNextSession, object: nil)
        case Self.skipActionID:
            NotificationCenter.default.post(name: .pomodoroSkipNextSession, object: nil)
        default:
            break
        }
        completionHandler()
    }

    /// Show banners even while the app is in the foreground.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .list])
    }
}

extension Foundation.Notification.Name {
    static let pomodoroStartNextSession = Foundation.Notification.Name("pomodoroStartNextSession")
    static let pomodoroSkipNextSession = Foundation.Notification.Name("pomodoroSkipNextSession")
}
