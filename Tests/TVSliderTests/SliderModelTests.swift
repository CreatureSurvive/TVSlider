import Testing
@testable import TVSlider

@Suite("SliderModel")
struct SliderModelTests {
    @Test func clampsAndSnaps() {
        let model = SliderModel(range: 0...10, step: 0.5)
        #expect(model.normalize(-3) == 0)
        #expect(model.normalize(12) == 10)
        #expect(model.normalize(3.3) == 3.5)
        #expect(model.normalize(3.2) == 3)
        #expect(model.normalize(.nan) == 0)
        #expect(model.normalize(.infinity) == 0)

        // Steps are anchored at the lower bound.
        let offset = SliderModel(range: 1...2, step: 0.3)
        #expect(abs(offset.normalize(1.5) - 1.6) < 1e-9)
        #expect(offset.normalize(2) == 1.9 || abs(offset.normalize(2) - 1.9) < 1e-9)
    }

    @Test func convertsFractions() {
        let model = SliderModel(range: 10...20)
        #expect(model.fraction(of: 15) == 0.5)
        #expect(model.fraction(of: 30) == 1)
        #expect(model.value(atFraction: 0.25) == 12.5)
        #expect(model.value(atFraction: -1) == 10)
        #expect(SliderModel(range: 5...5).fraction(of: 5) == 0)
    }

    @Test func pressesStepAndClamp() {
        var model = SliderModel(range: 0...1)
        #expect(model.pressIncrement == 0.05)
        var value = 0.0
        value = model.press(1, from: value, at: 0)
        #expect(abs(value - 0.05) < 1e-9)
        value = model.press(-1, from: value, at: 10)
        value = model.press(-1, from: value, at: 20)
        #expect(value == 0)
    }

    @Test func acceleratesOnRapidRepeatsOnly() {
        var model = SliderModel(range: 0...1000, step: 1)
        model.accelerationCurve = [1, 2, 4]
        var value = 0.0
        var time = 0.0
        var deltas: [Double] = []
        for _ in 0..<5 {
            let next = model.press(1, from: value, at: time)
            deltas.append(next - value)
            value = next
            time += 0.1
        }
        #expect(deltas == [1, 2, 4, 4, 4])

        // A pause resets acceleration.
        let slow = model.press(1, from: value, at: time + 5) - value
        #expect(slow == 1)

        // Reversing direction resets acceleration.
        value += slow
        _ = model.press(1, from: value, at: time + 5.1)
        let reversed = model.press(-1, from: value, at: time + 5.2) - value
        #expect(reversed == -1)
    }

    @Test func pressAlwaysMovesAtLeastOneStep() {
        var model = SliderModel(range: 0...10, step: 2, pressIncrement: 0.1)
        #expect(model.press(1, from: 4, at: 0) == 6)
    }

    @Test func scrubsRelativeToStart() {
        var model = SliderModel(range: 0...100, step: 1)
        #expect(model.scrub(from: 50, translation: 0.25) == 75)
        #expect(model.scrub(from: 50, translation: -1) == 0)
        model.touchSensitivity = 0.5
        #expect(model.scrub(from: 50, translation: 0.2) == 60)
    }
}
