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
    @State private var showPassword = false
    @State private var isLoggedIn = false
  
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
                             Thank you for choosing sustainable travel.🌱
                             To continue please login to your Account 
                             """)
                         .multilineTextAlignment(.leading)
                         .padding()
                         .italic()
                         .foregroundColor(.brown)
                    // MARK: Email Field and Password
                    VStack(spacing: 20){
                        TextField("Email Adress", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        
                        HStack{
                            if showPassword{
                                TextField("Password", text: $password)
                            } else {
                                SecureField("Password", text: $password)
                            }
                        }
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 10)
                    
                    VStack{
                        Button("Forgot Password?"){
                            print("Forgot Password tapped")
                        }
                        .font(.footnote)
                        .foregroundColor(.blue)
                        .padding(.trailing, 30)
                    }
                    .padding(.top, 10)
                    
                    Button(action: {
                        if !email.isEmpty && !password.isEmpty{
                            isLoggedIn = true
                        print("Logged In with email: \(email)")
                        }
                    }) {
                        Text("Log In")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(Color.white)
                            .font(.headline)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    
                }
                .navigationDestination(isPresented: $isLoggedIn) {
                    HomeScreen()
                        .navigationBarBackButtonHidden(true)
                }

            }
        }
    }
}

#Preview {
    TouristLogin()
}
