# Monday.com Board — "Bokunokoto — Multi-Tenant Rewrite"

This is the manual setup recipe. Import `items.csv` only after the groups and columns below exist; otherwise Monday will reject column values it doesn't recognize.

## Groups (Monday "Groups" = phase headers in the left column)

Create groups in this order, top-to-bottom. The group order is the execution order.

| Group order | Group name                       | Color    | Maps to milestone in GitHub Issues |
|-------------|----------------------------------|----------|------------------------------------|
| 1           | MT-0 — Plan & Issue Sync         | Blue     | MT-0                               |
| 2           | MT-1 — Schema Lift               | Purple   | MT-1                               |
| 3           | MT-2 — Model & Authorization     | Purple   | MT-2                               |
| 4           | MT-3 — API Surface               | Green    | MT-3                               |
| 5           | MT-4 — BKC Multi-Vault           | Orange   | MT-4                               |
| 6           | MT-5 — Flutter Switcher          | Orange   | MT-5                               |
| 7           | MT-6 — Migration & Compat        | Yellow   | MT-6                               |
| 8           | MT-7 — QA, Audit, Forensics      | Red      | MT-7                               |
| 9           | Deferred (post-v1)               | Grey     | MT-8 (future tier)                 |

## Columns

| Column name        | Type             | Notes                                                                        |
|--------------------|------------------|------------------------------------------------------------------------------|
| `Item`             | Item title (default) | Pre-existing                                                              |
| `Issue ID`         | Text             | MT-* slug from `GITHUB_ISSUES_MULTI_TENANT.md`                               |
| `Status`           | Status           | See § Status options                                                         |
| `Owner`            | People           | Assignee                                                                     |
| `Priority`         | Status           | `Critical` / `High` / `Medium` / `Low`                                       |
| `Type`             | Status           | `Epic` / `Task` / `Subtask` / `Bug` / `Spike`                                |
| `Phase`            | Status           | `MT-0` … `MT-7`, `Deferred`                                                  |
| `Area`             | Tags             | `backend`, `frontend`, `bkc`, `flutter`, `docs`, `security`, `ops`           |
| `Dependencies`     | Dependencies (Monday built-in) | Linked items, populated after CSV import                       |
| `Estimate (days)`  | Numbers          | T-shirt: 0.5, 1, 2, 3, 5                                                     |
| `Acceptance`       | Long text        | Pasted from the issue body                                                   |
| `GitHub URL`       | Link             | Populated once issues exist                                                  |
| `Last sync`        | Date             | Automation: last connector sync                                              |

## Status options

Pick the same colors Monday uses by default so the board reads at a glance.

| Status         | Color        | Meaning                                                                |
|----------------|--------------|------------------------------------------------------------------------|
| `Not started`  | Grey         | Default                                                                |
| `Blocked`      | Black        | Auto-set when any dependency isn't `Done`                              |
| `Planning`     | Blue         | Spec / design pass                                                     |
| `In progress`  | Yellow       | Implementation underway                                                |
| `In review`    | Orange       | PR open, awaiting review                                               |
| `Verifying`    | Purple       | QA pass running                                                        |
| `Done`         | Green        | Acceptance criteria met                                                |
| `Cancelled`    | Red          | Scope cut; do not delete                                               |

## Automations

| Trigger                                                                 | Action                                                                                  |
|-------------------------------------------------------------------------|-----------------------------------------------------------------------------------------|
| When `Status` changes to `In progress`                                  | Notify the `Owner`                                                                      |
| When a dependency moves to `Done` and this item is `Blocked`            | Move this item to `Not started`                                                         |
| When `Status` changes to `Done`                                         | Move date column "Completed at" to today                                                |
| When item moves to MT-7 group                                           | Notify the release-gate channel                                                         |
| Every Monday 09:00 JST                                                  | Generate "Status digest" doc with counts per group                                      |

## Board view defaults

- **Main view (Table):** Group by `Phase`, sort by `Priority`, show `Issue ID`, `Status`, `Owner`, `Estimate (days)`, `Dependencies`.
- **Kanban view:** Group by `Status`, swimlanes by `Phase`.
- **Timeline view:** Group by `Phase`, x-axis = date columns once dates exist.
- **Dependencies view:** Use Monday's built-in dependency map on `Dependencies` column.

## Sub-items

Each MT-* item has sub-items mirroring its `Tasks` checklist from `GITHUB_ISSUES_MULTI_TENANT.md`. Import via `subitems.csv` (see § Files in README).

## Notes

- Keep `Issue ID` matching the GitHub slug exactly. The connector key is by slug.
- The `Dependencies` column in Monday is bidirectional; you only need to set the "Blocked by" side and Monday will infer "Blocks."
- Don't delete `Cancelled` items — the dependency graph in `dependencies.csv` references them.
