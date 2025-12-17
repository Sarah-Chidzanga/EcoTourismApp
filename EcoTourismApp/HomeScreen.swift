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
        NavigationStack{
            ScrollView{
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
                            ForEach(destinations) { destination in
                                NavigationLink(destination: DestinationDetailsView(destination: destination)){
                                VStack(spacing: 8) {
                                 
                                    Image(destination.image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 130)
                                        .frame(maxWidth:   .infinity)
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
                    //  MARK: - Filter by Region
                                        Text("Filter by Region")
                                            .font(.title3).bold()
                                            .padding(.horizontal)
                                            .padding(.top, 6)
                            
                    //  MARK: - Filter by Region
                    LazyVGrid(columns: chipColumns, spacing: 12) {
                        ForEach(regions) { region in
                            NavigationLink(destination: RegionDetailsView(region: region)){
                                Text(region.name)
                                    .font(.subheadline)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity)
                                    .background(selectedRegion == region.name ? Color.brown : Color(.brown))
                                    .foregroundColor(selectedRegion == region.name ? .black : .white)
                                    .cornerRadius(16)
                            }
                        }
                    }
                    .padding(.horizontal)

                }
               
                .padding(.top, 10)
                .padding(.bottom, 0)
            }
            .ignoresSafeArea(edges: .bottom)
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
