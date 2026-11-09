import SwiftUI

struct Settings: View {
    @Environment(TravelCatalogStore.self) private var store
    @AppStorage("appearance") private var appearance = "System"
    @AppStorage("savedDestinationNames") private var savedNames = ""
    @AppStorage("savedVenueIDs") private var savedVenueIDs = ""
    @State private var confirmingClear = false
    @State private var refreshMessage: String?

    var body: some View {
        Form {
            Section("Keep in Touch") {
                NavigationLink { NotificationInbox() } label: { Label("Notifications", systemImage: "bell") }
                NavigationLink { AppSuggestions() } label: { Label("Suggest an Improvement", systemImage: "bubble.left.and.text.bubble.right") }
                AppRatingButton()
            }
            Section("Appearance") {
                Picker("Theme", selection: $appearance) {
                    Text("Use Device Setting").tag("System")
                    Text("Light").tag("Light")
                    Text("Dark").tag("Dark")
                }
            }
            Section {
                LabeledContent("Sources reviewed", value: store.catalog.reviewedAt)
                Button {
                    Task {
                        await store.refresh(force: true)
                        refreshMessage = store.statusMessage ?? "Your travel directory is up to date."
                    }
                } label: {
                    HStack {
                        Text("Refresh Travel Directory")
                        if store.isRefreshing { ProgressView() }
                    }
                }
                .disabled(store.isRefreshing)
                if let refreshMessage { Text(refreshMessage).font(.footnote).foregroundStyle(.secondary) }
            } header: {
                Text("Offline Travel Information")
            } footer: {
                Text("Destinations, stays, food and activities remain available offline. Websites and guide requests need a connection.")
            }
            Section {
                Button("Clear Saved Places on This Device", role: .destructive) { confirmingClear = true }
                    .disabled(savedNames.isEmpty && savedVenueIDs.isEmpty)
            } header: {
                Text("Saved Places")
            } footer: {
                Text("Clearing saved places does not cancel guide bookings or delete your account.")
            }
            Section("How Shanya Works") {
                Text("Hotels, restaurants and activity companies handle their own reservations through their websites. Confirm prices, availability and cancellation terms directly.")
                Text("Guide day requests made in Shanya appear in My Trips. A request is only accepted after the guide responds. Shanya does not take payments.")
                Text("Listings are sourced travel information, not a guarantee of quality or a partnership. Wildlife sightings are never guaranteed.")
            }
            Section("About") {
                LabeledContent("App", value: "Shanya")
                LabeledContent("Version", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Development")
            }
        }
        .navigationTitle("Settings")
        .tint(TravelStyle.ink)
        .confirmationDialog("Clear all saved places on this device?", isPresented: $confirmingClear, titleVisibility: .visible) {
            Button("Clear Saved Places", role: .destructive) { savedNames = ""; savedVenueIDs = "" }
        }
    }
}

#Preview {
    NavigationStack { Settings() }.environment(TravelCatalogStore()).environment(AuthSession())
}
