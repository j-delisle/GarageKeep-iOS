import XCTest
@testable import GarageKeep

@MainActor
final class ServiceDetailViewModelTests: XCTestCase {
    var mockServiceEventService: MockServiceEventService!
    var mockAttachmentService: MockAttachmentService!
    var stubVehicle: VehicleResponse!
    var stubEvent: ServiceEventResponse!
    var sut: ServiceDetailViewModel!
    private var retainedVMs: [AnyObject] = []

    override func setUp() {
        super.setUp()
        mockServiceEventService = MockServiceEventService()
        mockAttachmentService = MockAttachmentService()
        stubVehicle = VehicleResponse(
            id: UUID(), userId: UUID(),
            make: "Porsche", model: "911 GT3",
            year: 2022, vin: nil, licensePlate: nil,
            createdAt: Date(), updatedAt: Date()
        )
        stubEvent = ServiceEventResponse(
            id: UUID(), vehicleId: stubVehicle.id,
            serviceType: "Oil Change & Filter",
            serviceDate: "2024-03-12",
            mileage: 12450, cost: "245.00",
            location: "Precision Werkstatt",
            notes: "Full synthetic oil change.",
            createdAt: Date(), updatedAt: Date()
        )
        sut = ServiceDetailViewModel(
            event: stubEvent,
            vehicle: stubVehicle,
            previousMileage: 11200,
            serviceEventService: mockServiceEventService,
            attachmentService: mockAttachmentService
        )
    }

    override func tearDown() {
        retainedVMs.removeAll()
        super.tearDown()
    }

    private func makeVM(
        event: ServiceEventResponse? = nil,
        vehicle: VehicleResponse? = nil,
        previousMileage: Int? = 11200
    ) -> ServiceDetailViewModel {
        let vm = ServiceDetailViewModel(
            event: event ?? stubEvent,
            vehicle: vehicle ?? stubVehicle,
            previousMileage: previousMileage,
            serviceEventService: mockServiceEventService,
            attachmentService: mockAttachmentService
        )
        retainedVMs.append(vm)
        return vm
    }

    // MARK: - Initial State

    func testInitialState_attachmentsEmpty() {
        XCTAssertTrue(sut.attachments.isEmpty)
    }

    func testInitialState_isLoadingFalse() {
        XCTAssertFalse(sut.isLoadingAttachments)
    }

    func testInitialState_isDeletingFalse() {
        XCTAssertFalse(sut.isDeleting)
    }

    func testInitialState_noError() {
        XCTAssertNil(sut.errorMessage)
    }

    // MARK: - loadAttachments — Success

    func testLoadAttachments_populatesAttachments_onSuccess() async {
        let attachment = AttachmentResponse.stub
        mockAttachmentService.listResult = .success([attachment])

        await sut.loadAttachments()

        XCTAssertEqual(sut.attachments.count, 1)
        XCTAssertEqual(sut.attachments.first?.id, attachment.id)
    }

    func testLoadAttachments_callsServiceWithCorrectServiceId() async {
        await sut.loadAttachments()
        XCTAssertEqual(mockAttachmentService.lastListServiceId, stubEvent.id)
    }

    func testLoadAttachments_isLoadingFalse_afterCompletion() async {
        await sut.loadAttachments()
        XCTAssertFalse(sut.isLoadingAttachments)
    }

    func testLoadAttachments_setsEmptyArray_onEmptyResponse() async {
        mockAttachmentService.listResult = .success([])
        await sut.loadAttachments()
        XCTAssertTrue(sut.attachments.isEmpty)
    }

    // MARK: - loadAttachments — Failure

    func testLoadAttachments_silentlyFails_onError() async {
        mockAttachmentService.listResult = .failure(APIError.serverError(500))
        await sut.loadAttachments()
        XCTAssertTrue(sut.attachments.isEmpty)
        XCTAssertNil(sut.errorMessage)
    }

    func testLoadAttachments_isLoadingFalse_onError() async {
        mockAttachmentService.listResult = .failure(APIError.networkError(URLError(.notConnectedToInternet)))
        await sut.loadAttachments()
        XCTAssertFalse(sut.isLoadingAttachments)
    }

    // MARK: - getDownloadUrl — Success

    func testGetDownloadUrl_returnsURL_onSuccess() async {
        mockAttachmentService.downloadUrlResult = .success("https://example.com/signed.jpg")
        let url = await sut.getDownloadUrl(for: .stub)
        XCTAssertEqual(url?.absoluteString, "https://example.com/signed.jpg")
    }

    func testGetDownloadUrl_callsServiceWithCorrectAttachmentId() async {
        let attachment = AttachmentResponse.stub
        _ = await sut.getDownloadUrl(for: attachment)
        XCTAssertEqual(mockAttachmentService.lastDownloadAttachmentId, attachment.id)
    }

    // MARK: - getDownloadUrl — Failure

    func testGetDownloadUrl_returnsNil_onError() async {
        mockAttachmentService.downloadUrlResult = .failure(APIError.serverError(500))
        let url = await sut.getDownloadUrl(for: .stub)
        XCTAssertNil(url)
    }

