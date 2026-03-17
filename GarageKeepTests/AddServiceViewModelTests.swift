import XCTest
@testable import GarageKeep

@MainActor
final class AddServiceViewModelTests: XCTestCase {
    var mockServiceEventService: MockServiceEventService!
    var mockAttachmentService: MockAttachmentService!
    var sut: AddServiceViewModel!

    override func setUp() {
        super.setUp()
        mockServiceEventService = MockServiceEventService()
        mockAttachmentService = MockAttachmentService()
        sut = AddServiceViewModel(
            vehicle: .stubWithVin,
            serviceEventService: mockServiceEventService,
            attachmentService: mockAttachmentService
        )
    }

    // MARK: - Initial State

    func testInitialState_isDetailsStep() {
        XCTAssertEqual(sut.currentStep, .details)
    }

    func testInitialState_allFieldsEmpty() {
        XCTAssertEqual(sut.serviceTypePick, "")
        XCTAssertEqual(sut.serviceTypeCustom, "")
        XCTAssertEqual(sut.mileageText, "")
        XCTAssertEqual(sut.costText, "")
        XCTAssertEqual(sut.location, "")
        XCTAssertEqual(sut.notes, "")
        XCTAssertNil(sut.selectedImageData)
    }

    func testInitialState_cannotAdvanceFromDetails() {
        XCTAssertFalse(sut.canAdvanceFromDetails)
    }

    // MARK: - canAdvanceFromDetails

    func testCanAdvance_trueWhenServiceTypeSet() {
        sut.serviceTypePick = "Oil & Filter Change"
        XCTAssertTrue(sut.canAdvanceFromDetails)
    }

    func testCanAdvance_falseWhenOtherWithEmptyCustomText() {
        sut.serviceTypePick = "Other"
        sut.serviceTypeCustom = ""
        XCTAssertFalse(sut.canAdvanceFromDetails)
    }

    func testCanAdvance_falseWhenOtherWithWhitespaceOnlyCustomText() {
        sut.serviceTypePick = "Other"
        sut.serviceTypeCustom = "   "
        XCTAssertFalse(sut.canAdvanceFromDetails)
    }

    func testCanAdvance_trueWhenOtherWithCustomText() {
        sut.serviceTypePick = "Other"
        sut.serviceTypeCustom = "Detailing"
        XCTAssertTrue(sut.canAdvanceFromDetails)
    }

    // MARK: - resolvedServiceType

    func testResolvedServiceType_usesPickerValue() {
        sut.serviceTypePick = "Brake Service"
        XCTAssertEqual(sut.resolvedServiceType, "Brake Service")
    }

    func testResolvedServiceType_usesCustomText_whenOtherSelected() {
        sut.serviceTypePick = "Other"
        sut.serviceTypeCustom = "Engine Swap"
        XCTAssertEqual(sut.resolvedServiceType, "Engine Swap")
    }

    // MARK: - formattedDate

    func testFormattedDate_returnsISO8601DateString() {
        var components = DateComponents()
        components.year = 2025
        components.month = 6
        components.day = 15
        components.timeZone = TimeZone(secondsFromGMT: 0)
        let date = Calendar(identifier: .gregorian).date(from: components)!
        sut.serviceDate = date
        XCTAssertEqual(sut.formattedDate, "2025-06-15")
    }

    // MARK: - resolvedMileage

    func testResolvedMileage_nilForEmpty() {
        sut.mileageText = ""
        XCTAssertNil(sut.resolvedMileage)
    }

    func testResolvedMileage_returnsInt_forValidInput() {
        sut.mileageText = "12450"
        XCTAssertEqual(sut.resolvedMileage, 12450)
    }

    func testResolvedMileage_nilForNonNumeric() {
        sut.mileageText = "abc"
        XCTAssertNil(sut.resolvedMileage)
    }

    // MARK: - resolvedCost

    func testResolvedCost_nilForEmpty() {
        sut.costText = ""
        XCTAssertNil(sut.resolvedCost)
    }

    func testResolvedCost_nilForWhitespaceOnly() {
        sut.costText = "   "
        XCTAssertNil(sut.resolvedCost)
    }

    func testResolvedCost_returnsValue_forValidInput() {
        sut.costText = "85.00"
        XCTAssertEqual(sut.resolvedCost, "85.00")
    }

