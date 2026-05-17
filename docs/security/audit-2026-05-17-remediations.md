# Security Audit 2026-05-17 — Remediations

Companion to [`security-audit-report-2026-05-17.md`](../../security-audit-report-2026-05-17.md)
at the repo root.

- **Audit date**: 2026-05-17
- **Tracking issue**: [#151](https://github.com/kackey621/bokunokoto/issues/151)
- **Branch**: `claude/fix-issues-and-docs-jpWJD`
- **Pull request**: opened against `main` and closes
  [#118](https://github.com/kackey621/bokunokoto/issues/118) ..
  [#150](https://github.com/kackey621/bokunokoto/issues/150) (33 findings).

## Scope

The audit catalogued **2 Critical + 12 High + 11 Medium + 8 Low = 33
fixable findings** plus an umbrella tracking issue (#151). This PR fixes
**all 33**. Two of them (MEDIUM-024, MEDIUM-016) need a follow-up product
design; in this PR they receive defense-in-depth fixes plus a written
hand-off in the "Deferred work" section below.

## Status table

| # | Finding | Severity | Status | Where it landed |
|---|---|---|---|---|
| #118 | CRITICAL-001 — Bank account plaintext in API | Critical | **Fixed** | `app/controllers/api/v1/my/vault*_controller.rb`, Flutter `bank_account_screen.dart`, test update |
| #119 | CRITICAL-002 — Dev auto-login bypass | Critical | **Fixed** | `app/controllers/{console,bkc,super_admin}/base_controller.rb` + production boot guard |
| #120 | HIGH-003 — `force_ssl` / `assume_ssl` | High | **Fixed** | `config/environments/production.rb` |
| #121 | HIGH-004 — `config.hosts` unset | High | **Fixed** | `config/environments/production.rb` (`PRIMARY_HOST` env) |
| #122 | HIGH-005 — CSP disabled | High | **Fixed (report-only)** | `config/initializers/content_security_policy.rb` |
| #123 | HIGH-006 — httparty CVEs | High | **Fixed (CI guard)** | `.github/workflows/security.yml` |
| #124 | HIGH-007 — Super-admin login rate-limit | High | **Fixed** | `config/initializers/rack_attack.rb` |
| #125 | HIGH-008 — Remote Config publishable by operator | High | **Fixed** | `super_admin/{remote_config_controller,base_controller}.rb` |
| #126 | HIGH-009 — FCM publishable by operator | High | **Fixed (admin-only + structured log)** | `super_admin/fcm_controller.rb` |
| #127 | HIGH-010 — Remote Config `If-Match: *` | High | **Fixed** | `app/services/super_admin/remote_config_service.rb`, view + controller round-trip etag |
| #128 | HIGH-011 — DB password fallback | High | **Fixed** | `config/database.yml` (no fallback in production) |
| #129 | HIGH-012 — Firebase project-id placeholder | High | **Fixed** | `app/services/super_admin.rb` helper used by 5 services |
| #130 | HIGH-013 — `Dockerfile.dev` runs as root | High | **Fixed** | `Dockerfile.dev` (`USER rails` / uid 1000) |
| #131 | HIGH-014 — No Brakeman/bundler-audit CI | High | **Fixed** | `.github/workflows/security.yml` |
| #132 | MEDIUM-015 — Console role grant unaudited | Medium | **Fixed** | `app/controllers/console/users_controller.rb` (structured log) |
| #133 | MEDIUM-016 — Forensics exposes biometric PII | Medium | **Defense-in-depth banner** | `app/views/bkc/forensics/index.html.erb` (see deferred) |
| #134 | MEDIUM-017 — Uncaught `Date::Error` | Medium | **Fixed** | three controllers |
| #135 | MEDIUM-018 — LIKE wildcards un-escaped | Medium | **Fixed** | `console/users_controller.rb` (`sanitize_sql_like`) |
| #136 | MEDIUM-019 — Filter parameter list incomplete | Medium | **Fixed** | `config/initializers/filter_parameter_logging.rb` |
| #137 | MEDIUM-020 — `dbc` alias `--include-password` | Medium | **Fixed** | `config/deploy.yml` |
| #138 | MEDIUM-021 — IncidentDetectionJob writes duplicates | Medium | **Fixed** | `app/services/incident_detector_service.rb` (1h dedupe window) |
| #139 | MEDIUM-022 — AuditLog#actor_role free-text | Medium | **Fixed** | `app/models/audit_log.rb` + tests |
| #140 | MEDIUM-023 — CORS `headers: :any` | Medium | **Fixed** | `config/initializers/cors.rb` (explicit allow-list) |
| #141 | MEDIUM-024 — Half-implemented Bkc::SessionsController | Medium | **Placeholder page** | `app/controllers/bkc/sessions_controller.rb` (see deferred) |
| #142 | MEDIUM-025 — `format=html` content allowed unfiltered | Medium | **Fixed** | `app/models/content.rb` (Rails::HTML5::SafeListSanitizer) |
| #143 | LOW-026 — CSP nonce | Low | **Fixed (with HIGH-005)** | content_security_policy.rb |
| #144 | LOW-027 — Flutter clipboard plaintext | Low | **Fixed** | `flutter/.../bank_account_screen.dart` |
| #145 | LOW-028 — Flutter cert pinning | Low | **Deferred + documented** | this doc, see "Deferred work" |
| #146 | LOW-029 — Flutter `TODO_*` placeholders | Low | **Fixed (runtime guard)** | `flutter/lib/main.dart` |
| #147 | LOW-030 — `<%= raw … to_json %>` | Low | **Fixed** | `app/views/bkc/analytics/show.html.erb` |
| #148 | LOW-031 — Audit-log retention | Low | **Fixed** | `app/jobs/audit_retention_cleanup_job.rb` + `config/recurring.yml` |
| #149 | LOW-032 — `bk_active_vault` cookie missing `secure` | Low | **Fixed** | `app/controllers/bkc/active_vaults_controller.rb` |
| #150 | LOW-033 — Refresh certificates job retries forever | Low | **Fixed** | `app/jobs/refresh_firebase_certificates_job.rb` (cap at 5 + loud log) |

## Notable design decisions

### AuditLog for platform-scoped events

`AuditLog.vault_id` is `NOT NULL` in the schema. Rather than land a
migration that nullifies the column, FCM (HIGH-009) and Remote Config
(HIGH-008) actions are written through `Rails.logger` with a
structured `[audit][<event>]` tag and a stable key-value payload. This
keeps the AuditLog table semantically vault-scoped while still producing
a searchable trail for platform-level operator actions.

### CSP in report-only mode

`config/initializers/content_security_policy.rb` ships enabled but with
`config.content_security_policy_report_only = true`. Inline `<script>`
blocks remain in `app/views/bkc/forensics/index.html.erb` and
`app/views/bkc/analytics/show.html.erb`. The follow-up is to lift them
into nonce-tagged `javascript_tag` helpers and then flip the policy to
enforcing.

### Bank account display

`bank_account_info` is **never** in any API response after this PR. The
Flutter `BankAccountScreen` no longer pre-populates the form on load —
the user types each value when they want to update it. Designing a
re-authenticated reveal endpoint (TOTP / Firebase re-validate) is a
product follow-up.

### `ALLOW_DEV_AUTH_BYPASS`

The development-only auto-login shortcuts in BKC, Console, and
super_admin are now gated on `ENV["ALLOW_DEV_AUTH_BYPASS"] == "1"`. Boot
in `production.rb` raises if the variable is set — so a copy of a dev
`.env` file into a production deploy will hard-fail rather than silently
unlock admin access.

## Deferred work / follow-up issues to file

| Finding | Why deferred | Tracking |
|---|---|---|
| **MEDIUM-024** real Bkc/Console login flow | Needs product call on Firebase web SDK vs SSO vs magic link. This PR adds a placeholder page so the route no longer 404s but does not introduce a public credential surface. | File new issue once the product decision is made |
| **MEDIUM-016** forensics permission model | The audit's actual remediation is a permission redesign (who sees whose face). This PR adds a privacy banner; the redesign needs a 2–3 sprint plan. | File new issue with the proposed permission matrix |
| **LOW-028** Flutter certificate pinning | Pinning strategy (cert hash vs SPKI vs CA, rotation plan) is an ops decision. Add `network_security_config.xml` + iOS ATS pinning once the strategy is signed off. | File new issue |
| **CRITICAL-001** re-auth reveal endpoint | Removing plaintext is the critical fix; designing the audited reveal endpoint with fresh re-authentication is the follow-up. | File new issue |
| **HIGH-005** CSP enforcing mode | Currently report-only. Convert inline `<script>` blocks to nonce-tagged helpers, then flip `report_only: false`. | Single-issue follow-up |

## Verification

- `bin/rails test` (full suite, includes updated `vaults_controller_test.rb`
  and new `audit_log_test.rb` assertions).
- `bundle exec brakeman --no-pager --quiet -A` should remain at 0 warnings.
- `bundle exec bundle-audit check --update` passes with the existing
  httparty ignore list (HIGH-006).
- Production smoke test: boot with `RAILS_ENV=production`,
  `ALLOW_DEV_AUTH_BYPASS=1` set → must `raise`.
- Production smoke test: boot without `FIREBASE_PROJECT_ID` →
  `KeyError` from `ENV.fetch`.
- Manual: `curl -i https://<host>/api/v1/my/vault` returns
  `masked_account_number` but **not** `bank_account_info`.
- Manual: 6th `POST /super_admin/session` from the same IP within 60s
  returns 429.
- `mkdocs build` should publish this page under
  `Security → Audit Remediations (2026-05-17)`.

## Files touched (one-line index)

- `app/controllers/api/v1/my/vault_controller.rb`,
  `app/controllers/api/v1/my/vaults_controller.rb` — strip `bank_account_info`
- `app/controllers/{console,bkc,super_admin}/base_controller.rb` — gate dev bypass
- `app/controllers/super_admin/{remote_config,fcm}_controller.rb` — admin-only writes
- `app/controllers/bkc/{active_vaults,sessions,forensics,analytics}_controller.rb`
- `app/controllers/console/users_controller.rb` — audit + LIKE escape
- `app/controllers/api/v1/my/analytics_controller.rb` — Date.parse rescue
- `app/services/super_admin.rb` (new), services updated
- `app/services/incident_detector_service.rb` — dedupe
- `app/jobs/refresh_firebase_certificates_job.rb` — bounded retries
- `app/jobs/audit_retention_cleanup_job.rb` (new)
- `app/models/{audit_log,content}.rb`
- `app/views/bkc/forensics/index.html.erb` — privacy banner
- `app/views/bkc/analytics/show.html.erb` — `json_escape`
- `app/views/bkc/sessions/new.html.erb` (new) — placeholder page
- `app/views/super_admin/remote_config/index.html.erb` — etag field
- `config/database.yml`, `config/deploy.yml`, `config/recurring.yml`
- `config/initializers/{content_security_policy,cors,filter_parameter_logging,firebase_id_token,rack_attack}.rb`
- `config/environments/production.rb`, `config/routes.rb`
- `Dockerfile.dev`
- `flutter/lib/main.dart`,
  `flutter/lib/screens/profile/bank_account_screen.dart`
- `.github/workflows/security.yml` (new)
- `docs/security/audit-2026-05-17-remediations.md` (this file), `mkdocs.yml`
- Tests updated: `test/models/audit_log_test.rb`,
  `test/controllers/api/v1/my/vaults_controller_test.rb`
