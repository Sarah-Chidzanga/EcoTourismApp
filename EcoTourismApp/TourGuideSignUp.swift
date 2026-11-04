import SwiftUI

struct TourGuideSignUp: View {
    var body: some View {
        AuthenticationForm(role: .guide, isRegistration: true)
    }
}

#Preview {
    NavigationStack {
        TourGuideSignUp()
    }
    .environment(AuthSession())
}
