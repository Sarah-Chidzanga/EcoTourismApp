import SwiftUI
import Observation

struct PlannedStop: Identifiable, Codable {
    var id = UUID()
    let referenceID: String
    let kind: String
    let name: String
    var day: Int
}

struct TravelPlan: Identifiable, Codable {
    var id = UUID()
    var name: String
    var days: Int
    var notes = ""
    var stops: [PlannedStop] = []
}

@MainActor
@Observable
final class TripPlanStore {
    private(set) var plans: [TravelPlan] = []
    private(set) var errorMessage: String?
    private let defaults: UserDefaults
    private let key = "shanya.tripPlans.v1"
    private var readable = true

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        reload()
    }

    func reload() {
        guard let data = defaults.data(forKey: key) else {
            plans = []; readable = true; errorMessage = nil
            return
        }
        do {
            let saved = try JSONDecoder().decode([TravelPlan].self, from: data)
            guard Set(saved.map(\.id)).count == saved.count,
                  saved.allSatisfy({ plan in
                      (1...30).contains(plan.days) &&
                      Set(plan.stops.map(\.id)).count == plan.stops.count &&
                      plan.stops.allSatisfy { (1...plan.days).contains($0.day) }
                  }) else {
                throw CocoaError(.coderReadCorrupt)
            }
            plans = saved
            readable = true
            errorMessage = nil
        }
        catch {
            readable = false
            errorMessage = "Your saved plans couldn't be opened. They have been kept on this device."
        }
    }

    func save(_ plan: TravelPlan) {
        guard readable else { return }
        var updated = plans
        if let index = updated.firstIndex(where: { $0.id == plan.id }) { updated[index] = plan }
        else { updated.append(plan) }
        persist(updated)
    }

    func delete(_ id: UUID) {
        guard readable else { return }
        persist(plans.filter { $0.id != id })
    }

    private func persist(_ updated: [TravelPlan]) {
        do {
            let data = try JSONEncoder().encode(updated)
            defaults.set(data, forKey: key)
            plans = updated
            errorMessage = nil
        } catch { errorMessage = "Couldn't save your plan. Please try again." }
    }
}

struct TripPlanner: View {
    var suggestedName = "My Zimbabwe Trip"
    var suggestedDays = 3
    var suggestedNotes = ""
    @State private var store = TripPlanStore()
    @State private var showingCreate = false
    @State private var pendingDelete: TravelPlan?

    var body: some View {
        List {
            Section {
                Text("Build a trip at your own pace.")
                    .font(.title2.bold())
                Text("Organise destinations, stays, food and activities by day. Plans are saved on this device and are separate from guide bookings.")
                    .foregroundStyle(.secondary)
                Button { showingCreate = true } label: {
                    Label("Create a Trip", systemImage: "plus.circle.fill")
                }
                .disabled(store.errorMessage != nil)
            }
            if let error = store.errorMessage { Text(error).foregroundStyle(.red) }
            if store.plans.isEmpty {
                ContentUnavailableView("Your Plans Start Here", systemImage: "map",
                                       description: Text("Create a trip, then add places from the directory or your saved places."))
            }
            ForEach(store.plans) { plan in
                NavigationLink {
                    TripPlanDetail(store: store, planID: plan.id)
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(plan.name).font(.headline)
                        Text("\(plan.days) days · \(plan.stops.count) stops")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                }
                .swipeActions {
                    Button("Delete", role: .destructive) { pendingDelete = plan }
                }
            }
        }
        .navigationTitle("Plan a Trip")
        .onAppear { store.reload() }
        .tint(TravelStyle.ink)
        .sheet(isPresented: $showingCreate) {
            NewTravelPlan(name: suggestedName, days: suggestedDays, notes: suggestedNotes) { store.save($0) }
        }
        .confirmationDialog("Delete this trip plan?", isPresented: Binding(
            get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }
        ), titleVisibility: .visible) {
            if let plan = pendingDelete {
                Button("Delete \(plan.name)", role: .destructive) { store.delete(plan.id); pendingDelete = nil }
            }
        } message: { Text("This only removes the local plan. Guide requests are not cancelled.") }
    }
}

