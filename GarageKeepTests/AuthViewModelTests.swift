import XCTest
@testable import GarageKeep

@MainActor
final class AuthViewModelTests: XCTestCase {
    var mockService: MockAuthService!
    var sut: AuthViewModel!

    override func setUp() {
        super.setUp()
        KeychainHelper.clearAll()
        mockService = MockAuthService()
        sut = AuthViewModel(authService: mockService)
    }

    override func tearDown() {
        KeychainHelper.clearAll()
        super.tearDown()
    }

    // MARK: - Init

    func testInit_notAuthenticated_whenNoToken() async {
        XCTAssertFalse(sut.isAuthenticated)
    }

    func testInit_isAuthenticated_whenTokenExistsInKeychain() async {
        KeychainHelper.save("existing-token", for: KeychainHelper.accessTokenKey)
        let vm = AuthViewModel(authService: mockService)
        XCTAssertTrue(vm.isAuthenticated)
    }

    // MARK: - Login

    func testLoginSuccess_setsIsAuthenticated() async {
        await sut.login(email: "test@example.com", password: "password")
        XCTAssertTrue(sut.isAuthenticated)
    }

    func testLoginSuccess_storesTokensInKeychain() async {
        await sut.login(email: "test@example.com", password: "password")
        XCTAssertEqual(KeychainHelper.read(for: KeychainHelper.accessTokenKey), "test-access-token")
        XCTAssertEqual(KeychainHelper.read(for: KeychainHelper.refreshTokenKey), "test-refresh-token")
    }

    func testLoginSuccess_clearsErrorMessage() async {
        sut.errorMessage = "Previous error"
        await sut.login(email: "test@example.com", password: "password")
        XCTAssertNil(sut.errorMessage)
    }

    func testLoginFailure_setsErrorMessage() async {
        mockService.loginResult = .failure(APIError.invalidCredentials)
        await sut.login(email: "test@example.com", password: "wrong")
        XCTAssertNotNil(sut.errorMessage)
    }

    func testLoginFailure_doesNotSetIsAuthenticated() async {
        mockService.loginResult = .failure(APIError.serverError(500))
        await sut.login(email: "test@example.com", password: "password")
        XCTAssertFalse(sut.isAuthenticated)
    }

    func testLogin_isLoadingFalse_afterCompletion() async {
        await sut.login(email: "test@example.com", password: "password")
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - Register

    func testRegisterSuccess_setsIsAuthenticated() async {
        await sut.register(email: "new@example.com", password: "password", name: "Test User")
        XCTAssertTrue(sut.isAuthenticated)
    }

    func testRegisterFailure_setsErrorMessage() async {
        mockService.registerResult = .failure(APIError.serverError(409))
        await sut.register(email: "taken@example.com", password: "password", name: "Test User")
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertFalse(sut.isAuthenticated)
    }

    // MARK: - Logout

    func testLogout_clearsIsAuthenticated() async {
        await sut.login(email: "test@example.com", password: "password")
        sut.logout()
        XCTAssertFalse(sut.isAuthenticated)
    }

    func testLogout_clearsKeychain() async {
        await sut.login(email: "test@example.com", password: "password")
        sut.logout()
        XCTAssertNil(KeychainHelper.read(for: KeychainHelper.accessTokenKey))
        XCTAssertNil(KeychainHelper.read(for: KeychainHelper.refreshTokenKey))
    }

    // MARK: - Session Expiry

    func testSessionExpiredNotification_logsOut() async {
        await sut.login(email: "test@example.com", password: "password")
        XCTAssertTrue(sut.isAuthenticated)

        NotificationCenter.default.post(name: .sessionExpired, object: nil)
        await Task.yield()
        XCTAssertFalse(sut.isAuthenticated)
    }

    func testSessionExpiredNotification_clearsKeychain() async {
        await sut.login(email: "test@example.com", password: "password")
        XCTAssertNotNil(KeychainHelper.read(for: KeychainHelper.accessTokenKey))

        NotificationCenter.default.post(name: .sessionExpired, object: nil)
        await Task.yield()
        XCTAssertNil(KeychainHelper.read(for: KeychainHelper.accessTokenKey))
        XCTAssertNil(KeychainHelper.read(for: KeychainHelper.refreshTokenKey))
    }

    func testLoginFailure_invalidCredentials_setsCorrectMessage() async {
        mockService.loginResult = .failure(APIError.invalidCredentials)
        await sut.login(email: "test@example.com", password: "wrong")
        XCTAssertEqual(sut.errorMessage, "Invalid email or password.")
    }
}
