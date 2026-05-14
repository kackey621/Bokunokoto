# GitHub Issues — Account & Role Replan

This file is ready to be copied into GitHub Issues once repository access is available to the GitHub connector. Each issue is written as a shippable unit with aligned monday.com roadmap phases.

> **Multi-tenant continuation (2026-05-14).** All seven issues in this file are complete and shipped the person-first single-vault account model. The **multi-tenant rewrite** in `GITHUB_ISSUES_MULTI_TENANT.md` (MT-1 through MT-20) continues the work by lifting "one vault per user" to "one account → N vaults." Read this file for context, then move to `GITHUB_ISSUES_MULTI_TENANT.md` for active work.

---

## Issue: Account Foundation — person-first User model [COMPLETE]

**Labels:** `backend`, `data-model`, `auth`

**Milestone:** Phase 1 — Account Foundation

### Body

Refactor the account design so `User` represents an authenticated person rather than a fixed discloser/viewer role. Keep existing console functionality compatible while preparing the product for users who can both disclose and receive.

### Acceptance Criteria

- [x] Document which current `users.role` usages are platform/operator concerns versus product context.
- [x] Add or plan account capability fields for vault creation, BKC access, receive-only state, and account status.
- [x] Ensure Firebase Auth verification creates a person-first user record.
- [x] Treat `users.trust_level` as temporary compatibility data until per-vault permissions own trust.
- [x] Add tests or implementation notes for receive-only users.

### Dependencies

- Existing Firebase Auth verification plan.
- Current `User` console implementation.

---

## Issue: Vault Ownership — create a disclosure space per user [COMPLETE]

**Labels:** `backend`, `data-model`, `api`

**Milestone:** Phase 2 — Vault Ownership & Permission Model

### Body

Introduce vault ownership as the source of truth for discloser capabilities. A user may start without a vault, create one later, and remain able to receive access to other vaults.

### Acceptance Criteria

- [x] Define `Vault` ownership with a clear `User` foreign key.
- [x] Enforce initial product rule: one active vault per user.
- [x] Do not prevent future multiple-vault support in naming or authorization design.
- [x] Add owner-scoped queries for BKC and `/my/*` endpoints.
- [x] Add tests for users with no vault, own vault, and own vault plus received access.

### Dependencies

- Account Foundation.

---

## Issue: Relationship Permissions — per-vault trust levels [COMPLETE]

**Labels:** `backend`, `security`, `data-model`

**Milestone:** Phase 2 — Vault Ownership & Permission Model

### Body

Move viewer trust from global user state to the relationship between a viewer and a vault. This enables the same user to have different trust levels with different disclosers.

### Acceptance Criteria

- [x] Define `Permission` or `ViewerRelationship` with `vault_id`, `user_id`, `granted_level`, `status`, `relationship_context`, `source_access_link_id`, and owner notes.
- [x] Update content filtering design to call `viewer.trust_level_for(vault)`.
- [x] Preserve individual content whitelist behavior.
- [x] Add audit fields for permission changes.
- [x] Add tests for different trust levels across two vaults for the same viewer.

### Dependencies

- Vault Ownership.

---

## Issue: BKC Account Management — own-vault command center [COMPLETE]

**Labels:** `backend`, `admin`, `ux`

**Milestone:** Phase 3 — BKC Account Management

### Body

Update BKC so it manages the current user's owned vault and connected viewers instead of assuming a permanent admin/viewer split.

### Acceptance Criteria

- [x] Gate BKC by vault ownership and account capability.
- [x] Keep operator console access separate from personal BKC access.
- [x] Show receive-only users a vault creation path instead of a hard access denial.
- [x] List connected viewers through relationship permissions.
- [x] Update trust controls to edit per-vault permission records.

### Dependencies

- Account Foundation.
- Vault Ownership.
- Relationship Permissions.

---

## Issue: Client Context Switching — own vault and received vaults [COMPLETE]

**Labels:** `frontend`, `api`, `ux`

**Milestone:** Phase 4 — Client Mode Switching

### Body

Represent Admin/Viewer as runtime contexts rather than permanent roles. The client should let a user manage their own vault and browse vaults shared with them from the same account.

### Acceptance Criteria

- [x] Define API response shape for current account capabilities, owned vault, and received vault list.
- [x] Replace role-based mode checks with selected context checks.
- [x] Show own-vault actions only in owned-vault context.
- [x] Show viewer actions only in received-vault context.
- [x] Preserve platform restrictions, including Web L0-L4 limit.

### Dependencies

- BKC Account Management.
- Relationship Permissions.

---

## Issue: Migration & Compatibility — move away from global role/trust [COMPLETE]

**Labels:** `backend`, `testing`, `data-model`

**Milestone:** Phase 5 — Security, Audit, Release Readiness

### Body

Plan and implement compatibility handling so existing `role` and `trust_level` data does not block the new account model.

### Acceptance Criteria

- [x] Identify all references to `User.role` and `User.trust_level`.
- [x] Decide which fields remain for platform operators and which migrate to relationship records.
- [x] Provide a reversible migration or backfill plan.
- [x] Add regression tests for legacy users.
- [x] Update seeds and local console data.

### Dependencies

- Relationship Permissions.
- BKC Account Management.

---

## Issue: Docs & QA — account model documentation and acceptance checks [COMPLETE]

**Labels:** `docs`, `testing`

**Milestone:** Phase 0 — Planning & Issue Sync

### Body

Keep MKDocs, GitHub Issue planning, and monday.com roadmap aligned around the one-person, one-account model.

### Acceptance Criteria

- [x] Add MKDocs page for Account & Role Model.
- [x] Update architecture, API, BKC, and roadmap docs.
- [x] Keep local GitHub Issue Markdown ready for later connector sync.
- [x] Build MKDocs successfully.
- [x] Verify monday.com roadmap board structure and initial items.

### Dependencies

- None.
