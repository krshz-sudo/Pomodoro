import SwiftUI
import SwiftData
import UserNotifications

@main
struct PomodoroApp: App {

    @StateObject private var settings = PomodoroSettings.shared
    @StateObject private var engine = PomodoroTimerEngine()

    private let modelContainer: ModelContainer = {
        let schema = Schema([SessionRecord.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()

    init() {
        NotificationDelegate.shared.registerCategories()
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
                .environmentObject(engine)
                .task {
                    engine.attachModelContext(modelContainer.mainContext)
                    await requestNotificationPermission()
                }
        }
        .modelContainer(modelContainer)
    }

    private func requestNotificationPermission() async {
        try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
    }
}
