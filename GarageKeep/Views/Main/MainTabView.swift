import SwiftUI

struct MainTabView: View {
    @Environment(AuthViewModel.self) private var authViewModel

    var body: some View {
        TabView {
            Tab("Garage", systemImage: "car.2.fill") {
                NavigationStack {
                    GarageView()
                }
            }

            Tab("Service", systemImage: "wrench.and.screwdriver.fill") {
                NavigationStack {
                    placeholderScreen("Service")
                }
            }

            Tab("Stats", systemImage: "chart.bar.fill") {
                NavigationStack {
                    placeholderScreen("Stats")
                }
            }

            Tab("Profile", systemImage: "person.fill") {
                NavigationStack {
                    placeholderScreen("Profile")
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Log Out") { authViewModel.logout() }
                                    .foregroundStyle(Color.statusDanger)
                            }
                        }
                }
            }
        }
        .tint(.appPrimary)
    }

    private func placeholderScreen(_ title: String) -> some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            VStack(spacing: Spacing.md) {
                Text(title)
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color.textPrimary)
                Text("Coming soon")
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.appBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

#Preview {
    MainTabView()
        .environment(AuthViewModel())
}
