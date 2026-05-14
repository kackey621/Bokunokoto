# GitHub Issues — Index

Bokunokoto tracks work in three issue files. This index says which file owns which milestone, so contributors don't have to read everything to find the right ticket.

## Files

| File                                      | Scope                                                | Status                  |
|-------------------------------------------|------------------------------------------------------|-------------------------|
| `GITHUB_ISSUES.md`                        | Phase 1–4 baseline (Foundation → Polish & Beta)      | Open; some items marked **Superseded-by** MT-* |
| `GITHUB_ISSUES_ACCOUNT_REPLAN.md`         | Person-first single-vault account model              | All complete            |
| `GITHUB_ISSUES_SUPER_ADMIN_REPLAN.md`     | Super-admin / TailAdmin integration                  | Open                    |
| `GITHUB_ISSUES_MULTI_TENANT.md`           | **Multi-tenant rewrite (account → N vaults)**        | **Active**              |

## Milestones at a glance

| Milestone                                  | Issues                                                 | Owning file                          |
|--------------------------------------------|--------------------------------------------------------|--------------------------------------|
| Phase 1 — Foundation                       | #1–#9                                                  | `GITHUB_ISSUES.md`                   |
| Phase 2 — Security & Accessibility         | #10–#15                                                | `GITHUB_ISSUES.md`                   |
| Phase 3 — Communication & Greeting         | #16–#21                                                | `GITHUB_ISSUES.md`                   |
| Phase 4 — Polish & Beta                    | #22–#29                                                | `GITHUB_ISSUES.md`                   |
| Account & Role Replan                      | All complete                                           | `GITHUB_ISSUES_ACCOUNT_REPLAN.md`    |
| Super Admin Replan                         | See file                                               | `GITHUB_ISSUES_SUPER_ADMIN_REPLAN.md`|
| **MT — Multi-Tenant Rewrite**              | **MT-EPIC + MT-1…MT-20**                               | **`GITHUB_ISSUES_MULTI_TENANT.md`**  |

## Cross-references (superseded)

The multi-tenant rewrite supersedes implementation details of several earlier issues without invalidating their acceptance criteria. The acceptance for the first owned vault still holds; the *implementation* must use `current_vault` (active-vault resolver) instead of `current_user.vault`.

| Earlier issue                                       | Superseded by                       |
|-----------------------------------------------------|-------------------------------------|
| #3 Vault & Content data model                       | `MT-1`, `MT-2`                      |
| #4 Content API endpoints                            | `MT-5`, `MT-7`                      |
| #6 BKC Admin Console — base setup                   | `MT-8`, `MT-9`                      |
| #25 Analytics dashboard in BKC                      | `MT-9`                              |
| #26 Forensic monitor                                | `MT-9`                              |
| Vault Ownership (Account Replan, complete)          | `MT-1`, `MT-2` extend it            |
| BKC Account Management (Account Replan, complete)   | `MT-8`, `MT-9` extend it            |
| Client Context Switching (Account Replan, complete) | `MT-10`, `MT-11`, `MT-12` extend it |

## Where to start

1. New contributor? Read `docs/architecture/multi-tenant-model.md` first.
2. Picking up active work? Open `GITHUB_ISSUES_MULTI_TENANT.md`; start with unblocked MT-* issues (MT-1, MT-19 are unblocked at the start).
3. Looking for older context? `GITHUB_ISSUES_ACCOUNT_REPLAN.md` explains how we got to today's model.

## Monday.com alignment

`monday/items.csv` mirrors the MT-* issues 1:1. The `Issue ID` column matches the slug here. `monday/dependencies.csv` mirrors the `Blocked by` / `Blocks` relations.
