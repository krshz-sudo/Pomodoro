import WidgetKit
import SwiftUI

/// Optional home-screen widget. Belongs in the same Widget Extension target as
/// `PomodoroLiveActivity`. Reads the last-known timer state from a shared
/// App Group UserDefaults suite (configure "group.yourteam.pomodoro" in both
/// the app and widget target's Signing & Capabilities).
struct PomodoroWidgetEntry: TimelineEntry {
    let date: Date
    let sessionTitle: String
    let progress: Double
    let symbolName: String
}

struct PomodoroWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> PomodoroWidgetEntry {
        PomodoroWidgetEntry(date: .now, sessionTitle: "Focus", progress: 0.4, symbolName: "target")
    }

    func getSnapshot(in context: Context, completion: @escaping (PomodoroWidgetEntry) -> Void) {
        completion(readCurrentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PomodoroWidgetEntry>) -> Void) {
        let entry = readCurrentEntry()
        // Refresh every minute; the app also forces a reload on state changes
        // via WidgetCenter.shared.reloadAllTimelines().
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 1, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func readCurrentEntry() -> PomodoroWidgetEntry {
        let defaults = UserDefaults(suiteName: "group.yourteam.pomodoro")
        let title = defaults?.string(forKey: "sessionTitle") ?? "Focus"
        let progress = defaults?.double(forKey: "progress") ?? 0
        let symbol = defaults?.string(forKey: "symbolName") ?? "target"
        return PomodoroWidgetEntry(date: .now, sessionTitle: title, progress: progress, symbolName: symbol)
    }
}

struct PomodoroHomeScreenWidgetView: View {
    let entry: PomodoroWidgetEntry

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: entry.symbolName)
                .font(.title3)
            Text(entry.sessionTitle)
                .font(.caption.weight(.semibold))
            ProgressView(value: entry.progress)
                .progressViewStyle(.linear)
                .tint(.accentColor)
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct PomodoroHomeScreenWidget: Widget {
    let kind = "PomodoroHomeScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PomodoroWidgetProvider()) { entry in
            PomodoroHomeScreenWidgetView(entry: entry)
        }
        .configurationDisplayName("Pomodoro Progress")
        .description("Shows your current session and progress.")
        .supportedFamilies([.systemSmall])
    }
}
