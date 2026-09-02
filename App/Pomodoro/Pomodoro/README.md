# Pomodoro — SwiftUI iOS App

A native-feeling Pomodoro timer for iOS 17+, built with SwiftUI, SwiftData, Swift Charts, and ActivityKit.

## Project layout

```
PomodoroApp/
├── App/
│   ├── PomodoroApp.swift          # @main entry point, wires SwiftData + engine
│   └── NotificationDelegate.swift # Actionable notification buttons (Start Break / Skip)
├── Models/
│   ├── SessionType.swift          # SessionType enum + TimerState state machine
│   ├── PomodoroSettings.swift     # @AppStorage-backed settings (ObservableObject)
│   └── SessionRecord.swift        # @Model SwiftData entity for session history
├── ViewModels/
│   ├── PomodoroTimerEngine.swift  # Core state machine, Date-based countdown, Live Activity
│   └── AudioFeedbackPlayer.swift  # Completion chime (respects silent switch)
├── Views/
│   ├── ContentView.swift          # TabView root (Timer / Stats / Settings)
│   ├── Timer/
│   │   ├── TimerView.swift
│   │   ├── TimerRingView.swift    # Activity-ring style circular progress
│   │   └── SessionControlsView.swift
│   ├── Stats/
│   │   ├── StatsView.swift        # Today's focus time, streak, weekly Swift Charts bar chart
│   │   └── StatsCardView.swift
│   └── Settings/
│       └── SettingsView.swift     # Native Form for durations & toggles
├── LiveActivity/
│   ├── PomodoroActivityAttributes.swift   # Shared ActivityKit attributes (app + widget target)
│   ├── PomodoroLiveActivity.swift         # Lock Screen / Dynamic Island UI (Widget Extension target)
│   └── PomodoroHomeScreenWidget.swift     # Optional home-screen widget (Widget Extension target)
└── Resources/
    └── Info.plist              # Merge these keys into your generated Info.plist
```

## Building and running

1. **Create the Xcode project.** Open Xcode 15+, choose *App*, product name `Pomodoro`, interface **SwiftUI**, and set the deployment target to **iOS 17.0**. (This repo ships source files rather than a `.xcodeproj`, since project files are machine-generated and don't transfer reliably outside Xcode — dragging the folders below into a fresh project takes under a minute and avoids a corrupted project file.)
2. **Add the source files.** Drag the `App`, `Models`, `ViewModels`, `Views`, and `Resources` folders into your Xcode project (check "Copy items if needed" and add to the `Pomodoro` app target).
3. **Merge Info.plist keys.** Copy the keys from `Resources/Info.plist` into the Info.plist Xcode generated for you (or switch the target to use this file directly under *Build Settings → Packaging → Info.plist File*).
4. **Add the Live Activity / widget target.**
   - File → New → Target → **Widget Extension**. Name it `PomodoroWidgets`, and check **"Include Live Activity."**
   - Add `LiveActivity/PomodoroActivityAttributes.swift`, `PomodoroLiveActivity.swift`, and `PomodoroHomeScreenWidget.swift` to the new `PomodoroWidgets` target.
   - Also add `PomodoroActivityAttributes.swift` to the **main app target's** membership too (File Inspector → Target Membership), since both targets need the identical type.
   - If you keep the optional home-screen widget, create an **App Group** (e.g. `group.yourteam.pomodoro`) and enable it in both targets' *Signing & Capabilities*, then update the suite name in `PomodoroHomeScreenWidget.swift`.
5. **Enable capabilities** on the main app target: *Signing & Capabilities → + Capability → Push Notifications* is not required (notifications here are local-only), but do make sure *Background Modes → Audio* stays enabled to match the shipped Info.plist.
6. Build and run on a physical device or simulator running iOS 17+. On first launch you'll be prompted for notification permission.

## Where to adjust defaults

- **Default durations, cycles, and auto-start behavior:** `Models/PomodoroSettings.swift` — the `@AppStorage` default values in each property declaration (e.g. `focusDurationMinutes: Int = 25`). Users can also change these live in the Settings tab.
- **Long-break cadence logic:** `ViewModels/PomodoroTimerEngine.swift`, in `nextSession(after:)`.
- **Auto-start confirmation window length:** `autoStartGraceSeconds` in `PomodoroSettings.swift`.
- **Ring color per session type:** `SessionType.tintColor` in `Models/SessionType.swift`.
- **Completion sound:** `ViewModels/AudioFeedbackPlayer.swift` (swap the `SystemSoundID`, or replace with a bundled `.caf`/`.aiff` and `AVAudioPlayer` if you want a custom chime).

## Fixes applied in this version

Your project reported 2 errors / 2 warnings in Xcode. Root causes and fixes:

- **Build errors — `SessionType` wasn't `Equatable`.** `TimerState` (in `Models/SessionType.swift`) is declared `enum TimerState: Equatable` and has a case `awaitingConfirmation(next: SessionType)`. Swift can only auto-synthesize `Equatable` for an enum if every associated value is itself `Equatable` — and `SessionType` was only `String, Codable, CaseIterable`, not `Equatable`. That broke synthesis for `TimerState`, which then broke every `state == .running` / `state == .paused` comparison in `PomodoroTimerEngine.swift`. **Fix:** added `Equatable` to `SessionType`'s conformance list.
- **Warnings — deprecated ActivityKit calls.** `Activity.update(using:)` and `Activity.end(_:dismissalPolicy:)` taking a raw `ContentState` were deprecated in iOS 16.2 in favor of the `ActivityContent<ContentState>`-based overloads. **Fix:** `PomodoroTimerEngine.swift`'s `startLiveActivity()`, `updateLiveActivity()`, and `endLiveActivity()` now wrap state in `ActivityContent(...)` before calling `update`/`end`.

No other source changes were made — everything else in the original drop was valid Swift/SwiftUI/SwiftData/ActivityKit.

## Notes on accuracy & backgrounding

`PomodoroTimerEngine` never counts down by accumulating timer ticks. Instead, on `start()` it computes a `sessionEndDate = Date() + duration` and every tick just re-reads `endDate.timeIntervalSinceNow`. This means the countdown is correct even after the app is backgrounded, the process is suspended, or the device sleeps — there's no drift to correct for, because the remaining time is always derived fresh from the wall clock rather than accumulated.
