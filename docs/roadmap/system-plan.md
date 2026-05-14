# System Plan

## Direction

Bokunokoto grows around a person-first, **multi-tenant** account model:

- One `User` represents one authenticated person.
- A user becomes a discloser by owning **one or more `Vaults`** (capped by `AccountCapability.vault_quota`, default 3).
- A user becomes a receiver through a `Permission` to another vault.
- The active vault is a runtime context resolved from `X-BK-Active-Vault` (or `users.default_vault_id`) on every request.
- BKC access is authorized per active vault by ownership plus account capability, not by a permanent user role.

This plan supersedes earlier designs that assumed separate discloser/receiver accounts **or** a one-vault-per-user simplification. See [Multi-Tenant Model](../architecture/multi-tenant-model.md), [Multi-Tenant Rollout](multi-tenant-rollout.md), and [Comparative Analysis](../architecture/comparative-analysis.md).

## Implementation Sequence

| Order | Workstream | Goal | Primary docs |
|---|---|---|---|
| 1 | Account foundation | Keep `User` as identity, account status, verification, and capabilities. | [Account & Role Model](../architecture/account-role-model.md), [User Role Audit](../architecture/users-role-audit.md) |
| 2 | Vault ownership (single) | Add the owned disclosure space for users who become disclosers. | [Data Model](../architecture/data-model.md) |
| 3 | Viewer relationships | Move trust levels to per-vault permission records. | [API Design](../architecture/api-design.md) |
| 4 | BKC ownership model | Scope command center screens to the current user's owned vault. | [BKC Overview](../bkc/overview.md), [User & Trust Controller](../bkc/user-trust-controller.md) |
| 5 | Client context switching | Show own-vault and received-vault contexts in one account. | [System Overview](../architecture/overview.md) |
| 6 | Compatibility migration | Preserve current console behavior while product roles move to relationships. | [Account & Role Replan](account-role-replan.md) |
| **7** | **Multi-tenant rewrite** | **Lift one-vault-per-user; add quota, switcher, vault-scoped APIs.** | **[Multi-Tenant Model](../architecture/multi-tenant-model.md), [Context Switching](../architecture/context-switching.md), [Multi-Tenant Rollout](multi-tenant-rollout.md)** |
| 8 | Release hardening | Relationship-aware audit logs, security gates, billing, and eKYC. | [Release Phase](release.md) |

## System Boundaries

| Boundary | Decision |
|---|---|
| Identity | Firebase Auth maps to one `User`. Do not create separate accounts for discloser/receiver behavior. |
| Product role | Discloser and receiver are contexts derived from owned vaults and permissions. |
| Platform role | `User.role` may remain for operator/admin console access only. |
| Trust | Trust level is per target vault relationship. A global user trust level is compatibility data only. |
| BKC | Personal BKC is **scoped per active vault**. Each vault has exactly one owner in v1. Delegated/team management (`VaultMembership`, FB Page Roles analog) belongs to a future business tier. |
| Tenancy | Vault is the tenancy boundary. One user may own up to `account.vault_quota` vaults (default 3). The active vault is sent on every request as `X-BK-Active-Vault`. |
| Billing | Billing attaches capabilities to a user/account and can unlock vault-owner or receiver features without splitting accounts. |

## API Surface

The next implementation pass should introduce or stabilize these API concepts:

| Endpoint | Purpose |
|---|---|
| `GET /api/v1/account/context` | Current user, capabilities, owned vault summary, received vault list. |
| `POST /api/v1/my/vault` | Create the current user's first vault when allowed. |
| `/api/v1/my/*` | Owned-vault operations for the current user. |
| `/api/v1/vaults/:vault_id/*` | Viewer operations against a target vault through permission checks. |
| `/api/v1/my/permissions` | Relationship management for the current user's owned vault. |

## Migration Rules

1. Keep existing user records and console access stable.
2. Add vault and permission records without deleting `users.role` or `users.trust_level`.
3. Backfill owned vaults for users currently treated as owners.
4. Backfill permission records for users currently treated as viewers.
5. Change product authorization to use ownership/capability/permission checks.
6. Leave `User.role` only for platform operator/admin use.
7. Remove or hide global `trust_level` from product UI after relationship trust is complete.

## Acceptance Checklist

- [ ] Receive-only users can sign in and access a shared vault.
- [ ] Receive-only users can create their own vault later.
- [ ] Vault owners can also receive access to another vault.
- [ ] The same user can hold different trust levels across different vaults.
- [ ] BKC access is denied without owned-vault context and capability.
- [ ] Operator console access remains separate from personal BKC.
- [ ] Audit logs record the actor, target vault, target content, and relationship level at the time of access.
- [ ] GitHub Issue Markdown, MKDocs, and monday.com roadmap remain aligned by title and phase.
