import SwiftUI
import TVSlider

@main
struct DemoApp: App {
    var body: some Scene {
        WindowGroup {
            if ProcessInfo.processInfo.arguments.contains("-showcase") { ShowcaseView() } else { DemoView() }
        }
    }
}

struct DemoView: View {
    @State private var volume = 0.5
    @State private var subtitleScale = 1.0
    @State private var delay = 0.0
    @State private var editing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 40) {
            Text("TVSlider Demo").font(.title2)
            Button("Top Button") {}
            TVSlider(value: $volume, in: 0...1, onEditingChanged: { editing = $0 }) {
                Text("Volume")
            } valueLabel: {
                Text(volume, format: .percent.precision(.fractionLength(0)))
            }
            .accessibilityIdentifier("volumeSlider")
            TVSlider(value: $subtitleScale, in: 0.5...2, step: 0.25) {
                Text("Subtitle Size")
            } valueLabel: {
                Text(subtitleScale, format: .number.precision(.fractionLength(2)))
            }
            .accessibilityIdentifier("subtitleSlider")
            TVStepper("Subtitle Delay", value: $delay, in: -5...5, step: 0.5)
                .accessibilityIdentifier("delayStepper")
            Text("volume=\(volume, format: .number.precision(.fractionLength(2))) scale=\(subtitleScale, format: .number.precision(.fractionLength(2))) delay=\(delay, format: .number.precision(.fractionLength(1)))")
                .accessibilityIdentifier("readout")
        }
        .padding(80)
        .frame(maxWidth: 1200)
    }
}
