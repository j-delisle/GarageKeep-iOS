import XCTest

final class OnboardingScreenTests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--show-onboarding"]
        app.launch()
    }

    // MARK: - Initial State

    func testOnboarding_showsInitialElements() {
        XCTAssertTrue(app.staticTexts["Add Your Vehicle"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.textFields["field_vin"].exists)
        XCTAssertTrue(app.buttons["btn_decode_vin"].exists)
        XCTAssertTrue(app.buttons["btn_continue"].exists)
    }

    func testContinue_disabled_initially() {
        XCTAssertTrue(app.buttons["btn_continue"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["btn_continue"].isEnabled)
    }

    // MARK: - VIN Mode

    func testDecodeVin_disabled_untilSeventeenChars() {
        XCTAssertTrue(app.buttons["btn_decode_vin"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["btn_decode_vin"].isEnabled)

        app.textFields["field_vin"].tap()
        app.textFields["field_vin"].typeText("1HGBH41JXMN10918") // 16 chars
        XCTAssertFalse(app.buttons["btn_decode_vin"].isEnabled)

        app.textFields["field_vin"].typeText("6") // 17 chars
        XCTAssertTrue(app.buttons["btn_decode_vin"].isEnabled)
    }

    // MARK: - Manual Mode

    func testSwitchToManualMode_showsManualFields() {
        app.buttons["Manual"].tap()
        XCTAssertTrue(app.textFields["field_make"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.textFields["field_model"].exists)
        XCTAssertTrue(app.textFields["field_year"].exists)
    }

    func testContinue_disabled_inManualMode_untilMakeAndModel() {
        app.buttons["Manual"].tap()
        XCTAssertTrue(app.textFields["field_make"].waitForExistence(timeout: 2))
        XCTAssertFalse(app.buttons["btn_continue"].isEnabled)

        app.textFields["field_make"].tap()
        app.textFields["field_make"].typeText("Honda")
        XCTAssertFalse(app.buttons["btn_continue"].isEnabled)

        app.textFields["field_model"].tap()
        app.textFields["field_model"].typeText("Civic")
        XCTAssertTrue(app.buttons["btn_continue"].isEnabled)
    }

    func testContinue_navigatesToReviewStep_inManualMode() {
        app.buttons["Manual"].tap()
        XCTAssertTrue(app.textFields["field_make"].waitForExistence(timeout: 2))

        app.textFields["field_make"].tap()
        app.textFields["field_make"].typeText("Honda")
        app.textFields["field_model"].tap()
        app.textFields["field_model"].typeText("Civic")

        // Dismiss keyboard — btn_continue is behind it; typeText("\n") presses
        // return on the focused field without locating the keyboard button in the AX tree
        app.textFields["field_model"].typeText("\n")

        app.buttons["btn_continue"].tap()

        XCTAssertTrue(app.staticTexts["Confirm Details"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["btn_add_vehicle"].exists)
        XCTAssertTrue(app.buttons["btn_go_back"].exists)
    }

    // MARK: - Review Step

    // MARK: - Close Button

    func testCloseButton_notVisible_duringOnboarding() {
        // Launched with --show-onboarding (0 vehicles) — close button must not appear
        XCTAssertTrue(app.staticTexts["Add Your Vehicle"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["btn_close_add_vehicle"].exists)
    }

    func testGoBack_returnsToIdentityStep() {
        app.buttons["Manual"].tap()
        XCTAssertTrue(app.textFields["field_make"].waitForExistence(timeout: 2))

        app.textFields["field_make"].tap()
        app.textFields["field_make"].typeText("Honda")
        app.textFields["field_model"].tap()
        app.textFields["field_model"].typeText("Civic")
        app.textFields["field_model"].typeText("\n")

        app.buttons["btn_continue"].tap()

        XCTAssertTrue(app.buttons["btn_go_back"].waitForExistence(timeout: 3))
        app.buttons["btn_go_back"].tap()

        XCTAssertTrue(app.staticTexts["Add Your Vehicle"].waitForExistence(timeout: 3))
    }

    func testReviewStep_showsEnteredVehicleDetails() {
        app.buttons["Manual"].tap()
        XCTAssertTrue(app.textFields["field_make"].waitForExistence(timeout: 2))

        app.textFields["field_make"].tap()
        app.textFields["field_make"].typeText("Toyota")
        app.textFields["field_model"].tap()
        app.textFields["field_model"].typeText("Camry")
        // Dismiss regular keyboard before tapping field_year (at keyboard edge)
        app.textFields["field_model"].typeText("\n")

        app.textFields["field_year"].tap()
        app.textFields["field_year"].typeText("2023")

        // field_year uses .numberPad — no return key. Transfer focus to field_make
        // (regular keyboard) then dismiss with "\n".
        app.textFields["field_make"].tap()
        app.textFields["field_make"].typeText("\n")

        app.buttons["btn_continue"].tap()

        XCTAssertTrue(app.staticTexts["Toyota"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Camry"].exists)
        XCTAssertTrue(app.staticTexts["2023"].exists)
    }
}
