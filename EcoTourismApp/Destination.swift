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
    let description: String
    let region: String
    let tourGuides: [TourGuide]
    let hotels: [Hotel]?
    let activities: [Activity]?
    let tourCompanies: [TourCompany]?
    let restaurants: [Restaurant]?
    let wildlifeInfo: [Wildlife]?
    let plantInfo: [Plant]?
    let ecoTip: String?
    
    var tourGuide: String {
        tourGuides.first?.name ?? ""
    }
}

struct Region: Identifiable {
    var id = UUID()
    let name: String
}

struct Hotel: Identifiable, Codable {
    var id = UUID()
    let name: String
    let priceRange: String
    let website: String? // Made websites an optional to allow nil websites
}

struct Activity: Identifiable, Codable {
    var id = UUID()
    let image: String
    let name: String
    let price: String
}

struct TourCompany: Identifiable, Codable {
    var id = UUID()
    let name: String
    let website: String
}

struct Restaurant: Identifiable, Codable {
    var id = UUID()
    let name: String
    let cuisine: String
    let website: String?
}

struct Wildlife: Identifiable, Codable {
    var id = UUID()
    let name: String
    let image: String
    let description: String
}

struct Plant: Identifiable, Codable {
    var id = UUID()
    let name: String
    let image: String
    let description: String
}

