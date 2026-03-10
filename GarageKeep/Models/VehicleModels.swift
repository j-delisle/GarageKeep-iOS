import Foundation

struct VehicleListResponse: Decodable {
    let vehicles: [VehicleResponse]
    let total: Int
}

struct VehicleResponse: Codable {
    let id: UUID
    let userId: UUID
    let make: String
    let model: String
    let year: Int?
    let vin: String?
    let licensePlate: String?
    let createdAt: Date
    let updatedAt: Date
}

struct CreateVehicleRequest: Encodable {
    let make: String
    let model: String
    let year: Int?
    let vin: String?
    let licensePlate: String?
}

struct VinDecodeResponse: Decodable {
    let make: String
    let model: String
    let year: Int?
}
