import XCTest
@testable import GarageKeep

@MainActor
final class ServiceHistoryViewModelTests: XCTestCase {
    var mockService: MockServiceEventService!
    var stubVehicle: VehicleResponse!
    var sut: ServiceHistoryViewModel!

    override func setUp() {
        super.setUp()
        mockService = MockServiceEventService()
        stubVehicle = VehicleResponse(
            id: UUID(), userId: UUID(),
            make: "Porsche", model: "911 GT3",
            year: 2022, vin: "WP0AA2A90NS200001",
            licensePlate: nil,
            createdAt: Date(), updatedAt: Date()
        )
        sut = ServiceHistoryViewModel(vehicle: stubVehicle, serviceEventService: mockService)
    }

    // MARK: - Initial State

    func testInitialState_eventsEmpty() {
        XCTAssertTrue(sut.events.isEmpty)
    }

    func testInitialState_isLoadingFalse() {
        XCTAssertFalse(sut.isLoading)
    }

    func testInitialState_hasNoPages() {
        XCTAssertFalse(sut.hasMorePages)
    }

    // MARK: - loadInitial — Success

    func testLoadInitial_setsEvents_onSuccess() async {
        mockService.fetchResult = .success(
            ServiceEventListResponse(services: ServiceEventResponse.stubs, total: ServiceEventResponse.stubs.count)
        )
        await sut.loadInitial()
        XCTAssertEqual(sut.events.count, ServiceEventResponse.stubs.count)
    }

    func testLoadInitial_setsTotalCount() async {
        mockService.fetchResult = .success(ServiceEventListResponse(services: [.stub], total: 42))
        await sut.loadInitial()
        XCTAssertTrue(sut.hasMorePages)
    }

    func testLoadInitial_isLoadingFalse_afterCompletion() async {
        mockService.fetchResult = .success(ServiceEventListResponse(services: [], total: 0))
        await sut.loadInitial()
        XCTAssertFalse(sut.isLoading)
    }

    func testLoadInitial_clearsErrorOnRetry() async {
        mockService.fetchResult = .failure(APIError.serverError(500))
        await sut.loadInitial()
        XCTAssertNotNil(sut.errorMessage)

        mockService.fetchResult = .success(ServiceEventListResponse(services: [.stub], total: 1))
        await sut.loadInitial()
        XCTAssertNil(sut.errorMessage)
    }

    func testLoadInitial_callsServiceWithVehicleId() async {
        await sut.loadInitial()
        XCTAssertEqual(mockService.lastFetchVehicleId, stubVehicle.id)
    }

    func testLoadInitial_callsServiceWithOffsetZero() async {
        await sut.loadInitial()
        XCTAssertEqual(mockService.lastFetchOffset, 0)
    }

    // MARK: - loadInitial — Failure

    func testLoadInitial_setsErrorMessage_onFailure() async {
        mockService.fetchResult = .failure(APIError.serverError(500))
        await sut.loadInitial()
        XCTAssertNotNil(sut.errorMessage)
    }

    func testLoadInitial_keepsEventsEmpty_onFailure() async {
        mockService.fetchResult = .failure(APIError.serverError(500))
        await sut.loadInitial()
        XCTAssertTrue(sut.events.isEmpty)
    }

    // MARK: - loadMore

    func testLoadMore_appendsEvents() async {
        let first = makeEvent(date: "2024-08-01")
        let second = makeEvent(date: "2024-06-01")
        mockService.fetchResult = .success(ServiceEventListResponse(services: [first], total: 2))
        await sut.loadInitial()

        mockService.fetchResult = .success(ServiceEventListResponse(services: [second], total: 2))
        await sut.loadMore()

        XCTAssertEqual(sut.events.count, 2)
    }

    func testLoadMore_doesNotLoad_whenNoMorePages() async {
        mockService.fetchResult = .success(ServiceEventListResponse(services: [.stub], total: 1))
        await sut.loadInitial()
        XCTAssertFalse(sut.hasMorePages)

        let countBefore = mockService.fetchCallCount
        await sut.loadMore()
        XCTAssertEqual(mockService.fetchCallCount, countBefore)
    }

    func testLoadMore_silentlyIgnoresError() async {
        mockService.fetchResult = .success(ServiceEventListResponse(services: [.stub], total: 2))
        await sut.loadInitial()

        mockService.fetchResult = .failure(APIError.serverError(500))
        await sut.loadMore()

        XCTAssertEqual(sut.events.count, 1)
        XCTAssertNil(sut.errorMessage)
    }

