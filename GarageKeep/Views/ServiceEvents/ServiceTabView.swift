import SwiftUI

struct ServiceTabView: View {
    @State private var viewModel = GarageViewModel()

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            content
        }
        .navigationTitle("Service")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.appBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .task {
            if CommandLine.arguments.contains("--mock-vehicles") {
                viewModel.loadMockVehicles()
            } else {
                await viewModel.fetchVehicles()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            ProgressView()
                .tint(.appPrimary)
        } else if let error = viewModel.errorMessage {
            errorView(message: error)
        } else if viewModel.vehicles.isEmpty {
            EmptyGarageView { }
        } else if viewModel.vehicles.count == 1, let vehicle = viewModel.vehicles.first {
            ServiceHistoryView(vehicle: vehicle)
        } else {
            vehiclePickerList
        }
    }

    private var vehiclePickerList: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.sm) {
                Text("SELECT A VEHICLE")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)
                    .tracking(0.5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.md)

                ForEach(viewModel.vehicles, id: \.id) { vehicle in
                    NavigationLink(destination: ServiceHistoryView(vehicle: vehicle)) {
                        VehiclePickerRow(vehicle: vehicle)
                            .padding(.horizontal, Spacing.md)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, Spacing.xl)
        }
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: Spacing.md) {
            Text("Failed to load vehicles")
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.textPrimary)
            Text(message)
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
            Button("Retry") {
                Task { await viewModel.fetchVehicles() }
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(Color.appPrimary)
        }
        .padding(Spacing.md)
    }
}

// MARK: - Vehicle Picker Row

private struct VehiclePickerRow: View {
    let vehicle: VehicleResponse

    var body: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: Radius.button)
                    .fill(Color.appPrimary.opacity(0.12))
                    .frame(width: 48, height: 48)
                Image(systemName: "car.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.appPrimary)
            }

            VStack(alignment: .leading, spacing: 3) {
                let yearStr = vehicle.year.map { "\($0) " } ?? ""
                Text("\(yearStr)\(vehicle.make) \(vehicle.model)")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                if let plate = vehicle.licensePlate {
                    Text(plate)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.textSecondary)
                } else if let vin = vehicle.vin {
                    Text("VIN: \(vin.prefix(8))...")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.textSecondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.textTertiary)
        }
        .padding(Spacing.md)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.card))
    }
}

#Preview {
    NavigationStack {
        ServiceTabView()
    }
}
