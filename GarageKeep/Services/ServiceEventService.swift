import Foundation

protocol ServiceEventServiceProtocol {
    func fetchServiceEvents(vehicleId: UUID, limit: Int, offset: Int) async throws -> ServiceEventListResponse
    func createServiceEvent(vehicleId: UUID, request: CreateServiceEventRequest) async throws -> ServiceEventResponse
    func updateServiceEvent(serviceId: UUID, request: UpdateServiceEventRequest) async throws -> ServiceEventResponse
    func deleteServiceEvent(serviceId: UUID) async throws
}

final class ServiceEventService: ServiceEventServiceProtocol {
    private let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    func fetchServiceEvents(vehicleId: UUID, limit: Int = 20, offset: Int = 0) async throws -> ServiceEventListResponse {
        try await apiClient.request("/v1/vehicles/\(vehicleId)/services?limit=\(limit)&offset=\(offset)")
    }

    func createServiceEvent(vehicleId: UUID, request: CreateServiceEventRequest) async throws -> ServiceEventResponse {
        try await apiClient.request("/v1/vehicles/\(vehicleId)/services", method: "POST", body: request)
    }

    func updateServiceEvent(serviceId: UUID, request: UpdateServiceEventRequest) async throws -> ServiceEventResponse {
        try await apiClient.request("/v1/services/\(serviceId)", method: "PUT", body: request)
    }

    func deleteServiceEvent(serviceId: UUID) async throws {
        try await apiClient.requestVoid("/v1/services/\(serviceId)")
    }
}
