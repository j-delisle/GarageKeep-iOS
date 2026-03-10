import SwiftUI

struct GarageView: View {
    @State private var viewModel = GarageViewModel()

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            content
        }
        .navigationTitle("Garage")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.appBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .task { await viewModel.fetchVehicles() }
        .sheet(isPresented: $viewModel.showOnboarding) {
            OnboardingContainerView {
                Task { await viewModel.fetchVehicles() }
            }
            .interactiveDismissDisabled(true)
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
                LazyVStack(spacing: Spacing.sm) {
                    ForEach(viewModel.vehicles, id: \.id) { vehicle in
                        VehicleRowView(vehicle: vehicle)
                    }
                }
                .padding(Spacing.md)
            }
        }
    }
}

#Preview {
    NavigationStack {
        GarageView()
    }
}
