# Monday.com Project — Bokunokoto Multi-Tenant

This folder is the import-ready spec for a new Monday.com board that mirrors the multi-tenant rewrite tracked in `GITHUB_ISSUES_MULTI_TENANT.md`. It is designed to be imported via Monday's CSV import or recreated by hand following `board-structure.md`.

## Files

| File                  | Purpose                                                                                       |
|-----------------------|-----------------------------------------------------------------------------------------------|
| `board-structure.md`  | Groups, columns, status options, automations — the manual setup recipe                        |
| `items.csv`           | All MT-* items, ready to import as Monday "Items"                                             |
| `dependencies.csv`    | `Blocked by` / `Blocks` relations between items                                               |
| `subitems.csv`        | Sub-task breakdown for each MT-* item (lifted from the issue task lists)                      |

## Why a new board

The existing Bokunokoto Monday board (referenced in `docs/roadmap/`) tracked the Account & Role Replan and the baseline phases. The multi-tenant rewrite is a discrete workstream with its own milestones (MT-0 through MT-7), explicit dependencies, and a release gate. A dedicated board keeps the dependency graph readable.

## Import order (Monday CSV import)

1. Create the new board "Bokunokoto — Multi-Tenant Rewrite" following `board-structure.md` (groups, columns, status options first).
2. Import `items.csv` to populate the items.
3. Open each item that has a dependency listed in `dependencies.csv` and link the predecessor via the "Dependencies" column (Monday's "select item" UI). The CSV import doesn't link dependencies directly — Monday's importer treats it as text — so a small manual pass is required after import.
4. Import `subitems.csv` to populate sub-tasks. Use the "Import subitems" option and map the `Parent` column to the parent item slug.
5. Run the automations listed in `board-structure.md` § Automations.

## Sync model with GitHub

Every Monday item has an `Issue ID` column whose value is the MT-* slug from `GITHUB_ISSUES_MULTI_TENANT.md`. When the GitHub connector becomes available, automation can:

- Pull GitHub Issue state into the `Status` column.
- Push status changes from Monday to GitHub Issue labels (`in-progress`, `blocked`, `review`, `done`).
- Mirror the `Blocked by` relation by setting `Status = Blocked` while an upstream isn't `Done`.

Until the connector is wired up, treat GitHub Issues as the source of truth and Monday as the roadmap surface.

## Maintenance rules

- A new MT-* issue → add one row to `items.csv`, add its dependencies to `dependencies.csv`, add sub-tasks to `subitems.csv`.
- A renamed milestone → update `board-structure.md` § Groups **and** the `Group` column on every affected row.
- A scope cut → mark the row `Status = Cancelled`, do not delete it (the dependency graph references it).
