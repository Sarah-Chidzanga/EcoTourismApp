//
//  UserModels.swift
//  EcoTourismApp
//
//  Created by Sarah on 3/2/2026.
//

import Foundation


struct RegisterResponse: Codable {
    let id: Int?
    let message: String?
    let error: String?
}







import SwiftUI

//MARK: Reusable ViewModifier

struct FormFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color.white)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.4), lineWidth: 1)
            )
    }
}
