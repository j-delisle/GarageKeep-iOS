import SwiftUI

struct ServiceHistoryView: View {
    let vehicle: VehicleResponse
    @State private var viewModel: ServiceHistoryViewModel
    @State private var showAddService = false

    init(vehicle: VehicleResponse) {
        self.vehicle = vehicle
        _viewModel = State(initialValue: ServiceHistoryViewModel(vehicle: vehicle))
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.appBackground.ignoresSafeArea()
            mainContent
            AddServiceFAB { showAddService = true }
                .padding(.trailing, Spacing.md)
                .padding(.bottom, Spacing.md)
        }
        .fullScreenCover(isPresented: $showAddService) {
            AddServiceContainerView(vehicle: vehicle) { event in
                viewModel.appendEvent(event)
            }
        }
        .navigationTitle("Service History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.appBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .task {
            if CommandLine.arguments.contains("--mock-service-events") {
                viewModel.loadMockEvents()
            } else {
                await viewModel.loadInitial()
            }
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        if viewModel.isLoading {
            ProgressView()
                .tint(.appPrimary)
        } else if let error = viewModel.errorMessage, viewModel.events.isEmpty {
            errorView(message: error)
        } else {
            scrollContent
        }
    }

    private var scrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Stats row
                StatsRowView(
                    totalSpent: viewModel.totalSpentFormatted,
                    nextService: viewModel.nextServiceMileage
                )
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.md)
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("stats_total_spent")

                // Vehicle summary
                VehicleSummaryCardView(
                    vehicle: viewModel.vehicle,
                    maskedVin: viewModel.maskedVin,
                    mileage: viewModel.totalMileageFormatted
                )
                .padding(.horizontal, Spacing.md)
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("vehicle_summary_card")

                // Past maintenance
                if !viewModel.sortedEvents.isEmpty {
                    SectionHeaderView(title: "PAST MAINTENANCE")

                    LazyVStack(spacing: 0) {
                        ForEach(Array(viewModel.sortedEvents.enumerated()), id: \.element.id) { index, event in
                            NavigationLink(destination: ServiceDetailView(
                                event: event,
                                vehicle: viewModel.vehicle,
                                previousMileage: previousMileageFor(event),
                                onDeleted: {
                                    viewModel.removeEvent(event)
                                    Task { await viewModel.loadInitial() }
                                },
                                onUpdated: { updated in viewModel.replaceEvent(event, with: updated) }
                            )) {
                                ServiceEventRowView(
                                    event: event,
                                    isLast: index == viewModel.sortedEvents.count - 1
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityElement(children: .contain)
                            .accessibilityIdentifier("service_row_\(index)")
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    Task { await viewModel.deleteEvent(event) }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.md)

                    if viewModel.hasMorePages {
                        loadMoreButton
                    }
                } else if !viewModel.isLoading {
                    emptyEventsView
                }

                // Upcoming — commented out until alerts/reminders backend is implemented
                // SectionHeaderView(title: "UPCOMING")
                // UpcomingPlaceholderCardView()
                //     .padding(.horizontal, Spacing.md)
                //     .padding(.bottom, Spacing.xl)
            }
        }
    }

    private func previousMileageFor(_ event: ServiceEventResponse) -> Int? {
        let sorted = viewModel.sortedEvents
        guard let index = sorted.firstIndex(where: { $0.id == event.id }),
              index + 1 < sorted.count else { return nil }
        return sorted[(index + 1)...].first(where: { $0.mileage != nil })?.mileage
    }

    private var loadMoreButton: some View {
        Button {
            Task { await viewModel.loadMore() }
        } label: {
            if viewModel.isLoadingMore {
                ProgressView().tint(.appPrimary)
            } else {
                Text("Load More")
                    .font(.bodyMd.weight(.semibold))
                    .foregroundStyle(Color.appPrimary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.md)
        .buttonStyle(.plain)
        .padding(.horizontal, Spacing.md)
    }

    private var emptyEventsView: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "wrench.and.screwdriver")
                .font(.system(size: 40))
                .foregroundStyle(Color.appPrimary.opacity(0.5))
            Text("No service records yet")
                .font(.titleSm)
                .foregroundStyle(Color.textPrimary)
            Text("Add your first service event to start tracking history.")
                .font(.bodyMd)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xl)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: Spacing.md) {
            Text("Failed to load service history")
                .font(.titleSm)
                .foregroundStyle(Color.textPrimary)
            Text(message)
                .font(.bodyMd)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
            Button("Retry") {
                Task { await viewModel.loadInitial() }
            }
            .font(.bodyMd.weight(.semibold))
            .foregroundStyle(Color.appPrimary)
        }
        .padding(Spacing.md)
    }
}

// MARK: - Stats Row

private struct StatsRowView: View {
    let totalSpent: String
    let nextService: String

    var body: some View {
        HStack(spacing: Spacing.md) {
            StatCard(label: "Total Spent", value: totalSpent)
            StatCard(label: "Next Service", value: nextService)
        }
    }
}

private struct StatCard: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(label.uppercased())
                .font(.labelSm)
                .foregroundStyle(Color.textSecondary)
                .tracking(0.5)
            Text(value)
                .font(.displaySm)
                .foregroundStyle(Color.textPrimary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.card))
    }
}

// MARK: - Vehicle Summary Card

private struct VehicleSummaryCardView: View {
    let vehicle: VehicleResponse
    let maskedVin: String
    let mileage: String

    var body: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: Radius.button)
                    .fill(Color.appPrimary.opacity(0.15))
                    .frame(width: 52, height: 52)
                Image(systemName: "car.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Color.appPrimary)
            }

            VStack(alignment: .leading, spacing: 3) {
                let yearStr = vehicle.year.map { "\($0) " } ?? ""
                Text("\(yearStr)\(vehicle.make) \(vehicle.model)")
                    .font(.titleSm)
                    .foregroundStyle(Color.textPrimary)
                Text("VIN: \(maskedVin)")
                    .font(.bodyMd)
                    .foregroundStyle(Color.textSecondary)
                Text(mileage)
                    .font(.sectionHeader)
                    .foregroundStyle(Color.appPrimary)
            }

            Spacer()

            Image(systemName: "car.side.fill")
                .font(.system(size: 36))
                .foregroundStyle(Color.appBorder)
        }
        .padding(Spacing.md)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.card))
    }
}

// MARK: - Section Header

private struct SectionHeaderView: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.sectionHeader)
            .foregroundStyle(Color.textSecondary)
            .tracking(0.5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.lg)
            .padding(.bottom, Spacing.sm)
    }
}

// MARK: - Upcoming Placeholder Card

private struct UpcomingPlaceholderCardView: View {
    var body: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: Radius.button)
                    .fill(Color.appPrimary.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: "calendar")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.appPrimary)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Upcoming Service")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                Text("No upcoming service scheduled")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer()

            // REMIND button — disabled until backend reminder support is added
            // Button("REMIND") {}
            //     .font(.system(size: 11, weight: .semibold))
            //     .foregroundStyle(Color.appPrimary)
            //     .padding(.horizontal, 12)
            //     .padding(.vertical, 7)
            //     .overlay(
            //         RoundedRectangle(cornerRadius: Radius.button)
            //             .stroke(Color.appPrimary, lineWidth: 1.5)
            //     )
            //     .buttonStyle(.plain)
        }
        .padding(Spacing.md)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.card))
    }
}

// MARK: - Add Service FAB

private struct AddServiceFAB: View {
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
        .accessibilityIdentifier("btn_add_service")
    }
}

#Preview {
    NavigationStack {
        ServiceHistoryView(vehicle: .stubWithVin)
    }
}
