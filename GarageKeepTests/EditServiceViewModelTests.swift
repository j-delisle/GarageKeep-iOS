import XCTest
@testable import GarageKeep

@MainActor
final class EditServiceViewModelTests: XCTestCase {
    var mockService: MockServiceEventService!
    var stubEvent: ServiceEventResponse!
    var sut: EditServiceViewModel!
    // Keeps @Observable instances alive until tearDown — prevents malloc crash on mid-test dealloc
    private var retainedVMs: [AnyObject] = []

    override func setUp() {
        super.setUp()
        mockService = MockServiceEventService()
        stubEvent = ServiceEventResponse(
            id: UUID(), vehicleId: UUID(),
            serviceType: "Oil & Filter Change",
            serviceDate: "2024-03-12",
            mileage: 12450, cost: "245.00",
            location: "Precision Werkstatt",
            notes: "Full synthetic oil change.",
            createdAt: Date(), updatedAt: Date()
        )
        sut = EditServiceViewModel(event: stubEvent, serviceEventService: mockService)
    }

    override func tearDown() {
        retainedVMs.removeAll()
        super.tearDown()
    }

    private func makeVM(event: ServiceEventResponse) -> EditServiceViewModel {
        let vm = EditServiceViewModel(event: event, serviceEventService: mockService)
        retainedVMs.append(vm)
        return vm
    }

    // MARK: - Pre-population: Known Service Types

    func testInit_setsServiceTypePick_forKnownType() {
        XCTAssertEqual(sut.serviceTypePick, "Oil & Filter Change")
        XCTAssertEqual(sut.serviceTypeCustom, "")
    }

    func testInit_setsServiceTypePick_toOther_forUnknownType() {
        let vm = makeVM(event: makeEvent(serviceType: "Valve Cover Gasket Replacement"))
        XCTAssertEqual(vm.serviceTypePick, "Other")
        XCTAssertEqual(vm.serviceTypeCustom, "Valve Cover Gasket Replacement")
    }

    // MARK: - Pre-population: Date

