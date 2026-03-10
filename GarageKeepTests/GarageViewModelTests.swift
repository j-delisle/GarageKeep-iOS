import XCTest
@testable import GarageKeep

@MainActor
final class GarageViewModelTests: XCTestCase {
    var mockService: MockVehicleService!
    var sut: GarageViewModel!

    override func setUp() {
        super.setUp()
        mockService = MockVehicleService()
        sut = GarageViewModel(vehicleService: mockService)
    }

    // MARK: - Fetch Vehicles

    func testFetchVehicles_setsVehicles_onSuccess() async {
        mockService.fetchVehiclesResult = .success([.stub])
        await sut.fetchVehicles()
        XCTAssertEqual(sut.vehicles.count, 1)
        XCTAssertEqual(sut.vehicles.first?.make, "Toyota")
    }

    func testFetchVehicles_setsShowOnboarding_whenEmpty() async {
        mockService.fetchVehiclesResult = .success([])
        await sut.fetchVehicles()
        XCTAssertTrue(sut.showOnboarding)
    }

    func testFetchVehicles_doesNotSetOnboarding_whenVehiclesExist() async {
        mockService.fetchVehiclesResult = .success([.stub])
        await sut.fetchVehicles()
        XCTAssertFalse(sut.showOnboarding)
    }

    func testFetchVehicles_setsErrorMessage_onFailure() async {
        mockService.fetchVehiclesResult = .failure(APIError.serverError(500))
        await sut.fetchVehicles()
        XCTAssertNotNil(sut.errorMessage)
    }

    func testFetchVehicles_isLoadingFalse_afterCompletion() async {
        mockService.fetchVehiclesResult = .success([.stub])
        await sut.fetchVehicles()
        XCTAssertFalse(sut.isLoading)
    }

    func testFetchVehicles_clearsErrorOnRetry() async {
        mockService.fetchVehiclesResult = .failure(APIError.serverError(500))
        await sut.fetchVehicles()
        XCTAssertNotNil(sut.errorMessage)

        mockService.fetchVehiclesResult = .success([.stub])
        await sut.fetchVehicles()
        XCTAssertNil(sut.errorMessage)
    }
}
