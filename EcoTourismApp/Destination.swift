import Foundation
import Observation

struct Destination: Identifiable, Codable {
    let id: String
    let name: String
    let image: String
    let symbol: String
    let region: String
    let description: String
    let planning: String
    let sourceURL: String
    let guideSearch: String
    let aliases: [String]
    let ecoTip: String

    var mapURL: URL? {
        var components = URLComponents(string: "https://maps.apple.com/")
        components?.queryItems = [URLQueryItem(name: "q", value: "\(name), Zimbabwe")]
        return components?.url
    }

    var searchText: String { ([name, region, description] + aliases).joined(separator: " ") }
}

struct Region: Identifiable {
    let name: String
    var id: String { name }
}

struct TravelActivity: Identifiable, Codable {
    let id: String
    let destinationID: String
    let name: String
    let category: String
    let description: String
    let companyIDs: [String]
    let sourceURL: String
    let planning: String

    var symbol: String {
        switch category {
        case "Wildlife": return "pawprint"
        case "Water": return "water.waves"
        case "Adventure": return "bolt"
        case "Hiking": return "figure.hiking"
        case "Culture": return "building.columns"
        case "Scenic": return "binoculars"
        default: return "leaf"
        }
    }
}

struct TravelCompany: Identifiable, Codable {
    let id: String
    let name: String
    let kind: String
    let description: String
    let website: String
    let destinationIDs: [String]
}

struct TravelCatalog: Codable {
    let schemaVersion: Int
    let reviewedAt: String
    let destinations: [Destination]
    let activities: [TravelActivity]
    let companies: [TravelCompany]

    static let empty = TravelCatalog(schemaVersion: 1, reviewedAt: "", destinations: [], activities: [], companies: [])

    static let bundled: TravelCatalog = {
        guard let url = Bundle.main.url(forResource: "travel-catalog", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let catalog = try? JSONDecoder().decode(TravelCatalog.self, from: data),
              catalog.isValid else { return .empty }
        return catalog
    }()

    // Reject incompatible or broken remote data and retain the offline catalogue.
    var isValid: Bool {
        let destinationIDs = Set(destinations.map(\.id))
        let companyIDs = Set(companies.map(\.id))
        return schemaVersion == 1 && !destinations.isEmpty &&
            destinationIDs.count == destinations.count &&
            companyIDs.count == companies.count &&
            Set(activities.map(\.id)).count == activities.count &&
            destinations.allSatisfy { !$0.id.isEmpty && !$0.name.isEmpty && CatalogURL.website($0.sourceURL) != nil } &&
            companies.allSatisfy { !$0.id.isEmpty && CatalogURL.website($0.website) != nil && $0.destinationIDs.allSatisfy(destinationIDs.contains) } &&
            activities.allSatisfy { activity in
                !activity.id.isEmpty && destinationIDs.contains(activity.destinationID) &&
                CatalogURL.website(activity.sourceURL) != nil && !activity.companyIDs.isEmpty &&
                activity.companyIDs.allSatisfy { id in
                    companies.contains { $0.id == id && $0.destinationIDs.contains(activity.destinationID) }
                }
            }
    }
}

enum CatalogURL {
    static func website(_ address: String) -> URL? {
        guard let url = URL(string: address), url.scheme == "https",
              url.host != nil, url.user == nil, url.password == nil else { return nil }
        return url
    }
}

@MainActor
@Observable
final class TravelCatalogStore {
    private(set) var catalog = TravelCatalog.bundled
    private(set) var isRefreshing = false
    private(set) var statusMessage: String?
    private var didRefresh = false
    private let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        .first?.appendingPathComponent("shanya-travel-catalog-v1.json")

    init() {
        if let cacheURL, let data = try? Data(contentsOf: cacheURL),
           let saved = try? JSONDecoder().decode(TravelCatalog.self, from: data),
           saved.isValid, saved.reviewedAt >= catalog.reviewedAt {
            catalog = saved
        }
    }

    var destinations: [Destination] { catalog.destinations }
    var regions: [Region] { Set(destinations.map(\.region)).sorted().map { Region(name: $0) } }

    func activities(for destinationID: String) -> [TravelActivity] {
        catalog.activities.filter { $0.destinationID == destinationID }
    }

    func companies(for destinationID: String) -> [TravelCompany] {
        catalog.companies.filter { $0.destinationIDs.contains(destinationID) }
    }

    func refresh(force: Bool = false) async {
        guard !isRefreshing, force || !didRefresh else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            let updated: TravelCatalog = try await AuthAPI().request("catalog")
            guard updated.isValid else { throw AuthError.invalidResponse }
            catalog = updated
            if let cacheURL, let data = try? JSONEncoder().encode(updated) {
                try? data.write(to: cacheURL, options: .atomic)
            }
            statusMessage = nil
            didRefresh = true
        } catch {
            statusMessage = catalog.destinations.isEmpty
                ? "Couldn't load the travel directory. Pull down to try again."
                : "Showing offline travel information. Pull down to check for updates."
        }
    }
}

// Legacy region screens use the same reviewed offline catalogue.
let destinations = TravelCatalog.bundled.destinations
let regions = Set(destinations.map(\.region)).sorted().map { Region(name: $0) }
