import Foundation
@testable import GarageKeep

final class MockAttachmentService: AttachmentServiceProtocol {
    /// Default result used when resultsQueue is empty.
    var uploadResult: Result<AttachmentResponse, Error> = .success(.stub)

    /// Optional per-call results — dequeued in order, falls back to uploadResult when empty.
    var resultsQueue: [Result<AttachmentResponse, Error>] = []

    private(set) var uploadCallCount = 0
    private(set) var lastServiceId: UUID?
    private(set) var lastFileName: String?
    private(set) var lastData: Data?

    func uploadAttachment(serviceId: UUID, data: Data, fileName: String) async throws -> AttachmentResponse {
        uploadCallCount += 1
        lastServiceId = serviceId
        lastFileName = fileName
        lastData = data
        let result = resultsQueue.isEmpty ? uploadResult : resultsQueue.removeFirst()
        return try result.get()
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
