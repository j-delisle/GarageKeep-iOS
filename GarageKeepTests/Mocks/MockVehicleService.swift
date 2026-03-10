import Foundation
@testable import GarageKeep

final class MockVehicleService: VehicleServiceProtocol {
    var fetchVehiclesResult: Result<[VehicleResponse], Error> = .success([])
    var createVehicleResult: Result<VehicleResponse, Error> = .success(.stub)
    var decodeVinResult: Result<VinDecodeResponse, Error> = .success(.stub)

    private(set) var fetchVehiclesCallCount = 0
    private(set) var createVehicleCallCount = 0
    private(set) var decodeVinCallCount = 0
    private(set) var lastCreatedRequest: CreateVehicleRequest?
    private(set) var lastDecodedVin: String?

    func fetchVehicles() async throws -> [VehicleResponse] {
        fetchVehiclesCallCount += 1
        return try fetchVehiclesResult.get()
    }

    func createVehicle(_ request: CreateVehicleRequest) async throws -> VehicleResponse {
        createVehicleCallCount += 1
        lastCreatedRequest = request
        return try createVehicleResult.get()
    }

    func decodeVin(_ vin: String) async throws -> VinDecodeResponse {
        decodeVinCallCount += 1
        lastDecodedVin = vin
        return try decodeVinResult.get()
    }
}

// MARK: - Stub data

extension VehicleResponse {
    static let stub = VehicleResponse(
        id: UUID(),
        userId: UUID(),
        make: "Toyota",
        model: "Camry",
        year: 2023,
        vin: nil,
        licensePlate: nil,
        createdAt: Date(),
        updatedAt: Date()
    )
}

extension VinDecodeResponse {
    static let stub = VinDecodeResponse(make: "Toyota", model: "Camry", year: 2023)
}
