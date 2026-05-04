# API Design

## Base URL

```
/api/v1/
```

All endpoints require a valid Firebase ID Token in the `Authorization: Bearer <token>` header, except L0 public endpoints.

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
| `POST` | `/my/contents` | Create content (Admin mode) | Owner |
| `PATCH` | `/my/contents/:id` | Update content | Owner |
| `DELETE` | `/my/contents/:id` | Delete content | Owner |

### Access Links & Handshake

| Method | Path | Description | Auth |
|---|---|---|---|
| `GET` | `/p/:slug` | Resolve access link, return vault + preset info | Optional → Required for L1+ |
| `POST` | `/handshake` | QR/NFC handshake — exchange trust levels | Required |
| `POST` | `/my/access_links` | Create preset QR/access link (Admin mode) | Owner |
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

## Content Filtering Logic

```ruby
# app/models/content.rb
scope :accessible_for, ->(viewer, owner_vault, platform) {
  max_level = (platform == 'web') ? 4 : 9
  user_level = viewer.trust_level_for(owner_vault)

  where("required_level <= ?", [user_level, max_level].min)
    .or(where("? = ANY(permitted_user_ids)", viewer.id))
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
