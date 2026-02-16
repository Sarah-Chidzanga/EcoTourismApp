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
    
    func loginUser() {
        guard let url = URL(string: "http://localhost:3000/login") else { return }

        let body: [String: Any] = [
            "email": email,
            "password": password
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let data = data {
                    
                    if let str = String(data: data, encoding: .utf8) {
                        print("📡 SERVER RESPONSE: \(str)")
                    }
                    
                  
                    if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                        print("✅ Credentials verified! Logging in...")
                        self.isLoggedIn = true
                    } else {
                        print("❌ Login failed. Check your email/password.")
                    }
                } else if let error = error {
                    print("❌ Network Error: \(error.localizedDescription)")
                }
            }
        }.resume()
    }
  
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
                        .foregroundColor(.brown)
                        .padding(.trailing, 30)
                    }
                    .padding(.top, 10)
                    
                    Button(action: {
                        print("🚀 Attempting Login...")  
                        loginUser()
                    }) {
                        Text("Log In")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.brown)
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
