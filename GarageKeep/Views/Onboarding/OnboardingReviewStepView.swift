import SwiftUI

struct OnboardingReviewStepView: View {
    @Bindable var viewModel: AddVehicleViewModel
    let onSuccess: (VehicleResponse) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            summaryCard

            if let error = viewModel.errorMessage {
                ErrorBanner(message: error)
            }

            Spacer()

            VStack(spacing: Spacing.sm) {
                PrimaryButton(
                    title: "Add to Garage",
                    isLoading: viewModel.isLoading,
                    accessibilityID: "btn_add_vehicle"
                ) {
                    Task {
                        if let vehicle = await viewModel.submit() {
                            onSuccess(vehicle)
                        }
                    }
                }

                SecondaryButton(title: "Go Back", accessibilityID: "btn_go_back") {
                    viewModel.backToIdentity()
                }
            }
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Vehicle Details")
                .font(.sectionHeader)
                .foregroundStyle(Color.textSecondary)
                .textCase(.uppercase)

            VStack(spacing: 0) {
                detailRow(label: "Make", value: viewModel.resolvedMake)
                Color.appBackground.opacity(0.5).frame(height: 1).padding(.leading, Spacing.md)
                detailRow(label: "Model", value: viewModel.resolvedModel)
                if let year = viewModel.resolvedYear {
                    Color.appBackground.opacity(0.5).frame(height: 1).padding(.leading, Spacing.md)
                    detailRow(label: "Year", value: String(year))
                }
                if let vin = viewModel.resolvedVin {
                    Color.appBackground.opacity(0.5).frame(height: 1).padding(.leading, Spacing.md)
                    detailRow(label: "VIN", value: vin)
                }
            }
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.card))
        }
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.bodyMd)
                .foregroundStyle(Color.textSecondary)
            Spacer()
            Text(value)
                .font(.bodyMd.weight(.medium))
                .foregroundStyle(Color.textPrimary)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm + 2)
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        let vm: AddVehicleViewModel = {
            let v = AddVehicleViewModel()
            v.inputMode = .manual
            v.make = "Toyota"
            v.model = "Camry"
            v.year = "2023"
            return v
        }()
        OnboardingReviewStepView(viewModel: vm) { _ in }
            .padding(Spacing.md)
    }
}
