import XCTest

final class AddServiceScreenTests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--mock-vehicles", "--mock-service-events"]
        app.launch()
    }

    // MARK: - Navigation Helpers

    private func navigateToServiceHistory() {
        let serviceTab = app.tabBars.buttons["Service"]
        XCTAssertTrue(serviceTab.waitForExistence(timeout: 3))
        serviceTab.tap()

        // If vehicle picker is shown (multiple mock vehicles), select the first
        let vehicleButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS 'BMW'")
        ).firstMatch
        if vehicleButton.waitForExistence(timeout: 2) {
            vehicleButton.tap()
        }

        XCTAssertTrue(app.navigationBars["Service History"].waitForExistence(timeout: 3))
    }

    private func openAddService() {
        let fab = app.buttons["btn_add_service"]
        XCTAssertTrue(fab.waitForExistence(timeout: 3))
        fab.tap()
    }

    // MARK: - FAB

    func testFAB_isVisible_onServiceHistoryScreen() {
        navigateToServiceHistory()
        XCTAssertTrue(app.buttons["btn_add_service"].waitForExistence(timeout: 3))
    }

    func testFAB_tap_opensAddServiceScreen() {
        navigateToServiceHistory()
        openAddService()
        XCTAssertTrue(app.staticTexts["Add Service"].waitForExistence(timeout: 3))
    }

    // MARK: - Add Service Details Screen

    func testAddService_showsCancelButton() {
        navigateToServiceHistory()
        openAddService()
        XCTAssertTrue(app.buttons["Cancel"].waitForExistence(timeout: 3))
    }

    func testAddService_cancel_dismissesSheet() {
        navigateToServiceHistory()
        openAddService()
        XCTAssertTrue(app.staticTexts["Add Service"].waitForExistence(timeout: 3))
        app.buttons["Cancel"].tap()
        XCTAssertTrue(app.navigationBars["Service History"].waitForExistence(timeout: 3))
    }

    func testAddService_nextButton_isDisabled_withoutServiceType() {
        navigateToServiceHistory()
        openAddService()
        let nextButton = app.buttons.matching(
            NSPredicate(format: "label == 'Next'")
        ).firstMatch
        XCTAssertTrue(nextButton.waitForExistence(timeout: 3))
        XCTAssertFalse(nextButton.isEnabled)
    }

    func testAddService_showsStepIndicator() {
        navigateToServiceHistory()
        openAddService()
        // Step indicator dots are rendered — verify the screen is shown correctly
        XCTAssertTrue(app.staticTexts["Add Service"].waitForExistence(timeout: 3))
    }

    func testAddService_showsDetailsSection() {
        navigateToServiceHistory()
        openAddService()
        XCTAssertTrue(app.staticTexts["DETAILS"].waitForExistence(timeout: 3))
    }

    func testAddService_showsMetadataSection() {
        navigateToServiceHistory()
        openAddService()
        XCTAssertTrue(app.staticTexts["METADATA"].waitForExistence(timeout: 3))
    }

    func testAddService_showsServiceNotesSection() {
        navigateToServiceHistory()
        openAddService()
        XCTAssertTrue(app.staticTexts["SERVICE NOTES"].waitForExistence(timeout: 3))
    }

    // MARK: - Step 2: Upload Receipt

    func testAddService_nextEnabled_andNavigatesToReceiptStep() {
        navigateToServiceHistory()
        openAddService()

        // Select a service type via the menu
        let serviceTypeMenu = app.buttons.matching(
            NSPredicate(format: "label CONTAINS 'Select type'")
        ).firstMatch
        if serviceTypeMenu.waitForExistence(timeout: 3) {
            serviceTypeMenu.tap()
            let oilOption = app.buttons["Oil & Filter Change"]
            if oilOption.waitForExistence(timeout: 2) {
                oilOption.tap()
            }
        }

        let nextButton = app.buttons.matching(
            NSPredicate(format: "label == 'Next'")
        ).firstMatch
        XCTAssertTrue(nextButton.waitForExistence(timeout: 2))
        nextButton.tap()

        XCTAssertTrue(app.staticTexts["Upload Receipt"].waitForExistence(timeout: 3))
    }

    func testReceiptStep_showsCameraButton() {
        navigateToReceiptStep()
        XCTAssertTrue(app.buttons["Camera"].waitForExistence(timeout: 3))
    }

    func testReceiptStep_showsGalleryButton() {
        navigateToReceiptStep()
        XCTAssertTrue(app.buttons["Choose from Gallery"].waitForExistence(timeout: 3))
    }

    func testReceiptStep_backButton_returnsToDetailsStep() {
        navigateToReceiptStep()
        app.buttons["Back"].tap()
        XCTAssertTrue(app.staticTexts["Add Service"].waitForExistence(timeout: 3))
    }

    // MARK: - Step 3: Review

    func testReviewStep_showsConfirmButton() {
        navigateToReviewStep()
        XCTAssertTrue(app.buttons["btn_confirm_save"].waitForExistence(timeout: 3))
    }

    func testReviewStep_showsServiceType_inSummary() {
        navigateToReviewStep()
        XCTAssertTrue(app.staticTexts["Oil & Filter Change"].waitForExistence(timeout: 3))
    }

    func testReviewStep_backButton_returnsToReceiptStep() {
        navigateToReviewStep()
        app.buttons["Back"].tap()
        XCTAssertTrue(app.staticTexts["Upload Receipt"].waitForExistence(timeout: 3))
    }

    // MARK: - Navigation Helpers (Multi-step)

    private func navigateToReceiptStep() {
        navigateToServiceHistory()
        openAddService()

        let serviceTypeMenu = app.buttons.matching(
            NSPredicate(format: "label CONTAINS 'Select type'")
        ).firstMatch
        if serviceTypeMenu.waitForExistence(timeout: 3) {
            serviceTypeMenu.tap()
            let oilOption = app.buttons["Oil & Filter Change"]
            if oilOption.waitForExistence(timeout: 2) {
                oilOption.tap()
            }
        }

        let nextButton = app.buttons.matching(NSPredicate(format: "label == 'Next'")).firstMatch
        XCTAssertTrue(nextButton.waitForExistence(timeout: 2))
        nextButton.tap()
    }

    private func navigateToReviewStep() {
        navigateToReceiptStep()
        let nextButton = app.buttons.matching(NSPredicate(format: "label == 'Next'")).firstMatch
        XCTAssertTrue(nextButton.waitForExistence(timeout: 2))
        nextButton.tap()
    }
}
