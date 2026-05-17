# Full-Stack Security Audit Report

**Target**: Bokunokoto (Rails 8.1.3 backend + Flutter client)
**Date**: 2026-05-17
**Scope**: all (Web app, Infrastructure, Backend, Mobile, Compliance, Advanced)
**Tools**: Static analysis — Grep, Bash, Brakeman 8.0.4, bundler-audit. Chrome MCP dashboard inspection skipped (no Vercel/Supabase usage; deploy target is Kamal).

---

## Executive Summary

- **Critical: 2 / High: 12 / Medium: 11 / Low: 8** (33 total)
- **Top priority**: The vault `bank_account_info` (account number, routing number, bank name) is **decrypted and returned in plaintext** in the `/api/v1/my/vault[s]` JSON response, defeating the at-rest encryption. The Flutter client already consumes the full plaintext.
- **Runner-up**: All three sensitive web namespaces (Console, BKC, super_admin) contain `Rails.env.development?` auto-login fallbacks that grant `User.first` / `Manager.first` access without credentials — a single environment-variable misconfiguration in production would unlock platform admin/operator access.

Static analysis baseline is strong: **Brakeman reports 0 active warnings**, the Gemfile already wires `bundler-audit` + `brakeman` for CI, no plaintext secrets were committed (`config/master.key` and `config/firebase-credentials.json` are gitignored and absent from the worktree), and production Dockerfile correctly drops to a non-root UID 1000. The new findings are mostly authorization/PII-exposure and missing-defense-in-depth issues rather than classic OWASP injection bugs.

---

## Layer Summary

| Layer            | Critical | High | Medium | Low |
|------------------|----------|------|--------|-----|
| Web App (Rails)  |    1     |   3  |   4    |  1  |
| Infrastructure   |    0     |   3  |   2    |  1  |
| Backend (Rails)  |    1     |   2  |   3    |  3  |
| Mobile (Flutter) |    0     |   0  |   0    |  2  |
| Compliance       |    0     |   1  |   2    |  1  |
| Advanced         |    0     |   3  |   0    |  0  |
| Cross-Layer      |    0     |   0  |   0    |  0  |

---

## Findings

### [CRITICAL-001] Bank account data returned in plaintext via API
- **Layer**: Backend / Compliance
- **Category**: OWASP A02:2021 Cryptographic Failures, A04:2021 Insecure Design
- **Location**:
  - [app/controllers/api/v1/my/vault_controller.rb:97](app/controllers/api/v1/my/vault_controller.rb:97)
  - [app/controllers/api/v1/my/vaults_controller.rb:91](app/controllers/api/v1/my/vaults_controller.rb:91)
  - [app/models/vault.rb:18](app/models/vault.rb:18)
- **Description**: `Vault#bank_account_info` is correctly `encrypts :bank_account_info, deterministic: false` at rest. However, `Vault#bank_account_data` re-parses the decrypted JSON and `vault_response` returns the full plaintext under the `bank_account_info` key alongside the masked variant:
  ```ruby
  def vault_response(vault)
    { ..., masked_account_number: vault.masked_account_number,
          bank_account_info: vault.bank_account_data }   # <-- full plaintext
  end
  ```
  The Flutter `BankAccountScreen` already consumes the plaintext: `info['account_number']` → assigned to `_accountNumberController.text`. So the data-at-rest encryption is silently bypassed in every API response.
- **Impact**: Anyone who obtains a Firebase ID token for the vault owner (legitimately or via stolen device/session) sees the full account number and routing number. Bank account data is also written to Rails logs (see MEDIUM-019) because it is not in the parameter filter list.
- **Remediation**:
  ```diff
  def vault_response(vault)
    { id: vault.id,
      display_name: vault.display_name,
      bio: vault.bio,
  -   masked_account_number: vault.masked_account_number,
  -   bank_account_info: vault.bank_account_data }
  +   masked_account_number: vault.masked_account_number }
  end
  ```
  Then add an explicit, audited endpoint (e.g. `GET /api/v1/my/vault/bank_account/reveal`) that returns the plaintext only when the request includes a fresh re-authentication factor, and remove the `info['account_number']` reload path in [flutter/lib/screens/profile/bank_account_screen.dart](flutter/lib/screens/profile/bank_account_screen.dart) so the client only ever shows the masked value plus what the user just typed.

