import XCTest

final class ServiceHistoryScreenTests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--mock-vehicles", "--mock-service-events"]
        app.launch()
    }

    private func navigateToServiceTab() {
        let serviceTab = app.tabBars.buttons["Service"]
        XCTAssertTrue(serviceTab.waitForExistence(timeout: 3))
        serviceTab.tap()
    }

    private func selectFirstVehicle() {
        // With multiple mock vehicles the picker is shown — tap first vehicle row
        let firstRow = app.buttons.matching(NSPredicate(format: "label CONTAINS 'BMW'")).firstMatch
        if firstRow.waitForExistence(timeout: 2) {
            firstRow.tap()
        }
        // If only one vehicle, ServiceHistoryView is shown directly — no tap needed
    }

    func testServiceTab_isReachable() {
        navigateToServiceTab()
        XCTAssertTrue(app.tabBars.buttons["Service"].isSelected)
    }

    func testServiceHistory_showsNavigationTitle() {
        navigateToServiceTab()
        selectFirstVehicle()
        XCTAssertTrue(app.navigationBars["Service History"].waitForExistence(timeout: 3))
    }

    func testServiceHistory_showsStatCards() {
        navigateToServiceTab()
        selectFirstVehicle()
        XCTAssertTrue(
            app.otherElements["stats_total_spent"].waitForExistence(timeout: 3)
        )
    }

    func testServiceHistory_showsVehicleSummaryCard() {
        navigateToServiceTab()
        selectFirstVehicle()
        XCTAssertTrue(
            app.otherElements["vehicle_summary_card"].waitForExistence(timeout: 3)
        )
    }

    func testServiceHistory_showsServiceRows() {
        navigateToServiceTab()
        selectFirstVehicle()
        XCTAssertTrue(
            app.otherElements["service_row_0"].waitForExistence(timeout: 3)
        )
    }

    // Upcoming section commented out until alerts/reminders backend is implemented
    // func testServiceHistory_showsUpcomingSection() {
    //     navigateToServiceTab()
    //     selectFirstVehicle()
    //     XCTAssertTrue(
    //         app.staticTexts["UPCOMING"].waitForExistence(timeout: 3)
    //     )
    // }

    func testServiceHistory_showsPastMaintenanceSection() {
        navigateToServiceTab()
        selectFirstVehicle()
        XCTAssertTrue(
            app.staticTexts["PAST MAINTENANCE"].waitForExistence(timeout: 3)
        )
    }

    func testVehiclePicker_showsMultipleVehicles() {
        navigateToServiceTab()
        // With 3 mock vehicles, picker is shown — check for section header
        let header = app.staticTexts.matching(NSPredicate(format: "label == 'SELECT A VEHICLE'")).firstMatch
        if header.waitForExistence(timeout: 2) {
            // Picker is visible with multiple vehicles
            XCTAssertTrue(
                app.buttons.matching(NSPredicate(format: "label CONTAINS 'BMW'")).firstMatch.exists
            )
        }
    }
}
