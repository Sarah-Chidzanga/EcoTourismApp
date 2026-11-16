import SwiftUI

struct TravelPhoto: Codable {
    let author: String
    let license: String
    let licenseURL: String
    let sourceURL: String
    let caption: String
}

struct PhotoCredit: View {
    let photo: TravelPhoto

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(photo.caption).foregroundStyle(.secondary)
            if let source = CatalogURL.website(photo.sourceURL) {
                Link("Photo: \(photo.author)", destination: source)
            }
            if let license = CatalogURL.website(photo.licenseURL) {
                Link("\(photo.license) · cropped to fit", destination: license)
            }
        }
        .font(.caption)
    }
}

enum PlaceMaps {
    static func directions(query: String, walking: Bool = false, google: Bool = true) -> URL? {
        var components = URLComponents(string: google ? "https://www.google.com/maps/dir/" : "https://maps.apple.com/directions")
        // Omitting the origin lets Maps use the person's location, or ask for it.
        components?.queryItems = google ? [
            URLQueryItem(name: "api", value: "1"),
            URLQueryItem(name: "destination", value: query),
            URLQueryItem(name: "travelmode", value: walking ? "walking" : "driving")
        ] : [
            URLQueryItem(name: "destination", value: query),
            URLQueryItem(name: "mode", value: walking ? "walking" : "driving")
        ]
        return components?.url
    }

    static func preview(query: String) -> URL? {
        var components = URLComponents(string: "https://www.google.com/maps/search/")
        components?.queryItems = [
            URLQueryItem(name: "api", value: "1"),
            URLQueryItem(name: "query", value: query)
        ]
        return components?.url
    }
}

struct PlaceDirections: View {
    let query: String
    var isArea = false
    @Environment(\.openURL) private var openURL
    @State private var couldNotOpen = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Getting There", systemImage: "location.fill").font(.title2.bold())
            Text(query).font(.subheadline).foregroundStyle(.secondary)
            Menu {
                Button("Drive · Google Maps") { launch(PlaceMaps.directions(query: query)) }
                Button("Walk · Google Maps") { launch(PlaceMaps.directions(query: query, walking: true)) }
                Button("Drive · Apple Maps") { launch(PlaceMaps.directions(query: query, google: false)) }
                Button("Walk · Apple Maps") { launch(PlaceMaps.directions(query: query, walking: true, google: false)) }
            } label: {
                Label("Get Directions", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(TravelPrimaryButton())
            Button { launch(PlaceMaps.preview(query: query)) } label: {
                Label("View on Map", systemImage: "map")
            }
            Text("Maps uses your current location with your permission. You can also enter a starting point.")
                .font(.footnote).foregroundStyle(.secondary)
            if isArea {
                Text("This is a destination area. Confirm the entrance or meeting point with your guide before travelling.")
                    .font(.footnote).foregroundStyle(.secondary)
            } else {
                Text("Check the place shown in Maps before setting off. Routes depend on local map coverage.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .background(TravelStyle.card, in: RoundedRectangle(cornerRadius: 20))
        .alert("Couldn't Open Maps", isPresented: $couldNotOpen) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please try again or search for \(query) in your map app.")
        }
    }

    private func launch(_ url: URL?) {
        guard let url else { couldNotOpen = true; return }
        openURL(url) { accepted in
            if !accepted { couldNotOpen = true }
        }
    }
}
