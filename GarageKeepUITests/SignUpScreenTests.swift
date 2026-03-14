import XCTest

final class SignUpScreenTests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--clear-keychain"]
        app.launch()
        app.buttons["btn_get_started"].tap()
        XCTAssertTrue(app.buttons["btn_create_account"].waitForExistence(timeout: 3))
    }

    func testSignUpScreen_showsExpectedElements() {
        XCTAssertTrue(app.textFields["field_full_name"].exists)
        XCTAssertTrue(app.textFields["field_email"].exists)
        XCTAssertTrue(app.buttons["btn_create_account"].exists)
    }

    func testCreateAccount_disabled_whenFieldsEmpty() {
        XCTAssertFalse(app.buttons["btn_create_account"].isEnabled)
    }

    func testCreateAccount_disabled_whenPasswordsDontMatch() {
        app.textFields["field_full_name"].tap()
        app.textFields["field_full_name"].typeText("Test User")
        app.textFields["field_email"].tap()
        app.textFields["field_email"].typeText("test@example.com")
        app.secureTextFields["field_password"].tap()
        app.secureTextFields["field_password"].typeText("password123")
        app.secureTextFields["field_confirm_password"].tap()
        app.secureTextFields["field_confirm_password"].typeText("different")
        XCTAssertFalse(app.buttons["btn_create_account"].isEnabled)
    }

    func testLogInLink_navigatesToLoginScreen() {
        // Footer is below the fold — scroll before tapping
        app.swipeUp()
        app.buttons["link_log_in"].tap()
        XCTAssertTrue(app.buttons["btn_sign_in"].waitForExistence(timeout: 3))
    }

    func testBackButton_returnsToWelcomeScreen() {
        app.buttons["btn_back"].tap()
        XCTAssertTrue(app.buttons["btn_get_started"].waitForExistence(timeout: 3))
    }
}
