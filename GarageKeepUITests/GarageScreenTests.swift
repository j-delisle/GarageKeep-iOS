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

    func testGarageScreen_showsAddVehicleFAB() {
        XCTAssertTrue(app.buttons["btn_add_vehicle"].waitForExistence(timeout: 3))
    }

    func testVehicleCards_showAddServiceButton() {
        // Wait for mock vehicle text to confirm cards have rendered
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label == 'BMW X5'")).firstMatch.waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label == 'Add Service'")).firstMatch.exists)
    }

    func testVehicleCards_showStatusBadge() {
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label == 'BMW X5'")).firstMatch.waitForExistence(timeout: 3))
        // StatusBadgeView shows "ACTIVE" — match by label
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label == 'ACTIVE'")).firstMatch.exists)
    }

    func testAddVehicleButton_tapping_showsOnboarding() {
        app.buttons["btn_add_vehicle"].tap()
        XCTAssertTrue(app.staticTexts["Add Your Vehicle"].waitForExistence(timeout: 3))
    }

    // MARK: - Close Button

    func testCloseButton_visible_whenGarageHasVehicles() {
        app.buttons["btn_add_vehicle"].tap()
        XCTAssertTrue(app.buttons["btn_close_add_vehicle"].waitForExistence(timeout: 3))
    }

    func testCloseButton_dismissesAddVehicleSheet() {
        app.buttons["btn_add_vehicle"].tap()
        XCTAssertTrue(app.buttons["btn_close_add_vehicle"].waitForExistence(timeout: 3))
        app.buttons["btn_close_add_vehicle"].tap()
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 3))
        XCTAssertFalse(app.staticTexts["Add Your Vehicle"].exists)
    }

    func testInteractiveDismiss_allowed_whenGarageHasVehicles() {
        // Wait for vehicles to load so vehicleCount > 0 when the sheet opens
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label == 'BMW X5'")).firstMatch.waitForExistence(timeout: 3))
        app.buttons["btn_add_vehicle"].tap()
        let title = app.staticTexts.matching(NSPredicate(format: "label == 'Add Your Vehicle'")).firstMatch
        XCTAssertTrue(title.waitForExistence(timeout: 3))
        // Drag from the top of the sheet (drag indicator area) to the bottom to trigger interactive dismiss
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.15))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.95))
        start.press(forDuration: 0.05, thenDragTo: end)
        XCTAssertFalse(title.waitForExistence(timeout: 2))
    }

}
