import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query(
        filter: SessionRecord.focusPredicate(),
        sort: \SessionRecord.date,
        order: .reverse
    ) private var focusSessions: [SessionRecord]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    HStack(spacing: 16) {
                        StatsCardView(
                            title: "Today's Focus",
                            value: formattedDuration(todaysFocusSeconds),
                            symbolName: "clock.fill"
                        )
                        StatsCardView(
                            title: "Day Streak",
                            value: "\(currentStreak)",
                            symbolName: "flame.fill",
                            tint: .orange
                        )
                    }
                    .padding(.horizontal)

                    weeklyChart
                        .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Stats")
        }
    }

    // MARK: Weekly chart

    private var weeklyChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.headline)

            Chart(weeklyData) { day in
                BarMark(
                    x: .value("Day", day.label),
                    y: .value("Minutes", day.minutes)
                )
                .foregroundStyle(Color.accentColor.gradient)
                .cornerRadius(6)
            }
            .frame(height: 200)
            .accessibilityLabel("Weekly focus minutes bar chart")
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private struct DayMinutes: Identifiable {
        let id = UUID()
        let label: String
        let minutes: Int
    }

    private var weeklyData: [DayMinutes] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"

        return (0..<7).reversed().map { offset in
            let day = calendar.date(byAdding: .day, value: -offset, to: today)!
            let seconds = focusSessions
                .filter { calendar.isDate($0.date, inSameDayAs: day) }
                .reduce(0) { $0 + $1.durationSeconds }
            return DayMinutes(label: formatter.string(from: day), minutes: seconds / 60)
        }
    }

    // MARK: Derived stats

    private var todaysFocusSeconds: Int {
        let calendar = Calendar.current
        return focusSessions
            .filter { calendar.isDateInToday($0.date) }
            .reduce(0) { $0 + $1.durationSeconds }
    }

    /// Consecutive days (ending today or yesterday) with at least one completed focus session.
    private var currentStreak: Int {
        let calendar = Calendar.current
        let daysWithSessions = Set(focusSessions.map { calendar.startOfDay(for: $0.date) })
        guard !daysWithSessions.isEmpty else { return 0 }

        var streak = 0
        var cursor = calendar.startOfDay(for: .now)

        // Allow the streak to still count if today has no session yet but yesterday does.
        if !daysWithSessions.contains(cursor) {
            cursor = calendar.date(byAdding: .day, value: -1, to: cursor)!
        }

        while daysWithSessions.contains(cursor) {
            streak += 1
            cursor = calendar.date(byAdding: .day, value: -1, to: cursor)!
        }
        return streak
    }

    private func formattedDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }
}

#Preview {
    StatsView()
        .modelContainer(for: SessionRecord.self, inMemory: true)
}
