import SwiftUI

struct AddServiceContainerView: View {
    @State private var viewModel: AddServiceViewModel
    @Environment(\.dismiss) private var dismiss
    let onServiceAdded: (ServiceEventResponse) -> Void

    init(vehicle: VehicleResponse, onServiceAdded: @escaping (ServiceEventResponse) -> Void) {
        _viewModel = State(initialValue: AddServiceViewModel(vehicle: vehicle))
        self.onServiceAdded = onServiceAdded
    }

    var body: some View {
        NavigationStack {
            stepContent
                .background(Color.appBackground.ignoresSafeArea())
                .safeAreaInset(edge: .top) {
                    stepIndicator
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.xs)
                        .background(Color.appBackground)
                }
                .safeAreaInset(edge: .bottom) {
                    bottomNavBar
                }
                .animation(.easeInOut(duration: 0.2), value: viewModel.currentStep)
                .navigationTitle(stepTitle)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden()
                .toolbarBackground(Color.appBackground, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        if viewModel.currentStep == .details {
                            Button("Cancel") { dismiss() }
                                .foregroundStyle(Color.appPrimary)
                        }
                    }
                }
        }
        .tint(.appPrimary)
    }

    private var stepTitle: String {
        switch viewModel.currentStep {
        case .details: return "Add Service"
        case .receipt: return "Upload Receipt"
        case .review:  return "Review"
        }
    }

    // MARK: - Step Indicator

    private var stepIndicator: some View {
        HStack(spacing: Spacing.sm) {
            stepDot(index: 0)
            stepConnector(active: currentStepIndex > 0)
            stepDot(index: 1)
            stepConnector(active: currentStepIndex > 1)
            stepDot(index: 2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xs)
    }

    private func stepDot(index: Int) -> some View {
        let isActive = currentStepIndex == index
        let isDone   = currentStepIndex > index
        return Circle()
            .fill(isActive || isDone ? Color.appPrimary : Color.appBorder)
            .frame(width: 10, height: 10)
            .animation(.easeInOut, value: viewModel.currentStep)
            .accessibilityHidden(true)
    }

    private func stepConnector(active: Bool) -> some View {
        Rectangle()
            .fill(active ? Color.appPrimary : Color.appBorder)
            .frame(height: 2)
            .animation(.easeInOut, value: viewModel.currentStep)
    }

    private var currentStepIndex: Int {
        switch viewModel.currentStep {
        case .details: return 0
        case .receipt: return 1
        case .review:  return 2
        }
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case .details:
            AddServiceDetailsStepView(viewModel: viewModel)
        case .receipt:
            AddServiceReceiptStepView(viewModel: viewModel)
        case .review:
            AddServiceReviewStepView(viewModel: viewModel)
        }
    }

    // MARK: - Bottom Navigation Bar

    private var bottomNavBar: some View {
        HStack(spacing: Spacing.sm) {
            if viewModel.currentStep != .details {
                backButton
            }
            primaryActionButton
        }
        .padding(.horizontal, Spacing.md)
        .padding(.top, Spacing.md)
        .padding(.bottom, Spacing.lg)
        .background(Color.appBackground)
        .overlay(Rectangle().fill(Color.appBorder).frame(height: 1), alignment: .top)
    }

    private var backButton: some View {
        Button {
            viewModel.back()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 13, weight: .semibold))
                Text("Back")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(Color.appPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: Radius.button)
                    .stroke(Color.appPrimary, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var primaryActionButton: some View {
        if viewModel.currentStep == .review {
            Button {
                Task {
                    if let event = await viewModel.submit() {
                        onServiceAdded(event)
                        dismiss()
                    }
                }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: Radius.button)
                        .fill(Color.appPrimary)
                    if viewModel.isLoading {
                        ProgressView().tint(.appBackground)
                    } else {
                        Text("Confirm & Save")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.appBackground)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isLoading)
            .accessibilityIdentifier("btn_confirm_save")
        } else {
            Button {
                viewModel.advance()
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: Radius.button)
                        .fill(
                            viewModel.currentStep == .details && !viewModel.canAdvanceFromDetails
                                ? Color.appPrimary.opacity(0.3)
                                : Color.appPrimary
                        )
                    Text("Next")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.appBackground)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.currentStep == .details && !viewModel.canAdvanceFromDetails)
        }
    }
}

#Preview {
    AddServiceContainerView(vehicle: .stubWithVin) { _ in }
}