    // MARK: - totalSpent

    func testTotalSpent_sumsDecimalCosts() async {
        mockService.fetchResult = .success(ServiceEventListResponse(services: [
            makeEvent(cost: "49.99"),
            makeEvent(cost: "100.01"),
            makeEvent(cost: nil)
        ], total: 3))
        await sut.loadInitial()
        XCTAssertEqual(sut.totalSpent, Decimal(string: "150.00")!)
    }

    func testTotalSpent_ignoresNilCosts() async {
        mockService.fetchResult = .success(ServiceEventListResponse(services: [
            makeEvent(cost: nil),
            makeEvent(cost: nil)
        ], total: 2))
        await sut.loadInitial()
        XCTAssertEqual(sut.totalSpent, .zero)
    }

    func testTotalSpent_isZero_whenNoEvents() {
        XCTAssertEqual(sut.totalSpent, .zero)
    }

    func testTotalSpent_handlesZeroCostEntries() async {
        mockService.fetchResult = .success(ServiceEventListResponse(services: [
            makeEvent(cost: "0.00"),
            makeEvent(cost: "50.00")
        ], total: 2))
        await sut.loadInitial()
        XCTAssertEqual(sut.totalSpent, Decimal(string: "50.00")!)
    }

    // MARK: - maskedVin

    func testMaskedVin_shows12VisibleChars_masks5() {
        // stubVehicle has vin: "WP0AA2A90NS200001" (17 chars)
        XCTAssertEqual(ServiceHistoryViewModel.maskedVin(for: stubVehicle), "WP0AA2A90NS2*****")
    }

    func testMaskedVin_returnsDash_ifVinNil() {
        let vehicle = VehicleResponse(
            id: UUID(), userId: UUID(), make: "BMW", model: "X5",
            year: 2023, vin: nil, licensePlate: nil,
            createdAt: Date(), updatedAt: Date()
        )
        XCTAssertEqual(ServiceHistoryViewModel.maskedVin(for: vehicle), "—")
    }

    func testMaskedVin_returnsRawVin_ifNot17Chars() {
        let vehicle = VehicleResponse(
            id: UUID(), userId: UUID(), make: "BMW", model: "X5",
            year: 2023, vin: "ABC123", licensePlate: nil,
            createdAt: Date(), updatedAt: Date()
        )
        XCTAssertEqual(ServiceHistoryViewModel.maskedVin(for: vehicle), "ABC123")
    }

    // MARK: - sortedEvents

    func testSortedEvents_descending_byServiceDate() async {
        let older = makeEvent(date: "2024-01-01")
        let newer = makeEvent(date: "2024-08-15")
        let middle = makeEvent(date: "2024-04-20")
        mockService.fetchResult = .success(ServiceEventListResponse(services: [older, newer, middle], total: 3))
        await sut.loadInitial()

        XCTAssertEqual(sut.sortedEvents[0].serviceDate, "2024-08-15")
        XCTAssertEqual(sut.sortedEvents[1].serviceDate, "2024-04-20")
        XCTAssertEqual(sut.sortedEvents[2].serviceDate, "2024-01-01")
    }

    // MARK: - hasMorePages

    func testHasMorePages_falseWhenAllLoaded() async {
        mockService.fetchResult = .success(ServiceEventListResponse(services: [.stub], total: 1))
        await sut.loadInitial()
        XCTAssertFalse(sut.hasMorePages)
    }

    func testHasMorePages_trueWhenMoreExist() async {
        mockService.fetchResult = .success(ServiceEventListResponse(services: [.stub], total: 5))
        await sut.loadInitial()
        XCTAssertTrue(sut.hasMorePages)
    }

    // MARK: - iconName

    func testIconName_oilChange() {
        XCTAssertEqual(ServiceHistoryViewModel.iconName(for: "Oil Change"), "drop.fill")
    }

    func testIconName_tireRotation() {
        XCTAssertEqual(ServiceHistoryViewModel.iconName(for: "Tire Rotation"), "arrow.2.circlepath")
    }

    func testIconName_brakes() {
        XCTAssertEqual(ServiceHistoryViewModel.iconName(for: "Brake Pad Replacement"), "exclamationmark.octagon.fill")
    }

    func testIconName_default_unknownType() {
        XCTAssertEqual(ServiceHistoryViewModel.iconName(for: "Something Random"), "wrench.and.screwdriver.fill")
    }

