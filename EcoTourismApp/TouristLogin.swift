import SwiftUI

struct TouristLogin: View {
    var body: some View {
        AuthenticationForm(role: .tourist, isRegistration: false)
    }
}

#Preview {
    NavigationStack {
        TouristLogin()
    }
    .environment(AuthSession())
}
