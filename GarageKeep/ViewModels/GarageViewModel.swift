import Foundation

@Observable final class GarageViewModel {
    var vehicles: [VehicleResponse] = []
    var isLoading = false
    var errorMessage: String?
    var showOnboarding = false

    private let vehicleService: VehicleServiceProtocol

    init(vehicleService: VehicleServiceProtocol = VehicleService()) {
        self.vehicleService = vehicleService
    }

    func fetchVehicles() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            vehicles = try await vehicleService.fetchVehicles()
            if vehicles.isEmpty {
                showOnboarding = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
