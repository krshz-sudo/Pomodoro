import SwiftUI
import Combine
import UIKit
import UserNotifications
import SwiftData
#if canImport(ActivityKit)
import ActivityKit
#endif

/// Drives the Pomodoro state machine (idle -> running -> paused -> break -> longBreak),
/// keeps accurate time by comparing `Date` values rather than relying on tick counting
/// (so time stays correct even after the app is backgrounded/suspended), and coordinates
/// haptics, sound, local notifications, and the Live Activity.
@MainActor
final class PomodoroTimerEngine: ObservableObject {

    // MARK: Published state

    @Published private(set) var state: TimerState = .idle
    @Published private(set) var currentSession: SessionType = .focus
    @Published private(set) var timeRemaining: TimeInterval = 0
    @Published private(set) var completedCyclesToday: Int = 0
    @Published private(set) var confirmationSecondsRemaining: Int = 0

    /// Progress from 0 (just started) to 1 (finished), for the ring view.
    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return 1 - (timeRemaining / totalDuration)
    }

    // MARK: Dependencies

    private let settings: PomodoroSettings
    private var modelContext: ModelContext?

    // MARK: Internal timing state

    private var totalDuration: TimeInterval = 0
    private var sessionEndDate: Date?
    private var pausedRemaining: TimeInterval?
    private var cyclesCompletedSinceLongBreak: Int = 0

    private var tickTimer: AnyCancellable?
    private var confirmationTimer: AnyCancellable?

    #if canImport(ActivityKit)
    private var currentActivity: Activity<PomodoroActivityAttributes>?
    #endif

    init(settings: PomodoroSettings = .shared) {
        self.settings = settings
        self.currentSession = .focus
        self.totalDuration = settings.duration(for: .focus)
        self.timeRemaining = totalDuration

        NotificationCenter.default.addObserver(
            self, selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification, object: nil
        )
    }

    func attachModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // MARK: Public controls

    func start() {
        switch state {
        case .idle, .paused:
            beginCountingDown()
        case .awaitingConfirmation(let next):
            cancelConfirmationCountdown()
            beginSession(next)
        default:
            break
        }
    }

    func pause() {
        guard state == .running, let endDate = sessionEndDate else { return }
        pausedRemaining = max(0, endDate.timeIntervalSinceNow)
        sessionEndDate = nil
        tickTimer?.cancel()
        state = .paused
        updateLiveActivity()
    }

    func reset() {
        tickTimer?.cancel()
        cancelConfirmationCountdown()
        currentSession = .focus
        totalDuration = settings.duration(for: .focus)
        timeRemaining = totalDuration
        sessionEndDate = nil
        pausedRemaining = nil
        state = .idle
        endLiveActivity()
    }

    /// Skips the current confirmation window and jumps straight into the next session.
    func skipToNext() {
        if case .awaitingConfirmation(let next) = state {
            cancelConfirmationCountdown()
            beginSession(next)
        }
    }

    /// Cancels an in-progress auto-start confirmation, returning to idle with the
    /// upcoming session pre-loaded but not started.
    func cancelAutoStart() {
        guard case .awaitingConfirmation(let next) = state else { return }
        cancelConfirmationCountdown()
        currentSession = next
        totalDuration = settings.duration(for: next)
        timeRemaining = totalDuration
        state = .idle
    }

    // MARK: Session lifecycle

    private func beginCountingDown() {
        if let remaining = pausedRemaining {
            sessionEndDate = Date().addingTimeInterval(remaining)
            pausedRemaining = nil
        } else {
            totalDuration = settings.duration(for: currentSession)
            timeRemaining = totalDuration
            sessionEndDate = Date().addingTimeInterval(totalDuration)
        }
        state = .running
        fireHaptic(.impactMedium)
        startTicking()
        startLiveActivity()
    }

    private func startTicking() {
        tickTimer?.cancel()
        tickTimer = Timer.publish(every: 0.2, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }

    private func tick() {
        guard let endDate = sessionEndDate else { return }
        let remaining = endDate.timeIntervalSinceNow
        if remaining <= 0 {
            timeRemaining = 0
            completeCurrentSession()
        } else {
            timeRemaining = remaining
            // Live Activity is date-driven, so it self-updates on the Lock Screen;
            // we still refresh periodically to reflect settings/progress changes.
        }
    }

    private func completeCurrentSession() {
        tickTimer?.cancel()
        sessionEndDate = nil
        recordCompletion(of: currentSession)
        fireHaptic(.notificationSuccess)
        playCompletionSound()
        scheduleCompletionNotification(for: currentSession)

        let next = nextSession(after: currentSession)

        if currentSession == .focus {
            cyclesCompletedSinceLongBreak += 1
            completedCyclesToday += 1
        }

        if settings.autoStartNextSession {
            beginAutoStartConfirmation(next: next)
        } else {
            currentSession = next
            totalDuration = settings.duration(for: next)
            timeRemaining = totalDuration
            state = .idle
            endLiveActivity()
        }
    }

    private func nextSession(after session: SessionType) -> SessionType {
        switch session {
        case .focus:
            return cyclesCompletedSinceLongBreak + 1 >= settings.cyclesBeforeLongBreak
                ? .longBreak : .shortBreak
        case .shortBreak, .longBreak:
            if session == .longBreak { cyclesCompletedSinceLongBreak = 0 }
            return .focus
        }
    }

    private func beginAutoStartConfirmation(next: SessionType) {
        state = .awaitingConfirmation(next: next)
        confirmationSecondsRemaining = settings.autoStartGraceSeconds
        confirmationTimer?.cancel()
        confirmationTimer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                self.confirmationSecondsRemaining -= 1
                if self.confirmationSecondsRemaining <= 0 {
                    self.cancelConfirmationCountdown()
                    self.beginSession(next)
                }
            }
    }

    private func cancelConfirmationCountdown() {
        confirmationTimer?.cancel()
        confirmationTimer = nil
    }

    private func beginSession(_ session: SessionType) {
        currentSession = session
        totalDuration = settings.duration(for: session)
        timeRemaining = totalDuration
        beginCountingDown()
    }

    // MARK: Persistence

    private func recordCompletion(of session: SessionType) {
        guard let modelContext else { return }
        let record = SessionRecord(
            sessionType: session,
            durationSeconds: Int(totalDuration),
            completed: true
        )
        modelContext.insert(record)
        try? modelContext.save()
    }

    // MARK: Feedback

    private enum HapticKind { case impactMedium, notificationSuccess }

    private func fireHaptic(_ kind: HapticKind) {
        guard settings.hapticsEnabled else { return }
        switch kind {
        case .impactMedium:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .notificationSuccess:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    private func playCompletionSound() {
        guard settings.soundEnabled else { return }
        // Respects the device's silent-mode switch automatically because
        // AudioServicesPlaySystemSound (or AVAudioPlayer with .ambient category)
        // is silenced by the ringer switch, unlike .playback category audio.
        AudioFeedbackPlayer.shared.playCompletionSound()
    }

    private func scheduleCompletionNotification(for session: SessionType) {
        guard settings.notificationsEnabled else { return }
        let content = UNMutableNotificationContent()
        switch session {
        case .focus:
            content.title = "Focus session complete"
            content.body = "Nice work. Time for a break."
            content.categoryIdentifier = "SESSION_END_BREAK"
        case .shortBreak, .longBreak:
            content.title = "Break's over"
            content.body = "Ready to focus again?"
            content.categoryIdentifier = "SESSION_END_FOCUS"
        }
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // fire immediately, since this is called at completion time
        )
        UNUserNotificationCenter.current().add(request)
    }

    @objc private func appDidBecomeActive() {
        // Re-sync timeRemaining against the wall clock in case the app was
        // suspended; sessionEndDate-based math means no drift correction is needed,
        // this just forces an immediate UI refresh.
        guard state == .running, let endDate = sessionEndDate else { return }
        let remaining = endDate.timeIntervalSinceNow
        timeRemaining = max(0, remaining)
        if remaining <= 0 {
            completeCurrentSession()
        }
    }

    // MARK: Live Activity

    private func startLiveActivity() {
        #if canImport(ActivityKit)
        guard ActivityAuthorizationInfo().areActivitiesEnabled, let endDate = sessionEndDate else { return }
        let attributes = PomodoroActivityAttributes(sessionTitle: currentSession.title)
        let state = PomodoroActivityAttributes.ContentState(
            sessionType: currentSession.rawValue,
            endDate: endDate,
            isPaused: false
        )
        do {
            if let currentActivity {
                Task { await currentActivity.update(ActivityContent(state: state, staleDate: nil)) }
            } else {
                currentActivity = try Activity.request(
                    attributes: attributes,
                    content: .init(state: state, staleDate: nil)
                )
            }
        } catch {
            print("Live Activity failed to start: \(error)")
        }
        #endif
    }

    private func updateLiveActivity() {
        #if canImport(ActivityKit)
        guard let currentActivity else { return }
        let state = PomodoroActivityAttributes.ContentState(
            sessionType: currentSession.rawValue,
            endDate: sessionEndDate ?? Date(),
            isPaused: self.state == .paused
        )
        Task { await currentActivity.update(ActivityContent(state: state, staleDate: nil)) }
        #endif
    }

    private func endLiveActivity() {
        #if canImport(ActivityKit)
        guard let currentActivity else { return }
        let endedContent: ActivityContent<PomodoroActivityAttributes.ContentState>? = nil
        Task { await currentActivity.end(endedContent, dismissalPolicy: .immediate) }
        self.currentActivity = nil
        #endif
    }
}