private struct NewTravelPlan: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var days: Int
    let notes: String
    let create: (TravelPlan) -> Void

    init(name: String, days: Int, notes: String, create: @escaping (TravelPlan) -> Void) {
        _name = State(initialValue: name)
        _days = State(initialValue: days)
        self.notes = notes
        self.create = create
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Trip name", text: $name)
                Stepper("\(days) days", value: $days, in: 1...30)
                Text("You can change the name and add notes later.")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("New Trip")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        create(TravelPlan(name: name.trimmingCharacters(in: .whitespacesAndNewlines), days: days, notes: notes))
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

private struct TripPlanDetail: View {
    let store: TripPlanStore
    let planID: UUID
    @State private var addingDay: Int?
    private var plan: TravelPlan? { store.plans.first { $0.id == planID } }

    var body: some View {
        Group {
            if let plan {
                List {
                    Section("Trip Details") {
                        TextField("Trip name", text: Binding(get: { self.plan?.name ?? "" }, set: { value in
                            var updated = plan; updated.name = value; store.save(updated)
                        }))
                        TextField("Notes, transport and things to check", text: Binding(get: { self.plan?.notes ?? "" }, set: { value in
                            var updated = plan; updated.notes = value; store.save(updated)
                        }), axis: .vertical)
                        .lineLimit(3...8)
                        Text("Check travel times, opening hours and availability with operators. Adding a stop does not reserve it.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                    ForEach(1...plan.days, id: \.self) { day in
                        PlannedDaySection(day: day, plan: plan, store: store) { addingDay = day }
                    }
                    Section {
                        ShareLink(item: itineraryText(plan)) { Label("Share Itinerary", systemImage: "square.and.arrow.up") }
                    } footer: {
                        Text("This plan is stored on this device, not synced to your account. Share a copy to keep it elsewhere.")
                    }
                }
                .toolbar { EditButton() }
            } else {
                ContentUnavailableView("Plan Not Found", systemImage: "map")
            }
        }
        .navigationTitle("Your Itinerary")
        .onAppear { store.reload() }
        .sheet(isPresented: Binding(get: { addingDay != nil }, set: { if !$0 { addingDay = nil } })) {
            if let day = addingDay, let plan {
                PlanStopPicker { item in
                    var updated = self.plan ?? plan
                    updated.stops.append(PlannedStop(referenceID: item.referenceID, kind: item.kind, name: item.name, day: day))
                    store.save(updated)
                }
            }
        }
    }

    private func itineraryText(_ plan: TravelPlan) -> String {
        var lines = [plan.name, "Zimbabwe trip plan — not a booking confirmation", ""]
        for day in 1...plan.days {
            lines.append("Day \(day)")
            let stops = plan.stops.filter { $0.day == day }
            lines += stops.isEmpty ? ["Free time / to be planned"] : stops.map { "• \($0.name)" }
            lines.append("")
        }
        if !plan.notes.isEmpty { lines.append(plan.notes) }
        return lines.joined(separator: "\n")
    }
}

private struct PlannedDaySection: View {
    let day: Int
    let plan: TravelPlan
    let store: TripPlanStore
    let add: () -> Void
    @Environment(TravelCatalogStore.self) private var catalog
    private var stops: [PlannedStop] { plan.stops.filter { $0.day == day } }

    var body: some View {
        Section("Day \(day)") {
            ForEach(stops) { stop in
                VStack(alignment: .leading, spacing: 6) {
                    Text(stop.name).font(.headline)
                    Text(stop.kind).font(.caption).foregroundStyle(.secondary)
                    if let destination = catalog.destinations.first(where: { stop.kind == "Destination" && $0.id == stop.referenceID }) {
                        NavigationLink("View Place") { DestinationDetailsView(destination: destination) }
                    } else if let venue = catalog.catalog.venues.first(where: { stop.kind != "Destination" && stop.kind != "Activity" && $0.id == stop.referenceID }) {
                        NavigationLink("View Place") { VenueDetailView(venue: venue) }
                    }
                    if let activity = catalog.catalog.activities.first(where: { stop.kind == "Activity" && $0.id == stop.referenceID }) {
                        NavigationLink("View Activity") { ActivityDetailView(activity: activity) }
                    }
                    Menu("Move to Day") {
                        ForEach(1...plan.days, id: \.self) { target in
                            Button("Day \(target)") {
                                var updated = plan
                                if let index = updated.stops.firstIndex(where: { $0.id == stop.id }) {
                                    updated.stops[index].day = target; store.save(updated)
                                }
                            }
                        }
                    }
                }
            }
            .onDelete { indices in
                let removed = Set(indices.map { stops[$0].id })
                var updated = plan
                updated.stops.removeAll { removed.contains($0.id) }
                store.save(updated)
            }
            .onMove { source, destination in
                var ordered = stops
                ordered.move(fromOffsets: source, toOffset: destination)
                var updated = plan
                updated.stops.removeAll { $0.day == day }
                updated.stops.append(contentsOf: ordered)
                store.save(updated)
            }
            Button(action: add) { Label("Add a Stop", systemImage: "plus") }
        }
    }
}

private struct PlanChoice: Identifiable {
    let referenceID: String
    let name: String
    let kind: String
    let location: String
    let saved: Bool
    var id: String { kind + ":" + referenceID }
}

private struct PlanStopPicker: View {
    let add: (PlanChoice) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(TravelCatalogStore.self) private var catalog
    @AppStorage("savedDestinationNames") private var savedNames = ""
    @AppStorage("savedVenueIDs") private var savedVenueIDs = ""
    @State private var query = ""
    @State private var savedOnly = false
    private var choices: [PlanChoice] {
        let names = Set(savedNames.split(separator: "|").map(String.init))
        let ids = Set(savedVenueIDs.split(separator: "|").map(String.init))
        let destinations = catalog.destinations.map {
            PlanChoice(referenceID: $0.id, name: $0.name, kind: "Destination", location: $0.region,
                       saved: names.contains($0.name) || $0.aliases.contains(where: names.contains))
        }
        let venues = catalog.catalog.venues.map {
            PlanChoice(referenceID: $0.id, name: $0.name, kind: $0.category, location: $0.location, saved: ids.contains($0.id))
        }
        let activities = catalog.catalog.activities.map { activity in
            PlanChoice(referenceID: activity.id, name: activity.name, kind: "Activity",
                       location: catalog.destinations.first { $0.id == activity.destinationID }?.name ?? "", saved: false)
        }
        return (destinations + venues + activities).filter {
            (!savedOnly || $0.saved) && (query.isEmpty || "\($0.name) \($0.location) \($0.kind)".localizedCaseInsensitiveContains(query))
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Toggle("Saved Places Only", isOn: $savedOnly)
                if choices.isEmpty { ContentUnavailableView.search(text: query) }
                ForEach(choices) { item in
                    Button {
                        add(item); dismiss()
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.name).foregroundStyle(.primary)
                            Text("\(item.kind) · \(item.location)").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Choose a Stop")
            .searchable(text: $query, prompt: "Places, stays, food or activities")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
    }
}