### [CRITICAL-002] Dev/test auto-login bypass on all privileged web namespaces
- **Layer**: Web App / Backend
- **Category**: OWASP A07:2021 Identification and Authentication Failures
- **Location**:
  - [app/controllers/console/base_controller.rb:21](app/controllers/console/base_controller.rb:21)
  - [app/controllers/bkc/base_controller.rb:11](app/controllers/bkc/base_controller.rb:11)
  - [app/controllers/super_admin/base_controller.rb:13](app/controllers/super_admin/base_controller.rb:13)
- **Description**: All three privileged web namespaces accept identity through request headers when `Rails.env.test?` or `Rails.env.development?`:
  ```ruby
  user_id ||= request.headers["X-Dev-User-Id"] if Rails.env.development?
  # ...
  if Rails.env.development? && !@current_user
    @current_user = User.first        # BKC base
    @current_manager = Manager.first  # super_admin base
  end
  ```
  Combined with the fact that **no controller in the codebase ever sets `session[:user_id]`** (BKC `SessionsController` has only `destroy`; there is no Console login flow), the production code path is currently unreachable — but that means the *only* reachable login path on a misconfigured `RAILS_ENV=development` deploy is "anyone is admin." This has happened in many real-world incidents.
- **Impact**: A single misconfigured env var (`RAILS_ENV=development`) or accidentally-bundled dev image in production grants any anonymous HTTP client full BKC, Console, and super_admin access, including bank-account data, audit logs, biometric face snapshots, GPS coordinates, Firebase Remote Config publish, and FCM broadcasts.
- **Remediation**: Wrap the dev/test bypasses in a runtime guard that hard-fails outside permitted environments, and require explicit ENV opt-in:
  ```diff
  - user_id ||= request.headers["X-Dev-User-Id"] if Rails.env.development?
  + if Rails.env.development? && ENV["ALLOW_DEV_AUTH_BYPASS"] == "1"
  +   user_id ||= request.headers["X-Dev-User-Id"]
  + end
  ```
  And add a boot-time assertion in `config/environments/production.rb`:
  ```ruby
  raise "ALLOW_DEV_AUTH_BYPASS must not be set in production" if ENV["ALLOW_DEV_AUTH_BYPASS"]
  ```
  Then implement a real Console/BKC login flow (Firebase ID token verification, mirroring `Api::V1::BaseController#authenticate_user!`) before the namespace is exposed publicly.

### [HIGH-003] `force_ssl` and `assume_ssl` disabled in production
- **Layer**: Web App / Infrastructure
- **Category**: OWASP A05:2021 Security Misconfiguration
- **Location**: [config/environments/production.rb:25-31](config/environments/production.rb)
- **Description**: Both flags are commented out. Without them, Rails does not redirect HTTP→HTTPS, does not set `Strict-Transport-Security`, and does not mark session/CSRF cookies `secure`. If the Kamal/Cloudflare edge is misconfigured, plaintext requests reach the app and cookies are leaked over HTTP.
- **Impact**: Session-cookie theft over HTTP; downgrade attacks; missing HSTS allows first-visit MITM.
- **Remediation**:
  ```diff
  - # config.assume_ssl = true
  - # config.force_ssl = true
  + config.assume_ssl = true
  + config.force_ssl = true
  + config.ssl_options = { redirect: { exclude: ->(req) { req.path == "/up" } } }
  ```

### [HIGH-004] `config.hosts` not set — DNS rebinding / Host-header attacks possible
- **Layer**: Web App
- **Category**: OWASP A05:2021 Security Misconfiguration
- **Location**: [config/environments/production.rb:74-76](config/environments/production.rb)
- **Description**: The commented-out `config.hosts = ["example.com", /.*\.example\.com/]` is the only DNS-rebinding defense. With it absent, any `Host:` header is accepted, enabling cache-poisoning of URL helpers and DNS-rebinding from a malicious page.
- **Impact**: Password-reset / email-confirmation URLs can be poisoned to point at an attacker-controlled host.
- **Remediation**: Set `config.hosts` to the production hostnames before public launch.

### [HIGH-005] Content Security Policy initializer entirely disabled
- **Layer**: Web App
- **Category**: OWASP A03:2021 Injection (XSS hardening)
- **Location**: [config/initializers/content_security_policy.rb](config/initializers/content_security_policy.rb) (whole file commented)
- **Description**: The `csp_meta_tag` is called in [app/views/layouts/application.html.erb](app/views/layouts/application.html.erb), but no policy is defined, so the tag emits nothing. The BKC layout additionally pulls CSS from `https://cdn.jsdelivr.net/npm/@coreui/coreui` — once CSP is enabled it must include that origin.
- **Impact**: No defense-in-depth against an XSS sink elsewhere in the stack (analytics view, future feature). Combined with the `<%= raw ... .to_json %>` pattern in [app/views/bkc/analytics/show.html.erb:254,271](app/views/bkc/analytics/show.html.erb), any future server-side data containing a `</script>` payload would be unconstrained.
- **Remediation**: Uncomment the initializer, set `policy.default_src :self`, `script_src :self`, `style_src :self https://cdn.jsdelivr.net`, plus `nonce_generator`/`nonce_directives` to keep importmap working. Start in report-only mode for a release before enforcing.

