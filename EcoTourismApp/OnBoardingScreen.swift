//
//  OnBoardingScreen.swift
//  EcoTourismApp
//
//  Created by Sarah  on 16/10/2025.
//

import SwiftUI

struct OnBoardingScreen: View {
    var body: some View {
//        NavigationView{
            NavigationStack{
                ZStack{
                    Color.background
                        .ignoresSafeArea()
                    VStack(spacing: 20){
                        // Background Image
                        Image("onBoarding")
                            .resizable()
                            .frame(width: 300, height: 300)
                            .padding(.top, 60)
                            .offset(y: -90)
                        Text("Choose your role to continue")
                            .font(.system(size: 30, weight: .thin))
                            .italic()
                            .offset(y: -70)
                            
                         
                        
                        VStack(spacing: 16) {
                            NavigationLink(destination: TouristSignIn()) {
                                Text("I am a tourist")
                                    .font(.headline)
                                    .foregroundColor(.brown)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(25)
                            }
                            .padding(.horizontal, 35)
                            
                            NavigationLink(destination: TourGuideSignIn()) {
                                Text("I am a tour guide")
                                    .font(.headline)
                                    .foregroundColor(.brown)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(35)
                            }
                            .padding(.horizontal, 25)
                             Spacer()
                           
                           
                          //  Welcome text
                            Text("Visit Zimbabwe🇿🇼")
                                .font(.system(size: 40, weight: .thin))
                                .italic()
                            
                             Text("Welcome to Shanya")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                                .padding(.bottom, 30)
                        }
                        
                        
                    }
                    
                }
                
               // .navigationBarBackButtonHidden(true)
            }
        }
    }
//}

#Preview {
    OnBoardingScreen()
}










//
//
//
//import SwiftUI
//
//struct OnBoardingScreen: View {
//    var body: some View {
//        NavigationStack {
//            ZStack {
//                Color.background
//                    .ignoresSafeArea()
//
//                VStack {
//                    Spacer().frame(height: 40)
//
//                    // Logo (centered in a circle)
//                    ZStack {
//                        Circle()
//                            .fill(Color.orange.opacity(0.9))
//                            .frame(width: 180, height: 180)
//                        Image("onBoarding")
//                            .resizable()
//                            .scaledToFit()
//                            .frame(width: 120, height: 120)
//                    }
//
//                    Text("Choose your role to continue")
//                        .font(.system(size: 20, weight: .thin))
//                        .italic()
//                        .multilineTextAlignment(.center)
//                        .padding(.top, 12)
//
//                    Spacer()
//
//                    // Buttons - no offsets
//                    VStack(spacing: 16) {
//                        NavigationLink(destination: TouristSignIn()) {
//                            Text("I am a tourist")
//                                .font(.headline)
//                                .foregroundColor(.brown)
//                                .frame(maxWidth: .infinity)
//                                .padding()
//                                .background(Color.gray.opacity(0.2))
//                                .cornerRadius(25)
//                        }
//
//                        NavigationLink(destination: TourGuideSignIn()) {
//                            Text("I am a tour guide")
//                                .font(.headline)
//                                .foregroundColor(.brown)
//                                .frame(maxWidth: .infinity)
//                                .padding()
//                                .background(Color.gray.opacity(0.2))
//                                .cornerRadius(25)
//                        }
//                    }
//                    .padding(.horizontal, 40)
//
//                    Spacer()
//
//                    Text("Visit Zimbabwe")
//                        .font(.system(size: 28, weight: .thin))
//                        .italic()
//                        .padding(.bottom, 6)
//
//                    Text("Welcome to Shanya")
//                        .font(.footnote)
//                        .foregroundColor(.secondary)
//                        .padding(.bottom, 24)
//                } // VStack
//            } // ZStack
//            .navigationBarHidden(true)
//        } // NavigationStack
//    }
//}
//
//// Example destination views — make sure these are different
//struct TouristSignIn: View {
//    var body: some View { Text("Tourist Sign In") }
//}
//
//struct TourGuideSignIn: View {
//    var body: some View { Text("Tour Guide Sign In") }
//}
//
//#Preview {
//    OnBoardingScreen()
//}
//

























