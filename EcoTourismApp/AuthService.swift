import Foundation
import Observation
import Security

enum UserRole: String, Codable, CaseIterable {
    case tourist, guide
}

struct AccountProfile: Codable, Equatable {
    let id: Int
    let name: String
    let email: String
    let role: UserRole
    let nationality: String?
    let bio: String?
    let languages: String?
}

struct LoginCredentials: Encodable {
    let email: String
    let password: String
}

struct Registration: Encodable {
    let name: String
    let email: String
    let password: String
    let role: UserRole
    let nationality: String?
    let bio: String?
    let languages: String?
}

struct LoginResult: Decodable {
    let token: String
}

struct APIMessage: Decodable {
    let message: String?
    let error: String?
}

enum AuthError: LocalizedError {
    case server(Int, String)
    case configuration
    case invalidResponse
    case keychain
    case accountCreated

    var errorDescription: String? {
        switch self {
        case .server(_, let message): return message
        case .configuration: return "The service address is not configured correctly."
        case .invalidResponse: return "The service returned an unexpected response. Please try again."
        case .keychain: return "Your session could not be saved securely. Please try again."
        case .accountCreated: return "Your account was created, but we could not sign you in. Please use Log In."
        }
    }
}

struct AuthAPI {
    let baseURL: URL?
    var session: URLSession = .shared

    init(baseURL: URL? = nil, session: URLSession = .shared) {
        self.session = session
        if let baseURL {
            self.baseURL = baseURL
        } else {
            #if DEBUG
            let address = ProcessInfo.processInfo.environment["ECOTOURISM_API_URL"]
                ?? Bundle.main.object(forInfoDictionaryKey: "APIBaseURL") as? String
                ?? "http://localhost:3000"
            #else
            let address = Bundle.main.object(forInfoDictionaryKey: "APIBaseURL") as? String ?? ""
            #endif
            self.baseURL = URL(string: address)
        }
    }

    func request<Response: Decodable>(_ route: String, method: String = "GET",
                                       body: Data? = nil, token: String? = nil) async throws -> Response {
        guard let baseURL, let scheme = baseURL.scheme, baseURL.host != nil,
              baseURL.user == nil, baseURL.password == nil,
              ["http", "https"].contains(scheme) else { throw AuthError.configuration }
        #if !DEBUG
        guard scheme == "https" else { throw AuthError.configuration }
        #endif
        var request = URLRequest(url: baseURL.appendingPathComponent(route))
        request.httpMethod = method
        request.timeoutInterval = 15
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if body != nil { request.setValue("application/json", forHTTPHeaderField: "Content-Type") }
        if let token { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse else { throw AuthError.invalidResponse }
        guard (200..<300).contains(response.statusCode) else {
            let message = try? JSONDecoder().decode(APIMessage.self, from: data)
            throw AuthError.server(response.statusCode, message?.error ?? "The request failed. Please try again.")
        }
        do { return try JSONDecoder().decode(Response.self, from: data) }
        catch { throw AuthError.invalidResponse }
    }
}

struct SessionKeychain {
    let account: String
    private let service = "Shanya.Authentication"

    private var query: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service,
         kSecAttrAccount as String: account]
    }

    func read() throws -> String? {
        var query = query
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = item as? Data,
              let token = String(data: data, encoding: .utf8) else { throw AuthError.keychain }
        return token
    }

    func save(_ token: String) throws {
        let data = Data(token.utf8)
        let status = SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        if status == errSecItemNotFound {
            var item = query
            item[kSecValueData as String] = data
            item[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            guard SecItemAdd(item as CFDictionary, nil) == errSecSuccess else { throw AuthError.keychain }
        } else if status != errSecSuccess {
            throw AuthError.keychain
        }
    }

    func delete() throws {
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw AuthError.keychain }
    }
}

@MainActor
@Observable
final class AuthSession {
    var isBrowsing = false
    private(set) var user: AccountProfile?
    private(set) var isRestoring = true
    private(set) var isBusy = false
    private(set) var restoreError: String?
    private let api: AuthAPI
    private let keychain: SessionKeychain
    private var token: String?

    init(api: AuthAPI? = nil, keychainAccount: String? = nil) {
        let api = api ?? AuthAPI()
        self.api = api
        keychain = SessionKeychain(account: keychainAccount ?? api.baseURL?.absoluteString ?? "unconfigured")
    }

    func restore() async {
        guard !isBusy else { return }
        isRestoring = true
        restoreError = nil
        defer { isRestoring = false }
        do {
            guard let saved = try keychain.read() else { return }
            token = saved
            user = try await api.request("me", token: saved)
        } catch AuthError.server(401, _) {
            do { try forgetSession() }
            catch { restoreError = Self.message(for: error) }
        } catch {
            // Keep the saved token during an outage so a retry can restore the session.
            restoreError = Self.message(for: error)
        }
    }

    func signIn(email: String, password: String) async throws {
        guard !isBusy else { return }
        isBusy = true
        defer { isBusy = false }
        try await authenticate(email: email, password: password)
    }

    func register(_ registration: Registration) async throws {
        guard !isBusy else { return }
        isBusy = true
        defer { isBusy = false }
        let _: APIMessage = try await api.request("register", method: "POST", body: JSONEncoder().encode(registration))
        do { try await authenticate(email: registration.email, password: registration.password) }
        catch { throw AuthError.accountCreated }
    }

    private func authenticate(email: String, password: String) async throws {
        let credentials = LoginCredentials(email: email.trimmingCharacters(in: .whitespacesAndNewlines), password: password)
        let result: LoginResult = try await api.request("login", method: "POST", body: JSONEncoder().encode(credentials))
        try await acceptSession(result)
    }

    func completeSocialSignIn(code: String, verifier: String) async throws {
        guard !isBusy else { return }
        isBusy = true
        defer { isBusy = false }
        let body = try JSONEncoder().encode(["code": code, "verifier": verifier])
        let result: LoginResult = try await api.request("auth/social/exchange", method: "POST", body: body)
        try await acceptSession(result)
    }

    private func acceptSession(_ result: LoginResult) async throws {
        do {
            let profile: AccountProfile = try await api.request("me", token: result.token)
            try keychain.save(result.token)
            token = result.token
            user = profile
            restoreError = nil
        } catch {
            let _: APIMessage? = try? await api.request("logout", method: "POST", token: result.token)
            throw error
        }
    }

    func signOut() async throws {
        guard !isBusy else { return }
        isBusy = true
        defer { isBusy = false }
        if let token {
            do {
                let _: APIMessage = try await api.request("logout", method: "POST", token: token)
            } catch AuthError.server(401, _) {
                // An already expired session is safe to remove locally.
            }
        }
        try forgetSession()
    }

    func request<Response: Decodable>(_ route: String, method: String = "GET",
                                       body: Data? = nil, requiresAuth: Bool = true) async throws -> Response {
        if requiresAuth && token == nil { throw AuthError.server(401, "Please sign in to continue.") }
        do {
            return try await api.request(route, method: method, body: body, token: requiresAuth ? token : nil)
        } catch AuthError.server(401, let message) {
            try forgetSession()
            throw AuthError.server(401, message)
        }
    }

    func forgetSession() throws {
        isBrowsing = false
        try keychain.delete()
        token = nil
        user = nil
        restoreError = nil
    }

    static func message(for error: Error) -> String {
        if error is URLError {
            return "We couldn't connect. Check your connection and try again."
        }
        return error.localizedDescription
    }
}
