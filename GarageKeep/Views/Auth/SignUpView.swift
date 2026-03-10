import SwiftUI

struct SignUpView: View {
    @Binding var path: NavigationPath
    @Environment(AuthViewModel.self) private var authViewModel

    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    private var passwordsMatch: Bool {
        confirmPassword.isEmpty || password == confirmPassword
    }

    private var formIsValid: Bool {
        !fullName.isEmpty && !email.isEmpty && !password.isEmpty && password == confirmPassword
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    header
                    formSection
                    createAccountButton
                    Spacer(minLength: Spacing.xl)
                    loginFooter
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
            Text("Create Account")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.textSecondary)
                .textCase(.uppercase)
                .tracking(1)

            Text("Join GarageKeep")
                .font(.title.bold())
                .foregroundStyle(Color.textPrimary)

            Text("Keep your garage organised and your tools tracked.")
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
                label: "Full Name",
                placeholder: "John Doe",
                text: $fullName,
                textContentType: .name,
                accessibilityID: "field_full_name"
            )

            AppTextField(
                label: "Email Address",
                placeholder: "john@example.com",
                text: $email,
                keyboardType: .emailAddress,
                textContentType: .emailAddress,
                accessibilityID: "field_email"
            )

            AppTextField(
                label: "Password",
                placeholder: "••••••••",
                text: $password,
                textContentType: .newPassword,
                isSecure: true,
                accessibilityID: "field_password"
            )

            VStack(alignment: .leading, spacing: Spacing.xs) {
                AppTextField(
                    label: "Confirm Password",
                    placeholder: "••••••••",
                    text: $confirmPassword,
                    textContentType: .newPassword,
                    isSecure: true,
                    accessibilityID: "field_confirm_password"
                )

                if !passwordsMatch {
                    Text("Passwords don't match")
                        .font(.caption)
                        .foregroundStyle(Color.statusDanger)
                }
            }
        }
    }

    // MARK: - Create Account Button

    private var createAccountButton: some View {
        PrimaryButton(title: "Create Account →", isLoading: authViewModel.isLoading, accessibilityID: "btn_create_account") {
            Task { await authViewModel.register(email: email, password: password, name: fullName) }
        }
        .disabled(!formIsValid)
    }

    // MARK: - Footer

    private var loginFooter: some View {
        HStack {
            Spacer()
            Text("Already have an account? ")
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
            Button("Log In") {
                path = NavigationPath([AuthRoute.login])
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.appPrimary)
            .accessibilityIdentifier("link_log_in")
            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        SignUpView(path: .constant(NavigationPath()))
            .environment(AuthViewModel())
    }
}
