# GitHub Issues — Bokunokoto (BK)

Minimum issue set organized by milestone. Each issue represents a shippable unit of work.

> **Multi-tenant note (2026-05-14).** Issues #3, #4, #6, #25, #26 in this file were drafted under the original "one vault per user" simplification. They are **partially superseded** by `GITHUB_ISSUES_MULTI_TENANT.md`. The acceptance criteria for those issues remain valid for the *first* owned vault but the implementation must use `current_vault` (active-vault resolver) instead of `current_user.vault`. See `GITHUB_ISSUES_INDEX.md` for the canonical view across all three issue files.

---

## Milestone: Phase 1 — Foundation (Month 0–3)

### Issue #1: Rails project setup & base configuration

**Labels:** `backend`, `setup`

Set up the Rails 7+ project with PostgreSQL, Redis, and base configuration.

- [ ] `rails new bokunokoto --database=postgresql --api` (with admin views)
- [ ] Configure Active Record Encryption (master key, credentials)
- [ ] Add Sidekiq for background jobs
- [ ] Configure CORS for Flutter Web client
- [ ] Add `rack-cors`, `jbuilder`, base error handling
- [ ] Docker Compose for local development (PostgreSQL + Redis)
- [ ] CI pipeline (GitHub Actions: RSpec, RuboCop)

---

### Issue #2: Firebase Auth integration (Rails)

**Labels:** `backend`, `auth`

Implement Firebase ID Token verification on the Rails API.

- [ ] Add `firebase-id-token` gem (or equivalent)
- [ ] Create `ApplicationController#authenticate_user!` before_action
- [ ] `POST /api/v1/auth/verify` endpoint — verify token, find-or-create User
- [ ] User model: `firebase_uid`, `email`, `photo_url`, `is_admin`
- [ ] Tests: valid token → user created, invalid token → 401

---

### Issue #3: Vault & Content data model

**Labels:** `backend`, `data-model`
**Superseded-by:** `MT-1`, `MT-2` (multi-tenant rewrite — drop unique index, add quota)

Create core models for multi-tenant vault system.

- [ ] Vault model (`belongs_to :user`) with display_name, bio
- [ ] Content model (`belongs_to :vault`) with encrypted body, required_level (0–9), format (markdown/html), symbol_type, security flags
- [ ] Permission model (vault_id, user_id, granted_level, relationship_context)
- [ ] `Content.accessible_for(viewer, vault, platform)` scope
- [ ] Seeds for development/testing
- [ ] Tests: vault isolation, level-based filtering, platform restriction (Web ≤ L4)

---

### Issue #4: Content API endpoints

**Labels:** `backend`, `api`
**Superseded-by:** `MT-5`, `MT-7` (plural `/my/vaults/:id/contents` replaces singular `/my/contents`)

CRUD endpoints for vault content with level-based access control.

- [ ] `GET /api/v1/vaults/:vault_id/contents` — filtered by viewer level
- [ ] `GET /api/v1/contents/:id` — single content with permission check
- [ ] `POST /api/v1/my/contents` — create (owner only)
- [ ] `PATCH /api/v1/my/contents/:id` — update (owner only)
- [ ] `DELETE /api/v1/my/contents/:id` — delete (owner only)
- [ ] `X-BK-Platform` header enforcement (Web capped at L4)
- [ ] Tests: access denied for insufficient level, cross-vault access blocked

---

### Issue #5: AuditLog model (immutable write-only)

**Labels:** `backend`, `security`

Implement immutable audit logging for all content access.

- [ ] AuditLog model: user_id, content_id, action, ip_address, user_agent, lat/lng, face_snapshot_url, utc_timestamp
- [ ] `before_update` / `before_destroy` callbacks raise ReadOnlyRecord
- [ ] `after_action :log_view_activity` in contents controller
- [ ] `GET /api/v1/my/audit_logs` — owner views their vault's logs
- [ ] Tests: update/delete blocked, log created on content view

---

### Issue #6: BKC Admin Console — base setup

**Labels:** `backend`, `admin`
**Superseded-by:** `MT-8`, `MT-9` (vault switcher + per-active-vault scoping). The "current_user.my_vault" check below is replaced by `current_user.owns?(current_vault)`.

Set up the Rails admin console (BKC) for vault owners.

- [ ] Admin layout with Hotwire/ViewComponent (or Administrate)
- [ ] Dashboard: vault overview, recent activity summary
- [ ] Content management: list, create, edit, delete content
- [ ] User directory: list viewers with level and last access
- [ ] Route namespace: `/bkc/`
- [ ] Admin authentication check (current_user.my_vault) — **superseded:** use `current_user.owns?(current_vault)` per `MT-9`

