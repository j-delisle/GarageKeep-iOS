import Foundation

@Observable final class EditServiceViewModel {

    // MARK: - Form State (pre-populated from existing event)

    var serviceTypePick: String
    var serviceTypeCustom: String
    var serviceDate: Date
    var mileageText: String
    var costText: String
    var location: String
    var notes: String

    var isLoading = false
    var errorMessage: String?

    // MARK: - Private

    private let eventId: UUID
    private let serviceEventService: ServiceEventServiceProtocol

    init(
        event: ServiceEventResponse,
        serviceEventService: ServiceEventServiceProtocol = ServiceEventService()
    ) {
        self.eventId = event.id
        self.serviceEventService = serviceEventService

        // Pre-populate service type — match against known options or fall back to "Other"
        if AddServiceViewModel.serviceTypeOptions.contains(event.serviceType) {
            self.serviceTypePick = event.serviceType
            self.serviceTypeCustom = ""
        } else {
            self.serviceTypePick = "Other"
            self.serviceTypeCustom = event.serviceType
        }

        // Parse "yyyy-MM-dd" date string to Date
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        self.serviceDate = fmt.date(from: event.serviceDate) ?? .now

        self.mileageText = event.mileage.map { "\($0)" } ?? ""
        self.costText = event.cost ?? ""
        self.location = event.location ?? ""
        self.notes = event.notes ?? ""
    }

    // MARK: - Computed

    var resolvedServiceType: String {
        serviceTypePick == "Other" ? serviceTypeCustom : serviceTypePick
    }

    var canSave: Bool {
        !resolvedServiceType.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var formattedDate: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        return fmt.string(from: serviceDate)
    }

    private var resolvedMileage: Int? {
        let trimmed = mileageText.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? nil : Int(trimmed)
    }

    private var resolvedCost: String? {
        let trimmed = costText.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? nil : trimmed
    }

    private var resolvedLocation: String? {
        let trimmed = location.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? nil : trimmed
    }

    private var resolvedNotes: String? {
        let trimmed = notes.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? nil : trimmed
    }

    // MARK: - Save

    func save() async -> ServiceEventResponse? {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let request = UpdateServiceEventRequest(
            serviceType: resolvedServiceType,
            serviceDate: formattedDate,
            mileage: resolvedMileage,
            cost: resolvedCost,
            location: resolvedLocation,
            notes: resolvedNotes
        )

        do {
            return try await serviceEventService.updateServiceEvent(serviceId: eventId, request: request)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
