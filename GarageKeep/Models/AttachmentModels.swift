import Foundation

// MARK: - Upload URL (Step 1)

struct UploadUrlRequest: Encodable {
    let fileName: String
    let fileType: String
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
