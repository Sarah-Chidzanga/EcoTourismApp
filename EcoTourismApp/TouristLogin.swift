//
//  TouristLogin.swift
//  EcoTourismApp
//
//  Created by Sarah  on 20/10/2025.
//

import SwiftUI

struct TouristLogin: View {
    @State private var email = ""
    @State private var password: String = ""
  
    var body: some View {
        NavigationStack{
            ZStack{
                Color.background
                    .ignoresSafeArea()
                VStack{
                    Text("Welcome Back🐒!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.brown)
                        .padding(.top, 40)
                         Text("""
                             Your next eco-adventure awaits, from the majestic Victoria Falls to the serene Eastern Highlands.
                             Let’s travel lightly, leave only footprints, and make lasting memories in Zimbabwe’s wild heart.🌱 
                             """)
                         .multilineTextAlignment(.leading)
                         .padding()
                         .italic()
                         .foregroundColor(.brown)
                    
                }
            }
        }
    }
}

#Preview {
    TouristLogin()
}
