import SwiftUI

struct AddServiceReviewStepView: View {
    @Bindable var viewModel: AddServiceViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                serviceDetailsCard
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.md)

                if viewModel.selectedImageData != nil {
                    receiptPreview
                        .padding(.horizontal, Spacing.md)
                }

                if let error = viewModel.errorMessage {
                    ErrorBanner(message: error)
                        .padding(.horizontal, Spacing.md)
                }

                Spacer(minLength: Spacing.md)
            }
        }
    }

    // MARK: - Service Details Card

    private var serviceDetailsCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("SERVICE DETAILS")
                .font(.sectionHeader)
                .foregroundStyle(Color.textSecondary)
                .tracking(0.5)

            VStack(spacing: 0) {
                reviewRow(label: "Service Type", value: viewModel.resolvedServiceType)
                reviewDivider
                reviewRow(label: "Date", value: formattedDisplayDate)
                if let mileage = viewModel.resolvedMileage {
                    reviewDivider
                    reviewRow(label: "Odometer", value: "\(mileage) mi")
                }
                if let cost = viewModel.resolvedCost {
                    reviewDivider
                    reviewRow(label: "Total Cost", value: "$\(cost)")
                }
                if let location = viewModel.resolvedLocation {
                    reviewDivider
                    reviewRow(label: "Service Center", value: location)
                }
                if let notes = viewModel.resolvedNotes {
                    reviewDivider
                    reviewRow(label: "Notes", value: notes)
                }
            }
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.card))
        }
    }

    private var formattedDisplayDate: String {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .none
        return fmt.string(from: viewModel.serviceDate)
    }

    private func reviewRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.bodyMd)
                .foregroundStyle(Color.textSecondary)
            Spacer()
            Text(value)
                .font(.bodyMd.weight(.medium))
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 220, alignment: .trailing)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm + 2)
    }

    private var reviewDivider: some View {
        Color.appBackground.opacity(0.5).frame(height: 1)
    }

    // MARK: - Receipt Preview

    private var receiptPreview: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("RECEIPT")
                .font(.sectionHeader)
                .foregroundStyle(Color.textSecondary)
                .tracking(0.5)

            HStack(spacing: Spacing.md) {
                if let data = viewModel.selectedImageData,
                   let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.button))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.selectedImageName)
                        .font(.bodyMd.weight(.medium))
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(1)
                    Text("Image · Will be uploaded")
                        .font(.labelSm)
                        .foregroundStyle(Color.textSecondary)
                }

                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.statusSuccess)
            }
            .padding(Spacing.md)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.card))
        }
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        let vm: AddServiceViewModel = {
            let v = AddServiceViewModel(vehicle: .stubWithVin)
            v.serviceTypePick = "Oil & Filter Change"
            v.costText = "85.00"
            v.location = "Porsche Center"
            v.mileageText = "12450"
            v.notes = "Synthetic 0W-40"
            return v
        }()
        AddServiceReviewStepView(viewModel: vm)
    }
}
