//
//  TouristSignUp.swift
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
    @State private var goToLogin = false
    
    
    func signUpUser() {
        print("🚀 ATTEMPTING SIGN UP: \(name), \(email)")
        
        guard let url = URL(string: "http://localhost:3000/register") else {
            print("❌ URL error")
            return
        }

        let body: [String: Any] = [
            "name": name,
            "email": email,
            "password": password,
            "role": "tourist",
            "nationality": nationality
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ NETWORK ERROR: \(error.localizedDescription)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 SERVER STATUS CODE: \(httpResponse.statusCode)") 
                DispatchQueue.main.async {
                    if httpResponse.statusCode == 201 {
                        print("✅ SUCCESS: User created in Database!")
                        self.isSignedUp = true
                    } else {
                        print("❌ REJECTED: Server returned code \(httpResponse.statusCode)")
                    }
                }
            }
        }.resume()
    }
    
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
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    // MARK:  SignUp Button
                    Button(action: {
                        signUpUser()
                    }) {
                        Text("Sign Up")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.brown)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                     //MARK: -Already have an Account
                    HStack {
                        Text("Already have an Account")
                            .foregroundColor(.gray)
                        Button(action: {
                            goToLogin = true
                        }) {
                            Text("Login")
                                .fontWeight(.bold)
                                .foregroundColor(.brown)
                        }
                    }
                 }
                .navigationDestination(isPresented: $isSignedUp) {
                    HomeScreen(userName: name) 
                        .navigationBarBackButtonHidden(true)
                }
            }
           
        }
    }
}
#Preview {
    TouristSignUp()
}
