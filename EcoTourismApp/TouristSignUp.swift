import SwiftUI

struct TouristSignUp: View {
    var body: some View {
        AuthenticationForm(role: .tourist, isRegistration: true)
    }
}

#Preview {
    NavigationStack {
        TouristSignUp()
    }
    .environment(AuthSession())
}
