import Foundation

struct TokenResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let tokenType: String
    let expiresIn: Int
}

struct UserResponse: Codable {
    let id: UUID
    let email: String
    let name: String?
    let createdAt: Date
    let updatedAt: Date
}

struct LoginRequest: Encodable {
    let email: String
    let password: String
}

struct RegisterRequest: Encodable {
    let email: String
    let password: String
    let name: String
}
