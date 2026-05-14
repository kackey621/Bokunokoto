# Multi-Tenant Rollout

The multi-tenant rewrite turns Bokunokoto from "one vault per user" into "many vaults per account, with a per-vault context switcher." This page lists the phased shipping plan; GitHub Issues (`GITHUB_ISSUES_MULTI_TENANT.md`) tracks the work tickets and Monday.com mirrors the same phases.

## Why now

The single-vault rule was a product-scope simplification. The schema already supported multi-vault on the relational side (`permissions`, `audit_logs`, `access_links`, `contents` all carry `vault_id`); the rule survived as `User has_one :vault`, a unique DB index on `vaults.user_id`, the singular `resource :vault` route, and ~30 controller call sites of `current_user.vault`. Lifting the rule is mostly mechanical; the design work in [Multi-Tenant Model](../architecture/multi-tenant-model.md) covers what the rewrite *should* look like.

## Phases

| Phase | Name                              | Goal                                                                                                                     | Exit criteria                                                                                                       |
|-------|-----------------------------------|--------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------|
| MT-0  | Plan & Issue Sync                 | Docs, GitHub Issues markdown, Monday.com board mirror — all aligned.                                                     | MkDocs builds clean; issues file passes lint; Monday import-ready CSV is parsable.                                  |
| MT-1  | Schema Lift                       | Drop `vaults.user_id` unique index; add `default_vault_id`, `slug`, `kind`, `archived_at`; add `account_capabilities.vault_quota`. | Migrations run forward+backward on dev DB; schema.rb diff reviewed; backfill script tested on staging seed.        |
| MT-2  | Model & Authorization Refactor    | `User has_many :owned_vaults`; `vault.owner` association; `current_user.owns?(vault)`; quota check on create.            | Unit tests cover quota cap, multi-vault creation, ownership predicate; legacy `user.vault` still returns default.   |
| MT-3  | API Surface                       | Add `/my/vaults` (plural), `/my/vaults/:id/*`, `/my/default_vault`, `X-BK-Active-Vault` resolver. Keep deprecated aliases. | Postman collection green; contract tests for `409 active_vault_required`; deprecation header emitted on legacy routes. |
| MT-4  | BKC Multi-Vault                   | Vault switcher in BKC top-right; dashboard, content, viewers, audit, analytics, links, forensics all scoped to active vault. | Manual QA: create 2 vaults, switch between them, confirm data isolation; system tests pass.                         |
| MT-5  | Flutter Context Switcher          | Client persists `active_vault_id`; sends `X-BK-Active-Vault`; switcher UI in app bar; empty state for zero-vault accounts. | Two-vault user can switch on iOS, Android, Web; vault-archive flow handled; accessibility audit pass.               |
| MT-6  | Migration & Compatibility         | Backfill `default_vault_id` for existing users; soft-remove deprecated `GET/POST /my/vault` one release later.            | Production backfill dry-run on staging; deprecation warnings in logs after rollout; client release N+1 drops legacy. |
| MT-7  | QA, Audit, Forensics              | Cross-vault leakage tests; audit immutability per vault; forensic dashboard per vault.                                   | Penetration test sign-off (cross-vault data access denied); audit row count matches per-vault expectation.          |
| MT-8  | Future-tier prep (specced, deferred) | `vault_memberships` schema review; `kind: organization` discriminator promotion plan; vault transfer flow design.       | Design doc only; no code shipped.                                                                                   |

## Sequencing rules

- **MT-1 before MT-2.** Schema is the foundation; model code shouldn't pre-empt the index drop.
- **MT-2 before MT-3.** Authorization predicates feed the resolver in MT-3.
- **MT-3 before MT-4 and MT-5.** Both clients consume the new API; ship server-side first.
- **MT-4 and MT-5 can parallelize** once MT-3 is GA, but the Flutter team waits for the contract test suite from MT-3.
- **MT-6 is gated on MT-5 release.** Don't remove deprecated routes until the released client no longer calls them.
- **MT-7 is the launch gate.** No production rollout without cross-vault leakage tests.

## Risks and mitigations

| Risk                                                                              | Mitigation                                                                                          |
|-----------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------|
| Existing fixtures and tests assume `user.create_vault!` succeeds exactly once     | MT-2 includes a fixture sweep; replace "second vault forbidden" tests with "quota exceeded" tests.  |
| Flutter client deployed N versions back keeps calling `/my/vault`                 | Keep deprecated alias for ≥ 1 release cycle; add `Deprecation` header so the client team sees it.   |
| Vault context not sent → 409 storm in production                                  | Server emits a `default_vault_id` fallback; client falls back to last-known-good `active_vault_id`. |
| User accidentally archives their only vault                                       | UI shows a confirmation modal with the empty-state implication; archive is soft, restore is one tap.|
| Cross-vault data leakage via shared cache key                                     | Cache keys include `vault_id`; integration test sweeps for cross-vault cache hits.                  |
| BKC operator override accidentally reveals one vault's data in another's screen   | Override token carries `vault_id` scope; the operator banner shows the scoped vault.                |

## Acceptance checklist (top-level)

- [ ] A user can own up to `account.vault_quota` vaults from BKC.
- [ ] A user with two owned vaults can switch context in BKC and in Flutter; all surfaces re-scope.
- [ ] A viewer with permissions on two vaults sees both in the switcher and can move without re-auth.
- [ ] `/api/v1/my/*` without `X-BK-Active-Vault` and without `default_vault_id` returns `409 active_vault_required`.
- [ ] Audit logs cannot be written without `vault_id`.
- [ ] Cross-vault data access (e.g., requesting Vault B's content while active in Vault A) returns 404, not 403, to avoid existence disclosure.
- [ ] Web platform L4 cap is applied per active vault.
- [ ] Deprecated routes emit `Deprecation: true` header and are removed in release N+1.
- [ ] Legacy `users.role` / `users.trust_level` remain only as operator/console compatibility data.
- [ ] MkDocs nav exposes [Multi-Tenant Model](../architecture/multi-tenant-model.md), [Context Switching](../architecture/context-switching.md), [Comparative Analysis](../architecture/comparative-analysis.md), and this rollout page.
