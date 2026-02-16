//
//  HomeScreen.swift
//  EcoTourismApp
//
//  Created by Sarah on 16/10/2025.
//

import SwiftUI

struct HomeScreen: View {
    var userName: String = "Guest"
    @State private var searchText = ""
    @State private var selectedRegion: String? = nil
    
    // Animation States
    @State private var showWelcomeOverlay = true
    @State private var welcomeOpacity = 1.0
    @State private var welcomeOffset = 20.0
    
    // MARK: - TopDestination Grid
    let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 2)
    ]
    
    // MARK: - Region Filter Grid
    let chipColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        ZStack {
            
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // MARK: - Search Bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.brown)
                            TextField("Search destinations, wildlife or guides", text: $searchText)
                                .textFieldStyle(PlainTextFieldStyle())
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(25)
                        .padding(.horizontal)
                        .padding(.top, 20)
                        
                        // Top Destinations Header
                        Text("Top Destinations")
                            .font(.title3).bold()
                            .padding(.horizontal)
                        
                        // MARK: - Destination Grid
                        LazyVGrid(columns: columns, alignment: .center, spacing: 18) {
                            ForEach(destinations) { destination in
                                NavigationLink(destination: DestinationDetailsView(destination: destination)) {
                                    VStack(spacing: 8) {
                                        Image(destination.image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(height: 130)
                                            .frame(maxWidth: .infinity)
                                            .clipped()
                                            .cornerRadius(14)
                                        
                                        Text(destination.name)
                                            .foregroundColor(.black)
                                            .font(.subheadline)
                                            .bold()
                                            .multilineTextAlignment(.center)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // MARK: - Filter by Region Header
                        Text("Filter by Region")
                            .font(.title3).bold()
                            .padding(.horizontal)
                            .padding(.top, 6)
                        
                        // MARK: - Region Filter Chips
                        LazyVGrid(columns: chipColumns, spacing: 12) {
                            ForEach(regions) { region in
                                NavigationLink(destination: RegionDetailsView(region: region)) {
                                    Text(region.name)
                                        .font(.subheadline)
                                        .padding(.vertical, 8)
                                        .frame(maxWidth: .infinity)
                                        .background(selectedRegion == region.name ? Color.brown : Color.brown)
                                        .foregroundColor(selectedRegion == region.name ? .black : .white)
                                        .cornerRadius(16)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                }
                .ignoresSafeArea(edges: .bottom)
                .background(Color("background").ignoresSafeArea())
                .navigationBarTitleDisplayMode(.inline)
            }
            .tint(.white)
            .blur(radius: showWelcomeOverlay ? 6 : 0)
            
           
            if showWelcomeOverlay {
                ZStack {
                  
                    Color("background").ignoresSafeArea()
                    
                    VStack(spacing: 12) {
                        Text("Welcome,")
                            .font(.system(size: 22, weight: .light, design: .serif))
                            .foregroundColor(.secondary)
                        
                        Text(userName)
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundColor(.brown)
                    }
                    .opacity(welcomeOpacity)
                    .offset(y: welcomeOffset)
                }
                .onAppear {
         
                    withAnimation(.easeOut(duration: 0.8)) {
                        welcomeOffset = 0
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation(.easeIn(duration: 1.2)) {
                            welcomeOpacity = 0
                        }
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
                        showWelcomeOverlay = false
                    }
                }
            }
        }
    }
}

#Preview {
    HomeScreen(userName: "Sarah")
}
