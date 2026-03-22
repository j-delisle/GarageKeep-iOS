import Foundation
@testable import GarageKeep

final class MockServiceEventService: ServiceEventServiceProtocol {
    var fetchResult: Result<ServiceEventListResponse, Error> = .success(
        ServiceEventListResponse(services: [], total: 0)
    )
    var createResult: Result<ServiceEventResponse, Error> = .success(.stub)
    var updateResult: Result<ServiceEventResponse, Error> = .success(.stub)
    var deleteResult: Result<Void, Error> = .success(())

    private(set) var fetchCallCount = 0
    private(set) var lastFetchVehicleId: UUID?
    private(set) var lastFetchLimit: Int?
    private(set) var lastFetchOffset: Int?
    private(set) var createCallCount = 0
    private(set) var lastCreatedVehicleId: UUID?
    private(set) var lastCreatedRequest: CreateServiceEventRequest?
    private(set) var updateCallCount = 0
    private(set) var lastUpdatedServiceId: UUID?
    private(set) var lastUpdateRequest: UpdateServiceEventRequest?
    private(set) var deleteCallCount = 0
    private(set) var lastDeletedServiceId: UUID?

    func fetchServiceEvents(vehicleId: UUID, limit: Int, offset: Int) async throws -> ServiceEventListResponse {
        fetchCallCount += 1
        lastFetchVehicleId = vehicleId
        lastFetchLimit = limit
        lastFetchOffset = offset
        return try fetchResult.get()
    }

    func createServiceEvent(vehicleId: UUID, request: CreateServiceEventRequest) async throws -> ServiceEventResponse {
        createCallCount += 1
        lastCreatedVehicleId = vehicleId
        lastCreatedRequest = request
        return try createResult.get()
    }

    func updateServiceEvent(serviceId: UUID, request: UpdateServiceEventRequest) async throws -> ServiceEventResponse {
        updateCallCount += 1
        lastUpdatedServiceId = serviceId
        lastUpdateRequest = request
        return try updateResult.get()
    }

    func deleteServiceEvent(serviceId: UUID) async throws {
        deleteCallCount += 1
        lastDeletedServiceId = serviceId
        try deleteResult.get()
    }
}
