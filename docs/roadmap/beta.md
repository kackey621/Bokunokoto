# Beta Phase (Month 0–12)

## Strategy

The beta phase operates as a **free, invitation-only preview** targeting close personal relationships (friends, colleagues). All features are available without payment. Feature Flags gate experimental functionality for staged rollout.

## Phase Breakdown

### Phase 1: Foundation (Month 0–3)

**Goal:** Core platform operational with basic trust management.

| Area | Deliverable |
|---|---|
| Rails | Project setup (`rails new bokunokoto --database=postgresql`) |
| Rails | User, Vault, Content, Permission, AccessLink models |
| Rails | Firebase Auth integration (ID token verification) |
| Rails | 10-level content scoping with `accessible_for` scope |
| Rails | Active Record Encryption for sensitive fields |
| Rails | BKC admin console (content CRUD, user list) |
| Rails | AuditLog model (immutable, write-only) |
| Flutter | Project setup (single codebase: Web + iOS + Android) |
| Flutter | Firebase Auth login flow |
| Flutter | Own-vault / received-vault context switching |
| Flutter | Basic content viewing with level-based filtering |
| Flutter | QR code generation and scanning |
| Infra | PostgreSQL + Redis deployment |
| Infra | S3 bucket for Active Storage |
| Analytics | Structured logging on all API endpoints (from day 1) |

### Phase 2: Security & Accessibility (Month 3–6)

**Goal:** ABC Shield and secure audio operational.

| Area | Deliverable |
|---|---|
| Rails | OpenCV Haar Cascade face detection service |
| Rails | Face validation gate for L2 |
| Rails | Profile completion enforcement |
| Flutter | ABC Shield: CSS guards (Web), FLAG_SECURE (Android), secure view (iOS) |
| Flutter | Dynamic watermark overlay component |
| Flutter | Camera/GPS permission gate for L7+ content |
| Flutter | Earphone/earpiece detection via MethodChannel |
| Flutter | Secure TTS: Semantics label switching based on audio output |
| Flutter | NFC handshake (Android; QR fallback for iOS) |
| BKC | Symbol Palette (Help Mark, Rainbow, Ear Mark, etc.) |
| BKC | Content security toggles (ABC Shield, camera, GPS, earphone) |
| BKC | Preview simulator (view-as-level-X) |
| Analytics | Trust transition tracking, security event monitoring |

### Phase 3: Communication & Greeting (Month 6–9)

**Goal:** Greeting engine and notification system operational.

| Area | Deliverable |
|---|---|
| Rails | NTP sync endpoint (`/api/v1/ntp/sync`) |
| Rails | GreetingCard model with time-lock and timezone override |
| Rails | Excel batch import (`roo` gem) |
| Rails | Sidekiq workers for greeting delivery and FCM push |
| Rails | Notification model and fan-out delivery |
| Rails | Q&A system (3-tier visibility: direct/tiered/global) |
| Rails | Invitation system with email delivery |
| Flutter | BK Time client (NTP sync + uptime-based clock) |
| Flutter | Greeting card viewer with countdown and unlock animation |
| Flutter | Notification inbox with badge count |
| Flutter | Burn-after-reading flow (confirmation dialog → view → purge) |
| BKC | Greeting Center (template editor, batch input, scheduler) |
| BKC | Delivery Tracker (preload status, open rate) |
| Analytics | Greeting metrics, notification engagement |

### Phase 4: Polish & Beta Testing (Month 9–12)

**Goal:** Production-ready quality. Prepare for paid launch.

| Area | Deliverable |
|---|---|
| Rails | Feature Flag management UI in BKC |
| Rails | Bank account display endpoint (masked + copy) |
| Rails | Dynamic access links with preset context |
| Rails | Per-link analytics (attribution, conversion) |
| Flutter | Conversational onboarding flow (friendly profile input) |
| Flutter | Haptic feedback patterns |
| Flutter | Inclusive design audit (WCAG contrast, large tap targets) |
| BKC | Full analytics dashboard (Chart.js / D3.js graphs) |
| BKC | Forensic monitor (geo map, face archive, incident alerts) |
| Testing | End-to-end testing with real users (friends, colleagues) |
| Testing | Accessibility audit (VoiceOver / TalkBack testing) |
| Testing | Security penetration testing |
| Docs | User guide, privacy policy, terms of service |

## Beta Constraints

- **No billing** — all features free
- **Invitation-only** — new users require an AccessLink or Invitation from an existing user
- **Feature Flags** — experimental features (NFC, burn-after-reading) may be toggled per user
- **Data retention** — audit logs retained indefinitely; greeting cards retained for 1 year