### [HIGH-006] httparty 0.14.0 carries unpatched CVEs (SSRF + multipart tampering)
- **Layer**: Advanced / Supply chain
- **Category**: OWASP A06:2021 Vulnerable and Outdated Components, A10:2021 SSRF
- **Location**: Gemfile.lock httparty 0.14.0; [config/bundler-audit.yml](config/bundler-audit.yml) (ignores both CVEs)
- **Description**: `bundle-audit` confirms CVE-2025-68696 (HIGH, SSRF leading to API-key leakage) and CVE-2024-22049 (MEDIUM, multipart tampering). They are pinned by `firebase_id_token (~> 0.14.0)` and ignored on the grounds that httparty is only used to fetch Google's hard-coded public-key URL. The reasoning is correct *today*, but the ignore is open-ended; any future code that adopts httparty inherits a CVE-laden client.
- **Impact**: As-is: not exploitable. After future refactors: full SSRF / API-key exfiltration via tampered URLs.
- **Remediation**: (a) Add a CI guard that fails the build if any *new* file references `HTTParty`/`require "httparty"`; (b) track upstream — `firebase_id_token` master has merged a Faraday-based client; pin to that release when published. Re-evaluate the ignore on every Gemfile bump.

### [HIGH-007] No rate limiting / lockout on super_admin login
- **Layer**: Web App
- **Category**: OWASP A07:2021 Authentication Failures
- **Location**: [app/controllers/super_admin/sessions_controller.rb:9](app/controllers/super_admin/sessions_controller.rb), [config/initializers/rack_attack.rb](config/initializers/rack_attack.rb)
- **Description**: Rack::Attack throttles `/api/v1/auth/verify`, `/api/v1/handshake`, and `/api/v1/.../contents`. **It does not cover `POST /super_admin/session`**, which is the only password-based login surface in the app. There is also no failed-attempt audit row written.
- **Impact**: Unlimited bcrypt-paced credential stuffing against operator/admin accounts; nothing alerts the team.
- **Remediation**:
  ```ruby
  # config/initializers/rack_attack.rb
  throttle("super_admin login by IP", limit: 5, period: 60) do |req|
    req.ip if req.path == "/super_admin/session" && req.post?
  end
  throttle("super_admin login by email", limit: 5, period: 600) do |req|
    if req.path == "/super_admin/session" && req.post?
      req.params["email"].to_s.downcase.strip.presence
    end
  end
  ```
  Additionally, write an `AuditLog` row on every failed manager authentication.

### [HIGH-008] Firebase Remote Config publishable by operators (not only admins)
- **Layer**: Backend
- **Category**: OWASP A01:2021 Broken Access Control, OWASP LLM/AI #6 Sensitive Information Disclosure (config)
- **Location**: [app/controllers/super_admin/base_controller.rb:18](app/controllers/super_admin/base_controller.rb), [app/controllers/super_admin/remote_config_controller.rb](app/controllers/super_admin/remote_config_controller.rb)
- **Description**: `authenticate_super_admin!` admits both `platform_admin?` and `platform_operator?`. Since `Manager::ROLES = %w[admin operator]`, the disjunction matches every signed-in manager. A compromised *operator* account can therefore push any Firebase Remote Config payload — which on most mobile clients dictates feature flags, server URLs, and sometimes JavaScript snippets.
- **Impact**: A single low-privilege manager can pivot to all-clients code-influence (push a malicious API base URL via Remote Config, force a phishing flow, disable security toggles).
- **Remediation**:
  ```diff
  - unless @current_manager.platform_admin? || @current_manager.platform_operator?
  -   redirect_to new_super_admin_session_path, alert: "Unauthorized - Super Admin access required"
  - end
  + unless @current_manager.platform_admin?
  +   redirect_to new_super_admin_session_path, alert: "Super Admin access required"
  + end
  ```
  …or, if operators must keep read access, split into `before_action :require_admin!` on `RemoteConfigController#create` and `FcmController#create` specifically.

