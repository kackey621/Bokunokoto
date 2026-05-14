# GitHub Issues — Multi-Tenant Rewrite Epic (MT)

This file is the source of truth for the multi-tenant rewrite tickets. Each issue is a small, shippable unit with explicit relations encoded as `Parent`, `Blocked by`, `Blocks`, and `Related`. When the GitHub connector is wired up, these become real Issues; the parent issue becomes a tracking issue with sub-issue checkboxes. Monday.com mirrors the same tickets in `monday/items.csv`.

Relations vocabulary follows GitHub's built-in [issue sub-issues](https://docs.github.com/en/issues) + the standard "blocked by" convention used by ZenHub/Linear.

---

## Epic Tracker: MT-EPIC — Multi-Tenant Rewrite (Account + N Vaults)

**Labels:** `epic`, `multi-tenant`, `architecture`
**Milestone:** MT — Multi-Tenant Rewrite
**Type:** Epic / tracking issue

### Body

Lift Bokunokoto from "one vault per user" to "one account owns N vaults" (FB Pages + Instagram switcher model). The schema is mostly ready; the work is dropping the unique index on `vaults.user_id`, swapping `has_one` for `has_many`, adding a per-vault context switcher, and re-scoping every `/my/*` route to a resolved active vault.

See `docs/architecture/multi-tenant-model.md` for the design and `docs/roadmap/multi-tenant-rollout.md` for the phased plan.

### Sub-issues (in execution order)

- [ ] #MT-1 Drop unique index, add quota/slug/kind/archived_at, add default_vault_id
- [ ] #MT-2 Model refactor: `User has_many :owned_vaults`, `vault.owner`, `current_user.owns?`
- [ ] #MT-3 Quota enforcement + AccountCapability.vault_quota
- [ ] #MT-4 Active vault resolver (header + route param + default fallback)
- [ ] #MT-5 Plural `/api/v1/my/vaults` endpoints
- [ ] #MT-6 Deprecated alias retention for `/my/vault` (singular)
- [ ] #MT-7 Re-scope `/my/contents`, `/my/analytics`, `/my/audit_logs` to active vault
- [ ] #MT-8 BKC vault switcher (top-right dropdown)
- [ ] #MT-9 BKC: re-scope dashboard, contents, viewers, links, forensics, analytics
- [ ] #MT-10 Flutter client: context switcher UI + secure storage of active vault id
- [ ] #MT-11 Flutter client: `X-BK-Active-Vault` header on every request
- [ ] #MT-12 Empty-state UI for zero-vault accounts
- [ ] #MT-13 Vault soft-archive flow (BKC + Flutter)
- [ ] #MT-14 Cross-vault data-leakage test sweep
- [ ] #MT-15 Backfill `default_vault_id` for existing users
- [ ] #MT-16 Audit log per-vault verification
- [ ] #MT-17 Deprecation header rollout + telemetry
- [ ] #MT-18 Operator-only override flow per active vault
- [ ] #MT-19 Documentation pass + MkDocs build verification
- [ ] #MT-20 v1 release gate: cross-vault penetration test sign-off

### Acceptance

- Listed in `docs/roadmap/multi-tenant-rollout.md` § "Acceptance checklist".

---

## MT-1 — Schema lift: drop unique index, add default_vault_id, slug, kind, archived_at

**Labels:** `backend`, `data-model`, `migration`, `multi-tenant`
**Milestone:** MT-1 — Schema Lift
**Parent:** MT-EPIC
**Blocks:** MT-2
**Type:** Task

### Body

Drop the `UNIQUE INDEX vaults_on_user_id` and add the columns needed for multi-tenant operation.

### Tasks

