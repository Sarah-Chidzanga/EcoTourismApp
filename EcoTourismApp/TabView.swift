import SwiftUI

struct NavigateTabView: View {
    @Environment(AuthSession.self) private var session

    var body: some View {
        TabView {
            if session.user?.role == .guide {
                GuideDashboard()
                    .tabItem { Label("Dashboard", systemImage: "mountain.2") }
            } else {
                HomeScreen(userName: session.user?.name ?? "")
                    .tabItem { Label("Home", systemImage: "house") }
            }
            Profile()
                .tabItem { Label("Profile", systemImage: "person") }
            Settings()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
        .tint(.brown)
    }
}

struct GuideDashboard: View {
    @Environment(AuthSession.self) private var session

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "mountain.2.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.brown)
                Text("Welcome, \(session.user?.name ?? "")")
                    .font(.title.bold())
                Text("Your guide account is ready.")
                Text("Booking requests and availability management are coming next.")
                    .foregroundStyle(.secondary)
                NavigationLink("View Your Profile") { Profile() }
            }
            .multilineTextAlignment(.center)
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.background.ignoresSafeArea())
            .navigationTitle("Guide Dashboard")
        }
    }
}

#Preview {
    NavigateTabView()
        .environment(AuthSession())
}
