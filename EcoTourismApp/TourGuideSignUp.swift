//
//  TourGuideSignUp.swift
//  EcoTourismApp
//
//  Created by Sarah  on 17/10/2025.
//


import SwiftUI

struct TourGuideSignUp: View {
    @State private var name = ""
    @State private var email = ""
    @State private var bio = ""
    @State private var languages = ""
    @State private var password = ""
    @State private var isSignedUp = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.background
                    .ignoresSafeArea()
                
                VStack(spacing: 25) {
                    // MARK:  Title
                    VStack(spacing: 8) {
                        Text("Tour Guide Registration")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.brown) 
                        
                        Text("Join our network of eco-experts🌿")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 80)
                    
                    // MARK: SignUp Fields
                    Group {
                        TextField("Full Name", text: $name)
                            .modifier(FormFieldStyle())

                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .modifier(FormFieldStyle())

                        TextField("Languages (e.g. English, Spanish)", text: $languages)
                            .modifier(FormFieldStyle())

                        TextField("Short Bio / Expertise", text: $bio)
                            .modifier(FormFieldStyle())

                        SecureField("Password", text: $password)
                            .modifier(FormFieldStyle())
                    }
                    .padding(.horizontal)
                    
                    // MARK:  SignUp Button
                    Button(action: {
                        if !name.isEmpty && !email.isEmpty && !password.isEmpty {
                            isSignedUp = true
                        }
                    }) {
                        Text("Create Guide Account")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.brown)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
             
                    // MARK:  Already have an account
                    HStack {
                        Text("Already have an account?")
                            .foregroundColor(.gray)
                        
                        NavigationLink(destination: TourGuideLogin()) {
                            Text("Login")
                                .fontWeight(.bold)
                                .foregroundColor(.brown)
                        }
                    }
                    .padding(.top, 15)
                    
                    Spacer()
                }
                .navigationDestination(isPresented: $isSignedUp) {
                    // Where they go after signing up
                    Text("Welcome, Guide! Dashboard coming soon.")
                }
            }
        }
    }
}

#Preview {
    TourGuideSignUp()
}