- [ ] Generate migration `RemoveUniqueIndexFromVaultsUserId` (drop unique, add non-unique).
- [ ] Generate migration `AddMultiTenantColumnsToVaults` (`slug`, `kind`, `archived_at`).
- [ ] Generate migration `AddDefaultVaultIdToUsers` (nullable FK).
- [ ] Generate migration `AddVaultQuotaToAccountCapabilities` (or `users` if capabilities don't exist yet — see `docs/architecture/data-model.md` §AccountCapability).
- [ ] Schema.rb regenerated; reviewed; checked into repo.
- [ ] Forward + backward migration tested on a clean dev DB.

### Acceptance

- `db/schema.rb` shows non-unique index on `vaults.user_id` and the new columns.
- `bin/rails db:rollback STEP=4 && bin/rails db:migrate` passes cleanly.

### Dependencies

- None.

---

## MT-2 — Model refactor: User `has_many :owned_vaults`, vault.owner, owns? predicate

**Labels:** `backend`, `data-model`, `multi-tenant`
**Milestone:** MT-1 — Schema Lift
**Parent:** MT-EPIC
**Blocked by:** MT-1
**Blocks:** MT-3, MT-4, MT-7
**Type:** Task

### Body

Replace `User has_one :vault` with `has_many :owned_vaults`. Expose `vault.owner` via aliased association so new code reads naturally. Add `User#owns?(vault)`. Keep `User#vault` returning the default vault (or first owned) as a one-release compatibility shim so legacy callers don't break in the same PR.

### Tasks

- [ ] `User has_many :owned_vaults, class_name: "Vault", foreign_key: :user_id, dependent: :destroy`
- [ ] `Vault belongs_to :owner, class_name: "User", foreign_key: :user_id` (alongside existing `:user`)
- [ ] `Vault.validates :user_id, uniqueness: true` → remove
- [ ] `User#owns?(vault)` → `vault&.owner_id == id`
- [ ] `User#default_vault` returns the vault pointed at by `default_vault_id`, falling back to `owned_vaults.first`
- [ ] `User#vault` (deprecated) delegates to `default_vault` with a one-time `ActiveSupport::Deprecation` warning
- [ ] Update `User#trust_level_for(vault)` to use `owns?` instead of `self.vault == vault`
- [ ] Unit tests for: own one vault, own two vaults, own zero vaults, owns? predicate

### Acceptance

- `bin/rails test test/models/user_test.rb` green.
- `bin/rails test test/models/vault_test.rb` green.
- Existing controller tests still pass (compatibility shim in place).

### Dependencies

- Blocked by MT-1.

---

## MT-3 — Vault quota enforcement on create

**Labels:** `backend`, `multi-tenant`, `quota`
**Milestone:** MT-2 — Model & Authorization
**Parent:** MT-EPIC
**Blocked by:** MT-2
**Blocks:** MT-5
**Type:** Task

### Body

Enforce `AccountCapability.vault_quota` (default 3, beta tester 10, operator unlimited) when a user creates a new vault. Return a clear error with the current count and limit.

### Tasks

- [ ] Service object `Vaults::CreateForOwner` that checks quota
- [ ] Custom exception `Vaults::QuotaExceeded` rendered as `422 vault_quota_exceeded` with body `{count, limit}`
- [ ] Default `vault_quota = 3`; configurable via seeds
- [ ] Tests: at-quota → 422, under-quota → 201, operator → unlimited

### Acceptance

- Quota check runs on `POST /api/v1/my/vaults` and `POST /bkc/vaults`.

### Dependencies

- Blocked by MT-2.

---

## MT-4 — Active vault resolver (header + param + default fallback)

**Labels:** `backend`, `multi-tenant`, `api`
**Milestone:** MT-2 — Model & Authorization
**Parent:** MT-EPIC
**Blocked by:** MT-2
**Blocks:** MT-5, MT-7
**Type:** Task

### Body

Implement `current_vault` resolution in `ApplicationController` (and `Api::V1::BaseController`) per the contract in `docs/architecture/context-switching.md`: route `:vault_id` → `X-BK-Active-Vault` → `users.default_vault_id` → `409 active_vault_required`.

### Tasks

- [ ] `ApplicationController#current_vault` and `#current_vault!`
- [ ] Custom exception `Bkc::ActiveVaultRequired` rendered as `409` with owned vault list
- [ ] Reject vaults the current user neither owns nor has active permission on (`404` to avoid existence disclosure)
- [ ] Tests: param wins over header, header wins over default, missing all → 409, foreign vault → 404

### Acceptance

- Resolver is used by at least one `/my/*` endpoint by the end of this ticket (as a smoke test).

### Dependencies

- Blocked by MT-2.

---

## MT-5 — Plural `/api/v1/my/vaults` endpoints

**Labels:** `backend`, `api`, `multi-tenant`
**Milestone:** MT-3 — API Surface
**Parent:** MT-EPIC
**Blocked by:** MT-3, MT-4
**Blocks:** MT-7, MT-10
**Type:** Task

### Body

Add `resources :vaults` under `/api/v1/my/`. Endpoints: index, show, create, update, archive, restore. Plus `PATCH /api/v1/my/default_vault`.

### Tasks

- [ ] `routes.rb`: `namespace :my { resources :vaults, only: %i[index show create update] do member { post :archive; post :restore } } }`
- [ ] `Api::V1::My::VaultsController` rewritten for plural index/show
- [ ] `Api::V1::My::DefaultVaultController#update`
- [ ] Serialize `kind`, `slug`, `archived_at`, `default_vault?` in responses
- [ ] Controller tests for each action

### Acceptance

- Postman/RSpec collection green; the response shape for `GET /my/vaults` matches the schema doc.

### Dependencies

- Blocked by MT-3 and MT-4.

---

## MT-6 — Deprecated alias retention for `/my/vault` (singular)

**Labels:** `backend`, `api`, `compat`
**Milestone:** MT-3 — API Surface
**Parent:** MT-EPIC
**Blocked by:** MT-5
**Blocks:** MT-17
**Type:** Task

### Body

Keep `/api/v1/my/vault` (singular) responding for one release cycle so the deployed Flutter client doesn't break. Emit `Deprecation: true` header on every response.

### Tasks

- [ ] Singular route still maps to a thin controller that calls `current_user.default_vault`
- [ ] `Deprecation: true` and `Link: <…/multi-tenant-model>; rel="successor-version"` on responses
- [ ] `POST /api/v1/my/vault` allowed only when `owned_vaults.count == 0`; otherwise `409` with hint to use `/my/vaults`
- [ ] Tests for both happy path and the multi-vault redirect

### Acceptance

- Existing tests for `/my/vault` are kept and tagged `@deprecated`.

### Dependencies

- Blocked by MT-5.

---

## MT-7 — Re-scope `/my/contents`, `/my/analytics`, `/my/audit_logs` to active vault

**Labels:** `backend`, `api`, `multi-tenant`
**Milestone:** MT-3 — API Surface
**Parent:** MT-EPIC
**Blocked by:** MT-2, MT-4, MT-5
**Blocks:** MT-9, MT-11
**Type:** Task

### Body

Today these controllers call `current_user.vault` directly. Replace with `current_vault!` from MT-4. Add `X-BK-Active-Vault` requirement; emit `409` when missing.

### Tasks

- [ ] `Api::V1::My::ContentsController` → use `current_vault`
- [ ] `Api::V1::My::AnalyticsController` (6 actions) → use `current_vault`
- [ ] `Api::V1::My::AuditLogsController` → use `current_vault`
- [ ] `Api::V1::AccountController#context` → return owned vault **list** (array), not singular
- [ ] Update tests to send `X-BK-Active-Vault` header

### Acceptance

- All controller tests under `test/controllers/api/v1/my/*` green with the new contract.

### Dependencies

- Blocked by MT-2, MT-4, MT-5.

---

## MT-8 — BKC vault switcher (top-right dropdown)

**Labels:** `bkc`, `frontend`, `multi-tenant`, `ux`
**Milestone:** MT-4 — BKC Multi-Vault
**Parent:** MT-EPIC
**Blocked by:** MT-5
**Blocks:** MT-9
**Type:** Task

### Body

Add a vault switcher to the BKC top bar. Persists the active vault as a signed cookie (`bk_active_vault`). Renders two grouped lists: "Your vaults" and "Operator override" (for platform operators only).

### Tasks

- [ ] `Bkc::ApplicationController#current_vault` reads the cookie, falls back to `users.default_vault_id`
- [ ] ViewComponent `Bkc::VaultSwitcherComponent`
- [ ] `POST /bkc/active_vault` sets the cookie + redirects back
- [ ] Long-press / right-click → "Set as default" calls `PATCH /api/v1/my/default_vault`
- [ ] System test: create two vaults via console seed, switch between them in BKC

### Acceptance

- Manual QA pass on a two-vault account.

### Dependencies

- Blocked by MT-5.

---

## MT-9 — BKC: re-scope dashboard, contents, viewers, links, forensics, analytics

**Labels:** `bkc`, `backend`, `multi-tenant`
**Milestone:** MT-4 — BKC Multi-Vault
**Parent:** MT-EPIC
**Blocked by:** MT-7, MT-8
**Blocks:** MT-14
**Type:** Task

### Body

Sweep `app/controllers/bkc/*` for `current_user.vault` and replace with the cookie-resolved `current_vault`. Update views to show the active vault name in the page header.

### Tasks

- [ ] `Bkc::DashboardController` → use `current_vault`
- [ ] `Bkc::ContentsController` (4 places) → `current_vault`
- [ ] `Bkc::ViewersController` (2 places) → `current_vault`
- [ ] `Bkc::AccessLinksController` (7 places) → `current_vault`
- [ ] `Bkc::ForensicsController` (3 places) → `current_vault`
- [ ] `Bkc::AnalyticsController` (5 places) → `current_vault`
- [ ] `Bkc::VaultsController#create` → drop "already has vault" guard, replace with quota check
- [ ] Add active vault name + slug to BKC header partial

### Acceptance

- Switching vault in the BKC switcher swaps all the lists and counters without a hard refresh issue.

### Dependencies

- Blocked by MT-7, MT-8.

---

## MT-10 — Flutter client: context switcher UI + secure storage

**Labels:** `frontend`, `multi-tenant`, `ux`
**Milestone:** MT-5 — Flutter Switcher
**Parent:** MT-EPIC
**Blocked by:** MT-5
**Blocks:** MT-11, MT-12
**Type:** Task

### Body

Flutter context switcher in the app bar (mobile) and left rail (web). Persists `active_vault_id` in `flutter_secure_storage` (mobile) or `sessionStorage` + `localStorage` (web).

### Tasks

- [ ] `VaultContextProvider` (Riverpod) holding `activeVaultId`, `ownedVaults`, `receivedVaults`
- [ ] `VaultSwitcher` widget
- [ ] Persistence layer (secure storage adapter)
- [ ] Accessibility: VoiceOver / TalkBack labels per switcher item
- [ ] Loads `GET /api/v1/account/context` on launch and on switcher open

### Acceptance

- Manual two-vault flow works on iOS, Android, Web.

### Dependencies

- Blocked by MT-5.

---

## MT-11 — Flutter client: `X-BK-Active-Vault` header on every request

**Labels:** `frontend`, `multi-tenant`, `api`
**Milestone:** MT-5 — Flutter Switcher
**Parent:** MT-EPIC
**Blocked by:** MT-7, MT-10
**Type:** Task

### Body

Dio interceptor that sets `X-BK-Active-Vault` from `VaultContextProvider`. Also handles `409 active_vault_required` by opening the switcher.

### Tasks

- [ ] Interceptor adds header on every request
- [ ] 409 response → pop the switcher modal
- [ ] 403 `permission_revoked` → re-fetch context, drop the revoked vault, prompt
- [ ] Tests for the interceptor

### Acceptance

- API client never sends a request without the header (except `/account/context`).

### Dependencies

- Blocked by MT-7, MT-10.

---

## MT-12 — Empty-state UI for zero-vault accounts

**Labels:** `frontend`, `bkc`, `ux`, `multi-tenant`
**Milestone:** MT-5 — Flutter Switcher
**Parent:** MT-EPIC
**Blocked by:** MT-10
**Type:** Task

### Body

When a user has zero owned vaults AND zero received permissions, show the empty state in both BKC and Flutter: "You can create a vault" + "I have an invitation link."

### Tasks

- [ ] BKC `Bkc::OnboardingController#new_vault` polished
- [ ] Flutter `VaultEmptyStateScreen` with two CTAs
- [ ] Copy reviewed for disability/LGBTQ inclusion

### Acceptance

- Manual QA on a brand-new account.

### Dependencies

- Blocked by MT-10.

---

## MT-13 — Vault soft-archive flow

**Labels:** `backend`, `frontend`, `bkc`, `multi-tenant`
**Milestone:** MT-4 — BKC Multi-Vault
**Parent:** MT-EPIC
**Blocked by:** MT-1, MT-9
**Blocks:** MT-14
**Type:** Task

### Body

Soft-archive a vault (`archived_at` set). Archived vaults are hidden from `/account/context` unless `include_archived=true`. If the archived vault was the active one, the resolver returns 409 and the switcher prompts.

### Tasks

- [ ] `POST /api/v1/my/vaults/:id/archive` + restore
- [ ] BKC archive confirmation modal
- [ ] Flutter archive option in vault settings
- [ ] Operator hard-delete remains separate

### Acceptance

- Archive → switcher loses the entry; restore → entry comes back.

### Dependencies

- Blocked by MT-1, MT-9.

---

## MT-14 — Cross-vault data-leakage test sweep

**Labels:** `testing`, `security`, `multi-tenant`
**Milestone:** MT-7 — QA & Audit
**Parent:** MT-EPIC
**Blocked by:** MT-9, MT-13
**Blocks:** MT-20
**Type:** Task

### Body

Write integration tests that prove a user active in Vault A cannot read, write, or audit Vault B (where they have zero permission). Also: a viewer with L3 in Vault A and L9 in Vault B cannot see L9 content in Vault A.

### Tasks

- [ ] Cross-vault content read denied (404, not 403)
- [ ] Cross-vault audit log read denied
- [ ] Cross-vault analytics read denied
- [ ] Cross-vault permission update denied
- [ ] Cache-key sweep: confirm `vault_id` is in every per-vault cache key
- [ ] Header forgery: `X-BK-Active-Vault` pointing at foreign vault → 404

### Acceptance

- All test cases red before code change, green after.

### Dependencies

- Blocked by MT-9, MT-13.

---

## MT-15 — Backfill `default_vault_id` for existing users

**Labels:** `backend`, `migration`, `ops`
**Milestone:** MT-6 — Migration
**Parent:** MT-EPIC
**Blocked by:** MT-1
**Type:** Task

### Body

Run a backfill task that sets `users.default_vault_id` to the single owned vault for users who currently own exactly one (the vast majority pre-rewrite). Idempotent; safe to re-run.

### Tasks

- [ ] `lib/tasks/multi_tenant_backfill.rake`
- [ ] Dry-run mode that logs counts
- [ ] Run on staging snapshot before production
- [ ] Telemetry: count of users updated, count skipped

### Acceptance

- Backfill on a staging snapshot produces the expected counts.

### Dependencies

- Blocked by MT-1.

---

## MT-16 — Audit log per-vault verification

**Labels:** `backend`, `security`, `audit`, `multi-tenant`
**Milestone:** MT-7 — QA & Audit
**Parent:** MT-EPIC
**Blocked by:** MT-7
**Type:** Task

### Body

Confirm every `AuditLog` write carries `vault_id`. Add a model-level NOT NULL guard if missing. Update the audit log viewer in BKC to filter by `vault_id` of the active vault.

### Tasks

- [ ] Migration: `audit_logs.vault_id` NOT NULL (if not already)
- [ ] Model: `validates :vault_id, presence: true`
- [ ] Controller test: writing audit without vault_id raises
- [ ] BKC audit viewer filtered by active vault

### Acceptance

- Production audit row sample shows 100% vault_id coverage.

### Dependencies

- Blocked by MT-7.

---

## MT-17 — Deprecation header rollout + telemetry

**Labels:** `backend`, `ops`, `compat`
**Milestone:** MT-6 — Migration
**Parent:** MT-EPIC
**Blocked by:** MT-6
**Type:** Task

### Body

Track how often the deprecated `/api/v1/my/vault` (singular) endpoint is hit. When telemetry shows ≤ 1% of users still on the old client, schedule removal.

### Tasks

- [ ] Per-request log entry with `user_agent`, `bk_client_version`
- [ ] Daily aggregation
- [ ] Removal PR scheduled but not merged

### Acceptance

- Operator dashboard shows the deprecation trend.

### Dependencies

- Blocked by MT-6.

---

## MT-18 — Operator-only override flow per active vault

**Labels:** `backend`, `bkc`, `security`, `multi-tenant`
**Milestone:** MT-4 — BKC Multi-Vault
**Parent:** MT-EPIC
**Blocked by:** MT-9
**Type:** Task

### Body

When a platform operator needs to act on a vault they don't own (abuse response, compliance), they generate a time-boxed override token tied to a specific `vault_id`. BKC shows a red banner; every action is logged to the audit log with `action: operator_override`.

### Tasks

- [ ] `OperatorOverride` model: `operator_id`, `vault_id`, `reason`, `expires_at`
- [ ] BKC sees the banner; switcher shows an "operator context" pill
- [ ] All audit rows during override carry `actor_role: operator`
- [ ] Time-boxed: defaults to 30 minutes; renewal requires re-justification

### Acceptance

- Two-step: open override, perform action, close override; all auditable.

### Dependencies

- Blocked by MT-9.

---

## MT-19 — Documentation pass + MkDocs build verification

**Labels:** `docs`
**Milestone:** MT-0 — Plan & Sync
**Parent:** MT-EPIC
**Type:** Task

### Body

Keep MkDocs aligned with the rewrite. Already-shipped docs: `multi-tenant-model.md`, `context-switching.md`, `comparative-analysis.md`, `multi-tenant-rollout.md`. This ticket is the rolling docs sweep as code lands.

### Tasks

- [ ] `mkdocs build --strict` passes
- [ ] All cross-links resolve
- [ ] Nav order matches the rollout phase order
- [ ] Each MT-N issue has at least one doc reference in its acceptance criteria

### Acceptance

- CI passes; preview build matches the design doc URLs.

### Dependencies

- None (lives alongside the implementation work).

---

## MT-20 — v1 release gate: cross-vault penetration test sign-off

**Labels:** `testing`, `security`, `release`, `multi-tenant`
**Milestone:** MT-7 — QA & Audit
**Parent:** MT-EPIC
**Blocked by:** MT-14, MT-16, MT-18
**Type:** Task

### Body

External or internal pentest of the multi-tenant boundary. No production rollout without sign-off.

### Tasks

- [ ] Threat model review (writeup in `docs/security/`)
- [ ] Cross-vault data access attempts (read, write, audit, analytics)
- [ ] Header forgery (`X-BK-Active-Vault` pointing at foreign vault)
- [ ] Operator override misuse scenarios
- [ ] Cache poisoning across vaults
- [ ] Sign-off document filed under `docs/security/multi-tenant-pentest-YYYYMMDD.md`

### Acceptance

- Sign-off doc merged; no Critical/High findings open.

### Dependencies

- Blocked by MT-14, MT-16, MT-18.

---

## Relations cheat sheet

```
MT-1 ──> MT-2 ──> MT-3 ──┐
                ├──> MT-4 ──> MT-5 ──┬──> MT-6 ──> MT-17
                │                    ├──> MT-7 ──> MT-9 ──> MT-13 ──> MT-14 ──┐
                │                    │              └──> MT-18 ───────────────┤
                │                    │                                        ├──> MT-20
                │                    ├──> MT-8 ──> MT-9 (joined)              │
                │                    └──> MT-10 ──> MT-11                     │
                │                                  └──> MT-12                 │
                │                                                             │
MT-1 ──> MT-15                                                                │
MT-7 ──> MT-16 ───────────────────────────────────────────────────────────────┘

MT-19 runs in parallel; gates docs CI.
```

## Label dictionary (multi-tenant additions)

| Label            | Color      | Description                                                    |
|------------------|------------|----------------------------------------------------------------|
| `multi-tenant`   | `#1f6feb`  | Multi-tenant rewrite scope                                     |
| `epic`           | `#3fb950`  | Tracking issue                                                 |
| `migration`      | `#bc8cff`  | Schema / data migration                                        |
| `compat`         | `#d29922`  | Backwards compatibility / deprecation                          |
| `quota`          | `#39d353`  | Vault quota / capability gating                                |
| `audit`          | `#f85149`  | Audit logging / immutability                                   |
| `release`        | `#a371f7`  | Release gating                                                 |
| `ops`            | `#8b949e`  | Operations / telemetry                                         |

## Linking to Monday.com

Each issue here maps 1:1 to a Monday item in `monday/items.csv`. The `Issue ID` column in Monday matches the `MT-N` slug above. Dependencies in Monday are encoded in `monday/dependencies.csv` using the same slugs.
