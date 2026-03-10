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
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.textSecondary)
                .textCase(.uppercase)

            VStack(spacing: 0) {
                detailRow(label: "Make", value: viewModel.resolvedMake)
                Divider().background(Color.appBorder)
                detailRow(label: "Model", value: viewModel.resolvedModel)
                if let year = viewModel.resolvedYear {
                    Divider().background(Color.appBorder)
                    detailRow(label: "Year", value: String(year))
                }
                if let vin = viewModel.resolvedVin {
                    Divider().background(Color.appBorder)
                    detailRow(label: "VIN", value: vin)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: Radius.card)
                    .fill(Color.appSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.card)
                            .stroke(Color.appBorder, lineWidth: 1)
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: Radius.card))
        }
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
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