---

### Issue #7: Flutter project setup & Firebase Auth

**Labels:** `frontend`, `setup`

Initialize the Flutter project targeting Web, iOS, and Android.

- [ ] Flutter project with `firebase_auth`, `dio`, `riverpod`/`provider`
- [ ] Firebase project configuration (google-services.json, GoogleService-Info.plist)
- [ ] Login screen (Google, Email sign-in)
- [ ] Token forwarding to Rails API
- [ ] Admin/Viewer mode state management (`BKMode` enum)
- [ ] Basic navigation shell (bottom nav: Home, Cards, Profile)

---

### Issue #8: Flutter content viewer (level-based)

**Labels:** `frontend`, `feature`

Display vault contents filtered by the viewer's trust level.

- [ ] Fetch `GET /api/v1/vaults/:id/contents` via dio
- [ ] Render Markdown content (`flutter_markdown`)
- [ ] Render HTML content (`flutter_html` or WebView)
- [ ] Level indicator badge on each content card
- [ ] "Login required" gate for L1+ content
- [ ] "Profile required" gate for L2+ content
- [ ] Platform header (`X-BK-Platform`) set on all requests

---

### Issue #9: QR code generation & scanning

**Labels:** `frontend`, `feature`

Implement QR-based handshake for user connection.

- [ ] Admin mode: generate QR code from AccessLink data (`qr_flutter`)
- [ ] Viewer mode: scan QR code (`mobile_scanner`)
- [ ] `POST /api/v1/handshake` — register connection after scan
- [ ] AccessLink model on Rails: slug, preset_context, initial_level, welcome_message, expires_at, max_uses
- [ ] OTP URL binding: first-user lock after authentication
- [ ] Tests: expired link rejected, max-use limit enforced

---

## Milestone: Phase 2 — Security & Accessibility (Month 3–6)

### Issue #10: OpenCV face detection service

**Labels:** `backend`, `security`

Implement non-AI face validation for L2 gate.

- [ ] Install OpenCV + Haar Cascade XML in vendor/
- [ ] `FaceDetectorService.contains_face?(image_path)` service object
- [ ] `POST /api/v1/profile/photo` endpoint — upload, validate, set `face_verified_at`
- [ ] L2 gate: profile_completed? check (real_name + organization + face_verified_at)
- [ ] Tests: image with face → pass, image without face → fail

---

### Issue #11: ABC Shield — screenshot prevention

**Labels:** `frontend`, `security`

Implement multi-layer screen capture prevention.

- [ ] Android: `FLAG_SECURE` on secure views via MethodChannel
- [ ] iOS: secure UIView overlay via MethodChannel
- [ ] Web: CSS `user-select: none`, print media query hide, right-click disable
- [ ] Web: anti-debugger loop for DevTools detection
- [ ] Dynamic watermark overlay widget (user hash + timestamp, low opacity)
- [ ] Content-level toggle: render shield based on `is_antigravity_enabled` flag

---

### Issue #12: Camera/GPS permission gate (L7+)

**Labels:** `frontend`, `security`

Require camera capture and GPS before viewing L7+ content.

- [ ] Pre-view confirmation dialog: "This information requires camera and location access..."
- [ ] Camera capture: take face snapshot → upload to Rails → stored in S3
- [ ] GPS capture: get coordinates → send to Rails audit log
- [ ] Permission denial → permanent block (API returns 423)
- [ ] `POST /api/v1/audit_logs` with face_snapshot + coordinates

---

### Issue #13: Secure Audio — earphone-only TTS

**Labels:** `frontend`, `accessibility`

Restrict screen reader output for L5+ content to earphone/earpiece.

- [ ] MethodChannel: detect audio output route (earphone, earpiece, speaker)
- [ ] Android: AudioManager route detection
- [ ] iOS: AVAudioSession route detection
- [ ] Semantics widget: swap labels based on audio state
- [ ] Fallback message: "For privacy protection, please connect earphones"
- [ ] Respect `audio_protection_required` flag from API

---

### Issue #14: Symbolic Disclosure — symbols & marks

**Labels:** `backend`, `frontend`, `feature`

Implement visual symbol system (Help Mark, Rainbow, etc.).

- [ ] Rails: `symbol_type` array field on Content model
- [ ] Symbol master data (icon, label, alt_text, color)
- [ ] BKC: Symbol Palette — assign symbols to content with level-based visibility
- [ ] Flutter: Symbol badge rendering with accessibility alt text
- [ ] Status indicator: "Currently needs accommodation" toggle

