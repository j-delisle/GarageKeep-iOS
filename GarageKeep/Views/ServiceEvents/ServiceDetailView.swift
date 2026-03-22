import SwiftUI
import SafariServices

struct ServiceDetailView: View {
    @State private var viewModel: ServiceDetailViewModel
    @State private var showEditSheet = false
    @State private var showDeleteConfirm = false
    @State private var attachmentToOpen: IdentifiableURL?
    @Environment(\.dismiss) private var dismiss

    let onDeleted: () -> Void
    let onUpdated: (ServiceEventResponse) -> Void

    init(
        event: ServiceEventResponse,
        vehicle: VehicleResponse,
        previousMileage: Int?,
        onDeleted: @escaping () -> Void,
        onUpdated: @escaping (ServiceEventResponse) -> Void
    ) {
        _viewModel = State(initialValue: ServiceDetailViewModel(
            event: event,
            vehicle: vehicle,
            previousMileage: previousMileage
        ))
        self.onDeleted = onDeleted
        self.onUpdated = onUpdated
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    heroSection
                    statCardsRow
                    serviceDetailsSection
                    documentationSection
                    Color.clear.frame(height: Spacing.xl)
                }
                .padding(.horizontal, Spacing.outer)
            }

            bottomBar
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle("Service Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.appBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .task { await viewModel.loadAttachments() }
        .deleteConfirmationDialog(
            isPresented: $showDeleteConfirm,
            title: "Delete Service Record?",
            message: "This will permanently remove this service record and all its attachments. This cannot be undone.",
            isLoading: viewModel.isDeleting,
            onDelete: {
                Task {
                    await viewModel.delete {
                        onDeleted()
                        dismiss()
                    }
                }
            }
        )
        .sheet(isPresented: $showEditSheet) {
            EditServiceView(event: viewModel.event) { updated in
                viewModel.event = updated
                onUpdated(updated)
            }
        }
        .sheet(item: $attachmentToOpen) { item in
            SafariView(url: item.url)
                .ignoresSafeArea()
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(viewModel.event.serviceType)
                .font(.headlineMd)
                .foregroundStyle(Color.textPrimary)

            HStack(spacing: Spacing.xs) {
                Text(viewModel.formattedDate)
                Text("•")
                Text(viewModel.vehicleTitle)
            }
            .font(.bodyMd)
            .foregroundStyle(Color.textSecondary)
        }
        .padding(.top, Spacing.lg)
        .padding(.bottom, Spacing.md)
    }

    // MARK: - Stat Cards

    private var statCardsRow: some View {
        HStack(spacing: Spacing.md) {
            DetailStatCard(label: "TOTAL COST") {
                Text(viewModel.formattedCost ?? "—")
                    .font(.displaySm)
                    .foregroundStyle(Color.textPrimary)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }

            DetailStatCard(label: "ODOMETER") {
                VStack(alignment: .leading, spacing: 3) {
                    Text(viewModel.formattedMileage ?? "—")
                        .font(.displaySm)
                        .foregroundStyle(Color.textPrimary)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)

                    if let delta = viewModel.formattedMileageDelta {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(Color.appPrimary)
                            Text(delta)
                                .font(.labelSm)
                                .foregroundStyle(Color.appPrimary)
                        }
                    }
                }
            }
        }
        .padding(.bottom, Spacing.md)
    }

    // MARK: - Service Details

    @ViewBuilder
    private var serviceDetailsSection: some View {
        let hasLocation = viewModel.event.location != nil
        let hasNotes = viewModel.event.notes != nil

        if hasLocation || hasNotes {
            detailSectionHeader("Service Details")

            VStack(spacing: 0) {
                if let location = viewModel.event.location {
                    DetailInfoRow(icon: "building.2", label: "SERVICE CENTER", value: location)
                }
                if hasLocation && hasNotes {
                    FormDivider()
                }
                if let notes = viewModel.event.notes {
                    DetailInfoRow(icon: "doc.text", label: "TECH NOTES", value: notes)
                }
            }
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.card))
            .padding(.bottom, Spacing.md)
        }
    }

    // MARK: - Documentation

    @ViewBuilder
    private var documentationSection: some View {
        if viewModel.isLoadingAttachments {
            ProgressView()
                .tint(.appPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
        } else if !viewModel.attachments.isEmpty {
            detailSectionHeader("Documentation")

            VStack(spacing: Spacing.sm) {
                ForEach(viewModel.attachments) { attachment in
                    AttachmentRowView(attachment: attachment) {
                        Task {
                            if let url = await viewModel.getDownloadUrl(for: attachment) {
                                attachmentToOpen = IdentifiableURL(url: url)
                            }
                        }
                    }
                }
            }
            .padding(.bottom, Spacing.md)
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack(spacing: Spacing.md) {
            Button { showEditSheet = true } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "pencil")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Edit Service")
                        .font(.buttonLabel)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(LinearGradient.primaryCTA)
                .foregroundStyle(Color.appBackground)
                .clipShape(RoundedRectangle(cornerRadius: Radius.button))
            }
            .buttonStyle(.plain)

            Button { showDeleteConfirm = true } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "trash")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Delete")
                        .font(.buttonLabel)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.appSurfaceElevated)
                .foregroundStyle(Color.tertiary)
                .clipShape(RoundedRectangle(cornerRadius: Radius.button))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Spacing.outer)
        .padding(.vertical, Spacing.md)
        .background(Color.appBackground)
    }

    // MARK: - Helpers

    private func detailSectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.titleSm)
            .foregroundStyle(Color.appPrimary)
            .padding(.bottom, Spacing.sm)
            .padding(.top, Spacing.xs)
    }
}