    func testIconName_caseInsensitive() {
        XCTAssertEqual(ServiceHistoryViewModel.iconName(for: "OIL CHANGE"), "drop.fill")
        XCTAssertEqual(ServiceHistoryViewModel.iconName(for: "oil change"), "drop.fill")
    }

    // MARK: - deleteEvent

    func testDeleteEvent_removesFromEvents_optimistically() async {
        let event = ServiceEventResponse.stub
        mockService.fetchResult = .success(ServiceEventListResponse(services: [event], total: 1))
        await sut.loadInitial()

        await sut.deleteEvent(event)
        XCTAssertFalse(sut.events.contains(where: { $0.id == event.id }))
    }

    func testDeleteEvent_callsServiceWithCorrectId() async {
        let event = ServiceEventResponse.stub
        mockService.fetchResult = .success(ServiceEventListResponse(services: [event], total: 1))
        await sut.loadInitial()

        await sut.deleteEvent(event)
        XCTAssertEqual(mockService.lastDeletedServiceId, event.id)
    }

    func testDeleteEvent_rollsBack_onFailure() async {
        let event = ServiceEventResponse.stub
        mockService.fetchResult = .success(ServiceEventListResponse(services: [event], total: 1))
        await sut.loadInitial()

        mockService.deleteResult = .failure(APIError.serverError(500))
        await sut.deleteEvent(event)

        XCTAssertTrue(sut.events.contains(where: { $0.id == event.id }))
    }

    func testDeleteEvent_setsErrorMessage_onFailure() async {
        let event = ServiceEventResponse.stub
        mockService.fetchResult = .success(ServiceEventListResponse(services: [event], total: 1))
        await sut.loadInitial()

        mockService.deleteResult = .failure(APIError.serverError(500))
        await sut.deleteEvent(event)

        XCTAssertNotNil(sut.errorMessage)
    }

    // MARK: - removeEvent

    func testRemoveEvent_removesFromList() async {
        let event = ServiceEventResponse.stub
        mockService.fetchResult = .success(ServiceEventListResponse(services: [event], total: 1))
        await sut.loadInitial()

        sut.removeEvent(event)
        XCTAssertFalse(sut.events.contains(where: { $0.id == event.id }))
    }

    func testRemoveEvent_decrementsCount() async {
        let event = ServiceEventResponse.stub
        mockService.fetchResult = .success(ServiceEventListResponse(services: [event], total: 1))
        await sut.loadInitial()

        sut.removeEvent(event)
        XCTAssertFalse(sut.hasMorePages)
    }

    func testRemoveEvent_isNoOp_forUnknownEvent() {
        let unknown = ServiceEventResponse.stub
        sut.removeEvent(unknown)
        XCTAssertTrue(sut.events.isEmpty)
    }

    // MARK: - replaceEvent

    func testReplaceEvent_updatesEventInPlace() async {
        let original = makeEvent(date: "2024-01-01")
        mockService.fetchResult = .success(ServiceEventListResponse(services: [original], total: 1))
        await sut.loadInitial()

        let updated = ServiceEventResponse(
            id: original.id, vehicleId: original.vehicleId,
            serviceType: "Tire Rotation", serviceDate: "2024-01-01",
            mileage: 15000, cost: "75.00", location: nil, notes: nil,
            createdAt: original.createdAt, updatedAt: Date()
        )
        sut.replaceEvent(original, with: updated)

        XCTAssertEqual(sut.events.first?.serviceType, "Tire Rotation")
        XCTAssertEqual(sut.events.count, 1)
    }

    func testReplaceEvent_isNoOp_forUnknownEvent() async {
        let event = makeEvent(date: "2024-01-01")
        mockService.fetchResult = .success(ServiceEventListResponse(services: [event], total: 1))
        await sut.loadInitial()

        let unrelated = ServiceEventResponse.stub
        sut.replaceEvent(unrelated, with: unrelated)

        XCTAssertEqual(sut.events.first?.id, event.id)
    }

    // MARK: - Helpers

    private func makeEvent(date: String = "2024-01-01", cost: String? = "50.00") -> ServiceEventResponse {
        ServiceEventResponse(
            id: UUID(), vehicleId: stubVehicle.id,
            serviceType: "Oil Change", serviceDate: date,
            mileage: 10000, cost: cost, location: nil, notes: nil,
            createdAt: Date(), updatedAt: Date()
        )
    }
}
