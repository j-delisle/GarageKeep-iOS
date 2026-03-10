import Foundation

@Observable final class AddVehicleViewModel {
    enum InputMode { case vin, manual }
    enum Step { case identity, review }

    var currentStep: Step = .identity
    var inputMode: InputMode = .vin

    // Step 1 — VIN mode
    var vinInput: String = ""
    var vinDecoded: VinDecodeResponse? = nil
    var isDecoding = false
    var decodeError: String?

    // Step 1 — Manual mode
    var make: String = ""
    var model: String = ""
    var year: String = ""

    // Step 2
    var isLoading = false
    var errorMessage: String?

    private let vehicleService: VehicleServiceProtocol

    init(vehicleService: VehicleServiceProtocol = VehicleService()) {
        self.vehicleService = vehicleService
    }

    // MARK: - Computed

    var canAdvanceFromIdentity: Bool {
        switch inputMode {
        case .vin:    return vinDecoded != nil
        case .manual: return !make.trimmingCharacters(in: .whitespaces).isEmpty &&
                             !model.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }

    var resolvedMake: String {
        inputMode == .vin ? (vinDecoded?.make ?? "") : make.trimmingCharacters(in: .whitespaces)
    }

    var resolvedModel: String {
        inputMode == .vin ? (vinDecoded?.model ?? "") : model.trimmingCharacters(in: .whitespaces)
    }

    var resolvedYear: Int? {
        if inputMode == .vin { return vinDecoded?.year }
        return Int(year)
    }

    var resolvedVin: String? {
        inputMode == .vin ? vinInput : nil
    }

    // MARK: - Actions

    func decodeVin() async {
        guard vinInput.count == 17 else { return }
        isDecoding = true
        decodeError = nil
        defer { isDecoding = false }

        do {
            vinDecoded = try await vehicleService.decodeVin(vinInput)
        } catch {
            decodeError = "Could not decode VIN — try entering details manually."
        }
    }

    func advanceToReview() {
        currentStep = .review
    }

    func backToIdentity() {
        currentStep = .identity
    }

    func submit() async -> VehicleResponse? {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let request = CreateVehicleRequest(
            make: resolvedMake,
            model: resolvedModel,
            year: resolvedYear,
            vin: resolvedVin,
            licensePlate: nil
        )

        do {
            return try await vehicleService.createVehicle(request)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func switchMode(to mode: InputMode) {
        inputMode = mode
        vinDecoded = nil
        decodeError = nil
    }
}
