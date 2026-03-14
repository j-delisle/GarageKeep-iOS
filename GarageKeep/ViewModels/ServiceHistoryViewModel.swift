import Foundation

@Observable final class ServiceHistoryViewModel {

    // MARK: - State

    let vehicle: VehicleResponse
    var events: [ServiceEventResponse] = []
    var isLoading = false
    var isLoadingMore = false
    var errorMessage: String?

    private var currentOffset = 0
    private let pageSize = 20
    private var totalCount = 0

    // MARK: - Dependencies

    private let serviceEventService: ServiceEventServiceProtocol

    init(vehicle: VehicleResponse,
         serviceEventService: ServiceEventServiceProtocol = ServiceEventService()) {
        self.vehicle = vehicle
        self.serviceEventService = serviceEventService
    }

    // MARK: - Load

    func loadInitial() async {
        isLoading = true
        errorMessage = nil
        events = []
        currentOffset = 0
        defer { isLoading = false }

        do {
            let response = try await serviceEventService.fetchServiceEvents(
                vehicleId: vehicle.id,
                limit: pageSize,
                offset: 0
            )
            events = response.services
            totalCount = response.total
            currentOffset = response.services.count
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadMore() async {
        guard hasMorePages, !isLoadingMore else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let response = try await serviceEventService.fetchServiceEvents(
                vehicleId: vehicle.id,
                limit: pageSize,
                offset: currentOffset
            )
            events.append(contentsOf: response.services)
            currentOffset += response.services.count
        } catch {
            // Silent failure: preserve existing data, button remains visible to retry
        }
    }

    func deleteEvent(_ event: ServiceEventResponse) async {
        events.removeAll { $0.id == event.id }
        totalCount -= 1

        do {
            try await serviceEventService.deleteServiceEvent(serviceId: event.id)
        } catch {
            events.append(event)
            events = sortedEvents
            totalCount += 1
            errorMessage = "Could not delete service record."
        }
    }

    func loadMockEvents() {
        events = ServiceEventResponse.stubs
        totalCount = ServiceEventResponse.stubs.count
        currentOffset = events.count
    }

    // MARK: - Computed

    var hasMorePages: Bool {
        events.count < totalCount
    }

    var sortedEvents: [ServiceEventResponse] {
        events.sorted { $0.serviceDate > $1.serviceDate }
    }

    var totalSpent: Decimal {
        events.compactMap { event -> Decimal? in
            guard let cost = event.cost else { return nil }
            return Decimal(string: cost)
        }
        .reduce(.zero, +)
    }

    var totalSpentFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: totalSpent as NSDecimalNumber) ?? "$0.00"
    }

    var maskedVin: String {
        Self.maskedVin(for: vehicle)
    }

    static func maskedVin(for vehicle: VehicleResponse) -> String {
        guard let vin = vehicle.vin, vin.count == 17 else {
            return vehicle.vin ?? "—"
        }
        return "\(vin.prefix(12))*****"
    }

    var totalMileageFormatted: String {
        guard let max = events.compactMap(\.mileage).max() else { return "—" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return (formatter.string(from: NSNumber(value: max)) ?? "\(max)") + " Total Miles"
    }

    var nextServiceMileage: String {
        guard let latest = events.compactMap(\.mileage).max() else { return "—" }
        let next = latest + 5_000
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return "~" + (formatter.string(from: NSNumber(value: next)) ?? "\(next)") + " mi"
    }

    // MARK: - SF Symbol Mapping

    static func iconName(for serviceType: String) -> String {
        let lowered = serviceType.lowercased()
        switch true {
        case lowered.contains("oil"):
            return "drop.fill"
        case lowered.contains("tire") || lowered.contains("rotation"):
            return "arrow.2.circlepath"
        case lowered.contains("brake"):
            return "exclamationmark.octagon.fill"
        case lowered.contains("battery"):
            return "bolt.fill"
        case lowered.contains("transmission"):
            return "gear"
        case lowered.contains("air") || lowered.contains("filter"):
            return "wind"
        case lowered.contains("coolant") || lowered.contains("fluid"):
            return "thermometer.medium"
        case lowered.contains("wheel") || lowered.contains("alignment"):
            return "steeringwheel"
        case lowered.contains("wiper"):
            return "arrow.left.and.right"
        case lowered.contains("inspection") || lowered.contains("check"):
            return "checkmark.shield.fill"
        case lowered.contains("wash"):
            return "sparkles"
        case lowered.contains("fuel"):
            return "fuelpump.fill"
        case lowered.contains("spark"):
            return "bolt.horizontal.fill"
        case lowered.contains("belt"):
            return "arrow.triangle.2.circlepath"
        default:
            return "wrench.and.screwdriver.fill"
        }
    }
}
