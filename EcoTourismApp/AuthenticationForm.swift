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
    @State private var passwordVisible = false

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
                            .modifier(AuthenticationFieldStyle())
                    }
                    TextField("Email Address", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .modifier(AuthenticationFieldStyle())
                    if isRegistration && role == .tourist {
                        CountryField(selection: $nationality)
                    }
                    if isRegistration && role == .guide {
                        TextField("Languages (e.g. English, Shona)", text: $languages)
                            .modifier(AuthenticationFieldStyle())
                        TextField("Short Bio / Expertise", text: $bio, axis: .vertical)
                            .lineLimit(3...5)
                            .modifier(AuthenticationFieldStyle())
                    }
                    HStack(spacing: 12) {
                        Image(systemName: "lock")
                            .foregroundStyle(TravelStyle.ink)
                            .accessibilityHidden(true)
                        Group {
                            if passwordVisible {
                                TextField("Password", text: $password)
                            } else {
                                SecureField("Password", text: $password)
                            }
                        }
                        .textContentType(isRegistration ? .newPassword : .password)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        Button {
                            passwordVisible.toggle()
                        } label: {
                            Image(systemName: passwordVisible ? "eye.slash" : "eye")
                                .frame(minWidth: 44, minHeight: 44)
                        }
                        .accessibilityLabel(passwordVisible ? "Hide password" : "Show password")
                    }
                    .modifier(AuthenticationFieldStyle())
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
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .overlay(alignment: .trailing) {
                        Image(systemName: "arrow.right")
                            .padding(.trailing, 20)
                            .accessibilityHidden(true)
                    }
                    .foregroundStyle(.white)
                    .background(
                        LinearGradient(colors: [Color(red: 0.16, green: 0.43, blue: 0.32), TravelStyle.forest],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: RoundedRectangle(cornerRadius: 24)
                    )
                    .shadow(color: TravelStyle.forest.opacity(0.25), radius: 12, y: 8)
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
                Text("EXPLORE · CONNECT · CONSERVE")
                    .font(.caption2.weight(.semibold))
                    .tracking(2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 12)
            }
            .frame(maxWidth: 480)
            .padding(24)
            .frame(maxWidth: .infinity)
            .disabled(session.isBusy)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(AuthenticationBackground())
        .tint(TravelStyle.ink)
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

private struct AuthenticationBackground: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                TravelStyle.sand
                Circle()
                    .stroke(TravelStyle.ink.opacity(0.08), lineWidth: 28)
                    .frame(width: 260, height: 260)
                    .offset(x: -geometry.size.width / 2, y: -geometry.size.height / 2)
                Circle()
                    .fill(TravelStyle.ink.opacity(0.05))
                    .frame(width: 250, height: 250)
                    .offset(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

private struct AuthenticationFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .frame(minHeight: 62)
            .background(TravelStyle.card, in: RoundedRectangle(cornerRadius: 22))
            .overlay {
                RoundedRectangle(cornerRadius: 22)
                    .strokeBorder(TravelStyle.ink.opacity(0.12), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.07), radius: 8, x: 3, y: 5)
    }
}

private struct AuthenticationHeader: View {
    let role: UserRole
    let isRegistration: Bool

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: role == .guide ? "mountain.2.fill" : "leaf.fill")
                .font(.system(size: 64, weight: .medium))
                .foregroundStyle(
                    LinearGradient(colors: [TravelStyle.ink, Color.green],
                                   startPoint: .bottomLeading, endPoint: .topTrailing)
                )
                .frame(width: 140, height: 140)
                .background(TravelStyle.card, in: RoundedRectangle(cornerRadius: 42))
                .overlay {
                    RoundedRectangle(cornerRadius: 42)
                        .strokeBorder(TravelStyle.ink.opacity(0.1), lineWidth: 1)
                }
                .shadow(color: TravelStyle.forest.opacity(0.15), radius: 16, x: 5, y: 10)
                .accessibilityHidden(true)
            Text("SHANYA")
                .font(.caption.weight(.semibold))
                .tracking(4)
                .padding(.top, 8)
            Text(isRegistration
                 ? (role == .guide ? "Become a Guide" : "Start Exploring")
                 : "Welcome Back")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
            Text(isRegistration
                 ? (role == .guide ? "Share your knowledge of Zimbabwe." : "Make Zimbabwe part of your story.")
                 : (role == .guide ? "Sign in to your guide account." : "Sign in for your next adventure."))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(TravelStyle.ink)
        .padding(.vertical)
    }
}

private struct CountryField: View {
    @Binding var selection: String
    private static let countries = Locale.Region.isoRegions.filter { $0.identifier.count == 2 }.map { region in
        (id: region.identifier, name: Locale.current.localizedString(forRegionCode: region.identifier) ?? region.identifier)
    }.sorted { $0.name < $1.name }

    var body: some View {
        Picker("Country", selection: $selection) {
            Text("Select Country").tag("")
            ForEach(Self.countries, id: \.id) { country in
                Text(country.name).tag(country.name)
            }
        }
        .modifier(AuthenticationFieldStyle())
    }
}
