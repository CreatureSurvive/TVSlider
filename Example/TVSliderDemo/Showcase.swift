import SwiftUI
import TVSlider

/// A player settings screen for the README screenshots (`-showcase`).
struct ShowcaseView: View {
    @State private var volume = 0.65
    @State private var dialogue = 0.3
    @State private var subtitleSize = 1.25
    @State private var delay = -0.5
    private let light = ProcessInfo.processInfo.arguments.contains("-light")

    var body: some View {
        HStack(alignment: .top, spacing: 80) {
            VStack(alignment: .leading, spacing: 20) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 80))
                    .foregroundStyle(.tint)
                Text("Audio & Subtitles").font(.largeTitle.bold())
                Text("Northern Lights · S2 E4").foregroundStyle(.secondary)
            }
            .frame(width: 520, alignment: .leading)

            VStack(alignment: .leading, spacing: 44) {
                TVSlider(value: $volume, in: 0...1) {
                    Label("Volume", systemImage: "speaker.wave.2.fill")
                } valueLabel: {
                    Text(volume, format: .percent.precision(.fractionLength(0)))
                }
                .accessibilityIdentifier("volume")
                TVSlider(value: $dialogue, in: 0...1, step: 0.1) {
                    Label("Dialogue Boost", systemImage: "person.wave.2.fill")
                } valueLabel: {
                    Text(dialogue, format: .percent.precision(.fractionLength(0)))
                }
                TVSlider(value: $subtitleSize, in: 0.5...2, step: 0.25) {
                    Label("Subtitle Size", systemImage: "textformat.size")
                } valueLabel: {
                    Text("\(subtitleSize, format: .number.precision(.fractionLength(2)))×")
                }
                TVStepper(value: $delay, in: -5...5, step: 0.5, format: .number.precision(.fractionLength(1))) {
                    Label("Subtitle Delay (s)", systemImage: "clock.arrow.2.circlepath")
                }
                .accessibilityIdentifier("delay")
            }
            .frame(width: 1000)
        }
        .padding(100)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(light ? Color(white: 0.92) : Color(white: 0.06))
        .tint(.orange)
        .preferredColorScheme(light ? .light : .dark)
    }
}
