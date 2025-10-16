//
//  ContentView.swift
//  EcoTourismApp
//
//  Created by Sarah  on 16/10/2025.
//
import SwiftUI

struct ContentView: View {
@State private var animate = false
    var body: some View {
       NavigationView{
           NavigationStack {
               ZStack{
                   Color.brown.opacity(0.28)
                       .ignoresSafeArea()
                   VStack{
                       
                       // Background Image
                       Image("logo")
                           .resizable()
                           .scaledToFit()
                           .scaleEffect(animate ? 1 : 0.8)
                           .opacity(animate ? 1 : 0)
                           .animation(.easeOut(duration: 1.5), value: animate)
                           .ignoresSafeArea()
                           .offset(y: -30)
                       
                       //App Title
                           .navigationTitle("Shanya")
                       
                       //.navigationBarTitleDisplayMode(.inline)
                           .font(.largeTitle)
                           .foregroundColor(.brown)
                           .fontWeight(.bold)
                           .shadow(radius: 5)
                       
                       
                       //Welcome Message
                       Text("Cultural Connection & Wildlife Adventure, Where your journey begins.")
                           .font(.title2)
                           .foregroundColor(.brown)
                           .italic()
                           .multilineTextAlignment(.center)
                           .padding(.horizontal)
                       
                       // Get Started Button and Navigation Link
                       NavigationLink{
                           OnBoardingScreen()
                       } label: {
                               Text("Get Started")
                                   .font(.headline)
                                   .padding()
                                   .frame(maxWidth: .infinity)
                                   .background(Color.white.opacity(0.8))
                                   .foregroundColor(.black)
                                   .cornerRadius(12)
                                   .padding(.horizontal, 40)
                           }
                       }
                   }
               }
               .onAppear {
                   animate = true
               }
           }
        }
    }

#Preview {
    ContentView()
}







