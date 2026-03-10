import Foundation
import Observation

@Observable
final class AuthViewModel {
    var isAuthenticated: Bool
    var isLoading = false
    var errorMessage: String?

    private let authService: any AuthServiceProtocol

    init(authService: any AuthServiceProtocol = AuthService()) {
        self.authService = authService
        self.isAuthenticated = KeychainHelper.read(for: KeychainHelper.accessTokenKey) != nil

        NotificationCenter.default.addObserver(
            forName: .sessionExpired,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.logout()
        }
    }

    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let tokens = try await authService.login(email: email, password: password)
            KeychainHelper.save(tokens.accessToken, for: KeychainHelper.accessTokenKey)
            KeychainHelper.save(tokens.refreshToken, for: KeychainHelper.refreshTokenKey)
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func register(email: String, password: String, name: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let tokens = try await authService.register(email: email, password: password, name: name)
            KeychainHelper.save(tokens.accessToken, for: KeychainHelper.accessTokenKey)
            KeychainHelper.save(tokens.refreshToken, for: KeychainHelper.refreshTokenKey)
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func logout() {
        KeychainHelper.clearAll()
        isAuthenticated = false
    }
}
