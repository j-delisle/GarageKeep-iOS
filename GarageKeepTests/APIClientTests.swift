import XCTest
@testable import GarageKeep

final class APIClientTests: XCTestCase {
    var sut: APIClient!

    override func setUp() {
        super.setUp()
        KeychainHelper.clearAll()
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        sut = APIClient(session: URLSession(configuration: config))
    }

    override func tearDown() {
        KeychainHelper.clearAll()
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private struct SimpleResponse: Decodable { let value: String }

    // MARK: - Auth Header

    func testRequest_injectsAuthHeader_whenTokenExists() async throws {
        KeychainHelper.save("my-token", for: KeychainHelper.accessTokenKey)
        var capturedRequest: URLRequest?
        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            return self.makeResponse(statusCode: 200, json: #"{"value":"ok"}"#, for: request)
        }
        let _: SimpleResponse = try await sut.request("/v1/test", requiresAuth: true)
        XCTAssertEqual(capturedRequest?.value(forHTTPHeaderField: "Authorization"), "Bearer my-token")
    }

    func testRequest_omitsAuthHeader_whenRequiresAuthFalse() async throws {
        var capturedRequest: URLRequest?
        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            return self.makeResponse(statusCode: 200, json: #"{"value":"ok"}"#, for: request)
        }
        let _: SimpleResponse = try await sut.request("/v1/test", requiresAuth: false)
        XCTAssertNil(capturedRequest?.value(forHTTPHeaderField: "Authorization"))
    }

    // MARK: - Decoding

    func testRequest_decodesResponseCorrectly() async throws {
        MockURLProtocol.stub(statusCode: 200, json: #"{"value":"hello"}"#)
        let result: SimpleResponse = try await sut.request("/v1/test", requiresAuth: false)
        XCTAssertEqual(result.value, "hello")
    }

    func testRequest_throwsDecodingError_onBadJSON() async {
        MockURLProtocol.stub(statusCode: 200, json: "not-json")
        await assertThrows(APIError.decodingError(URLError(.unknown))) {
            let _: SimpleResponse = try await self.sut.request("/v1/test", requiresAuth: false)
        }
    }

    // MARK: - Error Handling

    func testRequest_throwsServerError_on500() async {
        MockURLProtocol.stub(statusCode: 500, json: "{}")
        do {
            let _: SimpleResponse = try await sut.request("/v1/test", requiresAuth: false)
            XCTFail("Expected serverError")
        } catch APIError.serverError(let code) {
            XCTAssertEqual(code, 500)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - 401 Handling

    func testRequest_throwsInvalidCredentials_on401_whenRequiresAuthFalse() async {
        MockURLProtocol.stub(statusCode: 401, json: "{}")
        do {
            let _: SimpleResponse = try await sut.request("/v1/auth/login", requiresAuth: false)
            XCTFail("Expected invalidCredentials")
        } catch APIError.invalidCredentials {
            // pass
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testRequest_postsSessionExpiredNotification_on401_whenRefreshFails() async {
        MockURLProtocol.stub(statusCode: 401, json: "{}")
        let expectation = XCTestExpectation(description: "sessionExpired notification posted")
        let observer = NotificationCenter.default.addObserver(
            forName: .sessionExpired, object: nil, queue: .main
        ) { _ in expectation.fulfill() }
        defer { NotificationCenter.default.removeObserver(observer) }

        _ = try? await sut.request("/v1/test", requiresAuth: true) as SimpleResponse
        await fulfillment(of: [expectation], timeout: 2)
    }

    func testRequest_doesNotPostSessionExpiredNotification_whenRequiresAuthFalse() async {
        MockURLProtocol.stub(statusCode: 401, json: "{}")
        var notificationFired = false
        let observer = NotificationCenter.default.addObserver(
            forName: .sessionExpired, object: nil, queue: .main
        ) { _ in notificationFired = true }
        defer { NotificationCenter.default.removeObserver(observer) }

        _ = try? await sut.request("/v1/auth/login", requiresAuth: false) as SimpleResponse
        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertFalse(notificationFired)
    }

    func testRequest_throwsUnauthorized_on401_whenNoRefreshToken() async {
        MockURLProtocol.stub(statusCode: 401, json: "{}")
        do {
            let _: SimpleResponse = try await sut.request("/v1/test", requiresAuth: true)
            XCTFail("Expected unauthorized")
        } catch APIError.unauthorized {
            // pass
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testRequest_retriesAfterSuccessfulTokenRefresh() async throws {
        KeychainHelper.save("old-token", for: KeychainHelper.accessTokenKey)
        KeychainHelper.save("valid-refresh", for: KeychainHelper.refreshTokenKey)

        var callCount = 0
        MockURLProtocol.requestHandler = { request in
            callCount += 1
            if callCount == 1 {
                // First call: 401
                return self.makeResponse(statusCode: 401, json: "{}", for: request)
            } else if request.url?.path.contains("/auth/refresh") == true {
                // Refresh endpoint
                let json = #"{"access_token":"new-token","refresh_token":"new-refresh","token_type":"Bearer","expires_in":3600}"#
                return self.makeResponse(statusCode: 200, json: json, for: request)
            } else {
                // Retry with new token
                return self.makeResponse(statusCode: 200, json: #"{"value":"ok"}"#, for: request)
            }
        }

        let result: SimpleResponse = try await sut.request("/v1/test", requiresAuth: true)
        XCTAssertEqual(result.value, "ok")
        XCTAssertEqual(KeychainHelper.read(for: KeychainHelper.accessTokenKey), "new-token")
    }

    // MARK: - Helpers

    private func makeResponse(statusCode: Int, json: String, for request: URLRequest) -> (HTTPURLResponse, Data) {
        let url = request.url ?? URL(string: "http://127.0.0.1:8005")!
        let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
        return (response, Data(json.utf8))
    }

    private func assertThrows<E: Error>(_ expectedError: E, block: () async throws -> Void) async {
        do {
            try await block()
            XCTFail("Expected error to be thrown")
        } catch is E {
            // pass
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
}
