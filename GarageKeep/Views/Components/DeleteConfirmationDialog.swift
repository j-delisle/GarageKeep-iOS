import SwiftUI

// MARK: - DeleteConfirmationDialog

struct DeleteConfirmationDialog: View {
    @Binding var isPresented: Bool
    let title: String
    let message: String
    let isLoading: Bool
    let onDelete: () -> Void

    init(
        isPresented: Binding<Bool>,
        title: String = "Delete?",
        message: String = "This action cannot be undone.",
        isLoading: Bool = false,
        onDelete: @escaping () -> Void
    ) {
        _isPresented = isPresented
        self.title = title
        self.message = message
        self.isLoading = isLoading
        self.onDelete = onDelete
    }

    var body: some View {
        ZStack {
            // Dim overlay
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { if !isLoading { isPresented = false } }

            // Dialog card
            VStack(spacing: 0) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.tertiary.opacity(0.15))
                        .frame(width: 56, height: 56)
                    Image(systemName: "trash")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Color.tertiary)
                }
                .padding(.top, Spacing.lg)
                .padding(.bottom, Spacing.md)

                // Title
                Text(title)
                    .font(.titleMd)
                    .foregroundStyle(Color.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.lg)

                // Message
                Text(message)
                    .font(.bodyMd)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.xs)
                    .padding(.bottom, Spacing.lg)

                // Divider
                Color.appBackground
                    .frame(height: 1)

                // Buttons
                HStack(spacing: 0) {
                    // Cancel
                    Button {
                        isPresented = false
                    } label: {
                        Text("Cancel")
                            .font(.buttonLabel)
                            .foregroundStyle(Color.textSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                    }
                    .buttonStyle(.plain)
                    .disabled(isLoading)

                    // Vertical divider
                    Color.appBackground
                        .frame(width: 1, height: 52)

                    // Delete
                    Button {
                        onDelete()
                    } label: {
                        Group {
                            if isLoading {
                                ProgressView().tint(Color.tertiary)
                            } else {
                                Text("Delete")
                                    .font(.buttonLabel)
                                    .foregroundStyle(Color.tertiary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                    }
                    .buttonStyle(.plain)
                    .disabled(isLoading)
                }
            }
            .background(Color.appSurfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: Radius.card))
            .padding(.horizontal, Spacing.xl)
            .shadow(color: .black.opacity(0.4), radius: 32, x: 0, y: 8)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
}

// MARK: - ViewModifier

private struct DeleteConfirmationDialogModifier: ViewModifier {
    @Binding var isPresented: Bool
    let title: String
    let message: String
    let isLoading: Bool
    let onDelete: () -> Void

    func body(content: Content) -> some View {
        content
            .overlay {
                if isPresented {
                    DeleteConfirmationDialog(
                        isPresented: $isPresented,
                        title: title,
                        message: message,
                        isLoading: isLoading,
                        onDelete: onDelete
                    )
                    .animation(.spring(duration: 0.25), value: isPresented)
                }
            }
            .animation(.spring(duration: 0.25), value: isPresented)
    }
}

extension View {
    func deleteConfirmationDialog(
        isPresented: Binding<Bool>,
        title: String = "Delete?",
        message: String = "This action cannot be undone.",
        isLoading: Bool = false,
        onDelete: @escaping () -> Void
    ) -> some View {
        modifier(DeleteConfirmationDialogModifier(
            isPresented: isPresented,
            title: title,
            message: message,
            isLoading: isLoading,
            onDelete: onDelete
        ))
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        Text("Content behind dialog")
            .foregroundStyle(Color.textSecondary)
    }
    .deleteConfirmationDialog(
        isPresented: .constant(true),
        title: "Delete Service Record?",
        message: "This will permanently remove this service record and all its attachments. This cannot be undone.",
        onDelete: {}
    )
}