// MARK: - Detail Stat Card

private struct DetailStatCard<Content: View>: View {
    let label: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(label)
                .font(.labelSm)
                .foregroundStyle(Color.textSecondary)
                .tracking(0.5)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.card))
    }
}

// MARK: - Detail Info Row

private struct DetailInfoRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.appSurfaceContainerHigh)
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.textSecondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.labelSm)
                    .foregroundStyle(Color.textSecondary)
                    .tracking(0.3)
                Text(value)
                    .font(.bodyMd)
                    .foregroundStyle(Color.textPrimary)
            }

            Spacer()
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, 14)
    }
}

// MARK: - Attachment Row

private struct AttachmentRowView: View {
    let attachment: AttachmentResponse
    let onTap: () -> Void

    private var isPDF: Bool {
        attachment.fileType.lowercased().contains("pdf") ||
        attachment.fileName.lowercased().hasSuffix(".pdf")
    }

    private var displayName: String {
        isPDF ? "Service Report" : "View Receipt"
    }

    private var fileSizeText: String? {
        guard let size = attachment.fileSize else { return nil }
        if size >= 1_000_000 {
            return String(format: "%.1fMB", Double(size) / 1_000_000)
        } else if size >= 1_000 {
            return String(format: "%.0fKB", Double(size) / 1_000)
        }
        return "\(size)B"
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: Radius.input)
                        .fill(Color.appSurfaceContainerHigh)
                        .frame(width: 56, height: 56)
                    Image(systemName: isPDF ? "doc.fill" : "photo.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(isPDF ? Color.tertiary : Color.appPrimary)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(displayName)
                        .font(.titleSm)
                        .foregroundStyle(Color.textPrimary)
                    HStack(spacing: 4) {
                        Text(attachment.fileName)
                            .font(.labelSm)
                            .foregroundStyle(Color.textSecondary)
                            .lineLimit(1)
                        if let size = fileSizeText {
                            Text("• \(size)")
                                .font(.labelSm)
                                .foregroundStyle(Color.textSecondary)
                        }
                    }
                }

                Spacer()

                Image(systemName: isPDF ? "arrow.down.circle" : "arrow.up.right.square")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.textSecondary)
            }
            .padding(Spacing.md)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.card))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Safari View

private struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

// MARK: - Identifiable URL wrapper

private struct IdentifiableURL: Identifiable {
    let id = UUID()
    let url: URL
}

#Preview {
    NavigationStack {
        ServiceDetailView(
            event: .stub,
            vehicle: .stubWithVin,
            previousMileage: 11200,
            onDeleted: {},
            onUpdated: { _ in }
        )
    }
}
