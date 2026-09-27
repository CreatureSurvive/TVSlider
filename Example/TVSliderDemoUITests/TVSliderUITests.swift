import XCTest

/// Drives the demo with the Siri Remote and checks the bound values.
final class TVSliderUITests: XCTestCase {
    @MainActor
    func testRemoteControlsSlidersAndStepper() throws {
        let app = XCUIApplication()
        app.launch()
        let remote = XCUIRemote.shared
        let readout = app.staticTexts["readout"]
        XCTAssertTrue(readout.waitForExistence(timeout: 10))
        XCTAssertEqual(readout.label, "volume=0.50 scale=1.00 delay=0.0")

        // Focus starts on the top button; move down to the volume slider.
        remote.press(.down)
        XCTAssertTrue(app.descendants(matching: .any)["volumeSlider"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.descendants(matching: .any)["volumeSlider"].hasFocus, "Volume slider should take focus")

        remote.press(.right)
        sleep(1)
        XCTAssertEqual(readout.label, "volume=0.55 scale=1.00 delay=0.0")
        remote.press(.left)
        sleep(1)
        remote.press(.left)
        sleep(1)
        XCTAssertEqual(readout.label, "volume=0.45 scale=1.00 delay=0.0")

        // Stepped slider snaps to 0.25 increments.
        remote.press(.down)
        XCTAssertTrue(app.descendants(matching: .any)["subtitleSlider"].hasFocus)
        remote.press(.right)
        sleep(1)
        XCTAssertEqual(readout.label, "volume=0.45 scale=1.25 delay=0.0")

        // Stepper: exactly one step per press, clamped to the range.
        remote.press(.down)
        XCTAssertTrue(app.descendants(matching: .any)["delayStepper"].hasFocus)
        remote.press(.left)
        sleep(1)
        XCTAssertEqual(readout.label, "volume=0.45 scale=1.25 delay=-0.5")

        // Up/down still move focus normally.
        remote.press(.up)
        XCTAssertTrue(app.descendants(matching: .any)["subtitleSlider"].hasFocus)
    }
}
