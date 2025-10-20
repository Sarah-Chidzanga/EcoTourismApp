//
//  Destination.swift
//  EcoTourismApp
//
//  Created by Sarah  on 20/10/2025.
//

import Foundation


struct Destination: Identifiable, Codable {
    var id = UUID()
    let name: String
    let image: String
    
}

struct Region: Identifiable {
    var id = UUID()
    let name: String
}


let destinations: [Destination] = [
    Destination(name: "Victoria Falls", image: "victoria"),
    Destination(name: "Matopo Hills", image: "matopo"),
    Destination(name: "Hwange National Park", image: "hwange"),
    Destination(name: "Chinhoyi Caves", image: "chinhoyi")
]

let regions: [Region] = [
    Region(name: "Matabeleland North"),
    Region(name: "Mashonaland"),
    Region(name: "Manicaland"),
    Region(name: "Midlands"),
    Region(name: "Masvingo"),
    Region(name: "Harare"),
    Region(name: "Bulawayo"),
    Region(name: "Matabaleland South")
]
