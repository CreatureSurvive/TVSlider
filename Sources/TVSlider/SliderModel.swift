import Foundation

/// The value logic shared by ``TVSlider`` and ``TVStepper``: clamping, step
/// snapping, D-pad acceleration and touch-surface scrubbing.
///
/// It is a plain value type so it can be unit tested and reused by custom controls.
public struct SliderModel: Sendable, Equatable {
    public var range: ClosedRange<Double>
    /// Snap increment; `nil` for continuous values.
    public var step: Double?
    /// Base amount a single D-pad press moves the value.
    public var pressIncrement: Double
    /// Presses closer together than this count as a repeat and accelerate.
    public var repeatInterval: TimeInterval = 0.35
    /// Multiplier ramp for held/repeated presses.
    public var accelerationCurve: [Double] = [1, 1, 1, 2, 2, 4, 4, 8]
    /// Fraction of the full range traversed by one full-width swipe on the touch surface.
    public var touchSensitivity: Double = 1

    private var lastPress: (direction: Int, time: TimeInterval, count: Int)?

    public init(range: ClosedRange<Double>, step: Double? = nil, pressIncrement: Double? = nil) {
        precondition(range.upperBound >= range.lowerBound, "Invalid range")
        self.range = range
        self.step = step.flatMap { $0 > 0 ? $0 : nil }
        let span = range.upperBound - range.lowerBound
        self.pressIncrement = pressIncrement ?? self.step ?? (span > 0 ? span / 20 : 1)
    }

    public static func == (lhs: SliderModel, rhs: SliderModel) -> Bool {
        lhs.range == rhs.range && lhs.step == rhs.step && lhs.pressIncrement == rhs.pressIncrement
            && lhs.repeatInterval == rhs.repeatInterval && lhs.accelerationCurve == rhs.accelerationCurve
            && lhs.touchSensitivity == rhs.touchSensitivity
    }

    /// Clamps to the range and snaps to the step (anchored at the lower bound).
    public func normalize(_ value: Double) -> Double {
        guard value.isFinite else { return range.lowerBound }
        var result = min(max(value, range.lowerBound), range.upperBound)
        if let step {
            let steps = ((result - range.lowerBound) / step).rounded()
            result = min(range.upperBound, range.lowerBound + steps * step)
        }
        return result
    }

    /// Position of `value` in 0…1.
    public func fraction(of value: Double) -> Double {
        let span = range.upperBound - range.lowerBound
        guard span > 0 else { return 0 }
        return min(1, max(0, (normalize(value) - range.lowerBound) / span))
    }

    /// The value at a 0…1 position.
    public func value(atFraction fraction: Double) -> Double {
        normalize(range.lowerBound + min(1, max(0, fraction)) * (range.upperBound - range.lowerBound))
    }

    /// Applies a D-pad press (`direction` is -1 or +1) at time `now`,
    /// accelerating when presses repeat quickly in the same direction.
    public mutating func press(_ direction: Int, from value: Double, at now: TimeInterval) -> Double {
        let direction = direction < 0 ? -1 : 1
        var count = 0
        if let last = lastPress, last.direction == direction, now - last.time <= repeatInterval {
            count = last.count + 1
        }
        lastPress = (direction, now, count)
        let multiplier = accelerationCurve.isEmpty ? 1 : accelerationCurve[min(count, accelerationCurve.count - 1)]
        var delta = pressIncrement * multiplier
        // Always move at least one step so presses are never swallowed by snapping.
        if let step { delta = max(step, (delta / step).rounded() * step) }
        return normalize(value + Double(direction) * delta)
    }

    /// Forgets press history (e.g. when focus leaves the control).
    public mutating func resetAcceleration() {
        lastPress = nil
    }

    /// The value after a horizontal touch-surface pan, given the value when
    /// the pan began and the translation as a fraction of the surface width.
    public func scrub(from startValue: Double, translation: Double) -> Double {
        let span = range.upperBound - range.lowerBound
        return normalize(startValue + translation * span * touchSensitivity)
    }
}