    func testGetDownloadUrl_returnsNil_onMalformedURL() async {
        mockAttachmentService.downloadUrlResult = .success("not a valid url ://###")
        let url = await sut.getDownloadUrl(for: .stub)
        XCTAssertNil(url)
    }

    // MARK: - delete — Success

    func testDelete_callsServiceWithCorrectId() async {
        await sut.delete(onComplete: {})
        XCTAssertEqual(mockServiceEventService.lastDeletedServiceId, stubEvent.id)
    }

    func testDelete_callsOnComplete_onSuccess() async {
        var completionCalled = false
        await sut.delete(onComplete: { completionCalled = true })
        XCTAssertTrue(completionCalled)
    }

    func testDelete_isDeletingFalse_afterSuccess() async {
        await sut.delete(onComplete: {})
        XCTAssertFalse(sut.isDeleting)
    }

    // MARK: - delete — Failure

    func testDelete_setsErrorMessage_onFailure() async {
        mockServiceEventService.deleteResult = .failure(APIError.serverError(500))
        await sut.delete(onComplete: {})
        XCTAssertNotNil(sut.errorMessage)
    }

    func testDelete_doesNotCallOnComplete_onFailure() async {
        mockServiceEventService.deleteResult = .failure(APIError.serverError(500))
        var completionCalled = false
        await sut.delete(onComplete: { completionCalled = true })
        XCTAssertFalse(completionCalled)
    }

    func testDelete_isDeletingFalse_afterFailure() async {
        mockServiceEventService.deleteResult = .failure(APIError.serverError(500))
        await sut.delete(onComplete: {})
        XCTAssertFalse(sut.isDeleting)
    }

    // MARK: - Computed: formattedDate

    func testFormattedDate_parsesISO8601DateString() {
        XCTAssertEqual(sut.formattedDate, "March 12, 2024")
    }

    func testFormattedDate_returnsRaw_ifUnparseable() {
        sut.event = makeEvent(date: "not-a-date")
        XCTAssertEqual(sut.formattedDate, "not-a-date")
    }

    // MARK: - Computed: vehicleTitle

    func testVehicleTitle_includesYearMakeModel() {
        XCTAssertEqual(sut.vehicleTitle, "2022 Porsche 911 GT3")
    }

    func testVehicleTitle_omitsYear_whenNil() {
        let vehicle = VehicleResponse(
            id: UUID(), userId: UUID(), make: "BMW", model: "M3",
            year: nil, vin: nil, licensePlate: nil,
            createdAt: Date(), updatedAt: Date()
        )
        XCTAssertEqual(makeVM(vehicle: vehicle, previousMileage: nil).vehicleTitle, "BMW M3")
    }

    // MARK: - Computed: formattedCost

    func testFormattedCost_formatsCurrencyString() {
        XCTAssertEqual(sut.formattedCost, "$245.00")
    }

    func testFormattedCost_returnsNil_whenCostNil() {
        sut.event = makeEvent(cost: nil)
        XCTAssertNil(sut.formattedCost)
    }

    func testFormattedCost_returnsNil_whenCostNotDecimal() {
        sut.event = makeEvent(cost: "invalid")
        XCTAssertNil(sut.formattedCost)
    }

    // MARK: - Computed: formattedMileage

    func testFormattedMileage_formatsWithDecimalSeparator() {
        XCTAssertEqual(sut.formattedMileage, "12,450 mi")
    }

    func testFormattedMileage_returnsNil_whenMileageNil() {
        sut.event = makeEvent(mileage: nil)
        XCTAssertNil(sut.formattedMileage)
    }

    // MARK: - Computed: formattedMileageDelta

    func testMileageDelta_showsKFormat_forLargeDeltas() {
        // stubEvent mileage=12450, previousMileage=11200 → delta=1250
        XCTAssertEqual(sut.formattedMileageDelta, "+1.2k since last")
    }

    func testMileageDelta_showsExact_forSmallDeltas() {
        let vm = makeVM(event: makeEvent(mileage: 10500), previousMileage: 10000)
        XCTAssertEqual(vm.formattedMileageDelta, "+500 since last")
    }

    func testMileageDelta_returnsNil_whenNoPreviousMileage() {
        let vm = makeVM(previousMileage: nil)
        XCTAssertNil(vm.formattedMileageDelta)
    }

    func testMileageDelta_returnsNil_whenCurrentMileageNil() {
        let vm = makeVM(event: makeEvent(mileage: nil), previousMileage: 10000)
        XCTAssertNil(vm.formattedMileageDelta)
    }

    func testMileageDelta_returnsNil_whenCurrentNotGreaterThanPrevious() {
        let vm = makeVM(event: makeEvent(mileage: 9000), previousMileage: 10000)
        XCTAssertNil(vm.formattedMileageDelta)
    }

    // MARK: - Helpers

    private func makeEvent(
        date: String = "2024-03-12",
        mileage: Int? = 12450,
        cost: String? = "245.00"
    ) -> ServiceEventResponse {
        ServiceEventResponse(
            id: stubEvent.id, vehicleId: stubVehicle.id,
            serviceType: "Oil Change & Filter", serviceDate: date,
            mileage: mileage, cost: cost,
            location: "Precision Werkstatt", notes: "Full synthetic.",
            createdAt: Date(), updatedAt: Date()
        )
    }
}
