# Account & Role Replan

## Goal

Rework the product plan so every registered user can eventually be both a discloser and a receiver. The next build phase should establish account, vault, and relationship foundations before adding more high-level disclosure features.

## Near-Term Focus

The next 4 to 6 weeks should prioritize the account foundation:

| Priority | Workstream | Outcome |
|---|---|---|
| Critical | Account model | `User` becomes a person-first identity, not a fixed role. |
| Critical | Vault ownership | Users can have an owned vault without losing receiver capability. |
| Critical | Relationship permissions | Trust levels move to per-vault relationships. |
| High | BKC account management | BKC manages the current user's vault and connected viewers. |
| High | Client context switching | Client can switch between own-vault and viewer contexts. |
| Medium | Migration compatibility | Existing `role` and `trust_level` fields are treated as temporary compatibility fields. |

## Roadmap Phases

| Phase | Name | Target |
|---|---|---|
| Phase 0 | Planning & Issue Sync | Local GitHub Issue Markdown, MKDocs updates, monday.com roadmap. |
| Phase 1 | Account Foundation | Person-first user profile, account status, account capability flags. |
| Phase 2 | Vault Ownership & Permission Model | Vault ownership plus per-vault viewer relationships. |
| Phase 3 | BKC Account Management | Own-vault BKC, connected viewer directory, trust controls. |
| Phase 4 | Client Mode Switching | Context-aware API/client behavior for own vault and received vaults. |
| Phase 5 | Security, Audit, Release Readiness | Relationship-aware audit logs, security gates, QA, and release docs. |

## Acceptance Criteria

- A user can exist without a vault and still receive access to another vault.
- A user can create a vault later without creating a second account.
- A user who owns a vault can also hold permissions on other users' vaults.
- Trust level checks use the target vault relationship, not a global user trust level.
- BKC access is granted by vault ownership and account capability, not by a permanent `User.role`.
- GitHub Issue templates and monday.com items stay aligned by title and phase.
