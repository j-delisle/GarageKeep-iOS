import Foundation
@testable import GarageKeep

final class MockAuthService: AuthServiceProtocol {
    var loginResult: Result<TokenResponse, Error> = .success(.stub)
    var registerResult: Result<TokenResponse, Error> = .success(.stub)

    private(set) var loginCallCount = 0
    private(set) var registerCallCount = 0
    private(set) var lastLoginEmail: String?
    private(set) var lastRegisterName: String?

    func login(email: String, password: String) async throws -> TokenResponse {
        loginCallCount += 1
        lastLoginEmail = email
        return try loginResult.get()
    }

    func register(email: String, password: String, name: String) async throws -> TokenResponse {
        registerCallCount += 1
        lastRegisterName = name
        return try registerResult.get()
    }
}

// MARK: - Stub data

extension TokenResponse {
    static let stub = TokenResponse(
        accessToken: "test-access-token",
        refreshToken: "test-refresh-token",
        tokenType: "Bearer",
        expiresIn: 3600
    )
}
