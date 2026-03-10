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

**Theme:** Dark mode only (Teal/Dark)

### Colors

| Token | Hex | Usage |
|-------|-----|-------|
| `primary` | `#0DF2DF` | CTAs, active states, teal accent, tab selection |
| `background` | `#0E1117` | App background (near-black charcoal) |
| `surface` | `#1A1D24` | Cards, list rows, form containers |
| `surfaceElevated` | `#22262F` | Modals, dropdowns, elevated cards |
| `border` | `#2A2D38` | Subtle dividers, input borders |
| `textPrimary` | `#FFFFFF` | Headings, primary labels |
| `textSecondary` | `#8C8FA3` | Subtitles, metadata, placeholder text |
| `textTertiary` | `#55596A` | Disabled text, hints |
| `statusActive` | `#0DF2DF` | "ACTIVE" badge (same as primary) |
| `statusAlert` | `#F97316` | "ALERT" badge, warning states |
| `statusDanger` | `#EF4444` | "Fix Issue" button, error states, destructive actions |
| `statusSuccess` | `#22C55E` | Positive indicators, health 100% |
| `tabBarBackground` | `#0E1117` | Bottom tab bar background |

> Note: Primary teal `#0DF2DF` confirmed from Figma. Teal background tints use `primary` at reduced opacity (e.g. 10–20%) rather than separate colors. Other hex values are approximate — verify from Figma Inspect as needed.

### Typography

- **Font family:** SF Pro (iOS system font) — no custom typeface
- **App name / Hero headings:** SF Pro Display, Bold (32–34pt)
- **Screen titles:** SF Pro Display, Semibold (22–24pt)
- **Section headers:** SF Pro Text, Semibold (17pt)
- **Body / list rows:** SF Pro Text, Regular (15–16pt)
- **Captions / metadata:** SF Pro Text, Regular (12–13pt)
- **Badges / labels:** SF Pro Text, Semibold (11–12pt), uppercase

### Corner Radius

| Element | Radius |
|---------|--------|
| Cards | 12pt |
| Buttons (pill CTA) | 10pt |
| Input fields | 10pt |
| Badges / status pills | 6pt |
| Vehicle image thumbnails | 10pt |

### Spacing

- Standard horizontal padding: 16pt
- Card internal padding: 12–16pt
- Section vertical spacing: 20pt
- List row height: ~72pt (with thumbnail), ~56pt (text only)

### Button Styles

- **Primary:** Filled, `primary` background, `background`-colored text, full-width pill, 52pt height
- **Secondary:** Outlined, `primary` border + text, transparent background, same shape
- **Destructive:** Filled `statusDanger` background, white text
- **Small action (e.g. "Details", "Remind"):** Outlined pill, small — 32pt height

### Component Patterns

- Vehicle cards: horizontal layout, left-side thumbnail image (rounded), right side text stack, status badge top-left
- Status badges: `ACTIVE` (teal), `ALERT` (orange) — uppercase, pill shape, 11pt semibold
- Form fields: dark surface background, subtle border, 16pt internal padding, `textSecondary` placeholder
- Section labels: `textSecondary`, 12pt uppercase semibold, 20pt above section
- Bottom sheet / modals: `surfaceElevated` background, 20pt top corner radius

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

- [x] Design system / color scheme — added from Figma (hex values are approximate, verify from Figma Inspect)
- [ ] Create `DesignTokens.swift` (or `Color+App.swift`) with Swift `Color` extensions matching the design system
- [ ] Offline/caching strategy (not yet decided)
- [ ] Deployment target set to iOS 26.2 in project file — should be corrected to iOS 18.0
- [ ] Auth flow UX — designed in Figma (Login, Sign Up, Welcome screens)
