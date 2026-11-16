import SwiftUI

struct ListingVisual {
    let image: String
    let label: String
    let photo: TravelPhoto?
}

struct ListingPhotoThumbnail: View {
    let visual: ListingVisual
    let symbol: String

    var body: some View {
        DestinationArtwork(image: visual.image, symbol: symbol, height: 84)
            .frame(width: 84)
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct ListingPhotoHeader: View {
    let visual: ListingVisual
    let symbol: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            DestinationArtwork(image: visual.image, symbol: symbol, height: 230)
                .clipShape(RoundedRectangle(cornerRadius: 22))
            Text(visual.label).font(.caption).foregroundStyle(.secondary)
            if let photo = visual.photo { PhotoCredit(photo: photo) }
        }
    }
}
