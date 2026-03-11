import SwiftUI

struct GarageView: View {
    @State private var viewModel = GarageViewModel()

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            content
        }
        .toolbarBackground(Color.appBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                GarageToolbarButton(systemImage: "person.fill") {}
                    .accessibilityIdentifier("btn_profile")
            }
            ToolbarItem(placement: .principal) {
                Text("Garage")
                    .font(.system(.title3, design: .default, weight: .bold))
                    .foregroundStyle(Color.textPrimary)
            }
            ToolbarItem(placement: .topBarTrailing) {
                GarageToolbarButton(systemImage: "plus") {
                    viewModel.showOnboarding = true
                }
                .accessibilityIdentifier("btn_add_vehicle")
            }
        }
        .task {
            if CommandLine.arguments.contains("--mock-vehicles") {
                viewModel.loadMockVehicles()
            } else {
                await viewModel.fetchVehicles()
            }
        }
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
                LazyVStack(spacing: Spacing.md) {
                    ForEach(viewModel.vehicles, id: \.id) { vehicle in
                        NavigationLink(destination: Text("Detail — TODO")) {
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

private struct GarageToolbarButton: View {
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.appBackground)
                .frame(width: 34, height: 34)
                .background(Color.appPrimary)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        GarageView()
    }
}