---

### Issue #15: Profile completion & conversational onboarding

**Labels:** `frontend`, `ux`

Friendly onboarding flow for L2 registration.

- [ ] Conversational-style profile input (chat-like UI, not cold forms)
- [ ] Fields: real name, relationship to discloser, purpose
- [ ] Auto-populate from preset QR context when available
- [ ] Accessibility: audio guidance for each field
- [ ] `PATCH /api/v1/profile` API integration
- [ ] L2 gate enforcement in content viewer

---

## Milestone: Phase 3 — Communication & Greeting (Month 6–9)

### Issue #16: NTP time sync endpoint & client

**Labels:** `backend`, `frontend`, `security`

Implement BK Time for tamper-proof time-lock.

- [ ] Rails: `GET /api/v1/ntp/sync` returning UTC + timestamp
- [ ] Flutter: `BKTime` class using device uptime + server anchor
- [ ] Sync on app launch, every 30 min, and before time-locked content
- [ ] Server-side time validation on greeting card API

---

### Issue #17: Greeting card builder & delivery

**Labels:** `backend`, `frontend`, `feature`

Build the greeting card creation and time-locked delivery system.

- [ ] Rails: GreetingCard model (template_body, rendered_body, unlock_at, timezone_override)
- [ ] Rails: Variable injection engine (`{{name}}`, `{{company}}`, etc.)
- [ ] Rails: Excel batch import endpoint (`POST /api/v1/my/greetings/batch`)
- [ ] Rails: Sidekiq worker for FCM silent push (preload trigger)
- [ ] Flutter: Greeting viewer with countdown timer (BK Time)
- [ ] Flutter: Unlock animation and content display
- [ ] BKC: Template editor, batch input UI, scheduler, delivery tracker

---

### Issue #18: Notification & message box

**Labels:** `backend`, `frontend`, `feature`

Per-user notification inbox with push support.

- [ ] Rails: Notification model (recipient_id, type, title, body, link, is_read)
- [ ] Rails: Sidekiq fan-out for segment delivery
- [ ] Rails: FCM push notification integration
- [ ] `GET /api/v1/notifications`, `PATCH /api/v1/notifications/:id/read`
- [ ] Flutter: Notification inbox screen with badge count
- [ ] Flutter: Push notification handling (foreground + background)

---

### Issue #19: Q&A system (3-tier visibility)

**Labels:** `backend`, `frontend`, `feature`

Question box and progressive Q&A with tiered visibility.

- [ ] Rails: QaContent model (visibility: direct/tiered/global, required_level, asker_uid)
- [ ] `POST /api/v1/vaults/:id/questions` — submit question
- [ ] `GET /api/v1/vaults/:id/qa` — filtered by visibility rules
- [ ] `POST /api/v1/my/qa/:id/answer` — answer with visibility setting
- [ ] BKC: Q&A management UI (answer, set visibility tier)
- [ ] Flutter: Question submission form, Q&A list view

---

### Issue #20: Burn-after-reading

**Labels:** `backend`, `frontend`, `security`

One-time view content with automatic deletion.

- [ ] Rails: `is_burn_after_reading` flag + `is_viewed` + `viewed_at` on Content
- [ ] Atomic check-and-update (row-level lock or transaction)
- [ ] Sidekiq job: purge content body after viewing
- [ ] Auto-expiration job: delete unviewed content past `expires_at`
- [ ] Flutter: Pre-view confirmation dialog
- [ ] Flutter: "One-time viewing" indicator + forced ABC Shield
- [ ] API returns 410 Gone for already-viewed content

---

### Issue #21: Invitation system with email delivery

**Labels:** `backend`, `feature`

Email-based invitation with preset access.

- [ ] Rails: Invitation model (email, token, target_page_id, initial_level, status, expires_at)
- [ ] Rails: Email delivery via SendGrid/Postmark (Action Mailer)
- [ ] `POST /api/v1/my/invitations` — create and send
- [ ] Token validation on sign-up → auto-bind to user → apply permissions
- [ ] BKC: Invitation management UI

---

## Milestone: Phase 4 — Polish & Beta Testing (Month 9–12)

### Issue #22: Feature Flag system

**Labels:** `backend`, `admin`

Feature flag management for staged rollout.

- [ ] Rails: FeatureFlag model (name, enabled, user_ids)
- [ ] `User#feature_enabled?(name)` method
- [ ] API: include active feature flags in auth response
- [ ] BKC: Feature flag management UI (toggle, per-user beta assignment)
- [ ] Flutter: gate UI components based on feature flags

