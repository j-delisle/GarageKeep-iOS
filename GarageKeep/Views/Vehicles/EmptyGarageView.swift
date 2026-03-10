import SwiftUI

struct EmptyGarageView: View {
    let onAddVehicle: () -> Void

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            Image(systemName: "car.2.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.appPrimary.opacity(0.6))

            VStack(spacing: Spacing.sm) {
                Text("No vehicles yet")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)

                Text("Add your first vehicle to start tracking service history.")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
            }

            PrimaryButton(title: "Add Your First Vehicle", accessibilityID: "btn_add_first_vehicle") {
                onAddVehicle()
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.sm)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
    }
}

#Preview {
    EmptyGarageView(onAddVehicle: {})
}
