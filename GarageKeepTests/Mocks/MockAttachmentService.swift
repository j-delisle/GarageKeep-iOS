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

    func uploadAttachments(serviceId: UUID, attachments: [PendingAttachment]) async throws -> [AttachmentUploadResult] {
        return attachments.map { attachment in
            uploadCallCount += 1
            lastServiceId = serviceId
            lastFileName = attachment.fileName
            lastData = attachment.data
            let result = resultsQueue.isEmpty ? uploadResult : resultsQueue.removeFirst()
            return AttachmentUploadResult(fileName: attachment.fileName, result: result)
        }
    }

    var listResult: Result<[AttachmentResponse], Error> = .success([.stub])
    var downloadUrlResult: Result<String, Error> = .success("https://example.com/signed-url.jpg")

    private(set) var listCallCount = 0
    private(set) var lastListServiceId: UUID?
    private(set) var downloadUrlCallCount = 0
    private(set) var lastDownloadAttachmentId: UUID?

    func listAttachments(serviceId: UUID) async throws -> [AttachmentResponse] {
        listCallCount += 1
        lastListServiceId = serviceId
        return try listResult.get()
    }

    func getDownloadUrl(attachmentId: UUID) async throws -> String {
        downloadUrlCallCount += 1
        lastDownloadAttachmentId = attachmentId
        return try downloadUrlResult.get()
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
