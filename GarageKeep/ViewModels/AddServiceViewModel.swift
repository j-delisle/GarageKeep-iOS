import Foundation

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

    // Step 2 — Receipt
    var selectedImageData: Data?
    var selectedImageName: String = "receipt.jpg"

    // Submission
    var isLoading = false
    var errorMessage: String?

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
            if let imageData = selectedImageData {
                _ = try? await attachmentService.uploadAttachment(
                    serviceId: event.id,
                    data: imageData,
                    fileName: selectedImageName,
                    mimeType: "image/jpeg"
                )
            }
            return event
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