### [HIGH-009] FCM mass announcements publishable by operators
- **Layer**: Backend
- **Category**: OWASP A01:2021 Broken Access Control
- **Location**: [app/controllers/super_admin/fcm_controller.rb](app/controllers/super_admin/fcm_controller.rb), [app/services/super_admin/fcm_service.rb](app/services/super_admin/fcm_service.rb)
- **Description**: Same RBAC gap as HIGH-008. An operator can `POST /super_admin/fcm` with `title=...&body=...` to push a notification to topic `all_users`. Push notifications carry implicit trust on iOS/Android and are an excellent phishing surface.
- **Impact**: Trusted push channel abuse / brand-impersonation phishing without an audit row.
- **Remediation**: Restrict to admins (see HIGH-008 diff); additionally record an `AuditLog` row on every send, capturing the operator, title, body, topic, and timestamp.

### [HIGH-010] Firebase Remote Config publish forces `If-Match: *`
- **Layer**: Backend / Infrastructure
- **Category**: OWASP A04:2021 Insecure Design
- **Location**: [app/services/super_admin/remote_config_service.rb:30](app/services/super_admin/remote_config_service.rb)
- **Description**: The publish call sets `request["If-Match"] = "*"` with a comment saying "Use actual ETag in production." That bypasses Firebase's optimistic-concurrency check, so a stale template from one admin will silently overwrite a newer template from another admin — including emergency rollbacks.
- **Impact**: Race-condition / lost-update against safety toggles (e.g., kill-switch).
- **Remediation**: Pull the current `etag` from `fetch_template` (returned in the response), surface it as a hidden form field, and require it on publish:
  ```diff
  - request["If-Match"] = "*"
  + request["If-Match"] = etag # passed in from the controller
  ```

### [HIGH-011] Hard-coded default DB credential `bokunokoto/password`
- **Layer**: Backend / Infrastructure
- **Category**: OWASP A07:2021 Authentication Failures, CIS Docker 4.x
- **Location**: [config/database.yml:8](config/database.yml:8), [docker-compose.yml](docker-compose.yml:13)
- **Description**: `password: <%= ENV.fetch("DB_PASSWORD", "password") %>` falls back to the literal string `"password"` in *every* environment if the env var is missing, including production. The same literal appears in `docker-compose.yml` (dev only) and the seeded MySQL user.
- **Impact**: If a production deployment forgets `DB_PASSWORD`, the app silently connects with the default — and any attacker who has read access to `database.yml` (or the public repo) immediately knows it.
- **Remediation**: Drop the fallback for production:
  ```ruby
  password: <%= ENV["DB_PASSWORD"] || raise("DB_PASSWORD is required") if Rails.env.production? %>
  ```
  …or simpler: require the env var unconditionally and only fall back in dev/test via `config/database.yml`'s namespaced sections.

### [HIGH-012] Default Firebase project ID fallback to placeholder
- **Layer**: Backend
- **Category**: OWASP A05:2021 Security Misconfiguration
- **Location**: [config/initializers/firebase_id_token.rb:2](config/initializers/firebase_id_token.rb)
- **Description**: `config.project_ids = [ ENV.fetch("FIREBASE_PROJECT_ID", "bokunokoto-tell-you-myprofile") ]`. If the env var is unset, the verifier accepts ID tokens issued by a project named `bokunokoto-tell-you-myprofile`. That project presumably does not exist today, but the fallback is a footgun — and it sits next to a different default (`bokuno-koto`) in `docker-compose.yml` and `SuperAdmin::AuthService`, so production-env-var drift is plausible.
- **Impact**: If anyone ever creates a Firebase project with that placeholder name, every signed token from it is accepted. More generally, three different defaults (`bokuno-koto`, `bokunokoto-tell-you-myprofile`, `bokunokoto-prod`) make misconfiguration likely.
- **Remediation**: Fail-fast in production:
  ```ruby
  project_id = ENV["FIREBASE_PROJECT_ID"]
  raise "FIREBASE_PROJECT_ID must be set" if Rails.env.production? && project_id.blank?
  FirebaseIdToken.configure { |c| c.project_ids = [ project_id ] }
  ```

### [HIGH-013] `Dockerfile.dev` runs as root
- **Layer**: Infrastructure / Advanced
- **Category**: CIS Docker 4.1
- **Location**: [Dockerfile.dev](Dockerfile.dev)
- **Description**: The dev image has no `USER` directive — it inherits root from `ruby:slim`. Mounted bind-volumes (`.:/rails`) then write as root on the host, and any exploit during dev runs with full container root.
- **Impact**: Dev container compromise has full file-write to the project root on the host; supply-chain risk via `bundle install` running as root.
- **Remediation**:
  ```diff
  + RUN groupadd --system --gid 1000 rails && useradd --uid 1000 --gid 1000 -m rails
  + USER 1000:1000
  ```
  Mirror the production image's hardening for parity.

