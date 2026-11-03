import SwiftUI

struct DestinationDetailsView: View {
    let destination: Destination

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Image(destination.image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 290)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 26))
                VStack(alignment: .leading, spacing: 10) {
                    Label(destination.region, systemImage: "mappin.and.ellipse")
                        .font(.subheadline)
                        .foregroundStyle(TravelStyle.ink)
                    Text(destination.name).font(.largeTitle.bold())
                    Text(destination.description).foregroundStyle(.secondary)
                }
                NavigationLink {
                    GuideDirectory(initialSearch: destination.name)
                } label: {
                    Label("Find a Local Guide", systemImage: "person.crop.circle.badge.checkmark")
                }
                .buttonStyle(TravelPrimaryButton())
                if let activities = destination.activities, !activities.isEmpty {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Make a Day of It").font(.title2.bold())
                        ForEach(activities) { activity in
                            Label(activity.name, systemImage: "sun.max")
                                .padding(.vertical, 4)
                        }
                    }
                }
                if let wildlife = destination.wildlifeInfo, !wildlife.isEmpty {
                    Text("Wild Encounters").font(.title2.bold())
                    ForEach(wildlife) { animal in
                        HStack(alignment: .top, spacing: 16) {
                            Image(animal.image)
                                .resizable().scaledToFill()
                                .frame(width: 90, height: 90)
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                            VStack(alignment: .leading, spacing: 6) {
                                Text(animal.name).font(.headline)
                                Text(animal.description).font(.subheadline).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                if let ecoTip = destination.ecoTip {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Leave a Lighter Footprint", systemImage: "leaf")
                            .font(.headline)
                        Text(ecoTip).font(.subheadline)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(TravelStyle.forest.opacity(0.10), in: RoundedRectangle(cornerRadius: 22))
                }
                Text("Use this as inspiration. Confirm current access, opening hours, and activity arrangements with your guide or the destination before travelling.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(20)
        }
        .background(TravelStyle.sand)
        .navigationTitle(destination.name)
        .navigationBarTitleDisplayMode(.inline)
        .tint(TravelStyle.ink)
    }
}
