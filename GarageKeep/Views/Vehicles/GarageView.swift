import SwiftUI

struct GarageView: View {
    @State private var viewModel = GarageViewModel()

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.appBackground.ignoresSafeArea()
            content
            AddVehicleFAB {
                viewModel.showOnboarding = true
            }
            .padding(.trailing, Spacing.md)
            .padding(.bottom, Spacing.md)
        }
        .toolbarBackground(Color.appBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .task {
            if CommandLine.arguments.contains("--mock-vehicles") {
                viewModel.loadMockVehicles()
            } else {
                await viewModel.fetchVehicles()
            }
        }
        .sheet(isPresented: $viewModel.showOnboarding) {
            OnboardingContainerView(vehicleCount: viewModel.vehicles.count) {
                Task { await viewModel.fetchVehicles() }
            }
            .interactiveDismissDisabled(viewModel.vehicles.isEmpty)
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            ProgressView()
                .tint(.appPrimary)
        } else if let error = viewModel.errorMessage {
            VStack(spacing: Spacing.md) {
                Text("Failed to load garage")
                    .foregroundStyle(Color.textPrimary)
                    .font(.body.weight(.semibold))
                Text(error)
                    .foregroundStyle(Color.textSecondary)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                PrimaryButton(title: "Retry") {
                    Task { await viewModel.fetchVehicles() }
                }
                .frame(maxWidth: 200)
            }
            .padding(Spacing.md)
        } else if viewModel.vehicles.isEmpty {
            EmptyGarageView {
                viewModel.showOnboarding = true
            }
        } else {
            ScrollView {
                LazyVStack(spacing: Spacing.md) {
                    ForEach(viewModel.vehicles, id: \.id) { vehicle in
                        NavigationLink(destination: ServiceHistoryView(vehicle: vehicle)) {
                            VehicleCardView(vehicle: vehicle)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, Spacing.md)
                    }
                }
                .padding(.vertical, Spacing.md)
            }
        }
    }
}

private struct AddVehicleFAB: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color.appBackground)
                .frame(width: 56, height: 56)
                .background(LinearGradient.primaryCTA)
                .clipShape(Circle())
                .shadow(color: Color.appPrimary.opacity(0.3), radius: 24, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("btn_add_vehicle")
    }
}

#Preview {
    NavigationStack {
        GarageView()
    }
}
