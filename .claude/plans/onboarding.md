# Onboarding Flow — Feature Spec

## Overview

After a user registers or logs in with no vehicles in their garage, they are shown a mandatory multi-step onboarding sheet to add their first vehicle. The sheet cannot be dismissed until at least one vehicle is added.

## Trigger Condition

- User is authenticated (`authViewModel.isAuthenticated == true`)
- Garage fetch returns an empty vehicle list (`vehicles.isEmpty`)
- Sheet appears automatically and cannot be swiped away

## User Flow

```
Login / Sign Up
     │
     ▼
Garage Tab (fetches vehicles)
     │
     ├─ Vehicles exist? → Show vehicle list
     │
     └─ Empty? → Show onboarding sheet (non-dismissible)
          │
          ▼
     Step 1: Vehicle Identity
          │
          ├─ Mode A: VIN
          │    └─ Enter 17-char VIN → Tap "Decode VIN"
          │         └─ Backend decodes → Show make/model/year summary
          │              └─ Tap "Continue" → Step 2
          │
          └─ Mode B: Manual Entry
               └─ Enter Make (required), Model (required), Year (optional)
                    └─ Tap "Continue" → Step 2
          │
          ▼
     Step 2: Review
          ├─ Summary card with vehicle details
          ├─ "Add to Garage" → POST /v1/vehicles → dismiss sheet
          └─ "Go Back" → Step 1
```

## API Endpoints Used

| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | `/v1/vehicles` | Fetch vehicle list on Garage tab load |
| GET | `/v1/vehicles/vin-decode?vin=<VIN>` | Decode VIN to make/model/year |
| POST | `/v1/vehicles` | Create the vehicle on submit |

## Step 1: Vehicle Identity

### VIN Mode
- Text field bound to `vinInput` (17-char limit enforced)
- "Decode VIN" button enabled only when `vinInput.count == 17`
- On decode success: read-only summary card appears with make, model, year
- On decode failure: inline error message below field
- "Continue" enabled only after successful decode

### Manual Mode
- Make: required text field
- Model: required text field
- Year: optional numeric field (4-digit year)
- "Continue" enabled when Make and Model are non-empty

## Step 2: Review

- Read-only summary card showing all collected details
- "Add to Garage" (primary button) → submits `CreateVehicleRequest`
- "Go Back" (secondary button) → returns to Step 1
- Error banner shown on submit failure (stays on Step 2)

## Data Sent to Backend

```json
POST /v1/vehicles
{
  "make": "Toyota",
  "model": "Camry",
  "year": 2023,
  "vin": "1HGBH41JXMN109186",  // only if VIN mode was used
  "license_plate": null
}
```

## Decisions

| Topic | Decision |
|-------|----------|
| Dismissible? | No — `.interactiveDismissDisabled(true)` |
| VIN decoding | Backend endpoint `/v1/vehicles/vin-decode` |
| Trim field | Not in API spec — omitted |
| License plate | Collected in a future iteration |

## Files

| File | Role |
|------|------|
| `Models/VehicleModels.swift` | `VehicleResponse`, `CreateVehicleRequest`, `VinDecodeResponse` |
| `Services/VehicleService.swift` | Network calls for vehicles + VIN decode |
| `ViewModels/GarageViewModel.swift` | Fetch vehicles, trigger onboarding |
| `ViewModels/AddVehicleViewModel.swift` | Onboarding step state + submit |
| `Views/Vehicles/GarageView.swift` | List or empty state |
| `Views/Vehicles/EmptyGarageView.swift` | Empty state with CTA |
| `Views/Onboarding/OnboardingContainerView.swift` | Sheet + step routing |
| `Views/Onboarding/VehicleIdentityStepView.swift` | Step 1 |
| `Views/Onboarding/OnboardingReviewStepView.swift` | Step 2 |

## Testing

- Unit: `VehicleServiceTests`, `AddVehicleViewModelTests`, `GarageViewModelTests`
- UI: `OnboardingScreenTests`
- Mock: `MockVehicleService` (mirrors `MockAuthService` pattern)
