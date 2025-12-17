//
//  TouristSignIn.swift
//  EcoTourismApp
//
//  Created by Sarah  on 17/10/2025.
//

import SwiftUI

struct TouristSignUp: View {
    @State private var name = ""
    @State private var nationality = ""
    @State private var email = ""
    @State private var password: String = ""
    @State private var showPassword = false
    @State private var isSignedUp = false
    
    var body: some View {
        NavigationStack{
            ZStack{
                Color.background
                    .ignoresSafeArea()
                VStack(spacing: 25){
                    // MARK: - Tittle
                    Text("Create an Account")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.brown)
                        .padding(.top, 40)
                    
                    // MARK: - SignUp Fields
                    TextField("Full Name", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    TextField("Nationality", text: $nationality)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    TextField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    // MARK: - SignUp Button
                    Button(action: {
                        if !name.isEmpty && !nationality.isEmpty && !email.isEmpty && !password.isEmpty {
                            isSignedUp = true
                        }
                    }) {
                        Text("Sign Up")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.brown)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                     //MARK: -Already have an Account
                     HStack{
                         Text("Already have an Account")
                             .foregroundColor(.gray)
                         NavigationLink(destination:  TouristLogin()){
                             Text("Login")
                                 .fontWeight(.bold)
                                 .foregroundColor(.blue)
                }
                     }
                 }
                 .navigationDestination(isPresented: $isSignedUp) {
                     TouristLogin()
                         .navigationBarBackButtonHidden(true)
                 }
            }
           
        }
    }
}
#Preview {
    TouristSignUp()
}
