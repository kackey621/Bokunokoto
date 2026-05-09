# GitHub Issues — Super Admin Console & Core Features Replan

This document outlines the roadmap for separating the Super Admin Console from the Main Core Systems and integrating advanced operational and feature-management tools. Each issue is organized as a shippable unit of work.

---

## Issue: Super Admin Console Separation [PLANNED]

**Labels:** `backend`, `admin`, `architecture`

**Milestone:** Super Admin Foundation

### Body

Separate the Super Admin systems (`/super_admin`) from the Main Core systems (`/console` and `/bkc`). This ensures isolation of system-wide privileges (Super Admin) from individual vault management (BKC) and standard platform operations.

### Acceptance Criteria

- [ ] Create `SuperAdmin::BaseController` inheriting from `ApplicationController`.
- [ ] Implement `authenticate_super_admin!` to restrict access.
- [ ] Add `namespace :super_admin` in `config/routes.rb`.
- [ ] Create a dedicated Super Admin dashboard view.
- [ ] Ensure full test coverage and separation from standard user roles.

---

## Issue: Firebase Auth & Firestore Integration [PLANNED]

**Labels:** `backend`, `firebase`, `data-model`

**Milestone:** Super Admin Foundation

### Body

Integrate Firebase Admin SDK for deep integration with Firebase Auth and Firestore. This enables dynamic auth features and allows the Super Admin console to observe and manage data stored in Firestore, supporting users directly from the Rails backend.

### Acceptance Criteria

- [ ] Add `google-cloud-firestore` and `firebase_admin` (or equivalent HTTP integration) to `Gemfile`.
- [ ] Initialize Firebase Admin credentials securely via Rails credentials or ENV vars.
- [ ] Create `Firebase::AuthService` for dynamic user state management (e.g., revoking tokens, custom claims).
- [ ] Create `Firebase::FirestoreService` to read/write operational observation data to Firestore.
- [ ] Add Super Admin views to observe Firestore metrics and user support data.

---

## Issue: Remote Config Management for Mobile [PLANNED]

**Labels:** `backend`, `admin`, `mobile`

**Milestone:** Feature & Version Management

### Body

Provide an interface in the Super Admin console to manage Firebase Remote Config. This will allow Super Admins to dynamically switch versions, enforce minimum app versions, and deploy configuration changes to the mobile client without App Store updates.

### Acceptance Criteria

- [ ] Integrate Firebase Remote Config API client in Rails.
- [ ] Create a UI in the Super Admin console to view current Remote Config parameters.
- [ ] Allow Super Admins to update key parameters (e.g., `min_mobile_version`, `maintenance_mode`).
- [ ] Log all Remote Config changes to a Super Admin audit log.

---

## Issue: Feature Flagging with Flipt (Server & Web) [PLANNED]

**Labels:** `backend`, `frontend`, `feature-flags`

**Milestone:** Feature & Version Management

### Body

Integrate Flipt for robust feature flag management across the server (Rails) and web client (Flutter Web/React). This replaces or augments the rudimentary FeatureFlag model with an enterprise-ready solution.

### Acceptance Criteria

- [ ] Add Flipt SDK or REST client to the Rails backend.
- [ ] Create a `FeatureFlagService` wrapper around Flipt.
- [ ] Evaluate flags dynamically for users on the server side.
- [ ] Expose an API endpoint (`/api/v1/feature_flags`) for the web client to fetch its active flags.
- [ ] Provide deep linking or an iframe in the Super Admin console to the Flipt dashboard, or a custom UI to toggle key flags.

---

## Issue: FCM Push Notifications for Super Admins & Users [PLANNED]

**Labels:** `backend`, `notifications`, `firebase`

**Milestone:** Operational Communication

### Body

Implement Firebase Cloud Messaging (FCM) capabilities allowing Super Admins to send platform-wide announcements, news, or directory updates. Users will also be able to receive notifications for specific events.

### Acceptance Criteria

- [ ] Add FCM server integration (via `google-auth` or `fcm` gem utilizing HTTP v1 API).
- [ ] Create `NotificationService` to send directed and topic-based FCM messages.
- [ ] Build a "Send Announcement" UI in the Super Admin console.
- [ ] Allow Super Admins to target all users, specific segments, or individual users.
- [ ] Write integration tests simulating FCM payload delivery.

---

## Issue: Automated Browser Testing & QA [PLANNED]

**Labels:** `testing`, `qa`

**Milestone:** Stability & Release Readiness

### Body

Ensure that the newly separated Super Admin Console and core integrations pass all system tests and browser tests.

### Acceptance Criteria

- [ ] Write Capybara/Selenium system tests for Super Admin login and dashboard access.
- [ ] Write tests for unauthorized access attempts to the `/super_admin` namespace.
- [ ] Ensure all CI steps (RSpec, RuboCop, Brakeman) pass successfully.
- [ ] Validate core system workflows are unaffected by the new additions.
