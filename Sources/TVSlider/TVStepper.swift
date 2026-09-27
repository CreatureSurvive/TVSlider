import SwiftUI

/// A stepper that works on every platform, including tvOS where SwiftUI has no `Stepper`.
///
/// On tvOS the row is focusable and left/right presses change the value.
/// On other platforms it renders a native `Stepper`.
public struct TVStepper<Label: View>: View {
    @Binding private var value: Double
    private let range: ClosedRange<Double>
    private let step: Double
    private let format: FloatingPointFormatStyle<Double>
    private let label: Label

    public init(
        value: Binding<Double>,
        in range: ClosedRange<Double>,
        step: Double = 1,
        format: FloatingPointFormatStyle<Double> = .number,
        @ViewBuilder label: () -> Label
    ) {
        _value = value
        self.range = range
        self.step = step
        self.format = format
        self.label = label()
    }

    public var body: some View {
        #if os(tvOS)
        FocusStepperBody(value: $value, model: SliderModel(range: range, step: step), format: format, label: label)
        #else
        Stepper(value: $value, in: range, step: step) {
            HStack {
                label
                Spacer()
                Text(value, format: format).foregroundStyle(.secondary)
            }
        }
        #endif
    }
}

extension TVStepper where Label == Text {
    public init(_ title: some StringProtocol, value: Binding<Double>, in range: ClosedRange<Double>, step: Double = 1, format: FloatingPointFormatStyle<Double> = .number) {
        self.init(value: value, in: range, step: step, format: format) { Text(title) }
    }
}

#if os(tvOS)
struct FocusStepperBody<Label: View>: View {
    @Binding var value: Double
    @State var model: SliderModel
    let format: FloatingPointFormatStyle<Double>
    let label: Label

    @FocusState private var isFocused: Bool
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.tvSliderStyle) private var style

    init(value: Binding<Double>, model: SliderModel, format: FloatingPointFormatStyle<Double>, label: Label) {
        _value = value
        var model = model
        model.accelerationCurve = [1] // steppers move exactly one step per press
        _model = State(initialValue: model)
        self.format = format
        self.label = label
    }

    var body: some View {
        HStack(spacing: 20) {
            label
            Spacer(minLength: 24)
            Image(systemName: "chevron.left")
                .opacity(value > model.range.lowerBound ? 1 : 0.25)
            Text(value, format: format)
                .monospacedDigit()
                .frame(minWidth: 80)
            Image(systemName: "chevron.right")
                .opacity(value < model.range.upperBound ? 1 : 0.25)
        }
        .padding(style.padding)
        .background {
            RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous)
                .fill(isFocused ? AnyShapeStyle(.regularMaterial) : AnyShapeStyle(.clear))
                .shadow(color: .black.opacity(isFocused ? 0.25 : 0), radius: 16, y: 8)
        }
        .scaleEffect(isFocused ? style.focusedScale : 1)
        .animation(.spring(duration: 0.25), value: isFocused)
        .opacity(isEnabled ? 1 : 0.5)
        .focusable(isEnabled)
        .focused($isFocused)
        .onMoveCommand { direction in
            switch direction {
            case .left: value = model.press(-1, from: value, at: ProcessInfo.processInfo.systemUptime)
            case .right: value = model.press(1, from: value, at: ProcessInfo.processInfo.systemUptime)
            default: break
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue(Text(value, format: format))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: value = model.press(1, from: value, at: ProcessInfo.processInfo.systemUptime)
            case .decrement: value = model.press(-1, from: value, at: ProcessInfo.processInfo.systemUptime)
            @unknown default: break
            }
        }
    }
}
#endif
