import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case unauthorized
    case invalidCredentials
    case serverError(Int)
    case decodingError(Error)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:          return "Invalid request URL."
        case .unauthorized:        return "Session expired. Please log in again."
        case .invalidCredentials:  return "Invalid email or password."
        case .serverError(let c):  return "Server error (\(c))."
        case .decodingError:       return "Unexpected response from server."
        case .networkError(let e): return e.localizedDescription
        }
    }
}

extension Notification.Name {
    static let sessionExpired = Notification.Name("GarageKeep.sessionExpired")
}

final class APIClient {
    static let shared = APIClient()

    private let baseURL = "http://127.0.0.1:8005"
    private let session: URLSession

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let str = try container.decode(String.self)

            // 1. ISO8601 with fractional seconds + timezone (e.g. "2026-03-10T12:50:06.484Z")
            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = iso.date(from: str) { return date }

            // 2. ISO8601 without fractional seconds + timezone (e.g. "2026-03-10T12:50:06Z")
            iso.formatOptions = [.withInternetDateTime]
            if let date = iso.date(from: str) { return date }

            // 3. Naive datetime with microseconds (e.g. "2026-03-10T12:50:06.484000")
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            df.timeZone = TimeZone(secondsFromGMT: 0)
            df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
            if let date = df.date(from: str) { return date }

            // 4. Naive datetime without fractional seconds (e.g. "2026-03-10T12:50:06")
            df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            if let date = df.date(from: str) { return date }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date from: \(str)"
            )
        }
        return d
    }()

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        return e
    }()

    init(session: URLSession = .shared) {
        self.session = session
    }

    func request<T: Decodable>(
        _ path: String,
        method: String = "GET",
        body: (any Encodable)? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        guard let url = URL(string: baseURL + path) else { throw APIError.invalidURL }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if requiresAuth, let token = KeychainHelper.read(for: KeychainHelper.accessTokenKey) {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            req.httpBody = try encoder.encode(body)
        }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: req)
        } catch {
            throw APIError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.networkError(URLError(.badServerResponse))
        }

        if http.statusCode == 401 {
            if requiresAuth {
                if let refreshed = try? await attemptTokenRefresh() {
                    KeychainHelper.save(refreshed.accessToken, for: KeychainHelper.accessTokenKey)
                    KeychainHelper.save(refreshed.refreshToken, for: KeychainHelper.refreshTokenKey)
                    return try await request(path, method: method, body: body, requiresAuth: requiresAuth)
                }
                NotificationCenter.default.post(name: .sessionExpired, object: nil)
                throw APIError.unauthorized
            } else {
                throw APIError.invalidCredentials
            }
        }

        guard (200..<300).contains(http.statusCode) else {
            throw APIError.serverError(http.statusCode)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            #if DEBUG
            let raw = String(data: data, encoding: .utf8) ?? "<non-UTF8>"
            print("[APIClient] Decoding error for \(T.self): \(error)")
            print("[APIClient] Raw response: \(raw)")
            #endif
            throw APIError.decodingError(error)
        }
    }

    func requestVoid(
        _ path: String,
        method: String = "DELETE",
        requiresAuth: Bool = true
    ) async throws {
        guard let url = URL(string: baseURL + path) else { throw APIError.invalidURL }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if requiresAuth, let token = KeychainHelper.read(for: KeychainHelper.accessTokenKey) {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (_, response): (Data, URLResponse)
        do {
            (_, response) = try await session.data(for: req)
        } catch {
            throw APIError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.networkError(URLError(.badServerResponse))
        }

        if http.statusCode == 401 {
            if requiresAuth {
                if let refreshed = try? await attemptTokenRefresh() {
                    KeychainHelper.save(refreshed.accessToken, for: KeychainHelper.accessTokenKey)
                    KeychainHelper.save(refreshed.refreshToken, for: KeychainHelper.refreshTokenKey)
                    try await requestVoid(path, method: method, requiresAuth: requiresAuth)
                    return
                }
                NotificationCenter.default.post(name: .sessionExpired, object: nil)
                throw APIError.unauthorized
            } else {
                throw APIError.invalidCredentials
            }
        }

        guard (200..<300).contains(http.statusCode) else {
            throw APIError.serverError(http.statusCode)
        }
    }

    private func attemptTokenRefresh() async throws -> TokenResponse {
        guard let refreshToken = KeychainHelper.read(for: KeychainHelper.refreshTokenKey),
              let url = URL(string: baseURL + "/v1/auth/refresh") else {
            throw APIError.unauthorized
        }

        struct RefreshBody: Encodable { let refreshToken: String }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try encoder.encode(RefreshBody(refreshToken: refreshToken))

        let (data, _) = try await session.data(for: req)
        return try decoder.decode(TokenResponse.self, from: data)
    }
}
