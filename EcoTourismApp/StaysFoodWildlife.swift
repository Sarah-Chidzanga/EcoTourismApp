import SwiftUI

struct VenueDirectory: View {
    @Environment(TravelCatalogStore.self) private var store
    @AppStorage("savedVenueIDs") private var savedIDs = ""
    @State private var query = ""
    @State private var savedOnly = false
    @State private var category: String

    init(category: String = "Stays") { _category = State(initialValue: category) }

    private var venues: [TravelVenue] {
        let saved = Set(savedIDs.split(separator: "|").map(String.init))
        return store.catalog.venues.filter {
            $0.category == category && (!savedOnly || saved.contains($0.id)) &&
            (query.isEmpty || "\($0.name) \($0.location) \($0.kind)".localizedCaseInsensitiveContains(query))
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(category == "Stays" ? "Make yourself at home." : category == "Food" ? "A taste of the journey." : "A day somewhere new.")
                    .font(.largeTitle.bold())
                Picker("Browse", selection: $category) {
                    Text("Stays").tag("Stays")
                    Text("Food").tag("Food")
                    Text("Day Visits").tag("Day visits")
                }
                .pickerStyle(.segmented)
                Toggle("Saved Only", isOn: $savedOnly)
                Text(venues.count == 1 ? "1 place" : "\(venues.count) places").foregroundStyle(.secondary)
                if venues.isEmpty {
                    ContentUnavailableView("No Matching Places", systemImage: "magnifyingglass",
                        description: Text(savedOnly ? "Save a place first, or turn off Saved Only." : "Try another name or town. More places will be added as their details are checked."))
                }
                LazyVStack(spacing: 14) {
                    ForEach(venues) { VenueRow(venue: $0) }
                }
                CatalogFootnote(reviewedAt: store.catalog.reviewedAt, status: store.statusMessage)
            }
            .padding(20)
        }
        .background(TravelStyle.sand)
        .navigationTitle(category)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $query, prompt: "Property, restaurant or town")
        .refreshable { await store.refresh(force: true) }
        .task { await store.refresh() }
        .tint(TravelStyle.ink)
    }
}

struct VenueRow: View {
    let venue: TravelVenue

    var body: some View {
        NavigationLink { VenueDetailView(venue: venue) } label: {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: venue.symbol).font(.title2).foregroundStyle(TravelStyle.ink)
                VStack(alignment: .leading, spacing: 8) {
                    Text(venue.name).font(.headline).foregroundStyle(.primary)
                    Text("\(venue.kind) · \(venue.location)").font(.subheadline).foregroundStyle(.secondary)
                    Text(venue.description).font(.subheadline).foregroundStyle(.secondary).lineLimit(3)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").foregroundStyle(.secondary)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(TravelStyle.card, in: RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }
}

struct VenueDetailView: View {
    let venue: TravelVenue
    @Environment(TravelCatalogStore.self) private var store
    @AppStorage("savedVenueIDs") private var savedIDs = ""

    private var isSaved: Bool { savedIDs.split(separator: "|").contains(Substring(venue.id)) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Label(venue.kind, systemImage: venue.symbol).foregroundStyle(TravelStyle.ink)
                Text(venue.name).font(.largeTitle.bold())
                Label(venue.location, systemImage: "mappin.and.ellipse").foregroundStyle(.secondary)
                Text(venue.description)
                HStack {
                    Button {
                        var saved = Set(savedIDs.split(separator: "|").map(String.init))
                        if isSaved { saved.remove(venue.id) } else { saved.insert(venue.id) }
                        savedIDs = saved.sorted().joined(separator: "|")
                    } label: {
                        Label(isSaved ? "Saved" : "Save Place", systemImage: isSaved ? "bookmark.fill" : "bookmark")
                    }
                    Spacer()
                    if let url = venue.mapURL { Link("Find in Maps", destination: url) }
                }
                TravelInfoSection(title: venue.category == "Stays" ? "Plan Your Stay" : "Plan Your Visit", text: venue.planning)
                ExternalTravelLink(title: venue.sourceLabel == "Official website" ? "Visit Website & Enquire" : "View Contact Listing", address: venue.website)
                    .buttonStyle(TravelPrimaryButton())
                Text("Source: \(venue.sourceLabel). Reservations are arranged with the venue; Shanya does not show live room or table availability.")
                    .font(.footnote).foregroundStyle(.secondary)
                if let destination = store.destinations.first(where: { $0.id == venue.destinationID }) {
                    NavigationLink { DestinationDetailsView(destination: destination) } label: {
                        Label("Explore \(destination.name)", systemImage: "safari")
                    }
                }
                CatalogFootnote(reviewedAt: store.catalog.reviewedAt, status: nil)
            }
            .padding(20)
        }
        .background(TravelStyle.sand)
        .navigationTitle(venue.category == "Stays" ? "Place to Stay" : "Place to Visit")
        .navigationBarTitleDisplayMode(.inline)
        .tint(TravelStyle.ink)
    }
}

