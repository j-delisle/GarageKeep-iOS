import Foundation

@Observable final class ServiceDetailViewModel {

    // MARK: - State

    var event: ServiceEventResponse
    let vehicle: VehicleResponse
    let previousMileage: Int?

    var attachments: [AttachmentResponse] = []
    var isLoadingAttachments = false
    var isDeleting = false
    var errorMessage: String?

    // MARK: - Dependencies

    private let serviceEventService: ServiceEventServiceProtocol
    private let attachmentService: AttachmentServiceProtocol

    init(
        event: ServiceEventResponse,
        vehicle: VehicleResponse,
        previousMileage: Int?,
        serviceEventService: ServiceEventServiceProtocol = ServiceEventService(),
        attachmentService: AttachmentServiceProtocol = AttachmentService.shared
    ) {
        self.event = event
        self.vehicle = vehicle
        self.previousMileage = previousMileage
        self.serviceEventService = serviceEventService
        self.attachmentService = attachmentService
    }

    // MARK: - Actions

    func loadAttachments() async {
        isLoadingAttachments = true
        defer { isLoadingAttachments = false }
        do {
            attachments = try await attachmentService.listAttachments(serviceId: event.id)
        } catch {
            // Silent — Documentation section stays hidden on error
        }
    }

    func getDownloadUrl(for attachment: AttachmentResponse) async -> URL? {
        do {
            let urlStr = try await attachmentService.getDownloadUrl(attachmentId: attachment.id)
            print("[ServiceDetail] download url=\(urlStr)")
            let url = URL(string: urlStr)
            if url == nil { print("[ServiceDetail] URL(string:) returned nil for: \(urlStr)") }
            return url
        } catch {
            print("[ServiceDetail] getDownloadUrl failed: \(error)")
            return nil
        }
    }

    func delete(onComplete: @escaping () -> Void) async {
        isDeleting = true
        defer { isDeleting = false }
        do {
            try await serviceEventService.deleteServiceEvent(serviceId: event.id)
            onComplete()
        } catch {
            errorMessage = "Could not delete service record."
        }
    }

    // MARK: - Computed

    var formattedDate: String {
        let input = DateFormatter()
        input.dateFormat = "yyyy-MM-dd"
        input.locale = Locale(identifier: "en_US_POSIX")
        guard let date = input.date(from: event.serviceDate) else { return event.serviceDate }
        let output = DateFormatter()
        output.dateStyle = .long
        output.timeStyle = .none
        return output.string(from: date)
    }

    var vehicleTitle: String {
        let yearStr = vehicle.year.map { "\($0) " } ?? ""
        return "\(yearStr)\(vehicle.make) \(vehicle.model)"
    }

    var formattedCost: String? {
        guard let costStr = event.cost, let value = Decimal(string: costStr) else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: value as NSDecimalNumber)
    }

    var formattedMileage: String? {
        guard let m = event.mileage else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return (formatter.string(from: NSNumber(value: m)) ?? "\(m)") + " mi"
    }

    var formattedMileageDelta: String? {
        guard let current = event.mileage, let previous = previousMileage, current > previous else { return nil }
        let delta = current - previous
        if delta >= 1000 {
            return String(format: "+%.1fk since last", Double(delta) / 1000.0)
        } else {
            return "+\(delta) since last"
        }
    }
}
