import SwiftUI

struct TravelDirectory: View {
    @Environment(TravelCatalogStore.self) private var store
    @State private var query = ""
    @State private var category = "All"
    @State private var section: String

    init(section: String = "Activities") {
        _section = State(initialValue: section)
    }

    private var activities: [TravelActivity] {
        store.catalog.activities.filter { activity in
            let place = store.destinations.first { $0.id == activity.destinationID }
            let companies = store.catalog.companies.filter { activity.companyIDs.contains($0.id) }.map(\.name).joined(separator: " ")
            let text = "\(activity.name) \(activity.category) \(place?.searchText ?? "") \(companies)"
            return (category == "All" || activity.category == category) &&
                (query.isEmpty || text.localizedCaseInsensitiveContains(query))
        }
    }

    private var companies: [TravelCompany] {
        store.catalog.companies.filter { company in
            let places = store.destinations.filter { company.destinationIDs.contains($0.id) }.map(\.searchText).joined(separator: " ")
            return query.isEmpty || "\(company.name) \(company.kind) \(places)".localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Find your kind of adventure.").font(.largeTitle.bold())
                Text("Explore activities and the companies or visitor teams that can help arrange them.")
                    .foregroundStyle(.secondary)
                Picker("Directory", selection: $section) {
                    Text("Activities").tag("Activities")
                    Text("Companies").tag("Companies")
                }
                .pickerStyle(.segmented)
                if section == "Activities" {
                    Picker("Activity type", selection: $category) {
                        ForEach(["All"] + Set(store.catalog.activities.map(\.category)).sorted(), id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.menu)
                    Text(activities.count == 1 ? "1 activity" : "\(activities.count) activities").font(.subheadline).foregroundStyle(.secondary)
                    if activities.isEmpty { ContentUnavailableView.search(text: query) }
                    LazyVStack(spacing: 14) {
                        ForEach(activities) { ActivityDirectoryRow(activity: $0) }
                    }
                } else {
                    Text(companies.count == 1 ? "1 company or visitor team" : "\(companies.count) companies & visitor teams").font(.subheadline).foregroundStyle(.secondary)
                    if companies.isEmpty { ContentUnavailableView.search(text: query) }
                    LazyVStack(spacing: 14) {
                        ForEach(companies) { CompanyDirectoryRow(company: $0) }
                    }
                }
                CatalogFootnote(reviewedAt: store.catalog.reviewedAt, status: store.statusMessage)
            }
            .padding(20)
        }
        .background(TravelStyle.sand)
        .navigationTitle("Things to Do")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $query, prompt: "Activity, company or destination")
        .refreshable { await store.refresh(force: true) }
        .task { await store.refresh() }
        .tint(TravelStyle.ink)
    }
}

struct ActivityDirectoryRow: View {
    let activity: TravelActivity
    @Environment(TravelCatalogStore.self) private var store

