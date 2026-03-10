import SwiftUI

enum AuthRoute: Hashable {
    case login
    case signUp
}

struct AuthContainerView: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            WelcomeView(path: $path)
                .navigationDestination(for: AuthRoute.self) { route in
                    switch route {
                    case .login:  LoginView(path: $path)
                    case .signUp: SignUpView(path: $path)
                    }
                }
        }
        .tint(.appPrimary)
    }
}

#Preview {
    AuthContainerView()
        .environment(AuthViewModel())
}