struct WildlifeDirectory: View {
    @Environment(TravelCatalogStore.self) private var store
    @State private var query = ""

    private var animals: [WildlifeListing] {
        store.catalog.wildlife.filter { animal in
            let places = store.destinations.filter { animal.destinationIDs.contains($0.id) }.map(\.name).joined(separator: " ")
            return query.isEmpty || "\(animal.name) \(places)".localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Meet the wild side.").font(.largeTitle.bold())
                Text("Discover animals and places to look for them, then find a guided experience. Sightings are never guaranteed.")
                    .foregroundStyle(.secondary)
                NavigationLink { TravelDirectory(category: "Game drives") } label: {
                    Label("Find Game Drives", systemImage: "car.side")
                }.buttonStyle(TravelPrimaryButton())
                if animals.isEmpty { ContentUnavailableView.search(text: query) }
                LazyVStack(spacing: 14) {
                    ForEach(animals) { WildlifeRow(animal: $0) }
                }
                CatalogFootnote(reviewedAt: store.catalog.reviewedAt, status: store.statusMessage)
            }
            .padding(20)
        }
        .background(TravelStyle.sand)
        .navigationTitle("Wildlife")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $query, prompt: "Animal or destination")
        .task { await store.refresh() }
        .tint(TravelStyle.ink)
    }
}

struct WildlifeRow: View {
    let animal: WildlifeListing

    var body: some View {
        NavigationLink { WildlifeDetailView(animal: animal) } label: {
            HStack(alignment: .top, spacing: 14) {
                DestinationArtwork(image: animal.image, symbol: "pawprint", height: 80)
                    .frame(width: 80).clipShape(RoundedRectangle(cornerRadius: 14))
                VStack(alignment: .leading, spacing: 8) {
                    Text(animal.name).font(.headline).foregroundStyle(.primary)
                    Text(animal.description).font(.subheadline).foregroundStyle(.secondary).lineLimit(3)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(TravelStyle.card, in: RoundedRectangle(cornerRadius: 20))
        }.buttonStyle(.plain)
    }
}

struct WildlifeDetailView: View {
    let animal: WildlifeListing
    @Environment(TravelCatalogStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                DestinationArtwork(image: animal.image, symbol: "pawprint", height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                Text(animal.name).font(.largeTitle.bold())
                Text(animal.description)
                Text("Where to Look").font(.title2.bold())
                ForEach(store.destinations.filter { animal.destinationIDs.contains($0.id) }) { place in
                    NavigationLink { DestinationDetailsView(destination: place) } label: {
                        Label(place.name, systemImage: "mappin.and.ellipse")
                    }
                }
                Text("Find an Experience").font(.title2.bold())
                ForEach(store.catalog.activities.filter { animal.activityIDs.contains($0.id) }) { ActivityDirectoryRow(activity: $0) }
                Text("Wild animals move freely. Keep your distance, never feed them, and follow your guide’s instructions.")
                    .font(.footnote).foregroundStyle(.secondary)
                ExternalTravelLink(title: "Read Wildlife Source", address: animal.sourceURL)
            }.padding(20)
        }
        .background(TravelStyle.sand)
        .navigationTitle("Wildlife")
        .navigationBarTitleDisplayMode(.inline)
        .tint(TravelStyle.ink)
    }
}
