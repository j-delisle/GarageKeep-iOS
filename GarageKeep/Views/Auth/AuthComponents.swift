import SwiftUI

// MARK: - AppTextField

struct AppTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    var isSecure: Bool = false
    var accessibilityID: String? = nil

    @State private var isRevealed = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(label)
                .font(.sectionHeader)
                .foregroundStyle(Color.textSecondary)

            ZStack {
                // surface-container-highest background — no border stroke per design rules
                RoundedRectangle(cornerRadius: Radius.input)
                    .fill(Color.appSurfaceElevated)

                HStack(spacing: Spacing.sm) {
                    Group {
                        if isSecure && !isRevealed {
                            SecureField(placeholder, text: $text)
                        } else {
                            TextField(placeholder, text: $text)
                                .keyboardType(keyboardType)
                        }
                    }
                    .textContentType(textContentType)
                    .font(.bodyMd)
                    .foregroundStyle(Color.textPrimary)
                    .tint(.appPrimary)
                    .accessibilityIdentifier(accessibilityID ?? "")

                    if isSecure {
                        Button {
                            isRevealed.toggle()
                        } label: {
                            Image(systemName: isRevealed ? "eye.slash" : "eye")
                                .foregroundStyle(Color.textSecondary)
                        }
                    }
                }
                .padding(.horizontal, Spacing.md)
            }
            .frame(height: 52)
        }
    }
}

// MARK: - PrimaryButton

struct PrimaryButton: View {
    let title: String
    var isLoading: Bool = false
    var accessibilityID: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: Radius.button)
                    .fill(LinearGradient.primaryCTA)

                if isLoading {
                    ProgressView()
                        .tint(.appBackground)
                } else {
                    Text(title)
                        .font(.buttonLabel)
                        .foregroundStyle(Color.appBackground)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
        }
        .disabled(isLoading)
        .accessibilityIdentifier(accessibilityID ?? "")
    }
}

// MARK: - SecondaryButton

struct SecondaryButton: View {
    let title: String
    var accessibilityID: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                // Ghost border per design: outline-variant at 20% opacity
                RoundedRectangle(cornerRadius: Radius.button)
                    .stroke(Color.appBorder.opacity(0.2), lineWidth: 1.5)

                Text(title)
                    .font(.buttonLabel)
                    .foregroundStyle(Color.appPrimary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
        }
        .accessibilityIdentifier(accessibilityID ?? "")
    }
}

// MARK: - SocialButton

struct SocialButton: View {
    let iconName: String
    let isSystemImage: Bool
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                if isSystemImage {
                    Image(systemName: iconName)
                        .font(.bodyMd.weight(.medium))
                } else {
                    Text(iconName)
                        .font(.titleSm.weight(.bold))
                }

                Text(title)
                    .font(.titleSm)
            }
            .foregroundStyle(Color.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: Radius.button)
                    .fill(Color.appSurfaceElevated)
            )
        }
    }
}

// MARK: - OrDivider

struct OrDivider: View {
    var body: some View {
        HStack(spacing: Spacing.md) {
            Rectangle()
                .fill(Color.appBorder.opacity(0.3))
                .frame(height: 1)
            Text("Or continue with")
                .font(.labelSm)
                .foregroundStyle(Color.textTertiary)
                .fixedSize()
            Rectangle()
                .fill(Color.appBorder.opacity(0.3))
                .frame(height: 1)
        }
    }
}

// MARK: - ErrorBanner

struct ErrorBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(Color.statusDanger)
            Text(message)
                .font(.bodyMd)
                .foregroundStyle(Color.textPrimary)
            Spacer()
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Radius.button)
                .fill(Color.statusDanger.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.button)
                        .stroke(Color.statusDanger.opacity(0.4), lineWidth: 1)
                )
        )
    }
}
