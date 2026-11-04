import Foundation
import SwiftUI

enum TravelStyle {
    static let forest = Color(red: 0.12, green: 0.29, blue: 0.24)
    static let ink = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.62, green: 0.82, blue: 0.70, alpha: 1)
            : UIColor(red: 0.12, green: 0.29, blue: 0.24, alpha: 1)
    })
    static let sand = Color(uiColor: .systemGroupedBackground)
    static let card = Color(uiColor: .secondarySystemGroupedBackground)
}

struct GuideListing: Codable, Identifiable, Equatable {
    let id: Int
    let name: String
    var title: String
    var location: String
    var bio: String
    var languages: String
    var dailyRate: Double
    var maxGuests: Int
    var published: Bool?

    var initials: String {
        name.split(separator: " ").prefix(2).compactMap(\.first).map(String.init).joined()
    }
}

struct GuideProfileUpdate: Encodable {
    let title: String
    let location: String
    let bio: String
    let languages: String
    let dailyRate: Double
    let maxGuests: Int
    let published: Bool
}

struct TripBooking: Decodable, Identifiable {
    let id: Int
    let guideId: Int
    let touristId: Int
    let guideName: String
    let touristName: String
    let tourDate: String
    let guests: Int
    let note: String
    let status: String
    let totalPrice: Double
    let guideEmail: String?
    let touristEmail: String?

    var statusLabel: String {
        switch status {
        case "confirmed": return "Accepted"
        case "declined": return "Declined"
        case "cancelled": return "Cancelled"
        default: return "Awaiting guide"
        }
    }

    var dateLabel: String {
        guard let date = TravelDate.formatter.date(from: tourDate) else { return tourDate }
        let formatter = DateFormatter()
        formatter.timeZone = TravelDate.timeZone
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct BookingRequest: Encodable {
    let guideId: Int
    let expectedPrice: Double
    let tourDate: String
    let guests: Int
    let note: String
    let requestId: String
}

struct BookingStatusUpdate: Encodable {
    let status: String
}

enum TravelDate {
    static let timeZone = TimeZone(identifier: "Africa/Harare") ?? .gmt
    static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

struct TravelPrimaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundStyle(.white)
            .background(TravelStyle.forest.opacity(configuration.isPressed ? 0.75 : 1), in: RoundedRectangle(cornerRadius: 18))
    }
}

struct GuideAvatar: View {
    let initials: String

    var body: some View {
        Text(initials)
            .font(.title2.bold())
            .foregroundStyle(TravelStyle.ink)
            .frame(width: 64, height: 64)
            .background(TravelStyle.forest.opacity(0.12), in: RoundedRectangle(cornerRadius: 20))
            .accessibilityHidden(true)
    }
}
