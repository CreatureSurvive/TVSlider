import XCTest

/// Captures the README screenshots. Run with `Scripts/screenshots.sh`.
final class ScreenshotTests: XCTestCase {
    @MainActor
    func capture(_ name: String) {
        sleep(1) // let focus animations settle
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testSettings() {
        let app = XCUIApplication()
        app.launchArguments = ["-showcase"]
        app.launch()
        XCTAssertTrue(app.descendants(matching: .any)["volume"].waitForExistence(timeout: 10))
        XCUIRemote.shared.press(.right) // volume 65% → 70%
        capture("settings")
    }

    @MainActor
    func testSettingsLight() {
        let app = XCUIApplication()
        app.launchArguments = ["-showcase", "-light"]
        app.launch()
        XCTAssertTrue(app.descendants(matching: .any)["volume"].waitForExistence(timeout: 10))
        XCUIRemote.shared.press(.right)
        capture("settings-light")
    }
}
