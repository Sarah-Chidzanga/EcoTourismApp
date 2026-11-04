import SwiftUI

struct GuideDirectory: View {
    var initialSearch = ""
    @Environment(AuthSession.self) private var session
    @State private var guides: [GuideListing] = []
    @State private var search = ""
    @State private var isLoading = true
    @State private var errorMessage: String?

    private var filtered: [GuideListing] {
        guides.filter { search.isEmpty || "\($0.name) \($0.location) \($0.languages) \($0.title)".localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("See it through local eyes.")
                        .font(.largeTitle.bold())
                    Text("Find a guide, choose your day, and send a request. Your trip is accepted when the guide says yes.")
                        .foregroundStyle(.secondary)
                }
                if isLoading {
                    ProgressView("Finding guides…").frame(maxWidth: .infinity).padding(40)
                } else if let errorMessage {
                    ContentUnavailableView {
                        Label("Couldn't Load Guides", systemImage: "wifi.exclamationmark")
                    } description: { Text(errorMessage) } actions: {
                        Button("Try Again") { Task { await load() } }
                    }
                } else if filtered.isEmpty {
                    ContentUnavailableView(search.isEmpty ? "Local Connections Start Here" : "No Matching Guides",
                                           systemImage: "person.2",
                                           description: Text(search.isEmpty ? "Guides appear here when they publish their profiles. Check back soon." : "Try another place, name, or language."))
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(filtered) { guide in
                            NavigationLink { GuideDetailView(guide: guide) } label: {
                                GuideListingCard(guide: guide)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(TravelStyle.sand)
        .navigationTitle("Local Guides")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $search, prompt: "Place, guide, or language")
        .refreshable { await load() }
        .task {
            search = initialSearch
            await load()
        }
        .tint(TravelStyle.ink)
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do { guides = try await session.request("guides", requiresAuth: false) }
        catch { errorMessage = AuthSession.message(for: error) }
    }
}

private struct GuideListingCard: View {
    let guide: GuideListing

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                GuideAvatar(initials: guide.initials)
                VStack(alignment: .leading, spacing: 5) {
                    Text(guide.name).font(.headline)
                    Text(guide.title).font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").foregroundStyle(.secondary)
            }
            Label(guide.location, systemImage: "mappin.and.ellipse").font(.subheadline)
            Text(guide.languages).font(.subheadline).foregroundStyle(.secondary)
            Divider()
            HStack {
                Text(guide.dailyRate, format: .currency(code: "USD")).font(.headline)
                Text("/ group · day").font(.caption).foregroundStyle(.secondary)
                Spacer()
                Label("Up to \(guide.maxGuests)", systemImage: "person.2").font(.caption)
            }
        }
        .padding(20)
        .background(TravelStyle.card, in: RoundedRectangle(cornerRadius: 24))
    }
}

struct GuideDetailView: View {
    let guide: GuideListing
    @Environment(AuthSession.self) private var session

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack(spacing: 16) {
                    GuideAvatar(initials: guide.initials)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(guide.name).font(.title.bold())
                        Text(guide.title).foregroundStyle(.secondary)
                    }
                }
                Label(guide.location, systemImage: "mappin.and.ellipse")
                VStack(alignment: .leading, spacing: 10) {
                    Text("A day, your way").font(.title2.bold())
                    Text(guide.bio)
                }
                VStack(alignment: .leading, spacing: 14) {
                    Label(guide.languages, systemImage: "bubble.left.and.bubble.right")
                    Label("Groups of up to \(guide.maxGuests)", systemImage: "person.2")
                    HStack {
                        Text(guide.dailyRate, format: .currency(code: "USD")).font(.title2.bold())
                        Text("per group, per day").foregroundStyle(.secondary)
                    }
                    Text("Guide fee only. Agree on the route, meeting point, transport, and entry costs directly after acceptance. No payment is collected in the app.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(20)
                .background(TravelStyle.card, in: RoundedRectangle(cornerRadius: 24))
                if session.user == nil {
                    NavigationLink {
                        AuthenticationForm(role: .tourist, isRegistration: false)
                    } label: { Text("Log In to Request a Day") }
                    .buttonStyle(TravelPrimaryButton())
                } else if session.user?.role == .tourist {
                    NavigationLink { BookTourGuide(guide: guide) } label: { Text("Request a Day with \(guide.name)") }
                        .buttonStyle(TravelPrimaryButton())
                }
                Text("Profile information is provided by the guide. Shanya has not verified qualifications.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
        }
        .background(TravelStyle.sand)
        .navigationTitle("Meet Your Guide")
        .navigationBarTitleDisplayMode(.inline)
    }
}
