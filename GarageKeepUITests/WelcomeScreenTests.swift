import XCTest

final class WelcomeScreenTests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        // Launch with no stored token so WelcomeView is shown
        app.launchArguments = ["--uitesting", "--clear-keychain"]
        app.launch()
    }

    func testWelcomeScreen_showsExpectedElements() {
        XCTAssertTrue(app.staticTexts["GarageKeep"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["btn_get_started"].exists)
        XCTAssertTrue(app.buttons["btn_log_in"].exists)
    }

    func testGetStarted_navigatesToSignUpScreen() {
        app.buttons["btn_get_started"].tap()
        XCTAssertTrue(app.staticTexts["Join GarageKeep"].waitForExistence(timeout: 3))
    }

    func testLogIn_navigatesToLoginScreen() {
        app.buttons["btn_log_in"].tap()
        XCTAssertTrue(app.staticTexts["Welcome back to\nGarageKeep"].waitForExistence(timeout: 3))
    }
}
