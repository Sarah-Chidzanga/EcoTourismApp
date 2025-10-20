//
//  TabView.swift
//  EcoTourismApp
//
//  Created by Sarah  on 20/10/2025.
//

import SwiftUI

struct NavigateTabView: View {
    var body: some View {
        
        TabView {
            HomeScreen()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            Profile()
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
            Settings()
                .tabItem{
                    Label("Settings", systemImage: "gear")
                }
        }
        .accentColor(.brown)
    }
}

#Preview {
    NavigateTabView()
}
