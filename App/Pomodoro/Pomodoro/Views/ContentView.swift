import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var engine: PomodoroTimerEngine

    var body: some View {
        TabView {
            TimerView()
                .tabItem { Label("Timer", systemImage: "timer") }

            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .onReceive(NotificationCenter.default.publisher(for: .pomodoroStartNextSession)) { _ in
            engine.start()
        }
        .onReceive(NotificationCenter.default.publisher(for: .pomodoroSkipNextSession)) { _ in
            engine.skipToNext()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(PomodoroSettings.shared)
        .environmentObject(PomodoroTimerEngine())
}
