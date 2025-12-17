//
//  RegionDetailsView.swift
//  EcoTourismApp
//
//  Created by Sarah  on 21/10/2025.
//
import SwiftUI

struct RegionDetailsView: View {
    let region: Region
    
    // Filtered destinations for  regions
    var filteredDestinations: [Destination] {
        destinations.filter { $0.region == region.name }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                
                // MARK:  Region Header
                ZStack(alignment: .bottomLeading) {
                    // Background map or region image
                    Image(region.name == "Matabeleland North" ? "northMap" :
                          region.name == "Matabeleland South" ? "southMap" :
                          "africaMap")
                        .resizable()
                        .scaledToFill()
                        .frame(height: 220)
                        .clipped()

                    
                    // Gradient overlay
                    LinearGradient(
                        gradient: Gradient(colors: [Color.black.opacity(0.5), Color.clear]),
                        startPoint: .bottom,
                        endPoint: .top
                    )
                    
                    // Region name title
                    VStack(alignment: .leading, spacing: 8) {
                        Text(region.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .shadow(radius: 5)
                        Text("Explore top destinations and attractions")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding()
                }
                
                // MARK: Destinations Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Destinations in \(region.name)")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(filteredDestinations) { dest in
                                NavigationLink(destination: DestinationDetailsView(destination: dest)) {
                                    DestinationCardView(destination: dest)
                                    
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                //  Eco Tip
                if region.name == "Matabeleland North" {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Travel Tip 🌿")
                            .font(.headline)
                            .padding(.horizontal)
                        Text("Respect wildlife and carry reusable water bottles. Stay on designated paths to protect the ecosystem.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                }
            }
            .padding(.bottom, 30)
        }
        .background(Color("background").ignoresSafeArea())
        .navigationTitle(region.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Destination Card View
struct DestinationCardView: View {
    let destination: Destination

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(destination.image)
                .resizable()
                .scaledToFill()
                .frame(width: 200, height: 140)
                .cornerRadius(16)
                .clipped()
            
            VStack(alignment: .leading, spacing: 4) {
                Text(destination.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(destination.description)
                    .lineLimit(2)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 6)
        }
        .frame(width: 200)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 4)
    }
}

#Preview {
    RegionDetailsView(region: Region(name: "Matabeleland North"))
}
