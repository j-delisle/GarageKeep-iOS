import SwiftUI

enum VehicleStatus {
    case active
    case alert

    var label: String { self == .active ? "ACTIVE" : "ALERT" }
    var badgeColor: Color { self == .active ? .appPrimary : .statusAlert }
    var badgeTextColor: Color { self == .active ? .appBackground : .white }
}

struct VehicleCardView: View {
    let vehicle: VehicleResponse

    // Stub — returns .active until alert logic is added to the model
    private var vehicleStatus: VehicleStatus { .active }

    var body: some View {
        VStack(spacing: 0) {
            // Hero image area
            ZStack(alignment: .topLeading) {
                heroImagePlaceholder
                StatusBadgeView(status: vehicleStatus)
            }

            // Info section
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Row 1: name + mileage stat
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(vehicle.make) \(vehicle.model)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color.textPrimary)
                            .lineLimit(1)
                        Text(subtitleText)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.textSecondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("MILEAGE")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color.textSecondary)
                            .tracking(0.5)
                        Text("---")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Color.textPrimary)
                    }
                }

                // Row 2: service detail + action button
                HStack {
                    Label("No service on record", systemImage: "calendar")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.textSecondary)
                        .lineLimit(1)
                    Spacer()
                    actionButton(for: vehicleStatus)
                }
            }
            .padding(Spacing.md)
            .background(Color.appSurface)
        }
        .clipShape(RoundedRectangle(cornerRadius: Radius.card))
        .overlay {
            if vehicleStatus == .alert {
                RoundedRectangle(cornerRadius: Radius.card)
                    .stroke(Color.appPrimary, lineWidth: 1.5)
            }
        }
        .accessibilityIdentifier("vehicle_card_\(vehicle.id)")
    }

    private var heroImagePlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [Color.appSurfaceElevated, Color.appSurface],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Color.appPrimary.opacity(0.06)
            Image(systemName: "car.fill")
                .font(.system(size: 52))
                .foregroundStyle(Color.textTertiary.opacity(0.5))
        }
        .aspectRatio(16 / 9, contentMode: .fit)
    }

    private var subtitleText: String {
        var parts: [String] = []
        if let year = vehicle.year { parts.append(String(year)) }
        if let plate = vehicle.licensePlate {
            parts.append(plate)
        } else if let vin = vehicle.vin {
            parts.append("VIN \(vin.prefix(8))...")
        }
        return parts.isEmpty ? "—" : parts.joined(separator: " • ")
    }

    @ViewBuilder
    private func actionButton(for status: VehicleStatus) -> some View {
        switch status {
        case .active:
            Button("Details") {}
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.appPrimary)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, 6)
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.button)
                        .stroke(Color.appPrimary, lineWidth: 1.5)
                )
                .buttonStyle(.plain)
                .accessibilityIdentifier("btn_vehicle_details")
        case .alert:
            Button("Fix Issue") {}
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, 6)
                .background(Color.statusDanger)
                .clipShape(RoundedRectangle(cornerRadius: Radius.button))
                .buttonStyle(.plain)
                .accessibilityIdentifier("btn_fix_issue")
        }
    }
}

private struct StatusBadgeView: View {
    let status: VehicleStatus

    var body: some View {
        Text(status.label)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(status.badgeTextColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status.badgeColor)
            .clipShape(RoundedRectangle(cornerRadius: Radius.badge))
            .accessibilityIdentifier("badge_status")
            .padding(Spacing.sm)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: Spacing.md) {
            VehicleCardView(vehicle: VehicleResponse(
                id: UUID(),
                userId: UUID(),
                make: "BMW",
                model: "X5",
                year: 2023,
                vin: nil,
                licensePlate: "xDrive40i",
                createdAt: Date(),
                updatedAt: Date()
            ))
            VehicleCardView(vehicle: VehicleResponse(
                id: UUID(),
                userId: UUID(),
                make: "Tesla",
                model: "Model 3",
                year: 2022,
                vin: "1HGBH41JXMN10918",
                licensePlate: nil,
                createdAt: Date(),
                updatedAt: Date()
            ))
            VehicleCardView(vehicle: VehicleResponse(
                id: UUID(),
                userId: UUID(),
                make: "Audi",
                model: "Q7",
                year: 2024,
                vin: nil,
                licensePlate: nil,
                createdAt: Date(),
                updatedAt: Date()
            ))
        }
        .padding(Spacing.md)
    }
    .background(Color.appBackground)
}
