import XCTest
@testable import GarageKeep

@MainActor
final class AddVehicleViewModelTests: XCTestCase {
    var mockService: MockVehicleService!
    var sut: AddVehicleViewModel!

    override func setUp() {
        super.setUp()
        mockService = MockVehicleService()
        sut = AddVehicleViewModel(vehicleService: mockService)
    }

    // MARK: - Init

    func testInitialState_isIdentityStep() {
        XCTAssertEqual(sut.currentStep, .identity)
        XCTAssertEqual(sut.inputMode, .vin)
    }

    func testInitialState_cannotAdvance() {
        XCTAssertFalse(sut.canAdvanceFromIdentity)
    }

    // MARK: - VIN Decode

    func testDecodeVin_setsVinDecoded_onSuccess() async {
        sut.vinInput = "1HGBH41JXMN109186"
        await sut.decodeVin()
        XCTAssertNotNil(sut.vinDecoded)
        XCTAssertEqual(sut.vinDecoded?.make, "Toyota")
        XCTAssertNil(sut.decodeError)
    }

    func testDecodeVin_setsDecodeError_onFailure() async {
        mockService.decodeVinResult = .failure(APIError.serverError(404))
        sut.vinInput = "1HGBH41JXMN109186"
        await sut.decodeVin()
        XCTAssertNil(sut.vinDecoded)
        XCTAssertNotNil(sut.decodeError)
    }

    func testDecodeVin_passesVinToService() async {
        sut.vinInput = "1HGBH41JXMN109186"
        await sut.decodeVin()
        XCTAssertEqual(mockService.lastDecodedVin, "1HGBH41JXMN109186")
    }

    func testDecodeVin_doesNotCallService_whenVinWrongLength() async {
        sut.vinInput = "SHORT"
        await sut.decodeVin()
        XCTAssertEqual(mockService.decodeVinCallCount, 0)
    }

    // MARK: - canAdvanceFromIdentity

    func testCanAdvance_inVinMode_requiresDecode() async {
        sut.vinInput = "1HGBH41JXMN109186"
        XCTAssertFalse(sut.canAdvanceFromIdentity)
        await sut.decodeVin()
        XCTAssertTrue(sut.canAdvanceFromIdentity)
    }

    func testCanAdvance_inManualMode_requiresMakeAndModel() {
        sut.switchMode(to: .manual)
        XCTAssertFalse(sut.canAdvanceFromIdentity)
        sut.make = "Honda"
        XCTAssertFalse(sut.canAdvanceFromIdentity)
        sut.model = "Civic"
        XCTAssertTrue(sut.canAdvanceFromIdentity)
    }

    // MARK: - Step Navigation

    func testAdvanceToReview_changesStep() {
        sut.advanceToReview()
        XCTAssertEqual(sut.currentStep, .review)
    }

    func testBackToIdentity_changesStep() {
        sut.advanceToReview()
        sut.backToIdentity()
        XCTAssertEqual(sut.currentStep, .identity)
    }

    // MARK: - Submit

    func testSubmit_callsCreateVehicle() async {
        sut.switchMode(to: .manual)
        sut.make = "Honda"
        sut.model = "Civic"
        _ = await sut.submit()
        XCTAssertEqual(mockService.createVehicleCallCount, 1)
    }

    func testSubmit_sendsCorrectPayload_manualMode() async {
        sut.switchMode(to: .manual)
        sut.make = "Honda"
        sut.model = "Civic"
        sut.year = "2020"
        _ = await sut.submit()
        XCTAssertEqual(mockService.lastCreatedRequest?.make, "Honda")
        XCTAssertEqual(mockService.lastCreatedRequest?.model, "Civic")
        XCTAssertEqual(mockService.lastCreatedRequest?.year, 2020)
        XCTAssertNil(mockService.lastCreatedRequest?.vin)
    }

    func testSubmit_sendsVin_inVinMode() async {
        sut.vinInput = "1HGBH41JXMN109186"
        await sut.decodeVin()
        _ = await sut.submit()
        XCTAssertEqual(mockService.lastCreatedRequest?.vin, "1HGBH41JXMN109186")
    }

    func testSubmit_returnsVehicle_onSuccess() async {
        sut.switchMode(to: .manual)
        sut.make = "Honda"
        sut.model = "Civic"
        let result = await sut.submit()
        XCTAssertNotNil(result)
    }

    func testSubmit_returnsNil_onFailure() async {
        mockService.createVehicleResult = .failure(APIError.serverError(500))
        sut.switchMode(to: .manual)
        sut.make = "Honda"
        sut.model = "Civic"
        let result = await sut.submit()
        XCTAssertNil(result)
        XCTAssertNotNil(sut.errorMessage)
    }

    func testSubmit_isLoadingFalse_afterCompletion() async {
        sut.switchMode(to: .manual)
        sut.make = "Honda"
        sut.model = "Civic"
        _ = await sut.submit()
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - SwitchMode

    func testSwitchMode_clearsVinDecode() async {
        sut.vinInput = "1HGBH41JXMN109186"
        await sut.decodeVin()
        XCTAssertNotNil(sut.vinDecoded)
        sut.switchMode(to: .manual)
        XCTAssertNil(sut.vinDecoded)
    }
}
