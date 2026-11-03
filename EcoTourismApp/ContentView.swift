import SwiftUI

struct ContentView: View {
    @Environment(AuthSession.self) private var session

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    ZStack(alignment: .bottomLeading) {
                        Image("victoria")
                            .resizable()
                            .scaledToFill()
                            .frame(height: 360)
                            .clipped()
                        LinearGradient(colors: [.clear, .black.opacity(0.8)], startPoint: .center, endPoint: .bottom)
                        VStack(alignment: .leading, spacing: 10) {
                            Label("SHANYA", systemImage: "leaf.fill")
                                .font(.subheadline.weight(.bold))
                            Text("A little closer\nto Zimbabwe.")
                                .font(.largeTitle.bold())
                        }
                        .foregroundStyle(.white)
                        .padding(24)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 30))
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Extraordinary places.\nLocal perspectives.")
                            .font(.title.bold())
                        Text("Discover places worth slowing down for, meet local guides, and plan a day that feels like yours.")
                            .foregroundStyle(.secondary)
                    }
                    Button("Start Exploring") { session.isBrowsing = true }
                        .buttonStyle(TravelPrimaryButton())
                    HStack {
                        NavigationLink("Log In") { AuthenticationForm(role: .tourist, isRegistration: false) }
                        Spacer()
                        NavigationLink("I'm a Tour Guide") { AuthenticationForm(role: .guide, isRegistration: true) }
                    }
                    .font(.subheadline.weight(.semibold))
                }
                .padding(20)
            }
            .background(TravelStyle.sand)
            .tint(TravelStyle.ink)
        }
    }
}

#Preview {
    ContentView().environment(AuthSession())
}
