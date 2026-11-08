import SwiftUI

struct Profile: View {
    @Environment(AuthSession.self) private var session
    @State private var errorMessage = ""
    @State private var showingError = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Travel Memories") {
                    NavigationLink { ShareMemory() } label: {
                        Label("Share a Memory", systemImage: "photo.on.rectangle")
                    }
                }
                if let user = session.user {
                    Section("Your Account") {
                        LabeledContent("Name", value: user.name)
                        LabeledContent("Email", value: user.email)
                        LabeledContent("Account Type", value: user.role == .guide ? "Tour Guide" : "Tourist")
                    }
                    if let nationality = user.nationality, !nationality.isEmpty {
                        Section("Country") { Text(nationality) }
                    }
                    if user.role == .guide {
                        Section("Your Business") {
                            NavigationLink("Edit Public Guide Listing") { GuideProfileEditor() }
                        }
                        if let languages = user.languages, !languages.isEmpty {
                            Section("Languages") { Text(languages) }
                        }
                        if let bio = user.bio, !bio.isEmpty {
                            Section("About You") { Text(bio) }
                        }
                    }
                    Section {
                        Button(role: .destructive) {
                            Task {
                                do { try await session.signOut() }
                                catch {
                                    errorMessage = AuthSession.message(for: error)
                                    showingError = true
                                }
                            }
                        } label: {
                            HStack {
                                Text("Log Out")
                                if session.isBusy { ProgressView() }
                            }
                        }
                        .disabled(session.isBusy)
                    }
                } else {
                    SignInPrompt()
                    Section {
                        NavigationLink("Join as a Tour Guide") {
                            AuthenticationForm(role: .guide, isRegistration: true)
                        }
                    }
                }
            }
            .navigationTitle("You")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink { Settings() } label: { Label("Settings", systemImage: "gearshape") }
                }
            }
            .scrollContentBackground(.hidden)
            .background(TravelStyle.sand)
            .tint(TravelStyle.ink)
            .alert("Couldn't Log Out", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
}

#Preview {
    Profile()
        .environment(AuthSession())
        .environment(TravelCatalogStore())
}
