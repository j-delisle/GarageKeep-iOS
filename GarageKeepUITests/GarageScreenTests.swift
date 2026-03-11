import XCTest

final class GarageScreenTests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--mock-vehicles"]
        app.launch()
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 3))
    }

    func testGarageScreen_showsToolbarButtons() {
        XCTAssertTrue(app.buttons["btn_add_vehicle"].exists)
        XCTAssertTrue(app.buttons["btn_profile"].exists)
    }

    func testVehicleCards_showDetailsButton() {
        XCTAssertTrue(app.buttons["btn_vehicle_details"].firstMatch.waitForExistence(timeout: 3))
    }

    func testVehicleCards_showStatusBadge() {
        XCTAssertTrue(app.staticTexts["badge_status"].firstMatch.waitForExistence(timeout: 3))
    }

    func testAddVehicleButton_tapping_showsOnboarding() {
        app.buttons["btn_add_vehicle"].tap()
        XCTAssertTrue(app.staticTexts["Tell us about your vehicle"].waitForExistence(timeout: 3))
    }
}
