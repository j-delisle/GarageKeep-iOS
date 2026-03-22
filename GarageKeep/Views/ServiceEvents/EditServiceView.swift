import SwiftUI

struct EditServiceView: View {
    @Bindable var viewModel: EditServiceViewModel
    @Environment(\.dismiss) private var dismiss
    let onUpdated: (ServiceEventResponse) -> Void

    init(event: ServiceEventResponse, onUpdated: @escaping (ServiceEventResponse) -> Void) {
        _viewModel = Bindable(EditServiceViewModel(event: event))
        self.onUpdated = onUpdated
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        detailsSection
                        metadataSection
                        notesSection
                            .padding(.bottom, 100) // space for sticky save button
                    }
                }
                .scrollDismissesKeyboard(.interactively)

                saveButton
            }
            .navigationTitle("Edit Service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.textSecondary)
                }
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
    }

    // MARK: - Details Section

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            FormSectionHeader(title: "DETAILS")

            VStack(spacing: 0) {
                ServiceFormRow(icon: "wrench.and.screwdriver", label: "SERVICE TYPE") {
                    serviceTypePicker
                }

                FormDivider()

                ServiceFormRow(icon: "calendar", label: "DATE") {
                    DatePicker(
                        "",
                        selection: $viewModel.serviceDate,
                        displayedComponents: .date
                    )
                    .labelsHidden()
                    .tint(.appPrimary)
                    .colorScheme(.dark)
                }

                FormDivider()

                ServiceFormRow(icon: "gauge.with.needle", label: "ODOMETER READING") {
                    HStack {
                        TextField("12450", text: $viewModel.mileageText)
                            .keyboardType(.numberPad)
                            .foregroundStyle(Color.textPrimary)
                            .tint(.appPrimary)
                        Text("MI")
                            .font(.sectionHeader)
                            .foregroundStyle(Color.textSecondary)
                    }
                }
            }
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.card))
            .padding(.horizontal, Spacing.md)
        }
    }

    private var serviceTypePicker: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Menu {
                ForEach(AddServiceViewModel.serviceTypeOptions, id: \.self) { option in
                    Button(option) {
                        viewModel.serviceTypePick = option
                        if option != "Other" {
                            viewModel.serviceTypeCustom = ""
                        }
                    }
                }
            } label: {
                HStack {
                    Text(viewModel.serviceTypePick.isEmpty ? "Select type..." : viewModel.serviceTypePick)
                        .font(.bodyMd)
                        .foregroundStyle(
                            viewModel.serviceTypePick.isEmpty ? Color.textSecondary : Color.textPrimary
                        )
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.textSecondary)
                }
            }
            .buttonStyle(.plain)

            if viewModel.serviceTypePick == "Other" {
                TextField("Describe the service...", text: $viewModel.serviceTypeCustom)
                    .font(.bodyMd)
                    .foregroundStyle(Color.textPrimary)
                    .tint(.appPrimary)
                    .padding(Spacing.sm)
                    .background(Color.appSurfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.input))
            }
        }
    }

    // MARK: - Metadata Section

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            FormSectionHeader(title: "METADATA")

            VStack(spacing: 0) {
                ServiceFormRow(icon: "dollarsign.circle", label: "TOTAL COST") {
                    HStack(spacing: 4) {
                        Text("$")
                            .font(.bodyMd)
                            .foregroundStyle(Color.textSecondary)
                        TextField("0.00", text: $viewModel.costText)
                            .keyboardType(.decimalPad)
                            .foregroundStyle(Color.textPrimary)
                            .tint(.appPrimary)
                    }
                }

                FormDivider()

                ServiceFormRow(icon: "building.2", label: "SERVICE CENTER") {
                    TextField("e.g. Precision Werkstatt", text: $viewModel.location)
                        .foregroundStyle(Color.textPrimary)
                        .tint(.appPrimary)
                }
            }
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.card))
            .padding(.horizontal, Spacing.md)
        }
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            FormSectionHeader(title: "SERVICE NOTES")

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: Radius.card)
                    .fill(Color.appSurface)

                if viewModel.notes.isEmpty {
                    Text("Add any details about the service performed, parts used, or future recommendations...")
                        .font(.bodyMd)
                        .foregroundStyle(Color.textSecondary)
                        .padding(Spacing.md)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $viewModel.notes)
                    .font(.bodyMd)
                    .foregroundStyle(Color.textPrimary)
                    .tint(.appPrimary)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 100)
                    .padding(Spacing.sm)
            }
            .padding(.horizontal, Spacing.md)
        }
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button {
            Task {
                if let updated = await viewModel.save() {
                    onUpdated(updated)
                    dismiss()
                }
            }
        } label: {
            Group {
                if viewModel.isLoading {
                    ProgressView().tint(Color.appBackground)
                } else {
                    Text("Save Changes")
                        .font(.buttonLabel)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(viewModel.canSave ? LinearGradient.primaryCTA : LinearGradient(colors: [.appSurfaceElevated], startPoint: .leading, endPoint: .trailing))
            .foregroundStyle(Color.appBackground)
            .clipShape(RoundedRectangle(cornerRadius: Radius.button))
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canSave || viewModel.isLoading)
        .padding(.horizontal, Spacing.outer)
        .padding(.bottom, Spacing.md)
    }
}

#Preview {
    EditServiceView(event: .stub) { _ in }
}
