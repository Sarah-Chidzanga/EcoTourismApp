//
//  HomeScreen.swift
//  EcoTourismApp
//
//  Created by Sarah  on 16/10/2025.
//

import SwiftUI
struct HomeScreen: View {
    @State private var searchText = ""
    @State private var selectedRegion: String? = nil
   
    
    // MARK: - Grid layout
    let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        NavigationStack{
            ScrollView{
               // ZStack{
                   // Color.background
                       // .background(Color.background)
                      //  .ignoresSafeArea()
                        // .frame(maxWidth: .infinity, maxHeight: .infinity)
                    VStack(alignment: .leading, spacing: 20){
                        //  MARK: - Search Bar
                        HStack{
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.brown)
                            TextField("Search destinations, wildlife or guides", text: $searchText)
                                .textFieldStyle(PlainTextFieldStyle())
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(25)
                        // Top Destinations
                        Text("Top Destinations")
                            .font(.title3).bold()
                            .padding(.horizontal)
                        
                        //  MARK: - Destination Grid
                        LazyVGrid(columns: columns, alignment: .center, spacing: 18) {
                            ForEach(Array(destinations.enumerated()), id: \.element.id) { index, dest in
                                VStack(spacing: 8) {
                                    Button(action: {
                                        print("Tapped \(dest.name)")
                                    }) {
                                        Image(dest.image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(height: 130)
                                            .frame(maxWidth:   .infinity)
                                           .clipped()
                                           .cornerRadius(14)
                                    }
                                    Text(dest.name)
                                        .foregroundColor(.black)
                                        .font(.subheadline)
                                        .bold()
                                        .multilineTextAlignment(.center)
                                }
                            }
                        }
                        .padding(.horizontal)
                        //  MARK: - Filter by Region
                        Text("Filter by Region")
                            .font(.title3).bold()
                            .padding(.horizontal)
                            .padding(.top, 6)
                        
                        //  MARK: - Region Filter
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(regions) { region in
                                    Button(action: {
                                        print("Filter by \(region.name)")
                                    }) {
                                        Text(region.name)
                                            .font(.subheadline)
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 14)
                                            .background(Color(.brown))
                                            .cornerRadius(16)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                        }
                    }
                    .padding(.vertical)
                }
                .background(Color("background").ignoresSafeArea())
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tint(.white)
            
           
            
            
        }
    }
//}


#Preview {
    HomeScreen()
}
