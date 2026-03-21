import Foundation

struct PendingAttachment: Identifiable {
    let id = UUID()
    let data: Data
    let fileName: String
}

@Observable final class AddServiceViewModel {
    enum Step { case details, receipt, review }

    // MARK: - State

    let vehicle: VehicleResponse
    var currentStep: Step = .details

    // Step 1 — Details
    var serviceTypePick: String = ""
    var serviceTypeCustom: String = ""
    var serviceDate: Date = .now
    var mileageText: String = ""
    var costText: String = ""
    var location: String = ""
    var notes: String = ""

    // Step 2 — Receipts
    static let maxAttachments = 5
    var pendingAttachments: [PendingAttachment] = []

    var canAddAttachment: Bool {
        pendingAttachments.count < Self.maxAttachments
    }

    // Submission
    var isLoading = false
    var errorMessage: String?
    var attachmentFailed = false
    var isComplete = false

    // MARK: - Service Type Options

    static let serviceTypeOptions: [String] = [
        "Oil & Filter Change",
        "Tire Rotation",
        "Brake Service",
        "Air Filter",
        "Transmission Service",
        "Coolant Flush",
        "Battery Replacement",
        "Inspection / Emissions",
        "Alignment",
        "Detailing",
        "Other"
    ]

    // MARK: - Dependencies

    private let serviceEventService: ServiceEventServiceProtocol
    private let attachmentService: AttachmentServiceProtocol

    init(
        vehicle: VehicleResponse,
        serviceEventService: ServiceEventServiceProtocol = ServiceEventService(),
        attachmentService: AttachmentServiceProtocol = AttachmentService.shared
    ) {
        self.vehicle = vehicle
        self.serviceEventService = serviceEventService
        self.attachmentService = attachmentService
    }

    // MARK: - Computed

    var resolvedServiceType: String {
        serviceTypePick == "Other" ? serviceTypeCustom : serviceTypePick
    }

    var canAdvanceFromDetails: Bool {
        !resolvedServiceType.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var formattedDate: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        return fmt.string(from: serviceDate)
    }

    var resolvedMileage: Int? {
        let trimmed = mileageText.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? nil : Int(trimmed)
    }

    var resolvedCost: String? {
        let trimmed = costText.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? nil : trimmed
    }

    var resolvedLocation: String? {
        let trimmed = location.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? nil : trimmed
    }

    var resolvedNotes: String? {
        let trimmed = notes.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? nil : trimmed
    }

    // MARK: - Navigation

    func advance() {
        switch currentStep {
        case .details: currentStep = .receipt
        case .receipt: currentStep = .review
        case .review: break
        }
    }

    func back() {
        switch currentStep {
        case .details: break
        case .receipt: currentStep = .details
        case .review: currentStep = .receipt
        }
    }

    // MARK: - Submit

    func submit() async -> ServiceEventResponse? {
        isLoading = true
        errorMessage = nil
        attachmentFailed = false
        defer { isLoading = false }

        let request = CreateServiceEventRequest(
            serviceType: resolvedServiceType,
            serviceDate: formattedDate,
            mileage: resolvedMileage,
            cost: resolvedCost,
            location: resolvedLocation,
            notes: resolvedNotes
        )

        do {
            let event = try await serviceEventService.createServiceEvent(
                vehicleId: vehicle.id,
                request: request
            )
            if !pendingAttachments.isEmpty {
                let uploadResults = try await attachmentService.uploadAttachments(
                    serviceId: event.id,
                    attachments: pendingAttachments
                )
                let failedCount = uploadResults.filter { if case .failure = $0.result { return true }; return false }.count
                if failedCount > 0 {
                    attachmentFailed = true
                    let total = pendingAttachments.count
                    errorMessage = failedCount == total
                        ? "Service saved, but receipts couldn't be uploaded."
                        : "Service saved, but \(failedCount) of \(total) receipts failed to upload."
                }
            }
            isComplete = true
            return event
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
