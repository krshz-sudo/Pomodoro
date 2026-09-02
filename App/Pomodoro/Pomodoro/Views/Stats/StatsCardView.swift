import SwiftUI

struct StatsCardView: View {
    let title: String
    let value: String
    let symbolName: String
    var tint: Color = .accentColor

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbolName)
                .font(.title3)
                .foregroundStyle(tint)

            Text(value)
                .font(.title2.bold())
                .monospacedDigit()
                .contentTransition(.numericText())

            Text(title)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

#Preview {
    StatsCardView(title: "Today's Focus", value: "1h 45m", symbolName: "clock.fill")
        .padding()
}
