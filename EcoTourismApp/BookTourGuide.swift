//
//  BookTourGuide.swift
//  EcoTourismApp
//
//  Created by Sarah  on 30/10/2025.
//


import SwiftUI

struct BookTourGuide: View {
    let guide: TourGuide
    
    @Environment(\.dismiss) private var dismiss
    @State private var fullName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var tourDate = Date()
    @State private var numberOfPeople = 1
    @State private var specialRequests = ""
    @State private var showConfirmation = false
    
    var body: some View {
        NavigationStack {
            ZStack{
                Color.background
                    .ignoresSafeArea()
                Form {
                    Section(header: Text("Tour Guide")) {
                        HStack {
                            Image(guide.image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                            VStack(alignment: .leading) {
                                Text(guide.name)
                                    .font(.headline)
                                Text(guide.priceRange)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Section(header: Text("Your Details")) {
                        TextField("Full Name", text: $fullName)
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                        TextField("Phone Number", text: $phone)
                            .keyboardType(.phonePad)
                    }
                    
                    Section(header: Text("Booking Info")) {
                        DatePicker("Tour Date", selection: $tourDate, displayedComponents: .date)
                        Stepper("Number of People: \(numberOfPeople)", value: $numberOfPeople, in: 1...10)
                        TextField("Special Requests", text: $specialRequests, axis: .vertical)
                    }
                    
                    Button(action: {
                        showConfirmation = true
                    }) {
                        Text("Confirm Booking")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundColor(.white)
                            .background(Color.brown)
                            .cornerRadius(10)
                    }
                    .alert("Booking Confirmed!", isPresented: $showConfirmation) {
                        Button("OK", role: .cancel) {
                            dismiss()
                        }
                    } message: {
                        Text("Your booking with \(guide.name) has been received. You’ll get a confirmation email shortly.")
                    }
                }
                .navigationTitle("Book Guide")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Close") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    BookTourGuide(
        guide: TourGuide(
            name: "Pride Mafira",
            image: "pride",
            phone: "+263 71 900 9990",
            email: "mafira.chinhoyi@adventurezim.co.zw",
            qualifications: [
                "Adventure & Nature Guide (FGASA Level 1)",
                "Scuba Diving Certified",
                "Emergency First Responder"
            ],
            priceRange: "$70 - $140 per tour"
        )
    )
}



