import XCTest

final class LoginScreenTests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--clear-keychain"]
        app.launch()
        app.buttons["btn_log_in"].tap()
        XCTAssertTrue(app.buttons["btn_sign_in"].waitForExistence(timeout: 3))
    }

    func testLoginScreen_showsExpectedElements() {
        XCTAssertTrue(app.textFields["field_email"].exists)
        XCTAssertTrue(app.secureTextFields["field_password"].exists)
        XCTAssertTrue(app.buttons["btn_sign_in"].exists)
    }

    func testSignIn_disabled_whenFieldsEmpty() {
        XCTAssertFalse(app.buttons["btn_sign_in"].isEnabled)
    }

    func testSignIn_enabled_whenFieldsFilled() {
        app.textFields["field_email"].tap()
        app.textFields["field_email"].typeText("test@example.com")
        app.secureTextFields["field_password"].tap()
        app.secureTextFields["field_password"].typeText("password")
        XCTAssertTrue(app.buttons["btn_sign_in"].isEnabled)
    }

    func testCreateAccountLink_navigatesToSignUp() {
        app.buttons["link_create_account"].tap()
        XCTAssertTrue(app.staticTexts["Join GarageKeep"].waitForExistence(timeout: 3))
    }

    func testBackButton_returnsToWelcomeScreen() {
        app.buttons["btn_back"].tap()
        XCTAssertTrue(app.buttons["btn_get_started"].waitForExistence(timeout: 3))
    }
}
