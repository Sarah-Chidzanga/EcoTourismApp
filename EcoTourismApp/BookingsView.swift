import SwiftUI

struct BookingsView: View {
    let isGuide: Bool
    @Environment(AuthSession.self) private var session
    @State private var bookings: [TripBooking] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedStatus = "Active"

    private var visible: [TripBooking] {
        bookings.filter {
            selectedStatus == "All" || ["pending", "confirmed"].contains($0.status)
        }.sorted { $0.tourDate < $1.tourDate }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(isGuide ? "Good days start\nwith a connection." : "Your next chapter.")
                    .font(.largeTitle.bold())
                Text(isGuide ? "Review requests and make a plan with your guests." : "All your guide requests, in one place.")
                    .foregroundStyle(.secondary)
                if !isGuide {
                    NavigationLink { TripPlanner() } label: {
                        Label("Your Trip Plans", systemImage: "map")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(TravelPrimaryButton())
                    Text("Trip plans are your ideas. A guide request is only confirmed when the guide accepts it.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Picker("Show bookings", selection: $selectedStatus) {
                    Text("Active").tag("Active")
                    Text("All").tag("All")
                }
                .pickerStyle(.segmented)
                if session.user == nil {
                    SignInPrompt()
                } else if isLoading {
                    ProgressView("Loading requests…").frame(maxWidth: .infinity).padding(40)
                } else if let errorMessage {
                    ContentUnavailableView {
                        Label("Couldn't Load Requests", systemImage: "wifi.exclamationmark")
                    } description: { Text(errorMessage) } actions: {
                        Button("Try Again") { Task { await load() } }
                    }
                } else if visible.isEmpty {
                    ContentUnavailableView(isGuide ? "Your Next Guests Are Out There" : "A New Adventure Awaits",
                                           systemImage: isGuide ? "tray" : "suitcase.rolling",
                                           description: Text(isGuide ? "Publish your guide profile to receive booking requests." : "Find a local guide and request a day together."))
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(visible) { booking in
                            NavigationLink {
                                BookingDetailView(booking: booking, isGuide: isGuide)
                            } label: {
                                BookingSummaryCard(booking: booking, isGuide: isGuide)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(TravelStyle.sand)
        .navigationTitle(isGuide ? "Requests" : "My Trips")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await load() }
        .task { await load() }
        .tint(TravelStyle.ink)
    }

    private func load() async {
        guard session.user != nil else { isLoading = false; return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do { bookings = try await session.request("bookings") }
        catch { errorMessage = AuthSession.message(for: error) }
    }
}

private struct BookingSummaryCard: View {
    let booking: TripBooking
    let isGuide: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(booking.statusLabel)
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 12).padding(.vertical, 7)
                    .background(TravelStyle.forest.opacity(0.1), in: Capsule())
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.secondary)
            }
            Text(isGuide ? booking.touristName : booking.guideName).font(.title3.bold())
            Label(booking.dateLabel, systemImage: "calendar")
            HStack {
                Label(booking.guests == 1 ? "1 traveller" : "\(booking.guests) travellers", systemImage: "person.2")
                Spacer()
                Text(booking.totalPrice, format: .currency(code: "USD")).fontWeight(.semibold)
            }
            .font(.subheadline)
        }
        .padding(20)
        .background(TravelStyle.card, in: RoundedRectangle(cornerRadius: 24))
    }
}

struct BookingDetailView: View {
    @State private var booking: TripBooking
    let isGuide: Bool

    init(booking: TripBooking, isGuide: Bool) {
        _booking = State(initialValue: booking)
        self.isGuide = isGuide
    }
    @Environment(AuthSession.self) private var session
    @State private var isUpdating = false
    @State private var errorMessage = ""
    @State private var showingError = false
    @State private var pendingStatus: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                BookingSummaryCard(booking: booking, isGuide: isGuide)
                if !booking.note.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("The Plan").font(.title2.bold())
                        Text(booking.note)
                    }
                }
                if booking.status == "pending" {
                    TravelInfoSection(title: "Awaiting Guide Confirmation",
                                      text: isGuide
                                        ? "This request is awaiting your response. Accept only when you can host these guests on the requested date."
                                        : "This is a request, not a confirmed booking. Check My Trips for the guide's response before making arrangements.")
                }
                if booking.status == "confirmed" {
                    let email = isGuide ? booking.touristEmail : booking.guideEmail
                    VStack(alignment: .leading, spacing: 12) {
                        Text("You're Connected").font(.title2.bold())
                        Text("Agree on the meeting point, route, timing, and any extra costs before your day together.")
                            .foregroundStyle(.secondary)
                        if let email, let url = URL(string: "mailto:\(email)") {
                            Link(destination: url) { Label("Email \(isGuide ? booking.touristName : booking.guideName)", systemImage: "envelope") }
                                .buttonStyle(TravelPrimaryButton())
                        }
                    }
                }
                Text("Guide fee: \(booking.totalPrice.formatted(.currency(code: "USD"))). Payment is arranged directly; Shanya hasn't collected a payment.")
                    .font(.footnote).foregroundStyle(.secondary)
                if isGuide && booking.status == "pending" {
                    Button("Accept Request") { pendingStatus = "confirmed" }
                        .buttonStyle(TravelPrimaryButton())
                    Button("Decline Request", role: .destructive) { pendingStatus = "declined" }
                        .frame(maxWidth: .infinity)
                }
                if ["pending", "confirmed"].contains(booking.status) {
                    Button("Cancel Request", role: .destructive) { pendingStatus = "cancelled" }
                        .frame(maxWidth: .infinity)
                }
                if isUpdating { ProgressView().frame(maxWidth: .infinity) }
            }
            .padding(20)
            .disabled(isUpdating)
        }
        .background(TravelStyle.sand)
        .navigationTitle("Booking Details")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Update this request?", isPresented: Binding(
            get: { pendingStatus != nil }, set: { if !$0 { pendingStatus = nil } }
        ), titleVisibility: .visible) {
            if let status = pendingStatus {
                Button(status == "confirmed" ? "Accept Request" : status == "declined" ? "Decline Request" : "Cancel Request",
                       role: status == "confirmed" ? nil : .destructive) {
                    Task { await update(status) }
                }
            }
        } message: {
            Text("The other person will see the updated status in their requests.")
        }
        .alert("Couldn't Update Request", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: { Text(errorMessage) }
    }

    private func update(_ status: String) async {
        isUpdating = true
        defer { isUpdating = false }
        do {
            booking = try await session.request("bookings/\(booking.id)", method: "PATCH",
                                                body: JSONEncoder().encode(BookingStatusUpdate(status: status)))
        } catch {
            errorMessage = AuthSession.message(for: error)
            showingError = true
        }
    }
}

struct SignInPrompt: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle").font(.largeTitle)
            Text("Make It Your Journey").font(.title2.bold())
            Text("Log in to request a guide and keep track of your trips.")
                .foregroundStyle(.secondary)
            NavigationLink { AuthenticationForm(role: .tourist, isRegistration: false) } label: { Text("Log In or Create an Account") }
                .buttonStyle(TravelPrimaryButton())
        }
        .multilineTextAlignment(.center)
        .padding(.vertical, 32)
    }
}
