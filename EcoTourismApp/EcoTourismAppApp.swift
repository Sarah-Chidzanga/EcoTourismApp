import SwiftUI

@main
struct EcoTourismAppApp: App {
    @State private var session = AuthSession()

    var body: some Scene {
        WindowGroup {
            SessionRootView()
                .environment(session)
        }
    }
}

struct SessionRootView: View {
    @Environment(AuthSession.self) private var session

    var body: some View {
        ZStack {
            if session.isRestoring {
                ProgressView("Restoring your session…")
            } else if let message = session.restoreError {
                SessionRecoveryView(message: message)
            } else if session.user != nil {
                NavigateTabView()
            } else {
                ContentView()
            }
        }
        .task { await session.restore() }
    }
}

private struct SessionRecoveryView: View {
    let message: String
    @Environment(AuthSession.self) private var session
    @State private var localError = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Couldn't Restore Your Session")
                .font(.title2.bold())
            Text(message)
            Button("Try Again") {
                Task { await session.restore() }
            }
            Button("Sign Out on This Device") {
                do { try session.forgetSession() }
                catch { localError = AuthSession.message(for: error) }
            }
            Text("Signing out here removes the saved login. Your server session will expire automatically.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            if !localError.isEmpty { Text(localError).foregroundStyle(.red) }
        }
        .multilineTextAlignment(.center)
        .padding()
        .tint(.brown)
    }
}
