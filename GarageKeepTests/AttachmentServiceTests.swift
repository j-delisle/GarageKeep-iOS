import XCTest
@testable import GarageKeep

final class AttachmentServiceTests: XCTestCase {
    var sut: AttachmentService!
    let serviceId = UUID()
    let attachmentId = UUID()
    let s3URL = "https://s3.amazonaws.com/test-bucket"

    override func setUp() {
        super.setUp()
        KeychainHelper.save("test-token", for: KeychainHelper.accessTokenKey)
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        sut = AttachmentService(session: URLSession(configuration: config))
    }

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        KeychainHelper.clearAll()
        super.tearDown()
    }

    // MARK: - Helpers

    /// Stubs all 3 steps and returns an array that captures each request in order.
    @discardableResult
    private func stubFullFlow(
        s3StatusCode: Int = 204,
        confirmStatusCode: Int = 200
    ) -> [URLRequest] {
        var capturedRequests: [URLRequest] = []
        var queue: [(URLRequest) throws -> (HTTPURLResponse, Data)] = [
            { [self] req in
                capturedRequests.append(req)
                return self.makeUploadUrlResponse()
            },
            { [self] req in
                capturedRequests.append(req)
                return self.makeS3Response(statusCode: s3StatusCode)
            },
            { [self] req in
                capturedRequests.append(req)
                return self.makeConfirmResponse(statusCode: confirmStatusCode)
            }
        ]
        MockURLProtocol.requestHandler = { req in
            guard !queue.isEmpty else {
                throw URLError(.badServerResponse)
            }
            return try queue.removeFirst()(req)
        }
        return capturedRequests
    }

    private func makeUploadUrlResponse() -> (HTTPURLResponse, Data) {
        let url = URL(string: "http://127.0.0.1:8005")!
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let json = """
        [
            {
                "attachment_id": "\(attachmentId)",
                "upload_url": "\(s3URL)",
                "upload_fields": {
                    "key": "uploads/receipt.jpg",
                    "policy": "base64encodedpolicy"
                },
                "s3_key": "uploads/receipt.jpg",
                "expires_in": 3600
            }
        ]
        """
        return (response, Data(json.utf8))
    }

    private func makeS3Response(statusCode: Int) -> (HTTPURLResponse, Data) {
        let url = URL(string: s3URL)!
        let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
        return (response, Data())
    }

    private func makeConfirmResponse(statusCode: Int) -> (HTTPURLResponse, Data) {
        let url = URL(string: "http://127.0.0.1:8005")!
        let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
        let json = """
        {
            "id": "\(UUID())",
            "service_event_id": "\(serviceId)",
            "file_name": "receipt.jpg",
            "file_type": "image/jpeg",
            "file_url": "https://example.com/receipt.jpg",
            "file_size": 12345,
            "uploaded_at": "2026-03-14T10:00:00Z",
            "created_at": "2026-03-14T10:00:00Z"
        }
        """
        return (response, Data(json.utf8))
    }

    private func performUpload(
        fileName: String = "receipt.jpg",
        mimeType: String = "image/jpeg",
        payload: Data = Data("test-image-bytes".utf8)
    ) async throws -> AttachmentResponse {
        try await sut.uploadAttachment(
            serviceId: serviceId,
            data: payload,
            fileName: fileName,
            mimeType: mimeType
        )
    }

    // MARK: - Step 1: Request Upload URL

    func testStep1_callsUploadUrlEndpoint() async throws {
        var step1Request: URLRequest?
        var queue: [(URLRequest) throws -> (HTTPURLResponse, Data)] = [
            { [self] req in step1Request = req; return self.makeUploadUrlResponse() },
            { [self] req in return self.makeS3Response(statusCode: 204) },
            { [self] req in return self.makeConfirmResponse(statusCode: 200) }
        ]
        MockURLProtocol.requestHandler = { req in try queue.removeFirst()(req) }

        _ = try await performUpload()

        XCTAssertEqual(step1Request?.url?.path, "/v1/services/\(serviceId)/attachments/upload-urls")
        XCTAssertEqual(step1Request?.httpMethod, "POST")
    }

    func testStep1_hasAuthorizationHeader() async throws {
        var step1Request: URLRequest?
        var queue: [(URLRequest) throws -> (HTTPURLResponse, Data)] = [
            { [self] req in step1Request = req; return self.makeUploadUrlResponse() },
            { [self] req in return self.makeS3Response(statusCode: 204) },
            { [self] req in return self.makeConfirmResponse(statusCode: 200) }
        ]
        MockURLProtocol.requestHandler = { req in try queue.removeFirst()(req) }

        _ = try await performUpload()

        XCTAssertEqual(step1Request?.value(forHTTPHeaderField: "Authorization"), "Bearer test-token")
    }

    func testStep1_bodyIsJsonArrayWithFileNameAndFileType() async throws {
        var step1Request: URLRequest?
        var queue: [(URLRequest) throws -> (HTTPURLResponse, Data)] = [
            { [self] req in step1Request = req; return self.makeUploadUrlResponse() },
            { [self] req in return self.makeS3Response(statusCode: 204) },
            { [self] req in return self.makeConfirmResponse(statusCode: 200) }
        ]
        MockURLProtocol.requestHandler = { req in try queue.removeFirst()(req) }

        _ = try await performUpload(fileName: "my-receipt.jpg", mimeType: "image/jpeg")

        guard let bodyData = step1Request?.bodyData,
              let decoded = try? JSONSerialization.jsonObject(with: bodyData) as? [[String: String]] else {
            XCTFail("Step 1 body is not a JSON array")
            return
        }
        XCTAssertEqual(decoded.count, 1)
        XCTAssertEqual(decoded[0]["file_name"], "my-receipt.jpg")
        XCTAssertEqual(decoded[0]["file_type"], "image/jpeg")
    }

    func testStep1_throwsOnServerError() async {
        MockURLProtocol.stub(statusCode: 500, json: "{}")

        do {
            _ = try await performUpload()
            XCTFail("Expected error")
        } catch APIError.serverError(let code) {
            XCTAssertEqual(code, 500)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testStep1_throwsOnMalformedJSON() async {
        MockURLProtocol.stub(statusCode: 200, json: "not-json")

        do {
            _ = try await performUpload()
            XCTFail("Expected decoding error")
        } catch APIError.decodingError {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Step 2: Upload to S3

    func testStep2_postsToPresignedS3URL() async throws {
        var step2Request: URLRequest?
        var queue: [(URLRequest) throws -> (HTTPURLResponse, Data)] = [
            { [self] req in return self.makeUploadUrlResponse() },
            { [self] req in step2Request = req; return self.makeS3Response(statusCode: 204) },
            { [self] req in return self.makeConfirmResponse(statusCode: 200) }
        ]
        MockURLProtocol.requestHandler = { req in try queue.removeFirst()(req) }

        _ = try await performUpload()

        XCTAssertEqual(step2Request?.url?.absoluteString, s3URL)
        XCTAssertEqual(step2Request?.httpMethod, "POST")
    }

    func testStep2_hasNoAuthorizationHeader() async throws {
        var step2Request: URLRequest?
        var queue: [(URLRequest) throws -> (HTTPURLResponse, Data)] = [
            { [self] req in return self.makeUploadUrlResponse() },
            { [self] req in step2Request = req; return self.makeS3Response(statusCode: 204) },
            { [self] req in return self.makeConfirmResponse(statusCode: 200) }
        ]
        MockURLProtocol.requestHandler = { req in try queue.removeFirst()(req) }

        _ = try await performUpload()

        XCTAssertNil(step2Request?.value(forHTTPHeaderField: "Authorization"),
                     "S3 request must not include Authorization header")
    }

    func testStep2_usesMultipartContentType() async throws {
        var step2Request: URLRequest?
        var queue: [(URLRequest) throws -> (HTTPURLResponse, Data)] = [
            { [self] req in return self.makeUploadUrlResponse() },
            { [self] req in step2Request = req; return self.makeS3Response(statusCode: 204) },
            { [self] req in return self.makeConfirmResponse(statusCode: 200) }
        ]
        MockURLProtocol.requestHandler = { req in try queue.removeFirst()(req) }

        _ = try await performUpload()

        let contentType = step2Request?.value(forHTTPHeaderField: "Content-Type") ?? ""
        XCTAssertTrue(contentType.hasPrefix("multipart/form-data; boundary="))
    }

    func testStep2_bodyIncludesUploadFields() async throws {
        var step2Request: URLRequest?
        var queue: [(URLRequest) throws -> (HTTPURLResponse, Data)] = [
            { [self] req in return self.makeUploadUrlResponse() },
            { [self] req in step2Request = req; return self.makeS3Response(statusCode: 204) },
            { [self] req in return self.makeConfirmResponse(statusCode: 200) }
        ]
        MockURLProtocol.requestHandler = { req in try queue.removeFirst()(req) }

        _ = try await performUpload()

        let bodyString = step2Request?.bodyData.flatMap { String(data: $0, encoding: .utf8) } ?? ""
        // Both presigned fields from makeUploadUrlResponse should be present
        XCTAssertTrue(bodyString.contains("uploads/receipt.jpg"), "Missing 'key' field value")
        XCTAssertTrue(bodyString.contains("base64encodedpolicy"), "Missing 'policy' field value")
    }

    func testStep2_bodyIncludesFileData() async throws {
        var step2Request: URLRequest?
        var queue: [(URLRequest) throws -> (HTTPURLResponse, Data)] = [
            { [self] req in return self.makeUploadUrlResponse() },
            { [self] req in step2Request = req; return self.makeS3Response(statusCode: 204) },
            { [self] req in return self.makeConfirmResponse(statusCode: 200) }
        ]
        MockURLProtocol.requestHandler = { req in try queue.removeFirst()(req) }

        let payload = Data("unique-image-content".utf8)
        _ = try await performUpload(payload: payload)

        let bodyString = step2Request?.bodyData.flatMap { String(data: $0, encoding: .utf8) } ?? ""
        XCTAssertTrue(bodyString.contains("unique-image-content"))
    }

    func testStep2_bodyIncludesMimeType() async throws {
        var step2Request: URLRequest?
        var queue: [(URLRequest) throws -> (HTTPURLResponse, Data)] = [
            { [self] req in return self.makeUploadUrlResponse() },
            { [self] req in step2Request = req; return self.makeS3Response(statusCode: 204) },
            { [self] req in return self.makeConfirmResponse(statusCode: 200) }
        ]
        MockURLProtocol.requestHandler = { req in try queue.removeFirst()(req) }

        _ = try await performUpload(mimeType: "image/png")

        let bodyString = step2Request?.bodyData.flatMap { String(data: $0, encoding: .utf8) } ?? ""
        XCTAssertTrue(bodyString.contains("image/png"))
    }

    func testStep2_throwsOnS3Error() async {
        var queue: [(URLRequest) throws -> (HTTPURLResponse, Data)] = [
            { [self] req in return self.makeUploadUrlResponse() },
            { [self] req in return self.makeS3Response(statusCode: 403) },
            { [self] req in return self.makeConfirmResponse(statusCode: 200) }
        ]
        MockURLProtocol.requestHandler = { req in try queue.removeFirst()(req) }

        do {
            _ = try await performUpload()
            XCTFail("Expected error")
        } catch APIError.serverError(let code) {
            XCTAssertEqual(code, 403)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Step 3: Confirm Upload

    func testStep3_callsConfirmEndpoint() async throws {
        var step3Request: URLRequest?
        var queue: [(URLRequest) throws -> (HTTPURLResponse, Data)] = [
            { [self] req in return self.makeUploadUrlResponse() },
            { [self] req in return self.makeS3Response(statusCode: 204) },
            { [self] req in step3Request = req; return self.makeConfirmResponse(statusCode: 200) }
        ]
        MockURLProtocol.requestHandler = { req in try queue.removeFirst()(req) }

        _ = try await performUpload()

        XCTAssertEqual(step3Request?.url?.path, "/v1/attachments/\(attachmentId)/confirm")
        XCTAssertEqual(step3Request?.httpMethod, "POST")
    }

    func testStep3_hasAuthorizationHeader() async throws {
        var step3Request: URLRequest?
        var queue: [(URLRequest) throws -> (HTTPURLResponse, Data)] = [
            { [self] req in return self.makeUploadUrlResponse() },
            { [self] req in return self.makeS3Response(statusCode: 204) },
            { [self] req in step3Request = req; return self.makeConfirmResponse(statusCode: 200) }
        ]
        MockURLProtocol.requestHandler = { req in try queue.removeFirst()(req) }

        _ = try await performUpload()

        XCTAssertEqual(step3Request?.value(forHTTPHeaderField: "Authorization"), "Bearer test-token")
    }

    func testStep3_throwsOnServerError() async {
        var queue: [(URLRequest) throws -> (HTTPURLResponse, Data)] = [
            { [self] req in return self.makeUploadUrlResponse() },
            { [self] req in return self.makeS3Response(statusCode: 204) },
            { [self] req in return self.makeConfirmResponse(statusCode: 500) }
        ]
        MockURLProtocol.requestHandler = { req in try queue.removeFirst()(req) }

        do {
            _ = try await performUpload()
            XCTFail("Expected error")
        } catch APIError.serverError(let code) {
            XCTAssertEqual(code, 500)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testStep3_throwsOnMalformedJSON() async {
        var queue: [(URLRequest) throws -> (HTTPURLResponse, Data)] = [
            { [self] req in return self.makeUploadUrlResponse() },
            { [self] req in return self.makeS3Response(statusCode: 204) },
            { [self] req in
                let url = URL(string: "http://127.0.0.1:8005")!
                let r = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (r, Data("not-json".utf8))
            }
        ]
        MockURLProtocol.requestHandler = { req in try queue.removeFirst()(req) }

        do {
            _ = try await performUpload()
            XCTFail("Expected decoding error")
        } catch APIError.decodingError {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Full Happy Path

    func testFullFlow_makesExactlyThreeRequests() async throws {
        var requestCount = 0
        var queue: [(URLRequest) throws -> (HTTPURLResponse, Data)] = [
            { [self] req in requestCount += 1; return self.makeUploadUrlResponse() },
            { [self] req in requestCount += 1; return self.makeS3Response(statusCode: 204) },
            { [self] req in requestCount += 1; return self.makeConfirmResponse(statusCode: 200) }
        ]
        MockURLProtocol.requestHandler = { req in try queue.removeFirst()(req) }

        _ = try await performUpload()

        XCTAssertEqual(requestCount, 3)
    }

    func testFullFlow_returnsDecodedAttachmentResponse() async throws {
        var queue: [(URLRequest) throws -> (HTTPURLResponse, Data)] = [
            { [self] req in return self.makeUploadUrlResponse() },
            { [self] req in return self.makeS3Response(statusCode: 204) },
            { [self] req in return self.makeConfirmResponse(statusCode: 200) }
        ]
        MockURLProtocol.requestHandler = { req in try queue.removeFirst()(req) }

        let result = try await performUpload(fileName: "receipt.jpg", mimeType: "image/jpeg")

        XCTAssertEqual(result.fileName, "receipt.jpg")
        XCTAssertEqual(result.fileType, "image/jpeg")
        XCTAssertEqual(result.fileUrl, "https://example.com/receipt.jpg")
    }

    func testFullFlow_requestOrderIsStep1ThenStep2ThenStep3() async throws {
        var capturedPaths: [String] = []
        var queue: [(URLRequest) throws -> (HTTPURLResponse, Data)] = [
            { [self] req in capturedPaths.append(req.url?.host ?? req.url?.path ?? "step1"); return self.makeUploadUrlResponse() },
            { [self] req in capturedPaths.append(req.url?.host ?? "step2"); return self.makeS3Response(statusCode: 204) },
            { [self] req in capturedPaths.append(req.url?.path ?? "step3"); return self.makeConfirmResponse(statusCode: 200) }
        ]
        MockURLProtocol.requestHandler = { req in try queue.removeFirst()(req) }

        _ = try await performUpload()

        // Step 1 and 3 hit local backend; step 2 hits S3
        XCTAssertEqual(capturedPaths[0], "127.0.0.1")
        XCTAssertEqual(capturedPaths[1], "s3.amazonaws.com")
        XCTAssertEqual(capturedPaths[2], "/v1/attachments/\(attachmentId)/confirm")
    }
}
