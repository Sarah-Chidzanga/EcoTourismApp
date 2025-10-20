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
                            NavigationLink(destination: TouristSignUp()) {
                                Text("I am a tourist")
                                    .font(.headline)
                                    .foregroundColor(.brown)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(25)
                            }
                            .padding(.horizontal, 35)
                            
                            NavigationLink(destination: TourGuideSignUp()) {
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