---

### Issue #23: Dynamic access links with analytics

**Labels:** `backend`, `frontend`, `feature`

Context-aware access links with per-link tracking.

- [ ] Rails: AccessLink model enhancements (template, visible_fields, tracking)
- [ ] `GET /p/:slug` — resolve link, apply preset
- [ ] Per-link analytics: click count, L1 conversion, L2 conversion
- [ ] BKC: Link creation form, QR generation, analytics dashboard
- [ ] Flutter: AccessLink-aware content display (welcome message, filtered sections)

---

### Issue #24: Bank account display (masked & copyable)

**Labels:** `frontend`, `feature`

Masked bank account display with clipboard copy.

- [ ] Rails: Bank info in vault settings (encrypted)
- [ ] Flutter: Masked display (012-****-5678)
- [ ] Reveal toggle (show/hide full number)
- [ ] Copy button using Clipboard API
- [ ] No ABC Shield needed — usability prioritized

---

### Issue #25: Analytics dashboard in BKC

**Labels:** `backend`, `admin`
**Superseded-by:** `MT-9` (analytics re-scoped to active vault). Each owned vault has its own dashboard; the switcher toggles between them.

Full analytics dashboard for vault owners.

- [ ] Trust transition funnel visualization
- [ ] Access link attribution chart
- [ ] Content engagement metrics (views, duration, repeats)
- [ ] Security event log (screenshot attempts, GPS denials)
- [ ] Accessibility metrics (earphone rate, TTS usage)
- [ ] Greeting metrics (preload rate, open rate, time-to-open)
- [ ] Chart.js / D3.js integration in Rails admin views

---

### Issue #26: Forensic monitor (geo map & face archive)

**Labels:** `backend`, `admin`, `security`
**Superseded-by:** `MT-9` (per-vault forensics stream). One vault, one live stream; switcher closes and reopens streams.

Real-time forensic monitoring dashboard in BKC.

- [ ] Live activity feed (streaming audit log entries)
- [ ] Geo map with active session pins (Leaflet.js or similar)
- [ ] Per-user timeline (chronological access history)
- [ ] Face snapshot archive (grid view by user)
- [ ] Incident alerts (anomalous behavior highlighting)

---

### Issue #27: Inclusive design audit & polish

**Labels:** `frontend`, `accessibility`

Final accessibility and UX audit before launch.

- [ ] WCAG contrast check on all symbols and UI elements
- [ ] VoiceOver (iOS) and TalkBack (Android) full-flow testing
- [ ] Haptic feedback patterns (level-up, NFC handshake, urgent notification)
- [ ] Large tap targets verification (minimum 48dp)
- [ ] Keyboard navigation for Flutter Web
- [ ] Conversational onboarding copy review
- [ ] Screen reader: QR display announcements

---

### Issue #28: NFC handshake (Android)

**Labels:** `frontend`, `feature`

Web NFC API integration for tap-to-connect.

- [ ] Android/Chrome: NDEF write with connection URL + temp token
- [ ] NDEF read: parse connection URL, trigger handshake flow
- [ ] Fallback: QR code for iOS and unsupported browsers
- [ ] Feature Flag gated (gradual rollout)

---

### Issue #29: Security & penetration testing

**Labels:** `testing`, `security`

Pre-launch security validation.

- [ ] Cross-vault data access attempts
- [ ] URL enumeration attack testing
- [ ] OTP URL binding bypass attempts
- [ ] ABC Shield effectiveness testing (screenshot tools, screen recording)
- [ ] Firebase Auth token replay/forgery
- [ ] Rate limiting verification
- [ ] Audit log immutability verification

---

## Label Definitions

| Label | Color | Description |
|---|---|---|
| `backend` | `#0075ca` | Rails API / BKC server-side work |
| `frontend` | `#7057ff` | Flutter client work |
| `security` | `#d73a4a` | Security-related implementation |
| `accessibility` | `#0e8a16` | Accessibility features |
| `feature` | `#a2eeef` | New feature implementation |
| `admin` | `#f9d0c4` | BKC admin console |
| `setup` | `#e4e669` | Project setup / configuration |
| `auth` | `#fbca04` | Authentication related |
| `data-model` | `#c5def5` | Database schema / model changes |
| `api` | `#bfdadc` | API endpoint implementation |
| `ux` | `#d4c5f9` | User experience improvements |
| `testing` | `#fef2c0` | Testing and quality assurance |
