import XCTest

final class TicTacToeIOSUITests: XCTestCase {
    func testAppLaunches() {
        let app = XCUIApplication()
        app.launch()
        // Basic sanity check: app is running.
        XCTAssertTrue(app.state == .runningForeground)
    }
}