    func testInit_parsesServiceDate() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let expected = formatter.date(from: "2024-03-12")!
        XCTAssertEqual(Calendar.current.dateComponents([.year, .month, .day], from: sut.serviceDate),
                       Calendar.current.dateComponents([.year, .month, .day], from: expected))
    }

    func testInit_defaultsToNow_forUnparseableDate() {
        let vm = makeVM(event: makeEvent(date: "not-a-date"))
        XCTAssertEqual(
            Calendar.current.dateComponents([.year, .month, .day], from: vm.serviceDate),
            Calendar.current.dateComponents([.year, .month, .day], from: .now)
        )
    }

    // MARK: - Pre-population: Other Fields

    func testInit_populatesMileageText() {
        XCTAssertEqual(sut.mileageText, "12450")
    }

    func testInit_populatesCostText() {
        XCTAssertEqual(sut.costText, "245.00")
    }

    func testInit_populatesLocation() {
        XCTAssertEqual(sut.location, "Precision Werkstatt")
    }

    func testInit_populatesNotes() {
        XCTAssertEqual(sut.notes, "Full synthetic oil change.")
    }

    func testInit_emptyMileageText_whenMileageNil() {
        let vm = makeVM(event: makeEvent(mileage: nil))
        XCTAssertEqual(vm.mileageText, "")
    }

    func testInit_emptyCostText_whenCostNil() {
        let vm = makeVM(event: makeEvent(cost: nil))
        XCTAssertEqual(vm.costText, "")
    }

    func testInit_emptyLocation_whenLocationNil() {
        let vm = makeVM(event: makeEvent(location: nil))
        XCTAssertEqual(vm.location, "")
    }

    func testInit_emptyNotes_whenNotesNil() {
        let vm = makeVM(event: makeEvent(notes: nil))
        XCTAssertEqual(vm.notes, "")
    }

    // MARK: - canSave

    func testCanSave_true_withValidServiceType() {
        XCTAssertTrue(sut.canSave)
    }

    func testCanSave_false_whenServiceTypePickEmpty() {
        sut.serviceTypePick = ""
        XCTAssertFalse(sut.canSave)
    }

    func testCanSave_false_whenOther_andCustomEmpty() {
        sut.serviceTypePick = "Other"
        sut.serviceTypeCustom = "   "
        XCTAssertFalse(sut.canSave)
    }

    func testCanSave_true_whenOther_andCustomFilled() {
        sut.serviceTypePick = "Other"
        sut.serviceTypeCustom = "Custom Service"
        XCTAssertTrue(sut.canSave)
    }

    // MARK: - save — Success

    func testSave_callsUpdateWithCorrectServiceId() async {
        _ = await sut.save()
        XCTAssertEqual(mockService.lastUpdatedServiceId, stubEvent.id)
    }

    func testSave_callsUpdateWithCorrectServiceType() async {
        _ = await sut.save()
        XCTAssertEqual(mockService.lastUpdateRequest?.serviceType, "Oil & Filter Change")
    }

    func testSave_callsUpdateWithCustomServiceType_whenOther() async {
        sut.serviceTypePick = "Other"
        sut.serviceTypeCustom = "Clutch Replacement"
        _ = await sut.save()
        XCTAssertEqual(mockService.lastUpdateRequest?.serviceType, "Clutch Replacement")
    }

    func testSave_callsUpdateWithCorrectMileage() async {
        sut.mileageText = "15000"
        _ = await sut.save()
        XCTAssertEqual(mockService.lastUpdateRequest?.mileage, 15000)
    }

    func testSave_sendsNilMileage_whenTextEmpty() async {
        sut.mileageText = ""
        _ = await sut.save()
        XCTAssertNil(mockService.lastUpdateRequest?.mileage)
    }

    func testSave_callsUpdateWithCorrectCost() async {
        sut.costText = "99.99"
        _ = await sut.save()
        XCTAssertEqual(mockService.lastUpdateRequest?.cost, "99.99")
    }

    func testSave_sendsNilCost_whenTextEmpty() async {
        sut.costText = "   "
        _ = await sut.save()
        XCTAssertNil(mockService.lastUpdateRequest?.cost)
    }

    func testSave_sendsNilLocation_whenTextEmpty() async {
        sut.location = ""
        _ = await sut.save()
        XCTAssertNil(mockService.lastUpdateRequest?.location)
    }

    func testSave_sendsNilNotes_whenTextEmpty() async {
        sut.notes = "   "
        _ = await sut.save()
        XCTAssertNil(mockService.lastUpdateRequest?.notes)
    }

    func testSave_returnsUpdatedEvent_onSuccess() async {
        let updated = ServiceEventResponse(
            id: stubEvent.id, vehicleId: stubEvent.vehicleId,
            serviceType: "Tire Rotation", serviceDate: "2024-03-12",
            mileage: nil, cost: nil, location: nil, notes: nil,
            createdAt: Date(), updatedAt: Date()
        )
        mockService.updateResult = .success(updated)
        let result = await sut.save()
        XCTAssertEqual(result?.id, updated.id)
        XCTAssertEqual(result?.serviceType, "Tire Rotation")
    }

    func testSave_isLoadingFalse_afterSuccess() async {
        _ = await sut.save()
        XCTAssertFalse(sut.isLoading)
    }

    func testSave_clearsErrorMessage_beforeAttempt() async {
        sut.errorMessage = "previous error"
        _ = await sut.save()
        XCTAssertNil(sut.errorMessage)
    }

    // MARK: - save — Failure

    func testSave_returnsNil_onFailure() async {
        mockService.updateResult = .failure(APIError.serverError(500))
        let result = await sut.save()
        XCTAssertNil(result)
    }

    func testSave_setsErrorMessage_onFailure() async {
        mockService.updateResult = .failure(APIError.serverError(500))
        _ = await sut.save()
        XCTAssertNotNil(sut.errorMessage)
    }

    func testSave_isLoadingFalse_afterFailure() async {
        mockService.updateResult = .failure(APIError.serverError(500))
        _ = await sut.save()
        XCTAssertFalse(sut.isLoading)
    }

    func testSave_incrementsUpdateCallCount() async {
        _ = await sut.save()
        XCTAssertEqual(mockService.updateCallCount, 1)
    }

    // MARK: - Helpers

    private func makeEvent(
        serviceType: String = "Oil & Filter Change",
        date: String = "2024-03-12",
        mileage: Int? = 12450,
        cost: String? = "245.00",
        location: String? = "Precision Werkstatt",
        notes: String? = "Full synthetic oil change."
    ) -> ServiceEventResponse {
        ServiceEventResponse(
            id: stubEvent.id, vehicleId: stubEvent.vehicleId,
            serviceType: serviceType, serviceDate: date,
            mileage: mileage, cost: cost,
            location: location, notes: notes,
            createdAt: Date(), updatedAt: Date()
        )
    }
}