### [HIGH-014] No CI/CD pipeline enforces Brakeman + bundler-audit
- **Layer**: Advanced / CI/CD
- **Category**: OWASP A06:2021 Vulnerable Components
- **Location**: No `.github/workflows/` or other CI directory was found.
- **Description**: Both `brakeman` and `bundler-audit` are in the Gemfile, but no CI workflow exists to run them on PRs. The single `brakeman.ignore` entry has `"updated": "2026-05-06"` — manual cadence, not gated by code review.
- **Impact**: Future regressions (a new `where("... #{params[:x]}")` for example) ship without notice.
- **Remediation**: Add `.github/workflows/security.yml` running `bundle exec brakeman -A -q --no-progress --no-pager` and `bundle exec bundle-audit check --update` on every push and PR, with pinned action SHAs (no floating `@v3` tags).

---

### [MEDIUM-015] Console::UsersController allows admins to grant themselves anything
- **Layer**: Web App
- **Category**: OWASP A01:2021 Broken Access Control
- **Location**: [app/controllers/console/users_controller.rb:52](app/controllers/console/users_controller.rb:52); ignored in [config/brakeman.ignore](config/brakeman.ignore).
- **Description**: `user_params` permits `:role`, `:status`, `:trust_level`, `:firebase_uid`. The brakeman ignore note is correct that only platform admins reach the action, but there is no audit row when an admin upgrades another user to admin or rewrites a Firebase UID (which would let the holder of that Firebase token impersonate the user).
- **Remediation**: Emit an `AuditLog` on every change to `role`, `status`, `trust_level`, or `firebase_uid`, and forbid editing your own `role`/`trust_level`.

### [MEDIUM-016] Forensics view exposes biometric face snapshots and GPS coordinates to vault owners
- **Layer**: Compliance / Backend
- **Category**: GDPR Art. 9 (special categories), CCPA biometric data
- **Location**: [app/controllers/bkc/forensics_controller.rb:21](app/controllers/bkc/forensics_controller.rb), [app/controllers/bkc/analytics_controller.rb:21](app/controllers/bkc/analytics_controller.rb)
- **Description**: A vault owner (regular user) can browse `face_snapshot_url`, `latitude`, and `longitude` of every visitor across audit logs and incidents. There is no documented consent flow, retention window, or DSR (data-subject-request) erasure path. The `audit_logs` schema has no retention column.
- **Impact**: GDPR/CCPA/APPI exposure; a vault owner is effectively a controller of biometric+location data of unknown third parties.
- **Remediation**: (a) Add a feature flag gating biometric capture; (b) Add a retention job that nulls `face_snapshot_url`, `latitude`, `longitude`, and `user_agent` after N days (e.g., 30); (c) Add a Console-admin-only "Erase user data" action that anonymizes a user's audit rows; (d) Show a privacy notice in the BKC forensics page describing the legal basis.

### [MEDIUM-017] Date parsing un-rescued — controller raises on bad input
- **Layer**: Backend
- **Category**: OWASP A05:2021 Security Misconfiguration
- **Location**:
  - [app/controllers/bkc/forensics_controller.rb:57](app/controllers/bkc/forensics_controller.rb)
  - [app/controllers/bkc/analytics_controller.rb:25](app/controllers/bkc/analytics_controller.rb)
  - [app/controllers/api/v1/my/analytics_controller.rb](app/controllers/api/v1/my/analytics_controller.rb)
- **Description**: `Date.parse(params[:start_date])` raises `Date::Error` on bad input. In development this hits the verbose error page with stack/env disclosure. In production it 500s without telemetry.
- **Remediation**: Centralize the parser:
  ```ruby
  def parse_date(value, default)
    return default if value.blank?
    Date.parse(value.to_s)
  rescue ArgumentError, Date::Error
    default
  end
  ```

### [MEDIUM-018] `Console::UsersController#index` LIKE wildcards not escaped
- **Layer**: Backend
- **Category**: Performance / DoS hardening
- **Location**: [app/controllers/console/users_controller.rb:8](app/controllers/console/users_controller.rb)
- **Description**: `where("email LIKE :query OR ...", query: "%#{@query}%")` is parameterized (no SQLi), but user-supplied `%` and `_` are not escaped, so `q=%_%_%_%_%_` triggers a full-table scan with no index help. The controller already `.limit(100)`s, but the scan still costs DB CPU.
- **Remediation**: `@query.gsub(/[\%_]/) { |c| "\\#{c}" }` before interpolation.

