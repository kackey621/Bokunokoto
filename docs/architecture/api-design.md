# API Design

## Base URL

```
/api/v1/
```

All endpoints require a valid Firebase ID Token in the `Authorization: Bearer <token>` header, except L0 public endpoints.

Authorization is relationship-based. A `User` is a person-first account; owner actions are allowed through vault ownership and account capability, while viewer actions are allowed through permission records for the target vault.

## Platform Header

```
X-BK-Platform: web | ios | android
```

The API uses this header to enforce platform-level restrictions. Web clients are limited to L0–L4 content.

## Endpoints

### Authentication & Profile

| Method | Path | Description | Auth |
|---|---|---|---|
| `POST` | `/auth/verify` | Verify Firebase ID token, create/find User record | Token |
| `GET` | `/profile` | Get current user's profile | Required |
| `PATCH` | `/profile` | Update profile (real name, organization, purpose) | Required |
| `POST` | `/profile/photo` | Upload profile photo for face validation | Required |

### Vault & Content

| Method | Path | Description | Auth |
|---|---|---|---|
| `GET` | `/vaults/:vault_id` | Get vault public info (L0) | Optional |
| `GET` | `/vaults/:vault_id/contents` | List contents filtered by viewer's level | Required |
| `GET` | `/contents/:id` | Get single content (with camera/GPS/NTP checks) | Required |
| `POST` | `/my/contents` | Create content in current user's owned vault | Owner |
| `PATCH` | `/my/contents/:id` | Update content in current user's owned vault | Owner |
| `DELETE` | `/my/contents/:id` | Delete content in current user's owned vault | Owner |

### Access Links & Handshake

| Method | Path | Description | Auth |
|---|---|---|---|
| `GET` | `/p/:slug` | Resolve access link, return vault + preset info | Optional → Required for L1+ |
| `POST` | `/handshake` | QR/NFC handshake — exchange trust levels | Required |
| `POST` | `/my/access_links` | Create preset QR/access link for current user's owned vault | Owner |
| `GET` | `/my/access_links` | List all access links with usage stats | Owner |

### Q&A

| Method | Path | Description | Auth |
|---|---|---|---|
| `GET` | `/vaults/:vault_id/qa` | List visible Q&A items | Required |
| `POST` | `/vaults/:vault_id/questions` | Submit a question | Required |
| `POST` | `/my/qa/:id/answer` | Answer a question (Admin) | Owner |

### Notifications

| Method | Path | Description | Auth |
|---|---|---|---|
| `GET` | `/notifications` | List notifications for current user | Required |
| `PATCH` | `/notifications/:id/read` | Mark as read | Required |

### Greeting Cards

| Method | Path | Description | Auth |
|---|---|---|---|
| `POST` | `/my/greetings` | Create greeting card | Owner |
| `POST` | `/my/greetings/batch` | Batch import from Excel data | Owner |
| `GET` | `/greetings/:id` | View greeting (time-lock enforced) | Recipient |

### Audit & Analytics

| Method | Path | Description | Auth |
|---|---|---|---|
| `POST` | `/audit_logs` | Submit access forensics (face photo, GPS, timestamp) | Required |
| `GET` | `/my/audit_logs` | View audit logs for own vault | Owner |
| `GET` | `/my/analytics` | View analytics dashboard data | Owner |

### NTP Sync

| Method | Path | Description | Auth |
|---|---|---|---|
| `GET` | `/ntp/sync` | Get server UTC time for BK Time calculation | Required |

**Response:**
```json
{
  "utc_time": "2026-05-05T09:00:00.123456Z",
  "timestamp": 1778234400.123456
}
```

### Permissions

| Method | Path | Description | Auth |
|---|---|---|---|
| `GET` | `/my/permissions` | List all viewers and their levels | Owner |
| `PATCH` | `/my/permissions/:id` | Update a viewer's trust level | Owner |
| `POST` | `/my/invitations` | Send email invitation with preset access | Owner |

### Account Context (multi-tenant)

| Method | Path | Description | Auth |
|---|---|---|---|
| `GET` | `/account/context` | Return current user, capabilities, **owned vault list**, **received vault list**, `default_vault_id` | Required |
| `GET` | `/my/vaults` | List the current user's owned vaults | Required |
| `POST` | `/my/vaults` | Create a new owned vault (subject to `account.vault_quota`) | Required |
| `PATCH` | `/my/vaults/:id` | Update an owned vault | Owner |
| `POST` | `/my/vaults/:id/archive` | Soft-archive an owned vault | Owner |
| `POST` | `/my/vaults/:id/restore` | Restore an archived vault | Owner |
| `PATCH` | `/my/default_vault` | Set or change the default vault seed | Required |

`/my/*` endpoints always refer to resources owned by the current user **within the active vault context** resolved from `X-BK-Active-Vault` (or `default_vault_id`). `/vaults/:vault_id/*` endpoints refer to a specific target vault.

#### Deprecated aliases (one-release-cycle compatibility)

| Method | Path | Notes |
|---|---|---|
| `GET` | `/my/vault` | Returns the default vault; emits `Deprecation: true` and `Link: <…multi-tenant-model>; rel="successor-version"` |
| `POST` | `/my/vault` | Creates the first vault for users with zero vaults; returns `409 vault_quota_required_endpoint` otherwise with the canonical `POST /my/vaults` endpoint in the body |

#### Required request headers

| Header | Required for | Purpose |
|---|---|---|
| `X-BK-Active-Vault` | All `/my/*` routes that don't carry `:vault_id` | Selects the vault context for the request |
| `X-BK-Platform` | All authenticated requests | Enforces the L4 web cap |
| `X-BK-Time-Anchor` | All authenticated requests | NTP anchor for time-locked content |

#### `409 active_vault_required` response body

```json
{
  "error": "active_vault_required",
  "message": "This request requires an active vault context. Send X-BK-Active-Vault, or set default_vault_id via PATCH /api/v1/my/default_vault.",
  "owned_vaults": [
    {"id": 1, "slug": "personal", "display_name": "Personal", "kind": "personal"},
    {"id": 2, "slug": "work", "display_name": "Work", "kind": "professional"}
  ],
  "default_vault_id": null
}
```

## Content Filtering Logic

```ruby
# app/models/content.rb
scope :accessible_for, ->(user, vault, platform: nil) {
  return where(vault: vault) if user.owns?(vault) # Owner sees everything in this vault

  user_level = user.trust_level_for(vault)
  
  # Cap trust level to L4 for web platform
  user_level = [user_level, 4].min if platform == "web"
  
  # If no permission exists and user is not owner, they see nothing
  permission = user.permissions.find_by(vault: vault)
  return none unless permission

  if ActiveRecord::Base.connection.adapter_name == "SQLite"
    where(vault: vault).where("required_level <= :level", level: user_level)
  else
    where(vault: vault).where(
      "required_level <= :level OR JSON_CONTAINS(permitted_user_ids, :user_id)",
      level: user_level,
      user_id: user.id.to_s
    )
  end
}
```

## Error Responses

| Status | Meaning |
|---|---|
| `401` | Not authenticated (Firebase token missing/invalid) |
| `403` | Insufficient trust level or platform restriction |
| `404` | Content not found (or hidden for security) |
| `410` | Burn-after-reading content already viewed |
| `423` | Permanently blocked (e.g., camera/GPS permission denied) |
| `429` | Rate limited (anomalous access pattern detected) |
