import SwiftUI

struct HomeScreen: View {
    var userName: String = ""
    @State private var searchText = ""
    @State private var selectedRegion = "All"

    private var filteredDestinations: [Destination] {
        destinations.filter {
            (selectedRegion == "All" || $0.region == selectedRegion) &&
            (searchText.isEmpty || "\($0.name) \($0.region) \($0.description)".localizedCaseInsensitiveContains(searchText))
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ExploreHeader(userName: userName)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(["All"] + regions.map(\.name), id: \.self) { region in
                                Button { selectedRegion = region } label: {
                                    Text(region)
                                        .font(.subheadline.weight(.medium))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .foregroundStyle(selectedRegion == region ? .white : .primary)
                                        .background(selectedRegion == region ? TravelStyle.forest : TravelStyle.card, in: Capsule())
                                }
                                .accessibilityAddTraits(selectedRegion == region ? .isSelected : [])
                            }
                        }
                    }
                    HStack {
                        Text(searchText.isEmpty ? "Find your next escape" : "Search results")
                            .font(.title2.bold())
                        Spacer()
                        Text(filteredDestinations.count == 1 ? "1 place" : "\(filteredDestinations.count) places")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if filteredDestinations.isEmpty {
                        ContentUnavailableView.search(text: searchText)
                    }
                    LazyVStack(spacing: 20) {
                        ForEach(filteredDestinations) { destination in
                            DestinationExploreCard(destination: destination)
                        }
                    }
                    Label("Travel thoughtfully. Support local people and respect the places you visit.", systemImage: "leaf")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.vertical)
                }
                .padding(20)
            }
            .background(TravelStyle.sand)
            .navigationTitle("Explore")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search places or regions")
            .tint(TravelStyle.ink)
        }
    }
}

private struct ExploreHeader: View {
    let userName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(userName.isEmpty ? "YOUR ZIMBABWE STARTS HERE" : "WELCOME, \(userName.uppercased())")
                .font(.caption.weight(.bold))
                .tracking(2)
                .foregroundStyle(TravelStyle.ink)
            Text("Go somewhere\nunforgettable.")
                .font(.largeTitle.bold())
            Text("Wild landscapes, living culture, and people who know the way.")
                .foregroundStyle(.secondary)
        }
    }
}

struct DestinationExploreCard: View {
    let destination: Destination
    @AppStorage("savedDestinationNames") private var savedNames = ""

    private var isSaved: Bool { savedNames.split(separator: "|").contains(Substring(destination.name)) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            NavigationLink {
                DestinationDetailsView(destination: destination)
            } label: {
                Image(destination.image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 220)
                    .clipped()
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
                    if isSaved { names.remove(destination.name) } else { names.insert(destination.name) }
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
    @AppStorage("savedDestinationNames") private var savedNames = ""
    private var saved: [Destination] {
        let names = Set(savedNames.split(separator: "|").map(String.init))
        return destinations.filter { names.contains($0.name) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if saved.isEmpty {
                    ContentUnavailableView("Keep a Little Inspiration", systemImage: "bookmark",
                                           description: Text("Save places from Explore and find them here. Saved places stay on this device."))
                        .padding(.top, 60)
                } else {
                    LazyVStack(spacing: 20) {
                        ForEach(saved) { DestinationExploreCard(destination: $0) }
                    }
                    .padding(20)
                }
            }
            .background(TravelStyle.sand)
            .navigationTitle("Saved Places")
        }
    }
}
