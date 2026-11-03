import SwiftUI

struct NavigateTabView: View {
    @Environment(AuthSession.self) private var session

    var body: some View {
        TabView {
            if session.user?.role == .guide {
                GuideDashboard()
                    .tabItem { Label("Workspace", systemImage: "square.grid.2x2") }
                NavigationStack { BookingsView(isGuide: true) }
                    .tabItem { Label("Requests", systemImage: "tray") }
            } else {
                HomeScreen(userName: session.user?.name ?? "")
                    .tabItem { Label("Explore", systemImage: "safari") }
                NavigationStack { GuideDirectory() }
                    .tabItem { Label("Guides", systemImage: "person.2") }
                NavigationStack { BookingsView(isGuide: false) }
                    .tabItem { Label("My Trips", systemImage: "suitcase.rolling") }
                SavedPlacesView()
                    .tabItem { Label("Saved", systemImage: "bookmark") }
            }
            Profile()
                .tabItem { Label("You", systemImage: "person.crop.circle") }
        }
        .tint(TravelStyle.ink)
    }
}

#Preview {
    NavigateTabView().environment(AuthSession())
}
