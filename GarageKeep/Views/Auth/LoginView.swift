import SwiftUI

struct LoginView: View {
    @Binding var path: NavigationPath
    @Environment(AuthViewModel.self) private var authViewModel

    @State private var email = ""
    @State private var password = ""

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    header
                    formSection
                    signInButton
                    OrDivider()
                    socialSection
                    Spacer(minLength: Spacing.xl)
                    createAccountFooter
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.lg)
                .padding(.bottom, Spacing.xxl)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                backButton
            }
        }
    }

    // MARK: - Back Button

    private var backButton: some View {
        Button {
            path.removeLast()
        } label: {
            Image(systemName: "chevron.left")
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.textPrimary)
        }
        .accessibilityIdentifier("btn_back")
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Log In")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.textSecondary)
                .textCase(.uppercase)
                .tracking(1)

            Text("Welcome back to\nGarageKeep")
                .font(.title.bold())
                .foregroundStyle(Color.textPrimary)

            Text("Enter your details to manage your collection.")
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
        }
    }

    // MARK: - Form

    private var formSection: some View {
        VStack(spacing: Spacing.md) {
            if let error = authViewModel.errorMessage {
                ErrorBanner(message: error)
            }

            AppTextField(
                label: "Email Address",
                placeholder: "your@email.com",
                text: $email,
                keyboardType: .emailAddress,
                textContentType: .emailAddress,
                accessibilityID: "field_email"
            )

            VStack(alignment: .trailing, spacing: Spacing.xs) {
                AppTextField(
                    label: "Password",
                    placeholder: "••••••••",
                    text: $password,
                    textContentType: .password,
                    isSecure: true,
                    accessibilityID: "field_password"
                )

                Button("Forgot password?") {}
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.appPrimary)
            }
        }
    }

    // MARK: - Sign In Button

    private var signInButton: some View {
        PrimaryButton(title: "Sign In", isLoading: authViewModel.isLoading, accessibilityID: "btn_sign_in") {
            Task { await authViewModel.login(email: email, password: password) }
        }
        .disabled(email.isEmpty || password.isEmpty)
    }

    // MARK: - Social

    private var socialSection: some View {
        HStack(spacing: Spacing.md) {
            SocialButton(iconName: "G", isSystemImage: false, title: "Google") {}
            SocialButton(iconName: "f.circle.fill", isSystemImage: true, title: "Facebook") {}
        }
    }

    // MARK: - Footer

    private var createAccountFooter: some View {
        HStack {
            Spacer()
            Text("Don't have an account? ")
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
            Button("Create Account") {
                path.append(AuthRoute.signUp)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.appPrimary)
            .accessibilityIdentifier("link_create_account")
            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        LoginView(path: .constant(NavigationPath()))
            .environment(AuthViewModel())
    }
}
