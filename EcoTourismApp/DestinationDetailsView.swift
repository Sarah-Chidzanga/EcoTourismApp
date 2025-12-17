//
//  DestinationDetailsView.swift
//  EcoTourismApp
//
//  Created by Sarah  on 22/10/2025.
///

import SwiftUI

struct DestinationDetailsView: View {
    @State private var showingBookingSheet = false
    @State private var selectedGuide: TourGuide? = nil
    let destination: Destination
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                
                // MARK: - Top Image
                ZStack(alignment: .bottomLeading) {
                    Image(destination.image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 250)
                        .clipped()
                    
                    LinearGradient(
                        gradient: Gradient(colors: [Color.black.opacity(0.6), Color.clear]),
                        startPoint: .bottom,
                        endPoint: .top
                    )
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(destination.name)
                            .font(.largeTitle)
                            .bold()
                            .foregroundColor(.white)
                        Text(destination.region)
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding()
                }
                
                // MARK: - Overview Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("About This Place")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text(destination.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    if !destination.tourGuide.isEmpty {
                        Text("Local Guide: \(destination.tourGuide)")
                            .font(.subheadline)
                            .foregroundColor(.brown)
                    }
                }
                .padding(.horizontal)
                
                Divider()
                
                // MARK: - Activities
                if let activities = destination.activities, !activities.isEmpty {
                    SectionHeader(title: "Things To Do")
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            ForEach(activities) { activity in
                                VStack(alignment: .leading) {
                                    Image(activity.image)  
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 160, height: 110)
                                        .cornerRadius(12)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(activity.name)
                                            .font(.subheadline)
                                            .bold()
                                        Text(activity.price)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .frame(width: 160)
                                .background(Color.white)
                                .cornerRadius(14)
                                .shadow(radius: 3)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                Divider()
                // MARK: - Tour Guides
                VStack(alignment: .leading, spacing: 12) {
                    Text("Tour Guides")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding(.horizontal)

                    ForEach(destination.tourGuides) { guide in
                        VStack(spacing: 8) {
                            HStack(spacing: 16) {
                                Image(guide.image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(Circle())
                                    .shadow(radius: 3)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(guide.name)
                                        .font(.headline)
                                    Text(guide.priceRange)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text("📞 \(guide.phone)")
                                        .font(.caption)
                                    Text("✉️ \(guide.email)")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                    VStack(alignment: .leading, spacing: 2) {
                                        ForEach(guide.qualifications, id: \.self) { qual in
                                            Text("• \(qual)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                Spacer()
                            }
                            .padding(.horizontal)

                            // Book button
                            Button(action: {
                                selectedGuide = guide
                                showingBookingSheet = true
                            }) {
                                Text("Book Guide")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(Color.brown)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                        }
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(radius: 2)
                        .padding(.horizontal)
                    }
                }
                .padding(.top, 10)
                Divider()
                // MARK: - Hotels
                if let hotels = destination.hotels, !hotels.isEmpty {
                    SectionHeader(title: "Hotels & Lodges")
                    
                    VStack(spacing: 12) {
                        ForEach(hotels) { hotel in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(hotel.name)
                                    .font(.headline)
                                Text("Price Range: \(hotel.priceRange)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                if let website = hotel.website, let url = URL(string: website) {
                                    Link("Visit Website", destination: url)
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.background)
                            .cornerRadius(14)
                            .shadow(radius: 2)
                        }
                    }
                    .padding(.horizontal)
                }
                
                Divider()
                
                // MARK: - Tour Companies
                if let companies = destination.tourCompanies, !companies.isEmpty {
                    SectionHeader(title: "Tour Operators")
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            ForEach(companies) { company in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(company.name)
                                        .font(.headline)
                                    if let url = URL(string: company.website) {
                                        Link("View Packages", destination: url)
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding()
                                .frame(width: 180, alignment: .leading)
                                .background(Color.white)
                                .cornerRadius(14)
                                .shadow(radius: 3)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                Divider()
                
                // MARK: - Wildlife Section
                if let wildlife = destination.wildlifeInfo, !wildlife.isEmpty {
                    SectionHeader(title: "Wildlife")
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            ForEach(wildlife) { animal in
                                VStack(alignment: .leading, spacing: 6) {
                                    Image(animal.image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 160, height: 110)
                                        .cornerRadius(12)
                                    VStack(alignment: .leading, spacing: 4) {
                                    Text(animal.name)
                                        .font(.subheadline)
                                        .bold()
                                    Text(animal.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    }
                                }
                                .frame(width: 160)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                Divider()
                
                   
                
                
                // MARK: - Plants Section
                if let plants = destination.plantInfo, !plants.isEmpty {
                    SectionHeader(title: "Plant Life")
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(plants) { plant in
                                VStack(alignment: .leading, spacing: 6) {
                                    Image(plant.image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 140, height: 100)
                                        .cornerRadius(10)
                                    Text(plant.name)
                                        .font(.subheadline)
                                        .bold()
                                    Text(plant.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .frame(width: 140)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                Divider()
                
                // MARK: - Eco Tip
                if let ecoTip = destination.ecoTip {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Eco Tip 🌿")
                            .font(.headline)
                        Text(ecoTip)
                            .italic()
                            .foregroundColor(.brown)
                    }
                    .padding(.horizontal)
                }
                
                // MARK: - Book Button
                Button(action: {
                   
                }) {
                    Text("Book Your Experience")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.brown)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                }
                .padding(.bottom, 40)
            }
        }
        .background(Color("background").ignoresSafeArea())
        .navigationTitle(destination.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingBookingSheet) {
            if let guide = selectedGuide {
                BookTourGuide(guide: guide)
                    .presentationDetents([.medium, .large])
            }
        }
    }
}

// MARK:  Section Header
struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.title3)
            .fontWeight(.semibold)
            .padding(.horizontal)
    }
}
