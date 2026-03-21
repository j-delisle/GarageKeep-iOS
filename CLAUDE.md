# Auto Service Logger — iOS Mobile App

## Project Overview

Frontend iOS mobile app for an auto service logger. Multi-user: each account has their own garage (vehicle list). Users log service events per vehicle and can attach receipts/documents to each event.

Communicates with a backend REST API at `http://127.0.0.1:8005` (local dev). All data lives on the backend — no local-only persistence currently planned.

## Tech Stack

- **Language:** Swift
- **UI Framework:** SwiftUI
- **Minimum iOS Target:** iOS 18
- **Bundle ID:** `DelisleDomain.GarageKeep`
- **Xcode target name:** `GarageKeep`
- **Dependencies:** None (no CocoaPods, no SPM packages yet)
- **Xcode:** Uses automatic file system synchronization — new files are picked up automatically, no need to touch `.pbxproj`

## Design System

**Full spec:** `design.md` (project root) — always read it before making UI changes.
**Theme:** Dark mode only — "Precision Atelier" (Technical Luxury aesthetic)
**Swift tokens:** `Utilities/DesignTokens.swift`

### Quick Reference

**Colors (key tokens)**
| Swift token | Hex | Role |
|-------------|-----|------|
| `appBackground` | `#131315` | Base floor surface |
| `appSurface` | `#1b1b1d` | Cards, secondary zones |
| `appSurfaceContainerHigh` | `#272729` | Elevated containers |
| `appSurfaceElevated` | `#353437` | Active modals, prioritized cards |
| `appPrimary` | `#59d9d9` | Teal accent — use sparingly |
| `appPrimaryContainer` | `#00a8a8` | Gradient endpoint for CTAs |
| `tertiary` | `#ffb691` | Service overdue / warning |
| `appBorder` | `#4a4a4f` | Ghost border only at low opacity |

**Typography** — Plus Jakarta Sans (display/headline) + Manrope (body/label). Fonts must be bundled in Xcode target.
| Swift token | Font | Size | Use |
|-------------|------|------|-----|
| `Font.displayLg` | Plus Jakarta Sans Bold | 56pt | Hero numbers (odometer) |
| `Font.headlineMd` | Plus Jakarta Sans SemiBold | 28pt | Page titles |
| `Font.titleMd` | Manrope SemiBold | 18pt | Card headers |
| `Font.bodyMd` | Manrope Regular | 14pt | General content |
| `Font.labelSm` | Manrope Regular | 11pt | Metadata, specs |

**Radius** — `Radius.card` = 24pt, `Radius.button` = 24pt, `Radius.badge` = 9999 (full pill), `Radius.input` = 12pt

**Spacing** — `Spacing.outer` = 24pt (required screen margins), `Spacing.md` = 16pt (card padding)

