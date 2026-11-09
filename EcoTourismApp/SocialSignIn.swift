import SwiftUI
import AuthenticationServices
import CryptoKit
import Security

struct SocialSignIn: View {
    let role: UserRole
    @Environment(AuthSession.self) private var session
    @Environment(\.webAuthenticationSession) private var webAuthentication
    @State private var providers: [String] = []
    @State private var loading = true
    @State private var busy = false
    @State private var loadFailed = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Rectangle().frame(height: 1)
                Text("OR CONTINUE WITH").font(.caption2).fixedSize()
                Rectangle().frame(height: 1)
            }
            .foregroundStyle(.secondary)
            ForEach(SocialProvider.allCases) { provider in
                Button {
                    Task { await signIn(provider.rawValue) }
                } label: {
                    HStack {
                        if provider == .apple {
                            Image(systemName: "apple.logo")
                        }
                        Text("Continue with \(provider.title)")
                            .font(.headline)
                        if busy { ProgressView() }
                    }
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(TravelStyle.card, in: RoundedRectangle(cornerRadius: 16))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(TravelStyle.ink.opacity(0.15))
                    }
                }
                .disabled(loading || busy || session.isBusy || !providers.contains(provider.rawValue))
            }
            if loading {
                ProgressView("Checking sign-in options…").font(.footnote)
            } else if loadFailed {
                Text("Couldn't check social sign-in. You can still use email.")
                    .font(.footnote).foregroundStyle(.secondary)
                Button("Retry") { Task { await loadProviders() } }
            } else if providers.count < SocialProvider.allCases.count {
                Text("Unavailable options will be enabled when they're ready.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .task { await loadProviders() }
        .alert("Couldn't Sign In", isPresented: Binding(
            get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: { Text(errorMessage ?? "") }
    }

    private func loadProviders() async {
        loading = true
        defer { loading = false }
        do {
            let result: ProviderAvailability = try await session.request("auth/providers", requiresAuth: false)
            providers = result.providers
            loadFailed = false
        } catch {
            providers = []
            loadFailed = true
        }
    }

    private func signIn(_ provider: String) async {
        busy = true
        defer { busy = false }
        do {
            var bytes = [UInt8](repeating: 0, count: 32)
            guard SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes) == errSecSuccess else {
                throw AuthError.invalidResponse
            }
            let verifier = Data(bytes).base64URL
            let challenge = Data(SHA256.hash(data: Data(verifier.utf8))).base64URL
            let body = try JSONEncoder().encode(["provider": provider, "role": role.rawValue, "challenge": challenge])
            let start: SocialStart = try await session.request("auth/social/start", method: "POST", body: body, requiresAuth: false)
            guard let url = URL(string: start.url), url.scheme == "https" else { throw AuthError.invalidResponse }
            let callback = try await webAuthentication.authenticate(using: url, callbackURLScheme: "shanya")
            let items = URLComponents(url: callback, resolvingAgainstBaseURL: false)?.queryItems ?? []
            guard callback.scheme == "shanya", callback.host == "auth",
                  items.first(where: { $0.name == "state" })?.value == start.state else {
                throw AuthError.invalidResponse
            }
            if let error = items.first(where: { $0.name == "error" })?.value {
                errorMessage = error == "existing_account"
                    ? "An account already uses this email. Please sign in using your original method."
                    : "Sign-in wasn't completed. Please try again and allow access to your email."
                return
            }
            guard let code = items.first(where: { $0.name == "code" })?.value else { throw AuthError.invalidResponse }
            try await session.completeSocialSignIn(code: code, verifier: verifier)
        } catch let error as ASWebAuthenticationSessionError where error.code == .canceledLogin {
            // Closing the provider page leaves the existing sign-in form intact.
        } catch {
            errorMessage = AuthSession.message(for: error)
        }
    }
}

private enum SocialProvider: String, CaseIterable, Identifiable {
    case google, facebook, apple
    var id: String { rawValue }
    var title: String {
        switch self {
        case .google: "Google"
        case .facebook: "Facebook"
        case .apple: "Apple"
        }
    }
}

private struct ProviderAvailability: Decodable { let providers: [String] }
private struct SocialStart: Decodable { let url: String; let state: String }
private extension Data {
    var base64URL: String {
        base64EncodedString().replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "")
    }
}
