import SwiftUI

struct WelcomeView: View {
    @Binding var path: NavigationPath

    var body: some View {
        ZStack(alignment: .top) {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                heroSection
                contentSection
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Hero

    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            // Background gradient (placeholder for actual car photo asset)
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "1A2A2A"), Color(hex: "0A1A1A")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Decorative teal glow
                Circle()
                    .fill(Color.appPrimary.opacity(0.08))
                    .frame(width: 280, height: 280)
                    .offset(x: 60, y: -30)

                Image(systemName: "car.fill")
                    .font(.system(size: 100, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.appPrimary.opacity(0.9), .appPrimary.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .offset(x: 20, y: 20)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 300)

            // Fade to background at bottom
            LinearGradient(
                colors: [.clear, .appBackground],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 120)

            // App logo overlaid bottom-left
            appLogo
                .padding(.horizontal, Spacing.md)
                .padding(.bottom, Spacing.lg)
        }
    }

    private var appLogo: some View {
        HStack(spacing: Spacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.appPrimary)
                    .frame(width: 36, height: 36)
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.appBackground)
            }
            Text("GarageKeep")
                .font(.title3.bold())
                .foregroundStyle(Color.textPrimary)
        }
    }

    // MARK: - Content

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Welcome Back")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color.textPrimary)

                Text("Your premium garage management suite.\nControl, monitor, and maintain your collection with ease.")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: Spacing.md) {
                PrimaryButton(title: "Get Started", accessibilityID: "btn_get_started") {
                    path.append(AuthRoute.signUp)
                }

                SecondaryButton(title: "Log In", accessibilityID: "btn_log_in") {
                    path.append(AuthRoute.login)
                }
            }

            OrDivider()

            HStack(spacing: Spacing.md) {
                SocialButton(iconName: "G", isSystemImage: false, title: "Google") {}
                SocialButton(iconName: "apple.logo", isSystemImage: true, title: "Apple") {}
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.bottom, Spacing.xxl)
    }
}

#Preview {
    AuthContainerView()
        .environment(AuthViewModel())
}
