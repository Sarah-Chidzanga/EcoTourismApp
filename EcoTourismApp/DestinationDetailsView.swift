import SwiftUI

struct DestinationDetailsView: View {
    let destination: Destination
    @Environment(TravelCatalogStore.self) private var store
    @AppStorage("savedDestinationNames") private var savedNames = ""
    @State private var selectedSection = "Activities"

    private var isSaved: Bool {
        let names = Set(savedNames.split(separator: "|").map(String.init))
        return names.contains(destination.name) || destination.aliases.contains(where: names.contains)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                DestinationArtwork(image: destination.image, symbol: destination.symbol, height: 260)
                    .clipShape(RoundedRectangle(cornerRadius: 26))
                DestinationOverview(destination: destination)
                HStack {
                    Button {
                        var names = Set(savedNames.split(separator: "|").map(String.init))
                        if isSaved {
                            names.remove(destination.name)
                            for alias in destination.aliases { names.remove(alias) }
                        } else { names.insert(destination.name) }
                        savedNames = names.sorted().joined(separator: "|")
                    } label: {
                        Label(isSaved ? "Saved" : "Save Place", systemImage: isSaved ? "bookmark.fill" : "bookmark")
                    }
                    Spacer()
                    if let url = destination.mapURL {
                        Link(destination: url) { Label("Find in Maps", systemImage: "map") }
                    }
                }
                TravelInfoSection(title: "Plan Your Visit", text: destination.planning)
                Picker("Explore this destination", selection: $selectedSection) {
                    Text("Activities").tag("Activities")
                    Text("Stays").tag("Stays")
                    Text("Food").tag("Food")
                    Text("Wildlife").tag("Wildlife")
                }
                .pickerStyle(.segmented)
                DestinationTravelSection(destinationID: destination.id, selection: selectedSection)
                NavigationLink {
                    GuideDirectory(initialSearch: destination.guideSearch)
                } label: {
                    Label("Find a Local Guide", systemImage: "person.2")
                }
                .buttonStyle(TravelPrimaryButton())
                Text("Independent guides on Shanya manage their own listings and day requests.")
                    .font(.footnote).foregroundStyle(.secondary)
                TravelInfoSection(title: "Travel Thoughtfully", text: destination.ecoTip)
                ExternalTravelLink(title: "Read the Destination Source", address: destination.sourceURL)
                CatalogFootnote(reviewedAt: store.catalog.reviewedAt, status: store.statusMessage)
            }
            .padding(20)
        }
        .background(TravelStyle.sand)
        .navigationTitle(destination.name)
        .navigationBarTitleDisplayMode(.inline)
        .tint(TravelStyle.ink)
    }
}

private struct DestinationOverview: View {
    let destination: Destination

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(destination.region, systemImage: "mappin.and.ellipse")
                .font(.subheadline).foregroundStyle(TravelStyle.ink)
            Text(destination.name).font(.largeTitle.bold())
            Text(destination.description).foregroundStyle(.secondary)
        }
    }
}

private struct DestinationExperiences: View {
    let activities: [TravelActivity]
    let companies: [TravelCompany]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Things to Do").font(.title2.bold())
            ForEach(activities) { ActivityDirectoryRow(activity: $0) }
            Text("Companies & Visitor Teams").font(.title2.bold()).padding(.top, 8)
            ForEach(companies) { CompanyDirectoryRow(company: $0) }
        }
    }
}

private struct DestinationTravelSection: View {
    let destinationID: String
    let selection: String
    @Environment(TravelCatalogStore.self) private var store

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if selection == "Activities" {
                DestinationExperiences(activities: store.activities(for: destinationID),
                                       companies: store.companies(for: destinationID))
            } else if selection == "Wildlife" {
                let animals = store.wildlife(for: destinationID)
                if animals.isEmpty {
                    Text("Wildlife information for this destination is still being researched.").foregroundStyle(.secondary)
                }
                ForEach(animals) { WildlifeRow(animal: $0) }
            } else {
                let venues = store.venues(for: destinationID, category: selection)
                if venues.isEmpty {
                    Text("No checked listings here yet. Browse the wider directory for more places.").foregroundStyle(.secondary)
                }
                ForEach(venues) { VenueRow(venue: $0) }
                NavigationLink("Browse All \(selection)") { VenueDirectory(category: selection) }
            }
        }
    }
}
