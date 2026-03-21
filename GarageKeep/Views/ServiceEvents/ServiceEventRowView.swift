import SwiftUI

struct ServiceEventRowView: View {
    let event: ServiceEventResponse
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            timelineColumn
            contentColumn
        }
    }

    // MARK: - Timeline Column

    private var timelineColumn: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(Color.appPrimary.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: ServiceHistoryViewModel.iconName(for: event.serviceType))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.appPrimary)
            }

            if !isLast {
                Rectangle()
                    .fill(Color.appBorder.opacity(0.25))
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }
        }
        .frame(width: 36)
    }

    // MARK: - Content Column

    private var contentColumn: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(alignment: .top) {
                Text(event.serviceType)
                    .font(.titleSm)
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                if let cost = displayCost {
                    Text(cost)
                        .font(.titleSm)
                        .foregroundStyle(Color.appPrimary)
                }
            }

            HStack(spacing: 4) {
                Text(formattedDate)
                    .font(.bodyMd)
                    .foregroundStyle(Color.textSecondary)
                if let location = event.location {
                    Text("•")
                        .font(.bodyMd)
                        .foregroundStyle(Color.textTertiary)
                    Text(location)
                        .font(.bodyMd)
                        .foregroundStyle(Color.textSecondary)
                        .lineLimit(1)
                }
            }

            if let notes = event.notes, !notes.isEmpty {
                HStack(alignment: .top, spacing: Spacing.xs) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.labelSm)
                        .foregroundStyle(Color.appPrimary)
                        .padding(.top, 1)
                    Text(notes)
                        .font(.bodyMd)
                        .foregroundStyle(Color.textSecondary)
                        .lineLimit(3)
                }
                .padding(Spacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.appSurfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: Radius.input))
            }
        }
        .padding(.bottom, Spacing.lg)
    }

    // MARK: - Helpers

    private var displayCost: String? {
        guard let cost = event.cost, !cost.isEmpty else { return nil }
        guard let decimal = Decimal(string: cost), decimal > 0 else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: decimal as NSDecimalNumber)
    }

    private var formattedDate: String {
        let input = DateFormatter()
        input.dateFormat = "yyyy-MM-dd"
        input.locale = Locale(identifier: "en_US_POSIX")
        guard let date = input.date(from: event.serviceDate) else { return event.serviceDate }
        let output = DateFormatter()
        output.dateStyle = .medium
        return output.string(from: date)
    }
}

#Preview {
    ScrollView {
        LazyVStack(spacing: 0) {
            ForEach(Array(ServiceEventResponse.stubs.enumerated()), id: \.element.id) { index, event in
                ServiceEventRowView(
                    event: event,
                    isLast: index == ServiceEventResponse.stubs.count - 1
                )
            }
        }
        .padding(.horizontal, Spacing.md)
    }
    .background(Color.appBackground)
}
