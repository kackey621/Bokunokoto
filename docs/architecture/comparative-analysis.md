# Comparative Analysis: How Bokunokoto's Multi-Tenant Model Maps to Prior Art

Bokunokoto's multi-tenant model is not invented — it is a deliberate composition of patterns from products whose audiences are larger and more battle-tested than ours. This page records what we borrowed, what we rejected, and why, so future contributors can argue with the choices instead of re-deriving them.

## At a glance

| Product   | Tenant unit              | Identity unit       | Audience model              | Role model inside a tenant            |
|-----------|--------------------------|---------------------|------------------------------|---------------------------------------|
| Facebook  | Page                     | User                | Followers, Friends, Custom   | Page Roles (Admin/Editor/Mod/Analyst/Advertiser) |
| LinkedIn  | Personal Profile + Company Page | Member       | Connections (1°/2°/3°), Followers | Page Admin / Content Admin / Curator |
| Instagram | Account                  | Same as account     | Followers, Close Friends     | Implicit single-owner per account     |
| Discord   | Server (Guild)           | User                | Server membership            | Owner / role hierarchy                |
| Slack     | Workspace                | User                | Workspace membership         | Owner / Admin / Member / Guest        |
| Notion    | Workspace                | User                | Workspace membership         | Owner / Member / Guest                |
| GitHub    | Organization + Repository| User                | Org membership + Repo collab | Org Owner / Repo Admin / Maintain / Triage / Read |
| Bokunokoto v1 | **Vault**            | **User**            | **Permission per (vault, user)** | **Owner-only (membership reserved for v2)** |

## What we took

### From Facebook Pages
- **Account owns many Pages.** Pages are not separate accounts; they are tenants attached to an account. Bokunokoto adopts this exactly.
- **Page Roles as a future extension.** We don't ship co-ownership in v1, but the `vault_memberships` table is specced with the same role vocabulary (Admin/Editor/Analyst), so adding it later is additive, not a redesign.
- **Per-page audit history.** A FB Page has its own activity log separate from the owner's personal activity. Bokunokoto's `audit_logs.vault_id` already enforces this scoping.

### From Instagram
- **Single-credential account switcher.** One Firebase identity, many vaults, in-app switcher. Bokunokoto's `X-BK-Active-Vault` header and `default_vault_id` mirror Instagram's "last active account per device + canonical default" split.
- **No mode toggle.** Instagram doesn't make you choose "creator mode" vs. "viewer mode" — it's all one feed with contextual actions. Bokunokoto follows this: the switcher picks a vault, and the actions available adapt to whether you own it or view it.

### From LinkedIn
- **Personal vs. organizational distinction at the data layer, deferred at the UI layer.** LinkedIn separates Personal Profile from Company Page because the audience model differs. Bokunokoto's v1 keeps both as `Vault` rows with a `kind` discriminator (`personal`, `professional`, `medical`, `social`, `legal`, `other`); the `kind` is a hint for default symbol palette and onboarding copy, not a hard authorization split. If demand warrants, we promote `kind: organization` to its own table later.
- **Connection degree as a trust signal.** LinkedIn shows degree of connection prominently. Bokunokoto's L0–L9 trust level is the analog — but ours is owner-controlled, not derived from graph distance.

### From Slack/Notion
- **Tenant-scoped audit + tenant-scoped settings.** Workspaces in Slack/Notion each have their own admin surface. Bokunokoto's BKC adopts this: the BKC dashboard is **per active vault**, not "all my vaults at once". A user with three vaults sees three BKC dashboards via the switcher.

### From GitHub
- **Default-private with explicit grants.** GitHub repos default private until the owner adds collaborators or sets public visibility. Bokunokoto vaults default to L0-only-visible-with-permission; nothing is world-readable without an explicit access link or permission.

## What we rejected

### Slack/Notion's workspace-as-tenant
Rejected for v1. Slack's workspace tenancy is designed for teams; promoting Org above Vault would force every user through an org-creation step before they could disclose anything. The disclosure use case is **person-first**. We may re-introduce Org as an additional tier later for the business / enterprise tier, but Vault stays user-owned at the base level.

### Discord's server invite explosion
Rejected. Discord servers are designed for many concurrent invite links. Bokunokoto's `AccessLink` is intentionally scarce — each link is a curated audience entry point with a preset relationship context, not a "join the server" URL. We keep `max_uses` and time-boxing on every link.

### Twitter/X's flat single-tenant
Rejected. Single-tenant collapses the disclosure surface, forcing oversharing or sock-puppet accounts. Multi-tenant is the whole point.

### Facebook's public-default exposure
Rejected. Facebook Pages are public unless restricted. Bokunokoto vaults are private unless granted. The level-based gating is the inverse of FB's permission model — closer to a doctor's office than a billboard.

## Where Bokunokoto diverges from all of them

| Divergence                                                       | Reason                                                                                                  |
|------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------|
| Trust level is per (vault, viewer) — not per graph distance      | The discloser controls audience tiers, not an algorithm.                                                |
| Web platform is hard-capped at L4 regardless of trust            | Screenshot/screen-record threat surface on the web is too broad for L5+ content.                        |
| Audit logs are write-only, with immutability enforced at the app layer | The disclosure use case treats audit history as evidence the discloser can show in a dispute.       |
| AccessLink binds to first authenticated user (OTP URL binding)   | Most platforms allow link reuse; Bokunokoto's links represent a specific relationship and should not be forwarded. |
| L7+ requires camera + GPS capture before view                    | Forensic accountability for the most sensitive content; no equivalent in mainstream products.           |
| Symbols (Help Mark, Rainbow, etc.) carry semantic accessibility meaning | The Navigation Sheet use case requires visual disclosure shortcuts a generic profile field cannot offer. |

## Why this matters for v1

The multi-tenant rewrite is small because we already lifted the right ideas from prior art when we designed `Permission`, `AccessLink`, and `AuditLog`. The remaining work — drop the unique index on `vaults.user_id`, swap `has_one` for `has_many`, add the switcher contract — is mechanical, not architectural.

The architectural decisions (vault-as-tenant, owner-only-in-v1, header-based context resolution, default-vault seed) match how successful multi-tenant products handle the same trade-offs. That's the point of comparing.
