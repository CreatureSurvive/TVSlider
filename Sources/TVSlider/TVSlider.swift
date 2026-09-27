import SwiftUI

/// A slider that works on every platform, including tvOS where SwiftUI has no `Slider`.
///
/// On tvOS the control is focusable. Left/right presses step the value (and
/// accelerate when repeated), and swiping on the Siri Remote's touch surface
/// scrubs continuously. On other platforms it renders a native `Slider`.
///
/// ```swift
/// TVSlider(value: $subtitleScale, in: 0.5...2, step: 0.1) {
///     Text("Subtitle Size")
/// } valueLabel: {
///     Text(subtitleScale, format: .percent)
/// }
/// ```
public struct TVSlider<Label: View, ValueLabel: View>: View {
    @Binding private var value: Double
    private let range: ClosedRange<Double>
    private let step: Double?
    private let label: Label
    private let valueLabel: ValueLabel
    private let onEditingChanged: (Bool) -> Void

    public init(
        value: Binding<Double>,
        in range: ClosedRange<Double> = 0...1,
        step: Double? = nil,
        onEditingChanged: @escaping (Bool) -> Void = { _ in },
        @ViewBuilder label: () -> Label,
        @ViewBuilder valueLabel: () -> ValueLabel
    ) {
        _value = value
        self.range = range
        self.step = step
        self.onEditingChanged = onEditingChanged
        self.label = label()
        self.valueLabel = valueLabel()
    }

    public var body: some View {
        #if os(tvOS)
        FocusSliderBody(
            value: $value,
            model: SliderModel(range: range, step: step),
            label: label,
            valueLabel: valueLabel,
            onEditingChanged: onEditingChanged
        )
        #else
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                label
                Spacer(minLength: 16)
                valueLabel.foregroundStyle(.secondary)
            }
            Group {
                if let step {
                    Slider(value: $value, in: range, step: step, onEditingChanged: onEditingChanged) { label }
                } else {
                    Slider(value: $value, in: range, onEditingChanged: onEditingChanged) { label }
                }
            }
            .labelsHidden()
        }
        #endif
    }
}

extension TVSlider where ValueLabel == EmptyView {
    public init(
        value: Binding<Double>,
        in range: ClosedRange<Double> = 0...1,
        step: Double? = nil,
        onEditingChanged: @escaping (Bool) -> Void = { _ in },
        @ViewBuilder label: () -> Label
    ) {
        self.init(value: value, in: range, step: step, onEditingChanged: onEditingChanged, label: label, valueLabel: { EmptyView() })
    }
}

extension TVSlider where Label == Text, ValueLabel == EmptyView {
    public init(_ title: some StringProtocol, value: Binding<Double>, in range: ClosedRange<Double> = 0...1, step: Double? = nil) {
        self.init(value: value, in: range, step: step, label: { Text(title) }, valueLabel: { EmptyView() })
    }
}

/// Visual configuration for ``TVSlider`` on tvOS.
public struct TVSliderStyle: Sendable {
    public var trackHeight: CGFloat = 10
    public var thumbDiameter: CGFloat = 28
    public var focusedScale: CGFloat = 1.04
    public var cornerRadius: CGFloat = 20
    public var padding = EdgeInsets(top: 20, leading: 28, bottom: 24, trailing: 28)

    public init() {}
}

extension EnvironmentValues {
    @Entry public var tvSliderStyle = TVSliderStyle()
}

extension View {
    /// Customizes the appearance of ``TVSlider`` and ``TVStepper`` on tvOS.
    public func tvSliderStyle(_ style: TVSliderStyle) -> some View {
        environment(\.tvSliderStyle, style)
    }
}

#if os(tvOS)
/// The raised background of a focused control: white in light mode and a
/// lighter gray in dark mode, like the system's focused rows.
struct FocusPlatter: View {
    let isFocused: Bool
    let cornerRadius: CGFloat
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(isFocused ? (colorScheme == .dark ? Color.white.opacity(0.16) : .white) : .clear)
            .shadow(color: .black.opacity(isFocused ? (colorScheme == .dark ? 0.45 : 0.18) : 0), radius: 16, y: 8)
    }
}

struct FocusSliderBody<Label: View, ValueLabel: View>: View {
    @Binding var value: Double
    @State var model: SliderModel
    let label: Label
    let valueLabel: ValueLabel
    let onEditingChanged: (Bool) -> Void

    @FocusState private var isFocused: Bool
    @State private var scrubStartValue: Double?
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.tvSliderStyle) private var style

    init(value: Binding<Double>, model: SliderModel, label: Label, valueLabel: ValueLabel, onEditingChanged: @escaping (Bool) -> Void) {
        _value = value
        _model = State(initialValue: model)
        self.label = label
        self.valueLabel = valueLabel
        self.onEditingChanged = onEditingChanged
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                label
                Spacer(minLength: 24)
                valueLabel.foregroundStyle(.secondary)
            }
            track
        }
        .padding(style.padding)
        .background { FocusPlatter(isFocused: isFocused, cornerRadius: style.cornerRadius) }
        .scaleEffect(isFocused ? style.focusedScale : 1)
        .animation(.spring(duration: 0.25), value: isFocused)
        .opacity(isEnabled ? 1 : 0.5)
        .focusable(isEnabled)
        .focused($isFocused)
        .onMoveCommand { direction in
            switch direction {
            case .left: press(-1)
            case .right: press(1)
            default: break
            }
        }
        .onChange(of: isFocused) { _, focused in
            if !focused { model.resetAcceleration() }
        }
        .background {
            RemoteScrubGesture(isActive: isFocused && isEnabled) { phase, translation in
                handleScrub(phase, translation)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue(Text(model.fraction(of: value), format: .percent.precision(.fractionLength(0))))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: press(1)
            case .decrement: press(-1)
            @unknown default: break
            }
        }
    }

    private var track: some View {
        GeometryReader { geometry in
            let fraction = model.fraction(of: value)
            let width = geometry.size.width
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.primary.opacity(0.18))
                    .frame(height: style.trackHeight)
                Capsule()
                    .fill(isFocused ? AnyShapeStyle(.tint) : AnyShapeStyle(Color.primary.opacity(0.55)))
                    .frame(width: max(style.trackHeight, width * fraction), height: style.trackHeight)
                Circle()
                    .fill(.white)
                    .frame(width: style.thumbDiameter, height: style.thumbDiameter)
                    .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                    .scaleEffect(scrubStartValue != nil ? 1.25 : 1)
                    .offset(x: (width - style.thumbDiameter) * fraction)
                    .opacity(isFocused ? 1 : 0)
            }
            .frame(height: geometry.size.height)
            .animation(.interactiveSpring(duration: 0.15), value: fraction)
        }
        .frame(height: style.thumbDiameter)
    }

    private func press(_ direction: Int) {
        let newValue = model.press(direction, from: value, at: ProcessInfo.processInfo.systemUptime)
        guard newValue != value else { return }
        onEditingChanged(true)
        value = newValue
        onEditingChanged(false)
    }

    private func handleScrub(_ phase: RemoteScrubGesture.Phase, _ translation: Double) {
        switch phase {
        case .began:
            scrubStartValue = value
            onEditingChanged(true)
        case .changed:
            guard let start = scrubStartValue else { return }
            value = model.scrub(from: start, translation: translation)
        case .ended:
            guard scrubStartValue != nil else { return }
            scrubStartValue = nil
            onEditingChanged(false)
        }
    }
}
#endif
