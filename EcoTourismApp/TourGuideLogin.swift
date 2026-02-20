//
//  TourGuideLogin.swift
//  EcoTourismApp
//
//  Created by Sarah on 29/1/2026.
//

import SwiftUI

struct TourGuideLogin: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoggedIn = false
    
    var body: some View {
        NavigationStack {
            ZStack {
            
                Color.background
                    .ignoresSafeArea()
                
                VStack(spacing: 25) {
                    
                    // MARK: - Header
                    VStack(spacing: 15) {
                        Image(systemName: "mountain.2.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.brown)
                        
                        Text("Guide Login")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.brown)
                        
                        Text("Welcome back, lead the way!")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 50)
                    
                    // MARK: - Login Fields
                    VStack(spacing: 15) {
                        TextField("Email Address", text: $email)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            .modifier(FormFieldStyle())

                        SecureField("Password", text: $password)
                            .modifier(FormFieldStyle())
                    }
                    .padding(.horizontal)
                    
                    // MARK: - Forgot Password
                    HStack {
                        Spacer()
                        Button("Forgot Password?") {
                            // Action to be worked on
                        }
                        .font(.footnote)
                        .foregroundColor(.brown)
                    }
                    .padding(.horizontal)
                    
                    // MARK: - Login Button
                    Button(action: {
                        // Logic to check credentials will go here
                        if !email.isEmpty && !password.isEmpty {
                            isLoggedIn = true
                        }
                    }) {
                        Text("Login")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.brown)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    // MARK: - Switch to Sign Up
                    HStack {
                        Text("New to the platform?")
                            .foregroundColor(.gray)
                        NavigationLink(destination: TourGuideSignUp()) {
                            Text("Join as a Guide")
                                .fontWeight(.bold)
                                .foregroundColor(.brown)
                        }
                    }
                    
                    Spacer()
                }
                .navigationDestination(isPresented: $isLoggedIn) {
                    // Tour Guide Dashboard
                    Text("Guide Dashboard Screen")
                }
            }
        }
    }
}

#Preview {
    TourGuideLogin()
}
