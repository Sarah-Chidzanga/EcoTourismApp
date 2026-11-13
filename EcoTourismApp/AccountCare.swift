import SwiftUI
import UserNotifications

private struct AccountFeatures: Decodable { let emailCodes: Bool }
private struct EmailCodeResponse: Decodable { let requestId: String; let message: String }

struct EmailAccountCare: View {
    let isRecovery: Bool
    @Environment(AuthSession.self) private var session
    @State private var email = ""
    @State private var code = ""
    @State private var password = ""
    @State private var requestID: String?
    @State private var enabled = false
    @State private var loading = true
    @State private var busy = false
    @State private var message: String?
    @State private var finished = false

    var body: some View {
        Form {
            Section {
                Text(isRecovery ? "Get back to your adventures." : "Confirm your account email.")
                    .font(.title2.bold())
                Text("Codes expire after 15 minutes. Only the most recently requested code works.")
                    .foregroundStyle(.secondary)
            }
            if loading { ProgressView("Checking email service…") }
            if !loading && !enabled {
                Text(message ?? "Email delivery isn't available yet. Please try again later.")
                Button("Check Again") { Task { await checkService() } }
            }
            if enabled && !finished {
                Section {
                    if isRecovery {
                        TextField("Account email", text: $email)
                            .keyboardType(.emailAddress).textContentType(.emailAddress)
                            .textInputAutocapitalization(.never).autocorrectionDisabled()
                            .disabled(requestID != nil)
                    } else { Text(session.user?.email ?? "") }
                    Button(requestID == nil ? "Send Code" : "Send a New Code") { Task { await sendCode() } }
                        .disabled(busy || (isRecovery && email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty))
                    if requestID != nil && isRecovery {
                        Button("Use a Different Email") { requestID = nil; code = ""; password = ""; message = nil }
                    }
                }
                if requestID != nil {
                    Section {
                        TextField("Six-digit code", text: $code)
                            .keyboardType(.numberPad).textContentType(.oneTimeCode)
                        if isRecovery {
                            SecureField("New password", text: $password).textContentType(.newPassword)
                            Text("Use at least 8 characters, up to 72 UTF-8 bytes.").font(.footnote)
                        }
                        Button(isRecovery ? "Reset Password" : "Verify Email") { Task { await confirm() } }
                            .disabled(busy || code.count != 6 || (isRecovery && (password.count < 8 || password.utf8.count > 72)))
                    }
                }
            }
            if let message, enabled { Section { Text(message) } }
            if busy { ProgressView() }
        }
        .disabled(busy)
        .navigationTitle(isRecovery ? "Reset Password" : "Verify Email")
        .task { await checkService() }
    }

    private func checkService() async {
        loading = true
        defer { loading = false }
        do {
            let features: AccountFeatures = try await session.request("account/features", requiresAuth: false)
            enabled = features.emailCodes
            message = enabled ? nil : "Email delivery isn't available yet. Please try again later."
        } catch { message = AuthSession.message(for: error) }
    }

    private func sendCode() async {
        busy = true; message = nil
        defer { busy = false }
        do {
            let body = isRecovery ? try JSONEncoder().encode(["email": email.trimmingCharacters(in: .whitespacesAndNewlines)]) : nil
            let response: EmailCodeResponse = try await session.request(
                isRecovery ? "account/password/request" : "account/verification/request",
                method: "POST", body: body, requiresAuth: !isRecovery)
            requestID = response.requestId; code = ""
            message = response.message
        } catch { message = AuthSession.message(for: error) }
    }

    private func confirm() async {
        guard let requestID else { return }
        busy = true
        defer { busy = false }
        do {
            var values = ["requestId": requestID, "code": code]
            if isRecovery { values["password"] = password }
            let response: APIMessage = try await session.request(
                isRecovery ? "account/password/confirm" : "account/verification/confirm",
                method: "POST", body: JSONEncoder().encode(values), requiresAuth: !isRecovery)
            if !isRecovery { try await session.refreshProfile() }
            finished = true; code = ""; password = ""
            message = response.message
        } catch { message = AuthSession.message(for: error) }
    }
}

struct DeleteAccountView: View {
    @Environment(AuthSession.self) private var session
    @State private var confirmation = ""
    @State private var confirming = false
    @State private var errorMessage: String?
    @State private var deleting = false

    var body: some View {
        Form {
            Section {
                Text("Delete your Shanya account").font(.title2.bold())
                Text("Your profile, sign-in access, suggestions and personal account details will be removed. Active guide requests will be cancelled. Other participants keep an anonymised booking history.")
                Text("Saved places, trip plans, drafts and reminders on this device will also be cleared. Photos in your photo library are not deleted.")
                Text("Please sign in again first if your last sign-in was more than 10 minutes ago.")
                    .foregroundStyle(.secondary)
            }
            Section {
                TextField("Type DELETE to confirm", text: $confirmation)
                    .textInputAutocapitalization(.characters).autocorrectionDisabled()
                Button("Delete My Account", role: .destructive) { confirming = true }
                    .disabled(confirmation != "DELETE" || deleting)
                if deleting { ProgressView("Deleting account…") }
                if let errorMessage { Text(errorMessage) }
            }
        }
        .navigationTitle("Delete Account")
        .disabled(deleting)
        .confirmationDialog("Permanently delete your account?", isPresented: $confirming, titleVisibility: .visible) {
            Button("Permanently Delete", role: .destructive) { Task { await delete() } }
        } message: { Text("This cannot be undone. You will be signed out.") }
    }

    private func delete() async {
        deleting = true; errorMessage = nil
        defer { deleting = false }
        do {
            try await session.deleteAccount()
            for key in ["savedDestinationNames", "savedVenueIDs", "shanya.tripPlans.v1", "suggestionDraft", "suggestionCategory", "suggestionRequestID"] {
                UserDefaults.standard.removeObject(forKey: key)
            }
            let center = UNUserNotificationCenter.current()
            center.removeAllPendingNotificationRequests()
            center.removeAllDeliveredNotifications()
        } catch { errorMessage = AuthSession.message(for: error) }
    }
}

struct PrivacyInformation: View {
    var body: some View {
        List {
            Section("Your Account") {
                Text("Shanya stores account details, guide listings, guide requests and suggestions on its backend. Published guide details are visible to other people. Contact emails are shared between participants after a guide accepts a request.")
            }
            Section("Your Device") {
                Text("Saved places, trip plans and unsent suggestion drafts are stored on this device. Photos selected for games or sharing are not uploaded to Shanya. Sharing passes the selected content to the app you choose.")
                Text("Local reminders are scheduled only when you ask. You can remove them in Reminder Settings.")
            }
            Section("Your Choices") {
                Text("You can browse without an account, unpublish a guide listing, cancel requests, clear saved places and delete your account. Deletion cancels active requests and removes personal fields; other participants retain anonymised booking history.")
            }
            Section("Service Information") {
                Text("Shanya does not collect booking payments. Company websites manage their own reservations and privacy practices. Before public release, the operator's full privacy policy, terms and support contact must be published here.")
            }
        }
        .navigationTitle("Privacy & Your Data")
    }
}