struct TourGuide: Identifiable, Codable {
    var id = UUID()
    let name: String
    let image: String
    let phone: String
    let email: String
    let qualifications: [String]
    let priceRange: String
}
// MARK: Victoria Falls
let destinations: [Destination] = [
    Destination(
        name: "Victoria Falls",
        image: "victoria",
        description: "One of the seven natural wonders of the world.",
        region: "Matabeleland North",
        tourGuides: [
            TourGuide(
                name: "Mr Dube",
                image: "dube",
                phone: "+263 71 555 0001",
                email: "dube.vfalls@greenadventures.co.zw",
                qualifications: ["Wildlife Interpretation Diploma", "Advanced Eco-Leadership", "7 Years Experience"],
                priceRange: "$70 - $100 per tour"
            ),
            TourGuide(
                name: "Mr Mpofu",
                image: "mpofu",
                phone: "+263 77 123 4567",
                email: "mpofu.guides@ecotourzim.co.zw",
                qualifications: ["Certified Safari Guide (FGASA Level 2)", "First Aid & Wilderness Training", "10 Years Experience"],
                priceRange: "$80 - $150 per tour"
            ),
            TourGuide(
                name: "Ms Ndlovu",
                image: "ndlovu",
                phone: "+263 78 987 6543",
                email: "ndlovu.guides@ecoexplore.com",
                qualifications: ["Licensed Tour Operator", "ZTA Registered", "Cultural Heritage Specialist"],
                priceRange: "$60 - $120 per tour"
            )
        ],
        hotels: [
            Hotel(name: "Victoria Falls Hotel", priceRange: "$250 - $600/night", website: "https://www.victoriafallshotel.com"),
            Hotel(name: "Ilala Lodge", priceRange: "$180 - $400/night", website: "https://www.ilalalodge.com")
        ],
        activities: [
            Activity(image: "cruise", name: "Sunset Cruise", price: "$50 per person"),
            Activity(image: "jump", name: "Bungee Jump", price: "$120 per person"),
            Activity(image: "helicopter", name: "Helicopter Flight", price: "$150 per person")
        ],
        tourCompanies: [
            TourCompany(name: "Wild Horizons", website: "https://www.wildhorizons.co.zw"),
            TourCompany(name: "Love for Africa", website: "https://www.loveforafrica.co.zw")
        ],
        restaurants: [
            Restaurant(name: "The Lookout Café", cuisine: "Modern African Fusion", website: "https://www.thelookoutcafe.com"),
            Restaurant(name: "The Three Monkeys", cuisine: "Pizza, Burgers & Grill", website: "https://www.thethreemonkeyszim.com")
        ],
        wildlifeInfo: [
            Wildlife(name: "African Elephant", image: "elephant", description: "Large herds often seen near the Zambezi River."),
            Wildlife(name: "Lion", image: "lion", description: "The king of the jungle, often spotted in nearby reserves.")
        ],
        plantInfo: [
            Plant(name: "Baobab Tree", image: "baobab", description: "Iconic tree storing water in its thick trunk."),
            Plant(name: "Rainforest Ferns", image: "fern", description: "Thriving in the mist of the falls.")
        ],
        ecoTip: "Temperatures in Matabeleland North are often high. Always carry a reusable water bottle and avoid plastic waste."
    ),

    // MARK: -Matopo
    Destination(
        name: "Matopo Hills",
        image: "matopo",
        description: "Matobo Hills (Matopos) is a UNESCO World Heritage site south of Bulawayo, characterized by granite kopjes, ancient rock art, rich birdlife (including endemic and raptors), and unique plant communities adapted to granitic soils. It’s better known for rock formations, cultural sites and rhino conservation than large elephant herds.",
        region: "Matabeleland South",
        tourGuides: [
            TourGuide(
                name: "Melisa Ndlovu",
                image: "Melisa",
                phone: "+263 77 345 6789",
                email: "ndlovu.matobo@heritagetours.co.zw",
                qualifications: [
                    "Professional Safari & Cultural Guide",
                    "Rock Art & Archaeology Specialist",
                    "10+ Years Experience in Matobo National Park"
                ],
                priceRange: "$60 - $120 per tour"
            ),
            TourGuide(
                name: "Sarah Cobs",
                image: "sarah",
                phone: "+263 78 234 1112",
                email: "moyo.tours@matoboexplore.co.zw",
                qualifications: [
                    "Ecotourism Diploma (NUST)",
                    "Wildlife & Birding Expert",
                    "Certified Rhino Conservation Volunteer"
                ],
                priceRange: "$70 - $150 per tour"
            ),
            TourGuide(
                name: "Delroy Dube",
                image: "delroy",
                phone: "+263 71 555 2323",
                email: "dube.guides@matopohills.co.zw",
                qualifications: [
                    "ZTA Registered Tour Operator",
                    "Cultural Heritage & Local History Specialist",
                    "First Aid & Wilderness Training"
                ],
                priceRange: "$50 - $100 per tour"
            )
        ],
        hotels: [
            Hotel(name: "Matobo Hills Lodge", priceRange: "$52 - $100/night", website: "https://www.matobohillslodge.co.zw"),
            Hotel(name: "Big Cave Camp", priceRange: "$61 - $120/night", website: "https://www.shashanilodge.com"),
            Hotel(name: "Lynns Guest House", priceRange: "$89 - $120/night", website: nil),
            Hotel(name: "Hillside Manor", priceRange: "$73 - $100/night", website: nil)
        ],
        activities: [
            Activity(image: "rockArt", name: "Cultural tours & Rock Art", price: "$60 - $70/person"),
            Activity(image: "rhinoTracking", name: "Rhino tracking", price: "$90 - $120/person"),
            Activity(image: "hiking", name: "Hiking, birding,", price: "$50 - $120/person")
        ],
        tourCompanies: [
            TourCompany(name: "Gondwana Tours & Safaris", website: "https://www.gondwanatoursandsafaris.com")
        ],
        restaurants: [
            Restaurant(name: "Matobo Hills Lodge", cuisine: "Luxury African Cuisine", website: "https://www.matobohillslodge.co.zw"),
            Restaurant(name: "Farmhouse Matopos", cuisine: "Luxury African Cuisine", website: "https://www.africanreservations.com")
        ],
        wildlifeInfo: [
            Wildlife(name: "Black & White Rhino", image: "rhino", description: "Matobo is an important rhino sanctuary with managed populations and anti-poaching efforts."),
            Wildlife(name: "Martial Eagle", image: "eagle", description: "Kopjes create nesting/roosting sites for raptors; excellent for birdwatchers.")
        ],
        plantInfo: [
            Plant(name: "Paperbark Tree (Commiphora marlothii)", image: "Paperbark", description: "Recognized by its pale flaky bark that peels away like paper, adding texture and color to the landscape."),
            Plant(name: "Wild Pear (Dombeya rotundifolia)", image: "Wild Pear", description: "Early season visitors might see this tree covered in beautiful white blossoms before its leaves appear.")
        ],
        ecoTip: "Respect the rock art sites (no touching, photograph respectfully), stick to marked trails, and support community-run tours that help preserve cultural heritage. Matobo is archaeologically sensitive — small actions (no climbing where prohibited, no litter) have outsized value."
    ),

    // MARK: Hwange National Park
    Destination(
        name: "Hwange National Park",
        image: "hwange",
        description: "Zimbabwe’s largest national park with elephants and lions.",
        region: "Matabeleland North",
        tourGuides: [
            TourGuide(
                name: "Naishe Rowland",
                image: "rowland",
                phone: "+263 78 321 4567",
                email: "rowland.hwange@safarizim.com",
                qualifications: ["Professional Safari Guide", "Animal Tracking Expert", "Conservation Volunteer"],
                priceRange: "$90 - $180 per safari"
            ),
            TourGuide(
                name: "Culture Ncube",
                image: "culture",
                phone: "+263 77 234 8888",
                email: "ncube.hwange@ecoexplore.com",
                qualifications: ["Birding Specialist", "Eco-Tourism Diploma", "CPR & First Aid Trained"],
                priceRange: "$70 - $130 per safari"
            ),
            TourGuide(
                name: "Shadreck Moyo",
                image: "shadreck",
                phone: "+263 71 222 5678",
                email: "moyo.safari@wildzim.co.zw",
                qualifications: ["ZTA Licensed", "Customer Service Excellence", "Wildlife Behavior Specialist"],
                priceRange: "$80 - $150 per safari"
            )
        ],
        hotels: [
            Hotel(name: "Linkwasha Camp (Wilderness Safaris)", priceRange: "$500/night", website: "https://www.wildernessdestinations.com/camps/linkwasha-camp"),
            Hotel(name: "Davison’s Camp", priceRange: "$200/night", website: "https://www.go2africa.com")
        ],
        activities: [
            Activity(image: "gamedrive", name: "Day game drives", price: "$50 – $150 per person"),
            Activity(image: "nightdrive", name: "Night drives", price: "$250 - $300 per person")
        ],
        tourCompanies: [
            TourCompany(name: "Hwange Safaris", website: "https://hwangesafaris.com")
        ],
        restaurants: [
            Restaurant(name: "Dingani Restaurant", cuisine: "À la carte", website: "https://hwangesafaris.com"),
            Restaurant(name: "Waterbuck’s Head Restaurant & Bar", cuisine: "Modern African Fusion", website: "https://hwangesafaris.com")
        ],
        wildlifeInfo: [
            Wildlife(name: "Giraffe", image: "girafe", description: "The southern giraffe, the tallest mammal on Earth, is a prominent sight in Hwange National Park."),
            Wildlife(name: "Zebra", image: "zebra", description: "Hwange is home to herds of zebra, among many plains game species that thrive in the park.")
        ],
        plantInfo: [
            Plant(name: "Mopane Woodland", image: "mopane", description: "Dominant in many areas; supports large browsers such as elephant and giraffe."),
            Plant(name: "Camelthorn", image: "thorn", description: "Characteristic of arid savanna; vegetation patterns influence seasonal wildlife movements.")
        ],
        ecoTip: "Bring a refillable water bottle, avoid single-use plastics, and stay on designated tracks around waterholes to reduce disturbance."
    ),

    // MARK: Chinhoyi Caves
    Destination(
        name: "Chinhoyi Caves",
        image: "chinhoyi",
        description: "Limestone caves with deep blue pools.",
        region: "Mashonaland",
        tourGuides: [
            TourGuide(
                name: "Octavia Chikowore",
                image: "octavia",
                phone: "+263 77 800 1234",
                email: "chikowore.caves@zimtours.co.zw",
                qualifications: [
                    "Certified Cave Diving Instructor",
                    "ZTA Licensed Guide",
                    "10 Years Experience in Chinhoyi Caves"
                ],
                priceRange: "$50 - $100 per tour"
            ),
            TourGuide(
                name: "Amanda Soganile",
                image: "amanda",
                phone: "+263 78 412 5678",
                email: "soganile.tours@ecoexplore.co.zw",
                qualifications: [
                    "Environmental Science Degree (UZ)",
                    "Local Cultural Heritage Specialist",
                    "Cave Safety & Rescue Certified"
                ],
                priceRange: "$60 - $120 per tour"
            ),
            TourGuide(
                name: "Pride Mafira",
                image: "pride",
                phone: "+263 78 603 3635",
                email: "mafira.chinhoyi@adventurezim.co.zw",
                qualifications: [
                    "Adventure & Nature Guide (FGASA Level 1)",
                    "Scuba Diving Certified",
                    "Emergency First Responder"
                ],
                priceRange: "$70 - $140 per tour"
            )
        ],
        hotels: [
            Hotel(name: "CUT Hotel", priceRange: "$56 - $120/night", website: "https://www.cut.ac.zw")
        ],
        activities: [
            Activity(image: "diving", name: "Scuba Diving", price: "$55 - $60/person"),
            Activity(image: "caveTour", name: "Chinhoyi Cave Tours", price: "$67 - $80/person")
        ],
        tourCompanies: [
            TourCompany(name: "ZimAdventures", website: "https://zimadventures.co.zw/"),
            TourCompany(name: "Tourice Travel", website: "https://tourice.co.zw")
        ],
        restaurants: [
            Restaurant(name: "Zebras Dazzle", cuisine: "International Cuisines", website: "http://zebrasdazzle.co.zw"),
            Restaurant(name: "Chicken Inn (Chinhoyi Complex)", cuisine: "Fast Food", website: "https://www.simbisabrands.com/our-brands/chicken-inn/")
        ],
        wildlifeInfo: [
            Wildlife(name: "Arnot's Chat", image: "bird", description: "Frequently sighted near the caves."),
            Wildlife(name: "Vervet Monkeys", image: "monkey", description: "The area’s lush vegetation is a prime spot for wildlife and birdwatching.")
        ],
        plantInfo: [
            Plant(name: "Water-Lilies", image: "waterlily", description: "The pools within the Chinhoyi Caves National Park support aquatic vegetation including water lilies."),
            Plant(name: "Flame Lily (Gloriosa superba)", image: "lily", description: "Zimbabwe’s national flower recorded at the caves.")
        ],
        ecoTip: "Respect this sacred space. The caves hold cultural and traditional significance; be mindful of their spiritual importance."
    ),
]

