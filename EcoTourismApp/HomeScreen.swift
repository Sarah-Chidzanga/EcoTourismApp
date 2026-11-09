import SwiftUI

struct HomeScreen: View {
    var userName: String = ""
    @Environment(TravelCatalogStore.self) private var store

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(userName.isEmpty ? "Where will you go next?" : "Where next, \(userName)?")
                        .font(.largeTitle.bold())
                    Text("Choose your adventure. Make it yours.")
                        .foregroundStyle(.secondary)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 145))], spacing: 12) {
                        NavigationLink { DestinationDirectory() } label: { ExploreTile(title: "Places", subtitle: "Discover Zimbabwe", symbol: "map") }
                        NavigationLink { TravelDirectory() } label: { ExploreTile(title: "Experiences", subtitle: "Activities & companies", symbol: "binoculars") }
                        NavigationLink { VenueDirectory(category: "Stays") } label: { ExploreTile(title: "Stays", subtitle: "Rest somewhere special", symbol: "bed.double") }
                        NavigationLink { VenueDirectory(category: "Food") } label: { ExploreTile(title: "Food", subtitle: "Find your next table", symbol: "fork.knife") }
                        NavigationLink { WildlifeDirectory() } label: { ExploreTile(title: "Wildlife", subtitle: "Animals & game drives", symbol: "pawprint") }
                        NavigationLink { TravelGames() } label: { ExploreTile(title: "Play", subtitle: "Three travel games", symbol: "puzzlepiece") }
                    }
                    .buttonStyle(.plain)
                    NavigationLink { TripPlanner() } label: {
                        Label("Plan Your Trip", systemImage: "plus.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(TravelPrimaryButton())
                }
                .padding(20)
            }
            .background(TravelStyle.sand)
            .navigationTitle("Explore")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink { NotificationInbox() } label: { Label("Notifications", systemImage: "bell") }
                }
            }
            .task { await store.refresh() }
            .tint(TravelStyle.ink)
        }
    }
}

private struct ExploreTile: View {
    let title: String
    let subtitle: String
    let symbol: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: symbol).font(.title2).foregroundStyle(TravelStyle.ink)
            Text(title).font(.headline).foregroundStyle(.primary)
            Text(subtitle).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .leading)
        .padding(16)
        .background(TravelStyle.card, in: RoundedRectangle(cornerRadius: 22))
        .accessibilityElement(children: .combine)
    }
}

struct DestinationDirectory: View {
    @Environment(TravelCatalogStore.self) private var store
    @State private var query = ""
    @State private var region = "All"
    private var places: [Destination] {
        store.destinations.filter {
            (region == "All" || $0.region == region) &&
            (query.isEmpty || $0.searchText.localizedCaseInsensitiveContains(query))
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                Picker("Region", selection: $region) {
                    Text("All Regions").tag("All")
                    ForEach(store.regions) { Text($0.name).tag($0.name) }
                }
                .pickerStyle(.menu)
                if places.isEmpty { ContentUnavailableView.search(text: query) }
                ForEach(places) { DestinationExploreCard(destination: $0) }
                CatalogFootnote(reviewedAt: store.catalog.reviewedAt, status: store.statusMessage)
            }
            .padding(20)
        }
        .background(TravelStyle.sand)
        .navigationTitle("Places")
        .searchable(text: $query, prompt: "Search places or regions")
        .refreshable { await store.refresh(force: true) }
        .tint(TravelStyle.ink)
    }
}

struct DestinationExploreCard: View {
    let destination: Destination
    @AppStorage("savedDestinationNames") private var savedNames = ""

    private var isSaved: Bool {
        let names = Set(savedNames.split(separator: "|").map(String.init))
        return names.contains(destination.name) || destination.aliases.contains(where: names.contains)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            NavigationLink {
                DestinationDetailsView(destination: destination)
            } label: {
                DestinationArtwork(image: destination.image, symbol: destination.symbol, height: 220)
                    .overlay(alignment: .bottomLeading) {
                        Text(destination.region)
                            .font(.caption.weight(.semibold))
                            .padding(10)
                            .background(.regularMaterial, in: Capsule())
                            .padding(16)
                    }
            }
            HStack(alignment: .top, spacing: 12) {
                NavigationLink {
                    DestinationDetailsView(destination: destination)
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(destination.name).font(.title3.bold()).foregroundStyle(.primary)
                        Text(destination.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                Button {
                    var names = Set(savedNames.split(separator: "|").map(String.init))
                    if isSaved {
                        names.remove(destination.name)
                        for alias in destination.aliases { names.remove(alias) }
                    } else { names.insert(destination.name) }
                    savedNames = names.sorted().joined(separator: "|")
                } label: {
                    Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                        .font(.title3)
                        .padding(12)
                }
                .accessibilityLabel(isSaved ? "Unsave \(destination.name)" : "Save \(destination.name)")
            }
            .padding(18)
        }
        .background(TravelStyle.card)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

struct SavedPlacesView: View {
    @AppStorage("savedVenueIDs") private var savedVenueIDs = ""
    private var savedVenues: [TravelVenue] {
        let ids = Set(savedVenueIDs.split(separator: "|").map(String.init))
        return store.catalog.venues.filter { ids.contains($0.id) }
    }
    @Environment(TravelCatalogStore.self) private var store
    @AppStorage("savedDestinationNames") private var savedNames = ""
    private var saved: [Destination] {
        let names = Set(savedNames.split(separator: "|").map(String.init))
        return store.destinations.filter { names.contains($0.name) || $0.aliases.contains(where: names.contains) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                NavigationLink { TripPlanner() } label: {
                    Label("Plan a Trip with Saved Places", systemImage: "map")
                        .padding()
                }
                if saved.isEmpty && savedVenues.isEmpty {
                    ContentUnavailableView("Keep a Little Inspiration", systemImage: "bookmark",
                                           description: Text("Save places from Explore and find them here. Saved places stay on this device."))
                        .padding(.top, 60)
                } else {
                    LazyVStack(spacing: 20) {
                        ForEach(saved) { DestinationExploreCard(destination: $0) }
                        ForEach(savedVenues) { VenueRow(venue: $0) }
                    }
                    .padding(20)
                }
            }
            .background(TravelStyle.sand)
            .navigationTitle("Saved Places")
        }
    }
}
