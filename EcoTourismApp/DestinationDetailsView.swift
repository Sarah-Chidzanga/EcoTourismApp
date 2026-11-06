import SwiftUI

struct DestinationDetailsView: View {
    let destination: Destination
    @Environment(TravelCatalogStore.self) private var store
    @AppStorage("savedDestinationNames") private var savedNames = ""

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
                DestinationExperiences(activities: store.activities(for: destination.id),
                                       companies: store.companies(for: destination.id))
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
