import Foundation

protocol AuthServiceProtocol {
    func login(email: String, password: String) async throws -> TokenResponse
    func register(email: String, password: String, name: String) async throws -> TokenResponse
}

final class AuthService: AuthServiceProtocol {
    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    func login(email: String, password: String) async throws -> TokenResponse {
        try await client.request(
            "/v1/auth/login",
            method: "POST",
            body: LoginRequest(email: email, password: password),
            requiresAuth: false
        )
    }

    func register(email: String, password: String, name: String) async throws -> TokenResponse {
        try await client.request(
            "/v1/auth/register",
            method: "POST",
            body: RegisterRequest(email: email, password: password, name: name),
            requiresAuth: false
        )
    }

    func refreshToken(_ token: String) async throws -> TokenResponse {
        struct RefreshBody: Encodable { let refreshToken: String }
        return try await client.request(
            "/v1/auth/refresh",
            method: "POST",
            body: RefreshBody(refreshToken: token),
            requiresAuth: false
        )
    }
}
