import Foundation

// MARK: - Upload URL (Step 1)

struct UploadUrlRequest: Encodable {
    let filename: String      // backend expects "filename" (no snake_case conversion needed)
    let contentType: String   // encodes to "content_type"
    let fileSize: Int         // encodes to "file_size"
}

struct UploadUrlResponse: Decodable {
    let attachmentId: UUID
    let uploadUrl: String
    let uploadFields: [String: String]
    let s3Key: String
    let expiresIn: Int
}

// MARK: - Attachment

struct AttachmentResponse: Codable, Identifiable {
    let id: UUID
    let serviceEventId: UUID
    let fileName: String
    let fileType: String
    let fileUrl: String
    let fileSize: Int?
    let uploadedAt: Date
    let createdAt: Date
}
