import XCTest
@testable import GarageKeep

final class AuthServiceTests: XCTestCase {
    var sut: AuthService!
    var capturedRequests: [URLRequest] = []

    override func setUp() {
        super.setUp()
        capturedRequests = []
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let client = APIClient(session: URLSession(configuration: config))
        sut = AuthService(client: client)
    }

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    // MARK: - Login

    func testLogin_callsCorrectEndpoint() async throws {
        stubTokenResponse()
        var capturedRequest: URLRequest?
        let baseHandler = MockURLProtocol.requestHandler
        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            return try baseHandler!(request)
        }
        _ = try await sut.login(email: "test@example.com", password: "password")
        XCTAssertEqual(capturedRequest?.url?.path, "/v1/auth/login")
        XCTAssertEqual(capturedRequest?.httpMethod, "POST")
    }

    func testLogin_encodesEmailAndPassword() async throws {
        stubTokenResponse()
        var capturedBody: [String: String]?
        MockURLProtocol.requestHandler = { request in
            capturedBody = try? JSONDecoder().decode([String: String].self, from: request.bodyData ?? Data())
            return self.makeTokenResponse(for: request)
        }
        _ = try await sut.login(email: "user@test.com", password: "secret123")
        XCTAssertEqual(capturedBody?["email"], "user@test.com")
        XCTAssertEqual(capturedBody?["password"], "secret123")
    }

    func testLogin_returnsDecodedTokenResponse() async throws {
        stubTokenResponse()
        let result = try await sut.login(email: "test@example.com", password: "password")
        XCTAssertEqual(result.accessToken, "test-access-token")
        XCTAssertEqual(result.refreshToken, "test-refresh-token")
    }

    // MARK: - Register

    func testRegister_callsCorrectEndpoint() async throws {
        stubTokenResponse()
        var capturedRequest: URLRequest?
        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            return self.makeTokenResponse(for: request)
        }
        _ = try await sut.register(email: "new@example.com", password: "password", name: "Test User")
        XCTAssertEqual(capturedRequest?.url?.path, "/v1/auth/register")
        XCTAssertEqual(capturedRequest?.httpMethod, "POST")
    }

    func testRegister_encodesNameEmailPassword() async throws {
        var capturedBody: [String: String]?
        MockURLProtocol.requestHandler = { request in
            capturedBody = try? JSONDecoder().decode([String: String].self, from: request.bodyData ?? Data())
            return self.makeTokenResponse(for: request)
        }
        _ = try await sut.register(email: "new@example.com", password: "pass", name: "Jane Doe")
        XCTAssertEqual(capturedBody?["email"], "new@example.com")
        XCTAssertEqual(capturedBody?["name"], "Jane Doe")
    }

    // MARK: - Helpers

    private func stubTokenResponse() {
        let json = #"{"access_token":"test-access-token","refresh_token":"test-refresh-token","token_type":"Bearer","expires_in":3600}"#
        MockURLProtocol.stub(statusCode: 200, json: json)
    }

    private func makeTokenResponse(for request: URLRequest) -> (HTTPURLResponse, Data) {
        let url = request.url ?? URL(string: "http://127.0.0.1:8005")!
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let json = #"{"access_token":"test-access-token","refresh_token":"test-refresh-token","token_type":"Bearer","expires_in":3600}"#
        return (response, Data(json.utf8))
    }
}
