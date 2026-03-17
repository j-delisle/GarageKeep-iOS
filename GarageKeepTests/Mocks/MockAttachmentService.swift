import Foundation
@testable import GarageKeep

final class MockAttachmentService: AttachmentServiceProtocol {
    var uploadResult: Result<AttachmentResponse, Error> = .success(.stub)

    private(set) var uploadCallCount = 0
    private(set) var lastServiceId: UUID?
    private(set) var lastFileName: String?
    private(set) var lastData: Data?
    private(set) var lastMimeType: String?

    func uploadAttachment(serviceId: UUID, data: Data, fileName: String, mimeType: String) async throws -> AttachmentResponse {
        uploadCallCount += 1
        lastServiceId = serviceId
        lastFileName = fileName
        lastData = data
        lastMimeType = mimeType
        return try uploadResult.get()
    }
}

extension AttachmentResponse {
    static let stub = AttachmentResponse(
        id: UUID(),
        serviceEventId: UUID(),
        fileName: "receipt.jpg",
        fileType: "image/jpeg",
        fileUrl: "https://example.com/receipt.jpg",
        fileSize: 12345,
        uploadedAt: Date(),
        createdAt: Date()
    )
}
