import XCTest
@testable import GarageKeep

final class VehicleServiceTests: XCTestCase {
    var sut: VehicleService!

    override func setUp() {
        super.setUp()
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let client = APIClient(session: URLSession(configuration: config))
        sut = VehicleService(apiClient: client)
    }

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    // MARK: - Fetch Vehicles

    func testFetchVehicles_callsCorrectEndpoint() async throws {
        stubVehicleListResponse()
        var capturedRequest: URLRequest?
        let baseHandler = MockURLProtocol.requestHandler
        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            return try baseHandler!(request)
        }
        _ = try await sut.fetchVehicles()
        XCTAssertEqual(capturedRequest?.url?.path, "/v1/vehicles")
        XCTAssertEqual(capturedRequest?.httpMethod, "GET")
    }

    func testFetchVehicles_returnsDecodedVehicles() async throws {
        stubVehicleListResponse()
        let result = try await sut.fetchVehicles()
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.make, "Toyota")
        XCTAssertEqual(result.first?.model, "Camry")
    }

    func testFetchVehicles_throwsOnServerError() async {
        MockURLProtocol.stub(statusCode: 500, json: "{}")
        do {
            _ = try await sut.fetchVehicles()
            XCTFail("Expected error")
        } catch APIError.serverError(let code) {
            XCTAssertEqual(code, 500)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Create Vehicle

    func testCreateVehicle_callsCorrectEndpoint() async throws {
        stubVehicleResponse()
        var capturedRequest: URLRequest?
        let baseHandler = MockURLProtocol.requestHandler
        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            return try baseHandler!(request)
        }
        let req = CreateVehicleRequest(make: "Honda", model: "Civic", year: 2020, vin: nil, licensePlate: nil)
        _ = try await sut.createVehicle(req)
        XCTAssertEqual(capturedRequest?.url?.path, "/v1/vehicles")
        XCTAssertEqual(capturedRequest?.httpMethod, "POST")
    }

    func testCreateVehicle_sendsCorrectBody() async throws {
        stubVehicleResponse()
        var capturedBody: [String: String?]?
        MockURLProtocol.requestHandler = { request in
            capturedBody = try? JSONDecoder().decode([String: String?].self, from: request.bodyData ?? Data())
            return self.makeVehicleResponse(for: request)
        }
        let req = CreateVehicleRequest(make: "Honda", model: "Civic", year: nil, vin: nil, licensePlate: nil)
        _ = try await sut.createVehicle(req)
        XCTAssertEqual(capturedBody?["make"] as? String, "Honda")
        XCTAssertEqual(capturedBody?["model"] as? String, "Civic")
    }

    func testCreateVehicle_throwsOnServerError() async {
        MockURLProtocol.stub(statusCode: 422, json: "{}")
        let req = CreateVehicleRequest(make: "Honda", model: "Civic", year: nil, vin: nil, licensePlate: nil)
        do {
            _ = try await sut.createVehicle(req)
            XCTFail("Expected error")
        } catch APIError.serverError(let code) {
            XCTAssertEqual(code, 422)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - VIN Decode

    func testDecodeVin_callsCorrectEndpoint() async throws {
        stubVinDecodeResponse()
        var capturedRequest: URLRequest?
        let baseHandler = MockURLProtocol.requestHandler
        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            return try baseHandler!(request)
        }
        _ = try await sut.decodeVin("1HGBH41JXMN109186")
        XCTAssertEqual(capturedRequest?.url?.path, "/v1/vehicles/vin-decode")
        XCTAssertEqual(capturedRequest?.url?.query, "vin=1HGBH41JXMN109186")
    }

    func testDecodeVin_returnsDecodedFields() async throws {
        stubVinDecodeResponse()
        let result = try await sut.decodeVin("1HGBH41JXMN109186")
        XCTAssertEqual(result.make, "Honda")
        XCTAssertEqual(result.model, "Civic")
        XCTAssertEqual(result.year, 2021)
    }

    func testDecodeVin_throwsOnServerError() async {
        MockURLProtocol.stub(statusCode: 404, json: "{}")
        do {
            _ = try await sut.decodeVin("1HGBH41JXMN109186")
            XCTFail("Expected error")
        } catch APIError.serverError(let code) {
            XCTAssertEqual(code, 404)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Helpers

    private func stubVehicleListResponse() {
        let json = #"""
        {"vehicles":[{"id":"00000000-0000-0000-0000-000000000001","user_id":"00000000-0000-0000-0000-000000000002","make":"Toyota","model":"Camry","year":2023,"vin":null,"license_plate":null,"created_at":"2024-01-01T00:00:00Z","updated_at":"2024-01-01T00:00:00Z"}],"total":1}
        """#
        MockURLProtocol.stub(statusCode: 200, json: json)
    }

    private func stubVehicleResponse() {
        MockURLProtocol.requestHandler = { request in
            return self.makeVehicleResponse(for: request)
        }
    }

    private func makeVehicleResponse(for request: URLRequest) -> (HTTPURLResponse, Data) {
        let url = request.url ?? URL(string: "http://127.0.0.1:8005")!
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let json = #"{"id":"00000000-0000-0000-0000-000000000001","user_id":"00000000-0000-0000-0000-000000000002","make":"Honda","model":"Civic","year":2020,"vin":null,"license_plate":null,"created_at":"2024-01-01T00:00:00Z","updated_at":"2024-01-01T00:00:00Z"}"#
        return (response, Data(json.utf8))
    }

    private func stubVinDecodeResponse() {
        let json = #"{"make":"Honda","model":"Civic","year":2021}"#
        MockURLProtocol.stub(statusCode: 200, json: json)
    }
}