    func testResolvedCost_trims_whitespace() {
        sut.costText = "  49.99  "
        XCTAssertEqual(sut.resolvedCost, "49.99")
    }

    // MARK: - resolvedLocation / resolvedNotes

    func testResolvedLocation_nilForEmpty() {
        sut.location = ""
        XCTAssertNil(sut.resolvedLocation)
    }

    func testResolvedLocation_returnsValue_forNonEmpty() {
        sut.location = "Porsche Center"
        XCTAssertEqual(sut.resolvedLocation, "Porsche Center")
    }

    func testResolvedNotes_nilForEmpty() {
        sut.notes = ""
        XCTAssertNil(sut.resolvedNotes)
    }

    func testResolvedNotes_returnsValue_forNonEmpty() {
        sut.notes = "Synthetic 0W-40"
        XCTAssertEqual(sut.resolvedNotes, "Synthetic 0W-40")
    }

    // MARK: - Step Navigation (advance)

    func testAdvance_detailsToReceipt() {
        sut.advance()
        XCTAssertEqual(sut.currentStep, .receipt)
    }

    func testAdvance_receiptToReview() {
        sut.advance()
        sut.advance()
        XCTAssertEqual(sut.currentStep, .review)
    }

    func testAdvance_staysAtReview() {
        sut.advance()
        sut.advance()
        sut.advance()
        XCTAssertEqual(sut.currentStep, .review)
    }

    // MARK: - Step Navigation (back)

    func testBack_reviewToReceipt() {
        sut.advance()
        sut.advance()
        sut.back()
        XCTAssertEqual(sut.currentStep, .receipt)
    }

    func testBack_receiptToDetails() {
        sut.advance()
        sut.back()
        XCTAssertEqual(sut.currentStep, .details)
    }

    func testBack_staysAtDetails() {
        sut.back()
        XCTAssertEqual(sut.currentStep, .details)
    }

    // MARK: - Submit: API calls

    func testSubmit_callsCreateServiceEvent() async {
        sut.serviceTypePick = "Oil & Filter Change"
        _ = await sut.submit()
        XCTAssertEqual(mockServiceEventService.createCallCount, 1)
    }

    func testSubmit_sendsCorrectVehicleId() async {
        sut.serviceTypePick = "Oil & Filter Change"
        _ = await sut.submit()
        XCTAssertEqual(mockServiceEventService.lastCreatedVehicleId, VehicleResponse.stubWithVin.id)
    }

    func testSubmit_sendsCorrectServiceType() async {
        sut.serviceTypePick = "Brake Service"
        _ = await sut.submit()
        XCTAssertEqual(mockServiceEventService.lastCreatedRequest?.serviceType, "Brake Service")
    }

    func testSubmit_sendsResolvedServiceType_forOther() async {
        sut.serviceTypePick = "Other"
        sut.serviceTypeCustom = "Engine Swap"
        _ = await sut.submit()
        XCTAssertEqual(mockServiceEventService.lastCreatedRequest?.serviceType, "Engine Swap")
    }

    func testSubmit_sendsFormattedDate() async {
        sut.serviceTypePick = "Oil & Filter Change"
        _ = await sut.submit()
        let request = mockServiceEventService.lastCreatedRequest
        // Date should match yyyy-MM-dd format
        XCTAssertNotNil(request?.serviceDate)
        XCTAssertEqual(request?.serviceDate.count, 10)
        XCTAssertTrue(request?.serviceDate.contains("-") ?? false)
    }

    func testSubmit_sendsMileage_whenSet() async {
        sut.serviceTypePick = "Oil & Filter Change"
        sut.mileageText = "12450"
        _ = await sut.submit()
        XCTAssertEqual(mockServiceEventService.lastCreatedRequest?.mileage, 12450)
    }

    func testSubmit_sendsNilMileage_whenEmpty() async {
        sut.serviceTypePick = "Oil & Filter Change"
        sut.mileageText = ""
        _ = await sut.submit()
        XCTAssertNil(mockServiceEventService.lastCreatedRequest?.mileage)
    }

    func testSubmit_sendsCost_whenSet() async {
        sut.serviceTypePick = "Oil & Filter Change"
        sut.costText = "85.00"
        _ = await sut.submit()
        XCTAssertEqual(mockServiceEventService.lastCreatedRequest?.cost, "85.00")
    }

