import SwiftUI

struct AuthenticationForm: View {
    let role: UserRole
    let isRegistration: Bool
    @Environment(AuthSession.self) private var session
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var nationality = ""
    @State private var bio = ""
    @State private var languages = ""
    @State private var errorMessage = ""
    @State private var showingError = false
    @State private var showingRecoveryInfo = false

    private var canSubmit: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.isEmpty &&
        (!isRegistration || !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                AuthenticationHeader(role: role, isRegistration: isRegistration)
                VStack(spacing: 16) {
                    if isRegistration {
                        TextField("Full Name", text: $name)
                            .textContentType(.name)
                            .modifier(FormFieldStyle())
                    }
                    TextField("Email Address", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .modifier(FormFieldStyle())
                    if isRegistration && role == .tourist {
                        CountryField(selection: $nationality)
                    }
                    if isRegistration && role == .guide {
                        TextField("Languages (e.g. English, Shona)", text: $languages)
                            .modifier(FormFieldStyle())
                        TextField("Short Bio / Expertise", text: $bio, axis: .vertical)
                            .lineLimit(3...5)
                            .modifier(FormFieldStyle())
                    }
                    SecureField("Password", text: $password)
                        .textContentType(isRegistration ? .newPassword : .password)
                        .modifier(FormFieldStyle())
                    if isRegistration {
                        Text("Use at least 8 characters for your password.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .disabled(session.isBusy)

                Button {
                    Task { await submit() }
                } label: {
                    HStack {
                        if session.isBusy { ProgressView().tint(.white) }
                        Text(isRegistration ? "Create Account" : "Log In")
                            .bold()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundStyle(.white)
                    .background(.brown, in: RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!canSubmit || session.isBusy)

                if isRegistration {
                    NavigationLink {
                        AuthenticationForm(role: role, isRegistration: false)
                    } label: {
                        Text("Already have an account? Log In")
                    }
                } else {
                    NavigationLink {
                        AuthenticationForm(role: role, isRegistration: true)
                    } label: {
                        Text("New here? Create an Account")
                    }
                    Button("Forgot Password?") { showingRecoveryInfo = true }
                        .font(.footnote)
                }
            }
            .padding(24)
            .disabled(session.isBusy)
        }
        .background(Color.background.ignoresSafeArea())
        .tint(.brown)
        .navigationBarBackButtonHidden(session.isBusy)
        .alert("Unable to Continue", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("Password Recovery", isPresented: $showingRecoveryInfo) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Password recovery isn't available yet. You can try signing in again with your existing password.")
        }
    }

    private func submit() async {
        do {
            if isRegistration {
                guard password.count >= 8 && password.utf8.count <= 72 else {
                    errorMessage = "Use at least 8 characters and no more than 72 bytes for your password."
                    showingError = true
                    return
                }
                try await session.register(Registration(
                    name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                    email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                    password: password, role: role,
                    nationality: role == .tourist ? nationality : nil,
                    bio: role == .guide ? bio : nil,
                    languages: role == .guide ? languages : nil
                ))
            } else {
                try await session.signIn(email: email, password: password)
            }
            password = ""
        } catch {
            errorMessage = AuthSession.message(for: error)
            showingError = true
        }
    }
}

private struct AuthenticationHeader: View {
    let role: UserRole
    let isRegistration: Bool

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: role == .guide ? "mountain.2.fill" : "leaf.fill")
                .font(.largeTitle)
            Text(isRegistration
                 ? (role == .guide ? "Tour Guide Registration" : "Create an Account")
                 : (role == .guide ? "Guide Login" : "Welcome Back"))
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
            Text(role == .guide ? "Share your knowledge of Zimbabwe." : "Your next adventure starts here.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(.brown)
        .padding(.vertical)
    }
}

private struct CountryField: View {
    @Binding var selection: String
    private static let countries = Locale.Region.isoRegions.map { region in
        (id: region.identifier, name: Locale.current.localizedString(forRegionCode: region.identifier) ?? region.identifier)
    }.sorted { $0.name < $1.name }

    var body: some View {
        Picker("Country", selection: $selection) {
            Text("Select Country").tag("")
            ForEach(Self.countries, id: \.id) { country in
                Text(country.name).tag(country.name)
            }
        }
        .modifier(FormFieldStyle())
    }
}
