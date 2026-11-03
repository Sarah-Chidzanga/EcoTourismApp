import SwiftUI

struct BookTourGuide: View {
    let guide: GuideListing
    @Environment(AuthSession.self) private var session
    @State private var date = Date()
    @State private var guests = 1
    @State private var note = ""
    @State private var request: BookingRequest?
    @State private var submitted: TripBooking?
    @State private var isSending = false
    @State private var errorMessage = ""
    @State private var showingError = false

    var body: some View {
        Group {
            if let submitted {
                BookingReceipt(booking: submitted)
            } else {
                Form {
                    Section {
                        HStack(spacing: 14) {
                            GuideAvatar(initials: guide.initials)
                            VStack(alignment: .leading, spacing: 6) {
                                Text(guide.name).font(.headline)
                                Text(guide.location).foregroundStyle(.secondary)
                            }
                        }
                    }
                    Section("Make It Your Day") {
                        DatePicker("Tour date", selection: $date, in: Date()..., displayedComponents: .date)
                            .environment(\.timeZone, TravelDate.timeZone)
                        Stepper(guests == 1 ? "1 traveller" : "\(guests) travellers", value: $guests, in: 1...guide.maxGuests)
                        TextField("What would you like to see or do?", text: $note, axis: .vertical)
                            .lineLimit(4...8)
                    }
                    .disabled(request != nil)
                    Section {
                        LabeledContent("One-day guide fee") { Text(guide.dailyRate, format: .currency(code: "USD")) }
                        Text("For your whole group. Entry fees, transport, accommodation, and meals are not included. Agree on final arrangements with your guide.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Section {
                        Button {
                            Task { await send() }
                        } label: {
                            HStack {
                                Text(request == nil ? "Send Booking Request" : "Retry Same Request")
                                if isSending { ProgressView() }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .disabled(isSending || note.count > 2000)
                        Text("This is a request, not a confirmed booking. Follow its status in My Trips. No payment is taken.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        if request != nil {
                            Text("If your connection dropped, retry safely or check My Trips before starting another request.")
                                .font(.footnote)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .background(TravelStyle.sand)
        .navigationTitle("Request a Day")
        .navigationBarTitleDisplayMode(.inline)
        .tint(TravelStyle.ink)
        .alert("Couldn't Send Request", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: { Text(errorMessage) }
    }

    private func send() async {
        guard !isSending else { return }
        isSending = true
        defer { isSending = false }
        let payload = request ?? BookingRequest(guideId: guide.id, expectedPrice: guide.dailyRate, tourDate: TravelDate.formatter.string(from: date),
                                                guests: guests, note: note, requestId: UUID().uuidString)
        request = payload
        do {
            submitted = try await session.request("bookings", method: "POST", body: JSONEncoder().encode(payload))
        } catch {
            if case AuthError.server(let status, _) = error, [400, 404, 409].contains(status) {
                request = nil
            }
            errorMessage = AuthSession.message(for: error)
            showingError = true
        }
    }
}

private struct BookingReceipt: View {
    let booking: TripBooking

    var body: some View {
        VStack(spacing: 22) {
            Image(systemName: "paperplane.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(TravelStyle.ink)
            Text("Your request is on its way.").font(.title.bold())
            Text("\(booking.guideName) can now review your request for \(booking.dateLabel).")
                .foregroundStyle(.secondary)
            Text("Look in My Trips for the guide’s response. Contact details become available after acceptance.")
            NavigationLink("View My Trips") { BookingsView(isGuide: false) }
                .buttonStyle(TravelPrimaryButton())
        }
        .multilineTextAlignment(.center)
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