    func testSubmit_sendsNilCost_whenEmpty() async {
        sut.serviceTypePick = "Oil & Filter Change"
        sut.costText = ""
        _ = await sut.submit()
        XCTAssertNil(mockServiceEventService.lastCreatedRequest?.cost)
    }

    // MARK: - Submit: Success / Failure

    func testSubmit_returnsEvent_onSuccess() async {
        sut.serviceTypePick = "Oil & Filter Change"
        let result = await sut.submit()
        XCTAssertNotNil(result)
    }

    func testSubmit_returnsNil_onServiceFailure() async {
        mockServiceEventService.createResult = .failure(APIError.serverError(500))
        sut.serviceTypePick = "Oil & Filter Change"
        let result = await sut.submit()
        XCTAssertNil(result)
    }

    func testSubmit_setsErrorMessage_onServiceFailure() async {
        mockServiceEventService.createResult = .failure(APIError.serverError(500))
        sut.serviceTypePick = "Oil & Filter Change"
        _ = await sut.submit()
        XCTAssertNotNil(sut.errorMessage)
    }

    func testSubmit_clearsErrorMessage_onRetrySuccess() async {
        mockServiceEventService.createResult = .failure(APIError.serverError(500))
        sut.serviceTypePick = "Oil & Filter Change"
        _ = await sut.submit()
        XCTAssertNotNil(sut.errorMessage)

        mockServiceEventService.createResult = .success(.stub)
        _ = await sut.submit()
        XCTAssertNil(sut.errorMessage)
    }

    func testSubmit_isLoadingFalse_afterSuccess() async {
        sut.serviceTypePick = "Oil & Filter Change"
        _ = await sut.submit()
        XCTAssertFalse(sut.isLoading)
    }

    func testSubmit_isLoadingFalse_afterFailure() async {
        mockServiceEventService.createResult = .failure(APIError.serverError(500))
        sut.serviceTypePick = "Oil & Filter Change"
        _ = await sut.submit()
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - Submit: Attachment Upload

    func testSubmit_doesNotCallAttachmentService_whenNoImageSelected() async {
        sut.serviceTypePick = "Oil & Filter Change"
        _ = await sut.submit()
        XCTAssertEqual(mockAttachmentService.uploadCallCount, 0)
    }

    func testSubmit_callsAttachmentService_whenImageSelected() async {
        sut.serviceTypePick = "Oil & Filter Change"
        sut.selectedImageData = Data("fake-image".utf8)
        _ = await sut.submit()
        XCTAssertEqual(mockAttachmentService.uploadCallCount, 1)
    }

    func testSubmit_passesCorrectServiceIdToAttachmentUpload() async {
        let expectedEvent = ServiceEventResponse.stub
        mockServiceEventService.createResult = .success(expectedEvent)
        sut.serviceTypePick = "Oil & Filter Change"
        sut.selectedImageData = Data("fake-image".utf8)
        _ = await sut.submit()
        XCTAssertEqual(mockAttachmentService.lastServiceId, expectedEvent.id)
    }

    func testSubmit_stillReturnsEvent_whenAttachmentUploadFails() async {
        mockAttachmentService.uploadResult = .failure(APIError.serverError(500))
        sut.serviceTypePick = "Oil & Filter Change"
        sut.selectedImageData = Data("fake-image".utf8)
        let result = await sut.submit()
        XCTAssertNotNil(result)
    }

    func testSubmit_doesNotSetErrorMessage_whenAttachmentUploadFails() async {
        mockAttachmentService.uploadResult = .failure(APIError.serverError(500))
        sut.serviceTypePick = "Oil & Filter Change"
        sut.selectedImageData = Data("fake-image".utf8)
        _ = await sut.submit()
        XCTAssertNil(sut.errorMessage)
    }

    // MARK: - Service Type Options

    func testServiceTypeOptions_includesOther() {
        XCTAssertTrue(AddServiceViewModel.serviceTypeOptions.contains("Other"))
    }

    func testServiceTypeOptions_otherIsLastItem() {
        XCTAssertEqual(AddServiceViewModel.serviceTypeOptions.last, "Other")
    }

    func testServiceTypeOptions_hasExpectedCount() {
        XCTAssertEqual(AddServiceViewModel.serviceTypeOptions.count, 11)
    }
}
