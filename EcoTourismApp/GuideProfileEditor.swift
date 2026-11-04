import SwiftUI

struct GuideProfileEditor: View {
    @Environment(AuthSession.self) private var session
    @State private var title = ""
    @State private var location = ""
    @State private var bio = ""
    @State private var languages = ""
    @State private var dailyRate = ""
    @State private var maxGuests = 6
    @State private var published = false
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var didLoad = false
    @State private var message = ""
    @State private var showingMessage = false

    var body: some View {
        Form {
            Section {
                Text("Help travellers picture a day with you. These details appear in your public guide listing when you publish.")
                    .foregroundStyle(.secondary)
            }
            Section("Your Story") {
                TextField("Headline, e.g. Wildlife walks in Hwange", text: $title)
                TextField("Places you guide, e.g. Victoria Falls", text: $location)
                TextField("Languages", text: $languages)
                TextField("Tell travellers about your experience", text: $bio, axis: .vertical)
                    .lineLimit(5...10)
            }
            Section {
                TextField("Group price per day (USD)", text: $dailyRate)
                    .keyboardType(.decimalPad)
                Stepper("Up to \(maxGuests) guests", value: $maxGuests, in: 1...20)
            } header: { Text("Your Day Rate") } footer: {
                Text("One-day guide fee for the whole group. Entry fees, meals, transport, and accommodation are excluded.")
            }
            Section {
                Toggle("Visible to Travellers", isOn: $published)
            } footer: {
                Text("Publishing makes your name, profile, location, languages, and rate public. Your email is shared only with guests whose requests you accept. Turn this off to pause new requests.")
            }
            Section {
                Button {
                    Task { await save() }
                } label: {
                    HStack {
                        Text(published ? "Save & Publish Profile" : "Save Private Profile")
                        if isSaving { ProgressView() }
                    }
                }
                .disabled(!didLoad || isSaving)
            }
            if !isLoading && !didLoad {
                Section {
                    Button("Retry Loading Profile") { Task { await load() } }
                }
            }
        }
        .disabled(isLoading || isSaving)
        .overlay { if isLoading { ProgressView("Loading profile…") } }
        .navigationTitle("Your Guide Listing")
        .navigationBarTitleDisplayMode(.inline)
        .tint(TravelStyle.ink)
        .task { if !didLoad { await load() } }
        .alert("Guide Profile", isPresented: $showingMessage) {
            Button("OK", role: .cancel) {}
        } message: { Text(message) }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let profile: GuideListing = try await session.request("guide-profile")
            title = profile.title
            location = profile.location
            bio = profile.bio
            languages = profile.languages
            dailyRate = profile.dailyRate == 0 ? "" : String(profile.dailyRate)
            maxGuests = profile.maxGuests
            published = profile.published ?? false
            didLoad = true
        } catch {
            message = AuthSession.message(for: error)
            showingMessage = true
        }
    }

    private func save() async {
        guard let rate = Double(dailyRate.isEmpty ? "0" : dailyRate.replacingOccurrences(of: ",", with: ".")) else {
            message = "Enter a valid daily price in USD."
            showingMessage = true
            return
        }
        isSaving = true
        defer { isSaving = false }
        do {
            let update = GuideProfileUpdate(title: title, location: location, bio: bio, languages: languages,
                                            dailyRate: rate, maxGuests: maxGuests, published: published)
            let result: APIMessage = try await session.request("guide-profile", method: "PUT", body: JSONEncoder().encode(update))
            message = result.message ?? "Profile saved."
        } catch { message = AuthSession.message(for: error) }
        showingMessage = true
    }
}

struct GuideDashboard: View {
    @Environment(AuthSession.self) private var session
    @State private var requests: [TripBooking] = []
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("YOUR LOCAL KNOWLEDGE.\nTHEIR NEXT ADVENTURE.")
                        .font(.caption.weight(.bold)).tracking(2)
                        .foregroundStyle(TravelStyle.ink)
                    Text("Hello, \(session.user?.name ?? "Guide").")
                        .font(.largeTitle.bold())
                    Text("Welcome people to the places you know best.")
                        .foregroundStyle(.secondary)
                    HStack(spacing: 16) {
                        GuideMetric(title: "Awaiting reply", count: requests.filter { $0.status == "pending" }.count, symbol: "tray")
                        GuideMetric(title: "Accepted", count: requests.filter { $0.status == "confirmed" }.count, symbol: "calendar")
                    }
                    if let errorMessage { Text(errorMessage).foregroundStyle(.secondary) }
                    NavigationLink {
                        BookingsView(isGuide: true)
                    } label: { Label("Review Booking Requests", systemImage: "tray.full") }
                    .buttonStyle(TravelPrimaryButton())
                    VStack(alignment: .leading, spacing: 14) {
                        Label("Your Story Brings People Here", systemImage: "person.text.rectangle")
                            .font(.headline)
                        Text("Set your locations, languages, and group day rate. Publish when you're ready to receive requests.")
                            .foregroundStyle(.secondary)
                        NavigationLink("Edit Your Guide Listing") { GuideProfileEditor() }
                            .font(.headline)
                    }
                    .padding(22)
                    .background(TravelStyle.card, in: RoundedRectangle(cornerRadius: 24))
                    Text("Pull down to refresh requests. Accepting a day reserves it for that group; other requests on that date can't be accepted unless the booking is cancelled.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                .padding(20)
            }
            .background(TravelStyle.sand)
            .navigationTitle("Your Workspace")
            .navigationBarTitleDisplayMode(.inline)
            .task { await load() }
            .refreshable { await load() }
        }
    }

    private func load() async {
        do {
            requests = try await session.request("bookings")
            errorMessage = nil
        } catch { errorMessage = AuthSession.message(for: error) }
    }
}

private struct GuideMetric: View {
    let title: String
    let count: Int
    let symbol: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: symbol).foregroundStyle(TravelStyle.ink)
            Text("\(count)").font(.largeTitle.bold())
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(TravelStyle.card, in: RoundedRectangle(cornerRadius: 24))
    }
}