let destinations2: [Destination] = [
    // MARK: Inyanga
    Destination(
        name: "Inyanga ",
        image: "inyanga",
        description: "Nyanga National Park is the primary focus, home to Mount Nyangani (Zimbabwe's highest peak at 2,592m) and Mutarazi Falls (Zimbabwe's highest waterfall at 762m).",
        region: "Manicaland",
        tourGuides: [
            TourGuide(
                name: "Octavia Chikowore",
                image: "octavia",
                phone: "+263 77 800 1234",
                email: "chikowore.caves@zimtours.co.zw",
                qualifications: [
                    "Certified Cave Diving Instructor",
                    "ZTA Licensed Guide",
                    "10 Years Experience in Chinhoyi Caves"
                ],
                priceRange: "$50 - $100 per tour"
            ),
            TourGuide(
                name: "Amanda Soganile",
                image: "amanda",
                phone: "+263 78 412 5678",
                email: "soganile.tours@ecoexplore.co.zw",
                qualifications: [
                    "Environmental Science Degree (UZ)",
                    "Local Cultural Heritage Specialist",
                    "Cave Safety & Rescue Certified"
                ],
                priceRange: "$60 - $120 per tour"
            ),
            TourGuide(
                name: "Pride Mafira",
                image: "pride",
                phone: "+263 78 603 3635",
                email: "mafira.chinhoyi@adventurezim.co.zw",
                qualifications: [
                    "Adventure & Nature Guide (FGASA Level 1)",
                    "Scuba Diving Certified",
                    "Emergency First Responder"
                ],
                priceRange: "$70 - $140 per tour"
            )
        ],
        hotels: [
            Hotel(name: "CUT Hotel", priceRange: "$56 - $120/night", website: "https://www.cut.ac.zw")
        ],
        activities: [
            Activity(image: "climbing", name: "Hiking & Climbing", price: "$5 - $10/person"),
            Activity(image: "mutarazi", name: "Mutarazi Falls Sky Walk", price: "$5 - $10/person"),
            Activity(image: "fishing", name: "Trout Fishing", price: "$5 - $10/person"),
            Activity(image: "mutarazi", name: "Historical Sites", price: "$5 - $10/person"),
            Activity(image: "mutarazi", name: "Water Activities", price: "$5 - $10/person"),
            Activity(image: "mutarazi", name: "Game Viewing", price: "$5 - $10/person")
        ],
        tourCompanies: [
            TourCompany(name: "Mauya Africa Travel & Tours:", website: "https://mauyaafrica.co.zw/"),
            TourCompany(name: "Far and Wide Zimbabwe", website: "https://www.farandwide.co.zw/"),
            TourCompany(name: "ZimAdventures", website: "https://zimadventures.co.zw/"),
            TourCompany(name: "Safaris Tours Africa", website: "https://www.safari.com/"),
     TourCompany(name: "Rhino Africa Tours", website: "https://www.rhinoafrica.com/en"),
    TourCompany(name: "Mikaya Travels", website: "https://mikayatravels.com/")
        ],
        restaurants: [
            Restaurant(name: "Zebras Dazzle", cuisine: "International Cuisines", website: "http://zebrasdazzle.co.zw"),
            Restaurant(name: "Chicken Inn (Chinhoyi Complex)", cuisine: "Fast Food", website: "https://www.simbisabrands.com/our-brands/chicken-inn/")
        ],
        wildlifeInfo: [
            Wildlife(name: "Arnot's Chat", image: "bird", description: "Frequently sighted near the caves."),
            Wildlife(name: "Vervet Monkeys", image: "monkey", description: "The area’s lush vegetation is a prime spot for wildlife and birdwatching.")
        ],
        plantInfo: [
            Plant(name: "Water-Lilies", image: "waterlily", description: "The pools within the Chinhoyi Caves National Park support aquatic vegetation including water lilies."),
            Plant(name: "Flame Lily (Gloriosa superba)", image: "lily", description: "Zimbabwe’s national flower recorded at the caves.")
        ],
        ecoTip: "Respect this sacred space. The caves hold cultural and traditional significance; be mindful of their spiritual importance."
    )
    
]

let regions: [Region] = [
    Region(name: "Matabeleland North"),
    Region(name: "Mashonaland"),
    Region(name: "Manicaland"),
    Region(name: "Midlands"),
    Region(name: "Masvingo"),
    Region(name: "Harare"),
    Region(name: "Bulawayo"),
    Region(name: "Matabeleland South")
]
