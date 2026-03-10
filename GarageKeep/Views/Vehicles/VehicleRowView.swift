import SwiftUI

struct VehicleRowView: View {
    let vehicle: VehicleResponse

    var body: some View {
        HStack(spacing: Spacing.md) {
            RoundedRectangle(cornerRadius: Radius.button)
                .fill(Color.appSurface)
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "car.fill")
                        .foregroundStyle(Color.textTertiary)
                        .font(.title3)
                )

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("\(vehicle.year.map { String($0) } ?? "") \(vehicle.make) \(vehicle.model)")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)

                if let vin = vehicle.vin {
                    Text("VIN: \(vin)")
                        .font(.caption)
                        .foregroundStyle(Color.textSecondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.textTertiary)
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Radius.card)
                .fill(Color.appSurface)
        )
    }
}

#Preview {
    VehicleRowView(vehicle: VehicleResponse(
        id: UUID(),
        userId: UUID(),
        make: "Toyota",
        model: "Camry",
        year: 2023,
        vin: "1HGBH41JXMN109186",
        licensePlate: nil,
        createdAt: Date(),
        updatedAt: Date()
    ))
    .padding()
    .background(Color.appBackground)
}