### [MEDIUM-019] Parameter filter list is incomplete for the data the app handles
- **Layer**: Backend / Compliance
- **Category**: OWASP A09:2021 Logging Failures, PCI/PII
- **Location**: [config/initializers/filter_parameter_logging.rb](config/initializers/filter_parameter_logging.rb)
- **Description**: Current filter list is `[:passw, :email, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn, :cvv, :cvc]`. Missing keys actively used by the app: `:account_number`, `:routing_number`, `:bank_name`, `:firebase_uid`, `:latitude`, `:longitude`, `:face_snapshot_url`, `:authorization`. Without these, the Rails request logs contain raw bank-account fields whenever a user calls `PATCH /api/v1/my/vault`.
- **Remediation**:
  ```diff
  - Rails.application.config.filter_parameters += [
  -   :passw, :email, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn, :cvv, :cvc
  - ]
  + Rails.application.config.filter_parameters += [
  +   :passw, :email, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn, :cvv, :cvc,
  +   :account_number, :routing_number, :bank_name, :bank_account_info,
  +   :firebase_uid, :authorization,
  +   :latitude, :longitude, :face_snapshot_url
  + ]
  ```

### [MEDIUM-020] `bin/dbc` Kamal alias uses `--include-password`
- **Layer**: Infrastructure
- **Category**: CIS / Operational hygiene
- **Location**: [config/deploy.yml](config/deploy.yml) aliases section
- **Description**: `dbc: app exec --interactive --reuse "bin/rails dbconsole --include-password"` prints the DB password to the running operator's terminal and into `~/.history`.
- **Remediation**: Drop `--include-password`; if needed, prompt for it.

### [MEDIUM-021] `IncidentDetectionJob` writes duplicate Incidents on every run
- **Layer**: Backend
- **Category**: OWASP A04:2021 Insecure Design (alert fatigue / DoS)
- **Location**: [app/jobs/incident_detection_job.rb](app/jobs/incident_detection_job.rb), [app/services/incident_detector_service.rb](app/services/incident_detector_service.rb)
- **Description**: `analyze_user_activity` is invoked for every (vault, permission) pair and creates a new `Incident` row whenever the threshold matches in the lookback window. There is no deduplication on `(user, vault, type, time_bucket)`, so the same `rapid_access` can be raised every scheduled run, and the detector loops over `Vault.find_each → vault.permissions.find_each` with no batching cap.
- **Impact**: Alert fatigue + unbounded growth of `incidents` rows; at scale a tight schedule will saturate the Sidekiq queue.
- **Remediation**: Add a `find_or_create_by!(vault:, user:, incident_type:, created_at: time_bucket)` pattern, or write a `last_seen_at` column instead of new rows.

### [MEDIUM-022] AuditLog `actor_role` allows arbitrary string values
- **Layer**: Backend
- **Category**: OWASP A04:2021 Insecure Design
- **Location**: [app/models/audit_log.rb](app/models/audit_log.rb), [app/controllers/concerns/audit_loggable.rb](app/controllers/concerns/audit_loggable.rb)
- **Description**: `actor_role` is a free-text column with no `inclusion` validation. A caller can pass any string. Forensic queries that filter on `actor_role = "operator"` may miss rows logged with a typo or be polluted by future code.
- **Remediation**: `validates :actor_role, inclusion: { in: %w[viewer owner operator admin], allow_nil: true }`.

### [MEDIUM-023] CORS exposes `Authorization` and allows any header
- **Layer**: Web App
- **Category**: OWASP A05:2021 Misconfiguration
- **Location**: [config/initializers/cors.rb](config/initializers/cors.rb)
- **Description**: `headers: :any, expose: %w[Authorization]`, `max_age: 600`. Exposing `Authorization` in CORS response headers is unusual — the client sends it, the server does not need to echo it. `headers: :any` is broad. The origins list comes from env, which is good.
- **Remediation**: Narrow `headers:` to the headers actually used (`%w[content-type authorization x-bk-platform x-bk-active-vault x-bk-client-version]`) and drop `expose: %w[Authorization]`.

