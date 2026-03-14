import Foundation

struct ServiceEventResponse: Codable, Identifiable {
    let id: UUID
    let vehicleId: UUID
    let serviceType: String
    let serviceDate: String   // "yyyy-MM-dd" — bare date string, not a datetime
    let mileage: Int?
    let cost: String?         // decimal string e.g. "49.99"
    let location: String?
    let notes: String?
    let createdAt: Date
    let updatedAt: Date
}

struct ServiceEventListResponse: Decodable {
    let services: [ServiceEventResponse]
    let total: Int
}

struct CreateServiceEventRequest: Encodable {
    let serviceType: String
    let serviceDate: String
    let mileage: Int?
    let cost: String?
    let location: String?
    let notes: String?
}

struct UpdateServiceEventRequest: Encodable {
    let serviceType: String
    let serviceDate: String
    let mileage: Int?
    let cost: String?
    let location: String?
    let notes: String?
}

// MARK: - Debug Stubs

#if DEBUG
extension ServiceEventResponse {
    static let stub = ServiceEventResponse(
        id: UUID(),
        vehicleId: UUID(),
        serviceType: "Oil Change & Filter",
        serviceDate: "2024-08-12",
        mileage: 12450,
        cost: "85.00",
        location: "Porsche Center Seattle",
        notes: "Synthetic 0W-40, OEM filter replaced.",
        createdAt: Date(),
        updatedAt: Date()
    )

    static let stubs: [ServiceEventResponse] = [
        ServiceEventResponse(
            id: UUID(), vehicleId: UUID(),
            serviceType: "Oil Change & Filter",
            serviceDate: "2024-08-12",
            mileage: 12450, cost: "85.00",
            location: "Porsche Center Seattle",
            notes: "Synthetic 0W-40, OEM filter replaced.",
            createdAt: Date(), updatedAt: Date()
        ),
        ServiceEventResponse(
            id: UUID(), vehicleId: UUID(),
            serviceType: "Brake Pad Replacement",
            serviceDate: "2024-06-05",
            mileage: 11200, cost: "420.00",
            location: "Motorsport Pros",
            notes: nil,
            createdAt: Date(), updatedAt: Date()
        ),
        ServiceEventResponse(
            id: UUID(), vehicleId: UUID(),
            serviceType: "Tire Rotation",
            serviceDate: "2024-02-18",
            mileage: 9800, cost: "60.00",
            location: "Discount Tire",
            notes: nil,
            createdAt: Date(), updatedAt: Date()
        ),
        ServiceEventResponse(
            id: UUID(), vehicleId: UUID(),
            serviceType: "Annual Inspection",
            serviceDate: "2024-01-10",
            mileage: 9100, cost: "120.00",
            location: "Porsche Center Seattle",
            notes: "Multi-point inspection passed with no issues found.",
            createdAt: Date(), updatedAt: Date()
        )
    ]
}

extension VehicleResponse {
    static let stubWithVin = VehicleResponse(
        id: UUID(), userId: UUID(),
        make: "Porsche", model: "911 GT3",
        year: 2022, vin: "WP0AA2A90NS200001",
        licensePlate: nil,
        createdAt: Date(), updatedAt: Date()
    )
}
#endif
