import SwiftUI

struct VehicleIdentityStepView: View {
    @Bindable var viewModel: AddVehicleViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            modePicker

            if viewModel.inputMode == .vin {
                vinSection
            } else {
                manualSection
            }

            Spacer()

            PrimaryButton(
                title: "Continue",
                accessibilityID: "btn_continue"
            ) {
                viewModel.advanceToReview()
            }
            .disabled(!viewModel.canAdvanceFromIdentity)
            .opacity(viewModel.canAdvanceFromIdentity ? 1 : 0.4)
        }
    }

    // MARK: - Mode Picker

    private var modePicker: some View {
        HStack(spacing: 0) {
            modeTab(title: "VIN", mode: .vin)
            modeTab(title: "Manual", mode: .manual)
        }
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.button))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.button)
                .stroke(Color.appBorder, lineWidth: 1)
        )
    }

    private func modeTab(title: String, mode: AddVehicleViewModel.InputMode) -> some View {
        let isSelected = viewModel.inputMode == mode
        return Button {
            viewModel.switchMode(to: mode)
        } label: {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? Color.appBackground : Color.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(
                    isSelected
                        ? RoundedRectangle(cornerRadius: Radius.button).fill(Color.appPrimary)
                        : RoundedRectangle(cornerRadius: Radius.button).fill(Color.clear)
                )
        }
        .padding(3)
        .animation(.easeInOut(duration: 0.15), value: viewModel.inputMode)
    }

    // MARK: - VIN Section

    private var vinSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            AppTextField(
                label: "VIN",
                placeholder: "Enter 17-character VIN",
                text: $viewModel.vinInput,
                accessibilityID: "field_vin"
            )
            .onChange(of: viewModel.vinInput) {
                viewModel.vinDecoded = nil
                viewModel.decodeError = nil
            }

            if let error = viewModel.decodeError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(Color.statusDanger)
            }

            if let decoded = viewModel.vinDecoded {
                decodedSummaryCard(decoded)
            } else {
                Button {
                    Task { await viewModel.decodeVin() }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: Radius.button)
                            .stroke(Color.appPrimary, lineWidth: 1.5)
                        if viewModel.isDecoding {
                            ProgressView().tint(.appPrimary)
                        } else {
                            Text("Decode VIN")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(Color.appPrimary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                }
                .disabled(viewModel.vinInput.count != 17 || viewModel.isDecoding)
                .opacity(viewModel.vinInput.count == 17 ? 1 : 0.4)
                .accessibilityIdentifier("btn_decode_vin")
            }
        }
    }

    private func decodedSummaryCard(_ decoded: VinDecodeResponse) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.statusSuccess)
                .font(.title3)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("\(decoded.year.map { String($0) } ?? "—") \(decoded.make) \(decoded.model)")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)
                Text("VIN decoded successfully")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer()
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Radius.card)
                .fill(Color.statusSuccess.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.card)
                        .stroke(Color.statusSuccess.opacity(0.3), lineWidth: 1)
                )
        )
        .accessibilityIdentifier("card_vin_decoded")
    }

    // MARK: - Manual Section

    private var manualSection: some View {
        VStack(spacing: Spacing.md) {
            AppTextField(
                label: "Make",
                placeholder: "e.g. Toyota",
                text: $viewModel.make,
                accessibilityID: "field_make"
            )
            AppTextField(
                label: "Model",
                placeholder: "e.g. Camry",
                text: $viewModel.model,
                accessibilityID: "field_model"
            )
            AppTextField(
                label: "Year (optional)",
                placeholder: "e.g. 2023",
                text: $viewModel.year,
                keyboardType: .numberPad,
                accessibilityID: "field_year"
            )
        }
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        VehicleIdentityStepView(viewModel: AddVehicleViewModel())
            .padding(Spacing.md)
    }
}
