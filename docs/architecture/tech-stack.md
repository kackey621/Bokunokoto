# Tech Stack

## Backend

| Layer | Technology | Purpose |
|---|---|---|
| Framework | Ruby on Rails 7+ (Rails Way) | Monolith API + Admin Console |
| Database | PostgreSQL | Primary data store with Active Record Encryption |
| Cache / Queue | Redis | Sidekiq job queue, session cache, NTP cache |
| Background Jobs | Sidekiq | Greeting batch delivery, audit log processing, burn-after-reading cleanup |
| Authentication | Firebase Auth (ID Token verification) | Google / Email sign-in, federated identity |
| Face Detection | OpenCV (Haar Cascade) | Non-AI face presence validation |
| File Storage | AWS S3 via Active Storage (SSE-KMS) | Face snapshots, greeting assets, profile images |
| Email | SendGrid / Postmark / Firebase Trigger Email | Invitation emails, greeting delivery |
| Excel Parsing | `roo` gem | Batch import for greeting cards |

## Frontend

| Layer | Technology | Purpose |
|---|---|---|
| Framework | Flutter (single codebase) | Web + iOS + Android |
| State Management | Riverpod / Provider | Admin/Viewer mode switching, feature flags |
| Auth | `firebase_auth` package | Firebase Auth integration |
| Secure Storage | `flutter_secure_storage` | Keychain (iOS) / KeyStore (Android) for tokens |
| Audio Detection | MethodChannel (platform-specific) | Earphone/earpiece connection detection |
| QR Code | `qrcode_flutter` / `mobile_scanner` | QR generation and scanning |
| NFC | Web NFC API (Android/Chrome) | Near-field communication handshake |
| Screenshot Prevention | `window_security` / platform flags | `FLAG_SECURE` (Android), `isSecureTextEntry` (iOS) |
| HTTP Client | `dio` | API communication with Rails backend |

## Infrastructure

| Service | Role |
|---|---|
| Firebase Auth | Identity provider |
| Firebase Cloud Messaging (FCM) | Push notifications, silent preload triggers |
| Firebase Hosting | Flutter Web deployment |
| Firebase App Distribution | Beta app distribution |
| AWS S3 (SSE-KMS) | Encrypted object storage |

## Development Principles

!!! info "Rails Way"
    The backend follows Rails conventions strictly — RESTful routes, Active Record patterns, standard directory structure, and convention over configuration. No microservices.

!!! info "Flutter Unified Client"
    A single Flutter codebase targets Web, iOS, and Android. Platform-specific behavior (screenshot blocking, audio routing) is handled via MethodChannel and conditional compilation.

!!! info "No AI Models"
    Face detection uses OpenCV's Haar Cascade classifier — a traditional computer vision algorithm, not a deep learning model. This reduces infrastructure cost and avoids AI-related compliance concerns.