    var body: some View {
        NavigationLink {
            ActivityDetailView(activity: activity)
        } label: {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: activity.symbol).font(.title2).foregroundStyle(TravelStyle.ink)
                    .frame(width: 32)
                VStack(alignment: .leading, spacing: 7) {
                    Text(activity.name).font(.headline).foregroundStyle(.primary)
                    Text(store.destinations.first { $0.id == activity.destinationID }?.name ?? "")
                        .font(.subheadline).foregroundStyle(.secondary)
                    Text(activity.category).font(.caption).foregroundStyle(TravelStyle.ink)
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

struct CompanyDirectoryRow: View {
    let company: TravelCompany

    var body: some View {
        NavigationLink {
            CompanyDetailView(company: company)
        } label: {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "building.2").font(.title2).foregroundStyle(TravelStyle.ink)
                VStack(alignment: .leading, spacing: 7) {
                    Text(company.name).font(.headline).foregroundStyle(.primary)
                    Text(company.kind).font(.caption).foregroundStyle(TravelStyle.ink)
                    Text(company.description).font(.subheadline).foregroundStyle(.secondary).lineLimit(3)
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

struct ActivityDetailView: View {
    let activity: TravelActivity
    @Environment(TravelCatalogStore.self) private var store

    private var providers: [TravelCompany] {
        store.catalog.companies.filter { activity.companyIDs.contains($0.id) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Label(activity.category, systemImage: activity.symbol).foregroundStyle(TravelStyle.ink)
                Text(activity.name).font(.largeTitle.bold())
                Text(activity.description)
                if let place = store.destinations.first(where: { $0.id == activity.destinationID }) {
                    NavigationLink { DestinationDetailsView(destination: place) } label: {
                        Label(place.name, systemImage: "mappin.and.ellipse")
                    }
                }
                TravelInfoSection(title: "Plan This Experience", text: activity.planning)
                TravelInfoSection(title: "Prices & Availability", text: "Check with the provider for a current quote and available dates. This listing does not reserve a place or collect payment.")
                Text("Who to Contact").font(.title2.bold())
                ForEach(providers) { CompanyDirectoryRow(company: $0) }
                ExternalTravelLink(title: "Read the Activity Source", address: activity.sourceURL)
                CatalogFootnote(reviewedAt: store.catalog.reviewedAt, status: nil)
            }
            .padding(20)
        }
        .background(TravelStyle.sand)
        .navigationTitle("Activity")
        .navigationBarTitleDisplayMode(.inline)
        .tint(TravelStyle.ink)
    }
}

struct CompanyDetailView: View {
    let company: TravelCompany
    @Environment(TravelCatalogStore.self) private var store

    private var activities: [TravelActivity] {
        store.catalog.activities.filter { $0.companyIDs.contains(company.id) }
    }
    private var places: [Destination] {
        store.destinations.filter { company.destinationIDs.contains($0.id) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Label(company.kind, systemImage: "building.2").foregroundStyle(TravelStyle.ink)
                Text(company.name).font(.largeTitle.bold())
                Text(company.description)
                ExternalTravelLink(title: "Visit Website & Enquire", address: company.website)
                    .buttonStyle(TravelPrimaryButton())
                Text("Opens the provider’s website. Confirm arrangements, prices and cancellation terms with them directly. A directory listing does not mean a partnership with Shanya.")
                    .font(.footnote).foregroundStyle(.secondary)
                Text("Places Covered").font(.title2.bold())
                ForEach(places) { place in
                    NavigationLink { DestinationDetailsView(destination: place) } label: {
                        Label(place.name, systemImage: "mappin.and.ellipse")
                    }
                }
                Text("Listed Experiences").font(.title2.bold())
                ForEach(activities) { ActivityDirectoryRow(activity: $0) }
                CatalogFootnote(reviewedAt: store.catalog.reviewedAt, status: nil)
            }
            .padding(20)
        }
        .background(TravelStyle.sand)
        .navigationTitle("Company & Visitor Team")
        .navigationBarTitleDisplayMode(.inline)
        .tint(TravelStyle.ink)
    }
}

struct ExternalTravelLink: View {
    let title: String
    let address: String
    @Environment(\.openURL) private var openURL
    @State private var showingError = false

    var body: some View {
        Button {
            guard let url = CatalogURL.website(address) else { showingError = true; return }
            openURL(url) { accepted in showingError = !accepted }
        } label: {
            Label(title, systemImage: "arrow.up.right.square")
        }
        .alert("Couldn't Open Link", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Try again when you have a connection. Website: \(address)")
        }
    }
}

struct TravelInfoSection: View {
    let title: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.title2.bold())
            Text(text).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct CatalogFootnote: View {
    let reviewedAt: String
    let status: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let status { Text(status) }
            Text("A growing directory, not every provider in Zimbabwe. Source review: \(reviewedAt). Check current arrangements with each provider.")
        }
        .font(.footnote).foregroundStyle(.secondary)
    }
}

struct DestinationArtwork: View {
    let image: String
    let symbol: String
    let height: CGFloat

    var body: some View {
        ZStack {
            LinearGradient(colors: [TravelStyle.forest, .black.opacity(0.85)], startPoint: .topLeading, endPoint: .bottomTrailing)
            if !image.isEmpty, UIImage(named: image) != nil {
                Image(image).resizable().scaledToFill()
            } else {
                Image(systemName: symbol).font(.system(size: 60, weight: .light)).foregroundStyle(.white.opacity(0.9))
            }
        }
        .frame(height: height)
        .clipped()
        .accessibilityHidden(true)
    }
}