### Critical Design Rules (from design.md)
- **No 1px solid borders** — define boundaries via surface color shifts, not lines
- **`appBorder` ghost border fallback** — only use at `.opacity(0.15)` when a container truly needs extra definition
- **Primary CTAs** — use `LinearGradient.primaryCTA` (primary → primaryContainer at 135°), not flat fill
- **Never pure black** — use `appBackground` (#131315), not #000000
- **`appPrimary` is a laser, not a paint bucket** — accent only, never large fills

### Navigation (Bottom Tab Bar)

4 tabs, dark background, teal selected indicator:

| Tab | Icon | Content |
|-----|------|---------|
| Garage | House/garage icon | Vehicle list → Vehicle detail → Service history |
| Service | Wrench icon | Service event list → Service event detail → Add service |
| Stats | Chart/stats icon | Activity overview, stats |
| Profile | Person icon | User profile, account settings |

## Architecture

**MVVM** with SwiftUI `@Observable` (iOS 17+):

```
mobile-app/
├── App/
│   ├── mobile_appApp.swift
│   └── ContentView.swift
├── Models/           # Codable structs matching API response shapes
├── ViewModels/       # @Observable classes, own state and call services
├── Views/
│   ├── Auth/         # Login, Register
│   ├── Vehicles/     # Garage tab — vehicle list, detail, add/edit
│   ├── ServiceEvents/# Service event list, detail, add/edit
│   ├── Attachments/  # Receipt/doc viewer, upload picker
│   └── Profile/      # User profile, account settings
├── Services/         # One class per API resource (networking)
└── Utilities/        # Extensions, formatters, helpers
```

- Views contain no business logic — layout and bindings only
- ViewModels own state and call Service classes
- Service classes own `URLSession` calls and decode responses
- Avoid `@EnvironmentObject` sprawl — prefer dependency injection into ViewModels

## Authentication

**JWT Bearer tokens** — `Authorization: Bearer <access_token>` header on all protected requests.

- Login returns both `access_token` and `refresh_token`
- Use `POST /v1/auth/refresh` with the refresh token to get a new access token
- Store tokens in **Keychain** (never `UserDefaults`)
- On app launch: check Keychain for a valid token; if missing/expired, show auth flow

## API

**Base URL:** `http://127.0.0.1:8005`
**Version prefix:** `/v1`

### Auth Endpoints

| Method | Path | Description |
|--------|------|-------------|
| POST | `/v1/auth/register` | Create account |
| POST | `/v1/auth/login` | Login → access + refresh tokens |
| POST | `/v1/auth/refresh` | Exchange refresh token for new access token |
| GET | `/v1/auth/me` | Current user info |

### User Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/v1/users/me` | Get profile |
| PUT | `/v1/users/me` | Update profile (email, name) |
| DELETE | `/v1/users/me` | Delete account |

### Vehicle Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/v1/vehicles` | List all vehicles for current user |
| POST | `/v1/vehicles` | Create vehicle |
| GET | `/v1/vehicles/{vehicle_id}` | Get vehicle |
| PUT | `/v1/vehicles/{vehicle_id}` | Update vehicle |
| DELETE | `/v1/vehicles/{vehicle_id}` | Delete vehicle |

### Service Event Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/v1/vehicles/{vehicle_id}/services` | List service events (paginated: `limit`, `offset`) |
| POST | `/v1/vehicles/{vehicle_id}/services` | Create service event |
| GET | `/v1/services/{service_id}` | Get service event |
| PUT | `/v1/services/{service_id}` | Update service event |
| DELETE | `/v1/services/{service_id}` | Delete service event |

### Attachment Endpoints

| Method | Path | Description |
|--------|------|-------------|
| POST | `/v1/services/{service_id}/attachments` | Upload attachment (multipart/form-data, field: `file`) |
| GET | `/v1/services/{service_id}/attachments` | List attachments for a service event |
| GET | `/v1/attachments/{attachment_id}` | Get attachment metadata |
| DELETE | `/v1/attachments/{attachment_id}` | Delete attachment |
| GET | `/v1/attachments/{attachment_id}/download` | Get a signed S3 download URL |

> Uploads go to S3 via the backend. Use `GET /download` to get a short-lived signed URL before displaying/downloading a file.

## Data Models

### User
```swift
struct UserResponse: Codable {
    let id: UUID
    let email: String
    let name: String?
    let createdAt: Date
    let updatedAt: Date
}
```

### Vehicle
```swift
struct VehicleResponse: Codable {
    let id: UUID
    let userId: UUID
    let make: String
    let model: String
    let year: Int?
    let vin: String?          // exactly 17 chars if provided
    let licensePlate: String? // max 20 chars
    let createdAt: Date
    let updatedAt: Date
}
```

### Service Event
```swift
struct ServiceEventResponse: Codable {
    let id: UUID
    let vehicleId: UUID
    let serviceType: String   // free-form text, max 100 chars
    let serviceDate: String   // ISO 8601 date (yyyy-MM-dd)
    let mileage: Int?
    let cost: String?         // decimal string e.g. "49.99"
    let location: String?     // max 255 chars
    let notes: String?
    let createdAt: Date
    let updatedAt: Date
}
```

### Attachment
```swift
struct AttachmentResponse: Codable {
    let id: UUID
    let serviceEventId: UUID
    let fileName: String
    let fileType: String
    let fileUrl: String
    let fileSize: Int?
    let uploadedAt: Date
    let createdAt: Date
}
```

### Auth Tokens
```swift
struct TokenResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let tokenType: String     // "Bearer"
    let expiresIn: Int
}
```

## Networking Conventions

- Use `URLSession` with `async/await`
- All `Codable` decoding uses `convertFromSnakeCase` key decoding strategy and ISO 8601 date decoding
- Centralize base URL, auth header injection, and token refresh in a single `APIClient`
- `APIClient` should handle 401 responses by attempting a token refresh before failing
- Never hardcode credentials — use Keychain for tokens

## SwiftUI Conventions

- Prefer `@Observable` over `ObservableObject`
- Keep view bodies small — extract subviews liberally
- Use `#Preview` macros for all views
- No logic in view bodies — push to ViewModels
- Use `NavigationStack` inside each tab, not `NavigationView`

## Open Items

- [x] Design system — full spec in `design.md`, tokens in `DesignTokens.swift`
- [ ] Bundle custom fonts — **Plus Jakarta Sans** and **Manrope** must be added to the Xcode target (`Info.plist` `UIAppFonts` entries + font files in bundle) before `Font.displayLg` / `Font.headlineMd` / `Font.titleMd` / `Font.bodyMd` / `Font.labelSm` render correctly
- [ ] Update existing views to use new design tokens (new colors, `Radius.card` = 24pt, `Radius.button` = 24pt, gradient CTAs, no solid borders)
- [ ] Offline/caching strategy (not yet decided)
- [ ] Deployment target set to iOS 26.2 in project file — should be corrected to iOS 18.0
- [ ] Auth flow UX — designed in Figma (Login, Sign Up, Welcome screens)
