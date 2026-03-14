//
//  GarageKeepApp.swift
//  GarageKeep
//
//  Created by Jay Delisle on 3/7/26.
//

import SwiftUI

@main
struct GarageKeepApp: App {
    @State private var authViewModel = AuthViewModel()

    private var showOnboardingForTesting: Bool {
        CommandLine.arguments.contains("--show-onboarding")
    }

    private var showMockVehicles: Bool {
        CommandLine.arguments.contains("--mock-vehicles")
    }

    init() {
        if CommandLine.arguments.contains("--clear-keychain") {
            KeychainHelper.clearAll()
        }
    }

    var body: some Scene {
        WindowGroup {
            if showOnboardingForTesting {
                OnboardingContainerView(vehicleCount: 0, onVehicleAdded: {})
                    .interactiveDismissDisabled(true)
            } else if showMockVehicles || authViewModel.isAuthenticated {
                MainTabView()
                    .environment(authViewModel)
            } else {
                AuthContainerView()
                    .environment(authViewModel)
            }
        }
    }
}
