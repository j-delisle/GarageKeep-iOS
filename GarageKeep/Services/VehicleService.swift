import Foundation

protocol VehicleServiceProtocol {
    func fetchVehicles() async throws -> [VehicleResponse]
    func createVehicle(_ request: CreateVehicleRequest) async throws -> VehicleResponse
    func decodeVin(_ vin: String) async throws -> VinDecodeResponse
}

final class VehicleService: VehicleServiceProtocol {
    private let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    func fetchVehicles() async throws -> [VehicleResponse] {
        let response: VehicleListResponse = try await apiClient.request("/v1/vehicles")
        return response.vehicles
    }

    func createVehicle(_ request: CreateVehicleRequest) async throws -> VehicleResponse {
        try await apiClient.request("/v1/vehicles", method: "POST", body: request)
    }

    func decodeVin(_ vin: String) async throws -> VinDecodeResponse {
        let encoded = vin.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? vin
        return try await apiClient.request("/v1/vehicles/vin/decode?vin=\(encoded)")
    }
}
