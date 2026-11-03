import SwiftUI

struct TourGuideLogin: View {
    var body: some View {
        AuthenticationForm(role: .guide, isRegistration: false)
    }
}

#Preview {
    NavigationStack {
        TourGuideLogin()
    }
    .environment(AuthSession())
}
