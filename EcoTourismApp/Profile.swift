//
//  Profile.swift
//  EcoTourismApp
//
//  Created by Sarah  on 20/10/2025.
//

import SwiftUI

struct Profile: View {
    var body: some View {
        NavigationStack {
            ZStack{
                Color.background
                    .ignoresSafeArea()
                Text("Profile Page coming 🔜!")
                    .foregroundColor(.brown)
                    .font(Font.largeTitle.bold())
            }
        }
    }
}

#Preview {
    Profile()
}
