import SwiftUI

struct AddServiceDetailsStepView: View {
    @Bindable var viewModel: AddServiceViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                vehicleHeader
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.md)
                    .padding(.bottom, Spacing.lg)

                detailsSection
                metadataSection
                notesSection
                    .padding(.bottom, Spacing.xl)
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: - Vehicle Header

    private var vehicleHeader: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: Radius.button)
                    .fill(Color.appPrimary.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: "car.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.appPrimary)
            }
            VStack(alignment: .leading, spacing: 3) {
                let yearStr = viewModel.vehicle.year.map { "\($0) " } ?? ""
                Text("\(yearStr)\(viewModel.vehicle.make) \(viewModel.vehicle.model)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                if let plate = viewModel.vehicle.licensePlate {
                    Text(plate)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.textSecondary)
                }
            }
            Spacer()
        }
        .padding(Spacing.md)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.card))
    }

    // MARK: - Details Section

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            FormSectionHeader(title: "DETAILS")

            VStack(spacing: 0) {
                // Service Type
                ServiceFormRow(
                    icon: "wrench.and.screwdriver",
                    label: "SERVICE TYPE"
                ) {
                    serviceTypePicker
                }

                FormDivider()

                // Date
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

                // Odometer
                ServiceFormRow(icon: "gauge.with.needle", label: "ODOMETER READING") {
                    HStack {
                        TextField("12450", text: $viewModel.mileageText)
                            .keyboardType(.numberPad)
                            .foregroundStyle(Color.textPrimary)
                            .tint(.appPrimary)
                        Text("MI")
                            .font(.system(size: 13, weight: .semibold))
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
                        .font(.system(size: 16))
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
                    .font(.system(size: 15))
                    .foregroundStyle(Color.textPrimary)
                    .tint(.appPrimary)
                    .padding(Spacing.sm)
                    .background(Color.appSurfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.button))
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.button)
                            .stroke(Color.appBorder, lineWidth: 1)
                    )
            }
        }
    }

    // MARK: - Metadata Section

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            FormSectionHeader(title: "METADATA")

            VStack(spacing: 0) {
                // Total Cost
                ServiceFormRow(icon: "dollarsign.circle", label: "TOTAL COST") {
                    HStack(spacing: 4) {
                        Text("$")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.textSecondary)
                        TextField("0.00", text: $viewModel.costText)
                            .keyboardType(.decimalPad)
                            .foregroundStyle(Color.textPrimary)
                            .tint(.appPrimary)
                    }
                }

                FormDivider()

                // Service Center / Location
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
                        .font(.system(size: 14))
                        .foregroundStyle(Color.textSecondary)
                        .padding(Spacing.md)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $viewModel.notes)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.textPrimary)
                    .tint(.appPrimary)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 100)
                    .padding(Spacing.sm)
            }
            .padding(.horizontal, Spacing.md)
        }
    }
}

// MARK: - Shared Form Components

struct FormSectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(Color.textSecondary)
            .tracking(0.5)
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.lg)
            .padding(.bottom, Spacing.sm)
    }
}

struct FormDivider: View {
    var body: some View {
        Divider()
            .background(Color.appBorder)
            .padding(.leading, 48)
    }
}

struct ServiceFormRow<Content: View>: View {
    let icon: String
    let label: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Color.textSecondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)
                    .tracking(0.3)
                content()
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, 14)
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        let vm: AddServiceViewModel = {
            let v = AddServiceViewModel(vehicle: .stubWithVin)
            return v
        }()
        AddServiceDetailsStepView(viewModel: vm)
    }
}
