import SwiftUI

struct OnboardingContainerView: View {
    @State private var viewModel = AddVehicleViewModel()
    @Environment(\.dismiss) private var dismiss
    let onVehicleAdded: () -> Void

    var body: some View {
        ZStack {
            Color.appSurfaceElevated.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.top, Spacing.lg)
                    .padding(.horizontal, Spacing.md)

                stepIndicator
                    .padding(.top, Spacing.md)
                    .padding(.horizontal, Spacing.md)

                stepContent
                    .padding(.top, Spacing.lg)
                    .padding(.horizontal, Spacing.md)
                    .padding(.bottom, Spacing.lg)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(stepTitle)
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.textPrimary)
            Text(stepSubtitle)
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var stepTitle: String {
        switch viewModel.currentStep {
        case .identity: return "Add Your Vehicle"
        case .review:   return "Confirm Details"
        }
    }

    private var stepSubtitle: String {
        switch viewModel.currentStep {
        case .identity: return "Enter your VIN or fill in the details manually."
        case .review:   return "Review your vehicle before adding it to your garage."
        }
    }

    // MARK: - Step Indicator

    private var stepIndicator: some View {
        HStack(spacing: Spacing.sm) {
            stepDot(index: 0)
            Rectangle()
                .fill(viewModel.currentStep == .review ? Color.appPrimary : Color.appBorder)
                .frame(height: 2)
                .animation(.easeInOut, value: viewModel.currentStep)
            stepDot(index: 1)
        }
        .frame(maxWidth: .infinity)
    }

    private func stepDot(index: Int) -> some View {
        let isActive = (index == 0 && viewModel.currentStep == .identity) ||
                       (index == 1 && viewModel.currentStep == .review)
        let isDone   = index == 0 && viewModel.currentStep == .review
        return ZStack {
            Circle()
                .fill(isActive || isDone ? Color.appPrimary : Color.appBorder)
                .frame(width: 10, height: 10)
        }
        .animation(.easeInOut, value: viewModel.currentStep)
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case .identity:
            VehicleIdentityStepView(viewModel: viewModel)
        case .review:
            OnboardingReviewStepView(viewModel: viewModel) { vehicle in
                onVehicleAdded()
                dismiss()
            }
        }
    }
}

#Preview {
    OnboardingContainerView(onVehicleAdded: {})
}
