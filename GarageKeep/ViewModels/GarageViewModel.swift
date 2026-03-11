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

    func loadMockVehicles() {
        vehicles = [
            VehicleResponse(id: UUID(), userId: UUID(), make: "BMW", model: "X5",
                            year: 2023, vin: nil, licensePlate: "xDrive40i",
                            createdAt: Date(), updatedAt: Date()),
            VehicleResponse(id: UUID(), userId: UUID(), make: "Tesla", model: "Model 3",
                            year: 2022, vin: nil, licensePlate: nil,
                            createdAt: Date(), updatedAt: Date()),
            VehicleResponse(id: UUID(), userId: UUID(), make: "Audi", model: "Q7",
                            year: 2024, vin: nil, licensePlate: "55 TFSI",
                            createdAt: Date(), updatedAt: Date())
        ]
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
