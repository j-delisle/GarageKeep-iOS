import Foundation

protocol AttachmentServiceProtocol {
    func uploadAttachment(serviceId: UUID, data: Data, fileName: String) async throws -> AttachmentResponse
    func uploadAttachments(serviceId: UUID, attachments: [PendingAttachment]) async throws -> [AttachmentUploadResult]
}

struct AttachmentUploadResult {
    let fileName: String
    let result: Result<AttachmentResponse, Error>
}

final class AttachmentService: AttachmentServiceProtocol {
    static let shared = AttachmentService()

    private let baseURL = "http://127.0.0.1:8005"
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let str = try container.decode(String.self)

            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = iso.date(from: str) { return date }

            iso.formatOptions = [.withInternetDateTime]
            if let date = iso.date(from: str) { return date }

            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            df.timeZone = TimeZone(secondsFromGMT: 0)
            df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
            if let date = df.date(from: str) { return date }

            df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            if let date = df.date(from: str) { return date }

            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date from: \(str)")
        }
        return d
    }()

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        return e
    }()

    // MARK: - Public

    func uploadAttachment(serviceId: UUID, data: Data, fileName: String) async throws -> AttachmentResponse {
        let detectedMimeType = Self.mimeType(for: data)
        print("[AttachmentUpload] detected mimeType=\(detectedMimeType) size=\(data.count)")

        // Step 1: Get presigned S3 upload URL from backend
        let uploadUrlResponse = try await requestUploadUrl(
            serviceId: serviceId,
            fileName: fileName,
            mimeType: detectedMimeType,
            fileSize: data.count
        )
        print("[AttachmentUpload] step1 OK — attachmentId=\(uploadUrlResponse.attachmentId) uploadUrl=\(uploadUrlResponse.uploadUrl)")

        // Step 2: Upload file directly to S3 (no auth header — uses presigned fields)
        try await uploadToS3(uploadResponse: uploadUrlResponse, data: data, mimeType: detectedMimeType)
        print("[AttachmentUpload] step2 OK — S3 upload complete")

        // Step 3: Confirm upload with backend to persist the record
        let result = try await confirmUpload(attachmentId: uploadUrlResponse.attachmentId)
        print("[AttachmentUpload] step3 OK — confirmed id=\(result.id)")
        return result
    }

    func uploadAttachments(serviceId: UUID, attachments: [PendingAttachment]) async throws -> [AttachmentUploadResult] {
        guard !attachments.isEmpty else { return [] }

        // Step 1: Request all presigned URLs in a single call
        let mimeTypes = attachments.map { Self.mimeType(for: $0.data) }
        let requests = zip(attachments, mimeTypes).map { attachment, mime in
            UploadUrlRequest(filename: attachment.fileName, contentType: mime, fileSize: attachment.data.count)
        }
        let uploadUrls = try await requestUploadUrls(serviceId: serviceId, requests: requests)
        print("[AttachmentUpload] batch step1 OK — got \(uploadUrls.count) upload URLs")

        // Steps 2 & 3: Upload to S3 then confirm, one per attachment
        var results: [AttachmentUploadResult] = []
        for (index, attachment) in attachments.enumerated() {
            let mime = mimeTypes[index]
            let uploadUrl = uploadUrls[index]
            do {
                try await uploadToS3(uploadResponse: uploadUrl, data: attachment.data, mimeType: mime)
                print("[AttachmentUpload] batch step2 OK — S3 upload complete for \(attachment.fileName)")
                let confirmed = try await confirmUpload(attachmentId: uploadUrl.attachmentId)
                print("[AttachmentUpload] batch step3 OK — confirmed id=\(confirmed.id)")
                results.append(AttachmentUploadResult(fileName: attachment.fileName, result: .success(confirmed)))
            } catch {
                print("[AttachmentUpload] FAILED \(attachment.fileName): \(error)")
                results.append(AttachmentUploadResult(fileName: attachment.fileName, result: .failure(error)))
            }
        }
        return results
    }

    // MARK: - MIME type detection

    private static func mimeType(for data: Data) -> String {
        var byte: UInt8 = 0
        data.copyBytes(to: &byte, count: 1)
        switch byte {
        case 0xFF: return "image/jpeg"
        case 0x89: return "image/png"
        case 0x47: return "image/gif"
        case 0x49, 0x4D: return "image/tiff"
        default:   return "application/octet-stream"
        }
    }

    // MARK: - Step 1: Request presigned upload URL(s)

    private func requestUploadUrls(serviceId: UUID, requests: [UploadUrlRequest]) async throws -> [UploadUrlResponse] {
        guard let url = URL(string: "\(baseURL)/v1/services/\(serviceId)/attachments/upload-urls") else {
            throw APIError.invalidURL
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = KeychainHelper.read(for: KeychainHelper.accessTokenKey) {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        req.httpBody = try encoder.encode(requests)

        let (responseData, response) = try await perform(req)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.networkError(URLError(.badServerResponse))
        }
        guard (200..<300).contains(http.statusCode) else {
            throw APIError.serverError(http.statusCode)
        }

        do {
            return try decoder.decode([UploadUrlResponse].self, from: responseData)
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.decodingError(error)
        }
    }

    private func requestUploadUrl(serviceId: UUID, fileName: String, mimeType: String, fileSize: Int) async throws -> UploadUrlResponse {
        guard let url = URL(string: "\(baseURL)/v1/services/\(serviceId)/attachments/upload-urls") else {
            throw APIError.invalidURL
        }

        let requestBody = [UploadUrlRequest(filename: fileName, contentType: mimeType, fileSize: fileSize)]
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = KeychainHelper.read(for: KeychainHelper.accessTokenKey) {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        req.httpBody = try encoder.encode(requestBody)

        let (responseData, response) = try await perform(req)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.networkError(URLError(.badServerResponse))
        }
        guard (200..<300).contains(http.statusCode) else {
            throw APIError.serverError(http.statusCode)
        }

        do {
            let responses = try decoder.decode([UploadUrlResponse].self, from: responseData)
            guard let first = responses.first else {
                throw APIError.decodingError(DecodingError.dataCorrupted(
                    .init(codingPath: [], debugDescription: "Empty upload-urls response")
                ))
            }
            return first
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.decodingError(error)
        }
    }

    // MARK: - Step 2: Upload directly to S3

    private func uploadToS3(uploadResponse: UploadUrlResponse, data: Data, mimeType: String) async throws {
        guard let url = URL(string: uploadResponse.uploadUrl) else {
            throw APIError.invalidURL
        }

        let boundary = "GarageKeep-\(UUID().uuidString)"
        var body = Data()

        // Debug: print all presigned fields so we can verify they match the policy
        print("[AttachmentUpload] uploadFields keys: \(uploadResponse.uploadFields.keys.sorted())")
        for (k, v) in uploadResponse.uploadFields { print("[AttachmentUpload]   \(k) = \(v.prefix(60))") }

        // All presigned fields must come before the file field
        for (key, value) in uploadResponse.uploadFields {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            body.append("\(value)\r\n")
        }

        // File field must be last for S3 presigned POST
        let fileName = uploadResponse.s3Key.components(separatedBy: "/").last ?? "file"
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n")
        body.append("Content-Type: \(mimeType)\r\n\r\n")
        body.append(data)
        body.append("\r\n--\(boundary)--\r\n")

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        // No Authorization header — S3 uses the presigned fields for auth
        req.httpBody = body

        let (s3Data, response) = try await perform(req)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.networkError(URLError(.badServerResponse))
        }
        // S3 presigned POST returns 204 No Content on success
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: s3Data, encoding: .utf8) ?? "<non-utf8>"
            print("[AttachmentUpload] S3 error \(http.statusCode): \(body)")
            throw APIError.serverError(http.statusCode)
        }
    }

    // MARK: - Step 3: Confirm upload with backend

    private func confirmUpload(attachmentId: UUID) async throws -> AttachmentResponse {
        guard let url = URL(string: "\(baseURL)/v1/attachments/\(attachmentId)/confirm") else {
            throw APIError.invalidURL
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        if let token = KeychainHelper.read(for: KeychainHelper.accessTokenKey) {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (responseData, response) = try await perform(req)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.networkError(URLError(.badServerResponse))
        }
        guard (200..<300).contains(http.statusCode) else {
            throw APIError.serverError(http.statusCode)
        }

        do {
            return try decoder.decode(AttachmentResponse.self, from: responseData)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    // MARK: - Shared network helper

    private func perform(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }
    }
}

// MARK: - Data helpers

private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
