import SwiftUI
import UserNotifications

struct NotificationInbox: View {
    @Environment(AuthSession.self) private var session
    @State private var items: [InboxNotification] = []
    @State private var loading = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section {
                NavigationLink { TravelReminders() } label: { Label("Reminder Settings", systemImage: "bell.badge") }
                Text("Booking updates appear here when you refresh. Phone reminders are managed separately.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            if session.user == nil { SignInPrompt() }
            else if loading { ProgressView("Loading updates…") }
            else if let errorMessage {
                Text(errorMessage).foregroundStyle(.secondary)
                Button("Try Again") { Task { await load() } }
            } else if items.isEmpty {
                ContentUnavailableView("You're All Caught Up", systemImage: "bell",
                                       description: Text("New guide requests and booking status changes will appear here."))
            } else {
                ForEach(items) { item in
                    NavigationLink { NotificationBooking(item: item) } label: {
                        HStack(alignment: .top) {
                            Image(systemName: item.isRead == 0 ? "circle.fill" : "checkmark.circle")
                                .foregroundStyle(TravelStyle.ink)
                                .accessibilityLabel(item.isRead == 0 ? "Unread" : "Read")
                            VStack(alignment: .leading, spacing: 6) {
                                Text(item.message)
                                Text(Date(timeIntervalSince1970: item.createdAt / 1000), style: .date)
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Notifications")
        .onAppear { Task { await load() } }
        .refreshable { await load() }
        .tint(TravelStyle.ink)
    }

    private func load() async {
        guard session.user != nil else { return }
        loading = true; errorMessage = nil
        defer { loading = false }
        do { items = try await session.request("notifications") }
        catch { errorMessage = AuthSession.message(for: error) }
    }
}

private struct InboxNotification: Decodable, Identifiable {
    let id: Int
    let bookingId: Int
    let message: String
    let createdAt: Double
    let isRead: Int
}

private struct NotificationBooking: View {
    let item: InboxNotification
    @Environment(AuthSession.self) private var session
    @State private var booking: TripBooking?
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if let booking { BookingDetailView(booking: booking, isGuide: session.user?.role == .guide) }
            else if let errorMessage {
                ContentUnavailableView("Couldn't Open Request", systemImage: "wifi.exclamationmark", description: Text(errorMessage))
            } else { ProgressView("Opening request…") }
        }
        .task {
            do {
                let bookings: [TripBooking] = try await session.request("bookings")
                guard let found = bookings.first(where: { $0.id == item.bookingId }) else {
                    errorMessage = "This request is no longer available."; return
                }
                booking = found
                let _: APIMessage = try await session.request("notifications/\(item.id)/read", method: "PATCH")
            } catch { errorMessage = AuthSession.message(for: error) }
        }
    }
}

struct TravelReminders: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL
    @State private var reminderDate = Date().addingTimeInterval(3600)
    @State private var title = "Prepare for my Zimbabwe trip"
    @State private var reminders: [UNNotificationRequest] = []
    @State private var permission = "Checking…"
    @State private var message: String?
    @State private var busy = false
    private let prefix = "shanya.travel-reminder."

    var body: some View {
        Form {
            Section("Notifications on This Phone") {
                LabeledContent("Permission", value: permission)
                Button("Open Notification Settings") {
                    if let url = URL(string: UIApplication.openNotificationSettingsURLString) { openURL(url) }
                }
            }
            Section("Add a Trip Reminder") {
                TextField("Reminder", text: $title)
                DatePicker("Remind me", selection: $reminderDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                Button("Schedule Reminder") { Task { await schedule() } }
                    .disabled(busy || title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || reminders.count >= 10)
                if busy { ProgressView() }
                if let message { Text(message).font(.footnote) }
            }
            Section {
                if reminders.isEmpty { Text("No reminders scheduled.").foregroundStyle(.secondary) }
                ForEach(reminders, id: \.identifier) { request in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(request.content.title)
                        if let date = (request.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate() {
                            Text(date, format: .dateTime.day().month().hour().minute()).font(.caption)
                        }
                        Button("Remove Reminder", role: .destructive) {
                            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [request.identifier])
                            reminders.removeAll { $0.identifier == request.identifier }
                        }
                    }
                }
            } header: { Text("Scheduled Reminders") } footer: {
                Text("Up to 10 reminders stay on this phone. They are independent of bookings: remove or update them if your plans change. Booking push alerts are not enabled yet.")
            }
        }
        .navigationTitle("Reminders")
        .task { await refresh() }
        .onChange(of: scenePhase) { if scenePhase == .active { Task { await refresh() } } }
    }

    private func refresh() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral: permission = "Allowed"
        case .denied: permission = "Off in Settings"
        case .notDetermined: permission = "Not requested"
        @unknown default: permission = "Unknown"
        }
        reminders = await center.pendingNotificationRequests()
            .filter { $0.identifier.hasPrefix(prefix) }
            .sorted {
                (($0.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate() ?? .distantFuture) <
                (($1.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate() ?? .distantFuture)
            }
    }

    private func schedule() async {
        busy = true; message = nil
        defer { busy = false }
        guard reminderDate.timeIntervalSinceNow >= 60 else {
            message = "Choose a time at least one minute from now."; return
        }
        do {
            let center = UNUserNotificationCenter.current()
            guard try await center.requestAuthorization(options: [.alert, .sound]) else {
                message = "Notifications are off. Enable them in Settings to schedule reminders."
                await refresh(); return
            }
            let content = UNMutableNotificationContent()
            content.title = String(title.trimmingCharacters(in: .whitespacesAndNewlines).prefix(120))
            content.body = "Open Shanya to check your trip plan and arrangements."
            content.sound = .default
            let date = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: reminderDate)
            try await center.add(UNNotificationRequest(identifier: prefix + UUID().uuidString, content: content,
                                                       trigger: UNCalendarNotificationTrigger(dateMatching: date, repeats: false)))
            message = "Reminder scheduled."
            await refresh()
        } catch { message = error.localizedDescription }
    }
}

struct AppSuggestions: View {
    @Environment(AuthSession.self) private var session
    @AppStorage("suggestionDraft") private var draft = ""
    @AppStorage("suggestionCategory") private var category = "Idea"
    @AppStorage("suggestionRequestID") private var requestID = ""
    @State private var busy = false
    @State private var message: String?
    @State private var succeeded = false

    var body: some View {
        Form {
            Section {
                Text("Help shape Shanya").font(.title2.bold())
                Text("Tell us what would make travelling or guiding easier. Include the place name when reporting a listing.")
            }
            if session.user == nil { SignInPrompt() }
            Section("Your Suggestion") {
                Picker("Category", selection: $category) {
                    Text("Idea").tag("Idea")
                    Text("Problem").tag("Problem")
                    Text("Listing correction").tag("Listing correction")
                }
                TextField("What should we improve?", text: $draft, axis: .vertical).lineLimit(6...12)
                Text("\(draft.count) / 2,000 characters").font(.caption).foregroundStyle(.secondary)
                Button("Send Suggestion") { Task { await submit() } }
                    .disabled(session.user == nil || busy || draft.trimmingCharacters(in: .whitespacesAndNewlines).count < 10 || draft.count > 2000)
                if busy { ProgressView() }
                if let message { Text(message).foregroundStyle(succeeded ? TravelStyle.ink : .primary) }
            }
            .disabled(busy)
            Section {
                Text("Submissions are linked to your account and stored for the Shanya team to review. Avoid passwords, payment details or other sensitive information. This is not an emergency or live-support channel. Unsent drafts stay on this device.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Suggestions")
        .onChange(of: draft) {
            if succeeded && draft.isEmpty { return }
            if !busy { requestID = UUID().uuidString; message = nil; succeeded = false }
        }
        .onChange(of: category) { requestID = UUID().uuidString; message = nil }
    }

    private func submit() async {
        busy = true; message = nil; succeeded = false
        defer { busy = false }
        if requestID.isEmpty { requestID = UUID().uuidString }
        do {
            let body = try JSONEncoder().encode(["requestId": requestID, "category": category, "message": draft])
            let response: APIMessage = try await session.request("suggestions", method: "POST", body: body)
            draft = ""; requestID = UUID().uuidString
            message = response.message ?? "Suggestion received. Thank you!"
            succeeded = true
        } catch { message = AuthSession.message(for: error) }
    }
}

struct AppRatingButton: View {
    @Environment(\.openURL) private var openURL
    @State private var message: String?
    var body: some View {
        Button {
            guard let id = Bundle.main.object(forInfoDictionaryKey: "AppStoreID") as? String,
                  !id.isEmpty, id.allSatisfy(\.isNumber),
                  let url = URL(string: "https://apps.apple.com/app/id\(id)?action=write-review") else {
                message = "App Store ratings will be available after Shanya is published. You can send suggestions now."
                return
            }
            openURL(url) { accepted in
                if !accepted { message = "Couldn't open the App Store. Please try again later." }
            }
        } label: { Label("Rate Shanya on the App Store", systemImage: "star") }
        .alert("App Store Rating", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
            Button("OK", role: .cancel) {}
        } message: { Text(message ?? "") }
    }
}