### [MEDIUM-024] Bkc::SessionsController has only `destroy` — half-implemented auth surface
- **Layer**: Web App
- **Category**: Design / pre-launch checklist
- **Location**: [app/controllers/bkc/sessions_controller.rb](app/controllers/bkc/sessions_controller.rb)
- **Description**: When the create flow is finally wired, ensure it: (a) verifies a Firebase ID token (don't roll your own); (b) sets the cookie with `httponly: true, secure: true, same_site: :lax`; (c) rotates `session.id` on login; (d) writes an `AuditLog` row; (e) is covered by the same Rack::Attack throttle pattern as `/api/v1/auth/verify`.
- **Remediation**: Treat this as a security feature, not a UX feature; add a checklist to the PR template that introduces it.

### [MEDIUM-025] Body content `format` allows `html` — stored HTML rendered to viewers
- **Layer**: Web App
- **Category**: OWASP A03:2021 Injection (Stored XSS)
- **Location**: [app/models/content.rb:7](app/models/content.rb), Flutter [flutter/lib/screens/vault/content_detail_screen.dart](flutter/lib/screens/vault/content_detail_screen.dart) (uses `flutter_html`)
- **Description**: `Content#format` accepts `markdown`, `html`, or `text`. The vault owner can author raw HTML; Flutter's `flutter_html` will render it. `flutter_html` evaluates inline event handlers in some configurations and will fetch remote images. Combined with the absence of CSP, a malicious owner could phish their viewers via the content stream.
- **Impact**: Limited (owner attacks viewers within their own vault) but worth gating.
- **Remediation**: In Rails, sanitize the HTML server-side before persisting (`ActionController::Base.helpers.sanitize`); in Flutter, configure `Html` with a strict `tagsList`/`onLinkTap` validator that rejects `javascript:` URLs and external `<iframe>`s.

---

### [LOW-026] CSP nonce mechanism not enabled — importmap-rails will need it when CSP turns on
- See HIGH-005.

### [LOW-027] Flutter `Clipboard.setData` copies full account number
- **Layer**: Mobile
- **Location**: [flutter/lib/screens/profile/bank_account_screen.dart](flutter/lib/screens/profile/bank_account_screen.dart) (`_copyToClipboard`)
- **Description**: Clipboard contents are readable by other apps and surveil-able by accessibility services. Even after fixing CRITICAL-001, copying the full number from the screen risks leakage.
- **Remediation**: Copy only the masked value, or use `Clipboard.setData` with a 30-second `setExpiry` (Android 13+) and document the iOS UIPasteboard.expirationDate equivalent.

### [LOW-028] Flutter app has no certificate pinning
- **Layer**: Mobile / MASVS-NETWORK-1
- **Location**: [flutter/lib/providers/api_client_provider.dart](flutter/lib/providers/api_client_provider.dart)
- **Description**: `dio` is used with default trust store. On rooted/jailbroken devices or with installed corporate CAs, traffic can be MITM'd.
- **Remediation**: Add `dio_certificate_pinning` (or `dio.httpClientAdapter` with `badCertificateCallback` enforcing a known SPKI hash) for the production API host. Not strictly required for many apps, but expected for bank-account-grade data.

### [LOW-029] Flutter `firebase_options.dart` ships with `TODO_*` placeholder values
- **Layer**: Mobile / Supply chain
- **Location**: [flutter/lib/firebase_options.dart](flutter/lib/firebase_options.dart)
- **Description**: Build will compile, runtime init will fail with a confusing error. Replace with the generated file from `flutterfire configure --project=…`.

### [LOW-030] `<%= raw ... .to_json %>` script-inline pattern
- **Layer**: Web App
- **Location**: [app/views/bkc/analytics/show.html.erb:254,271](app/views/bkc/analytics/show.html.erb)
- **Description**: ActiveSupport's `to_json` escapes `</`, but `raw` + JS context still warrants caution. Today the inputs come from server-computed analytics maps with no user-controlled keys; if a user-controlled string is ever added to the hash, it becomes XSS.
- **Remediation**: Replace with `<%= json_escape(@accessibility[:format_views].to_json).html_safe %>` (Rails has `json_escape` for `<` / `>` / `&` inside `<script>` blocks) — or move the data into a JSON `<script type="application/json">` block and load it from JS.

### [LOW-031] Audit logs and incidents retain `ip_address`, `user_agent`, `latitude/longitude` indefinitely
- **Layer**: Compliance
- **Location**: [db/schema.rb](db/schema.rb) audit_logs / incidents
- **Remediation**: Add a retention job; see MEDIUM-016 remediation.

### [LOW-032] `Bkc::ActiveVaultsController` sets `bk_active_vault` cookie without explicit `secure: true`
- **Layer**: Web App
- **Location**: [app/controllers/bkc/active_vaults_controller.rb:11](app/controllers/bkc/active_vaults_controller.rb)
- **Description**: The cookie is `httponly: true, same_site: :lax` but missing `secure: true`. Without `force_ssl` (see HIGH-003), the cookie can be set/read over HTTP.
- **Remediation**: `cookies.signed[:bk_active_vault] = { ..., secure: Rails.env.production? }`. Becomes moot once `force_ssl` is enabled.

### [LOW-033] `Refresh​FirebaseCertificatesJob` self-reschedules on failure with 5-min retry forever
- **Layer**: Backend
- **Location**: [app/jobs/refresh_firebase_certificates_job.rb](app/jobs/refresh_firebase_certificates_job.rb)
- **Description**: On exception, the job logs and re-enqueues itself every 5 minutes with no backoff or alert. A persistent failure quietly silos in Sidekiq logs while every API request fails with `NoCertificatesError`.
- **Remediation**: Add a max-consecutive-failure counter that pages on-call after N=12 failures (~1 hour).

---

## Remediation Roadmap

| Priority | Action | Layer | Type |
|----------|--------|-------|------|
| **Immediate (this week)** | CRITICAL-001: Stop returning plaintext `bank_account_info` from API; fix Flutter `_loadBankAccount` to use only the masked value | Backend + Mobile | Code |
| **Immediate** | CRITICAL-002: Gate dev/test auto-login behind explicit ENV opt-in + production-boot assertion | Backend | Code |
| **Immediate** | HIGH-003 / HIGH-004 / HIGH-005: Enable `force_ssl`, set `config.hosts`, enable CSP (report-only first) | Web App | Code |
| **Immediate** | HIGH-008 / HIGH-009: Tighten super_admin RBAC so only admins can publish Remote Config / FCM | Backend | Code |
| **Short-term (this sprint)** | HIGH-007 + MEDIUM-024: Rack::Attack throttle + AuditLog for super_admin login; design checklist for BKC login | Web App | Code |
| **Short-term** | HIGH-011 / HIGH-012: Remove hard-coded DB password fallback; fail-fast on missing `FIREBASE_PROJECT_ID`; consolidate Firebase project-id defaults | Backend / Infra | Code |
| **Short-term** | HIGH-013: Run `Dockerfile.dev` as non-root UID 1000 (parity with prod) | Infra | Code |
| **Short-term** | HIGH-014: Add `.github/workflows/security.yml` running brakeman + bundle-audit on every PR | CI/CD | Code |
| **Short-term** | MEDIUM-019: Extend `filter_parameters` to cover bank-account, lat/long, face URL, firebase_uid | Backend | Code |
| **Mid-term (this quarter)** | MEDIUM-016 + LOW-031: PII retention job; consent flow for biometric capture; DSR erasure path | Compliance | Code + Policy |
| **Mid-term** | HIGH-006: Track firebase_id_token upstream; replace httparty when a Faraday-based release lands | Supply chain | Code |
| **Mid-term** | MEDIUM-021: Deduplicate `Incident` writes + batching cap in `IncidentDetectionJob` | Backend | Code |
| **Mid-term** | MEDIUM-025 + LOW-030: Sanitize HTML format content server-side; lock down `flutter_html` config; replace `<%= raw to_json %>` with `json_escape` | Web App + Mobile | Code |
| **Continuous** | LOW-028: Add certificate pinning to Flutter `dio` client before public mobile launch | Mobile | Code |

---

## Notes & Out-of-Scope

- **Chrome MCP dashboard inspection**: Skipped — the project deploys via Kamal (not Vercel/Supabase). The closest equivalents (Firebase Console, Cloudflare/Kamal proxy settings) were not in scope for this static-analysis pass. Recommend a follow-up manual check of the Firebase Console for: (a) Remote Config publish permissions, (b) Authentication → Sign-in providers (ensure only Email/Password is enabled if that's the intent), (c) Firestore rules for the `support_tickets` collection.
- **CVE-2024-22049 / CVE-2025-68696** in httparty are intentionally ignored in `config/bundler-audit.yml`; the justification (sole consumer is firebase_id_token fetching Google's hard-coded URL) is correct for the current code. The risk is regression — a single new `require "httparty"` line would re-expose. CI guardrail recommended (HIGH-006 remediation).
- **No raw secrets** were found in the worktree. `config/master.key` and `config/firebase-credentials.json` are correctly gitignored and not present. The `credentials.yml.enc` blob is encrypted as expected.
- **Brakeman 8.0.4**: 0 active warnings, 1 ignored (Console::UsersController mass assignment — see MEDIUM-015 for the residual recommendation around audit logging).
