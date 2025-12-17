//
//  Settings.swift
//  EcoTourismApp
//
//  Created by Sarah  on 20/10/2025.
//

import SwiftUI

struct Settings: View {
    var body: some View {
        NavigationStack {
            ZStack{
                Color.background
                    .ignoresSafeArea()
                Text("Settings Page coming 🔜!")
                    .foregroundColor(.brown)
                    .font(Font.largeTitle.bold())
            }
        }
    }
}

#Preview {
    Settings()
}
