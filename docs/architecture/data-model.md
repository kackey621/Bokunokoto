# Data Model

## Entity Relationship Diagram

```mermaid
erDiagram
    User ||--o| Vault : "has one"
    User ||--o{ Permission : "has many (as viewer)"
    Vault ||--o{ Content : "has many"
    Vault ||--o{ Permission : "has many"
    Vault ||--o{ AccessLink : "has many"
    Vault ||--o{ GreetingCard : "has many"
    Vault ||--o{ QaContent : "has many"
    Content ||--o{ Symbol : "has many"
    Content ||--o{ AuditLog : "has many"
    User ||--o{ AuditLog : "has many (as viewer)"
    User ||--o{ Notification : "has many (as recipient)"
    Vault ||--o{ Invitation : "has many"
    User ||--o{ FeatureFlag : "checked against"
```

## Core Models

### User

| Column | Type | Notes |
|---|---|---|
| `id` | bigint | Primary key |
| `firebase_uid` | string | Unique, from Firebase Auth |
| `email` | string | Encrypted |
| `real_name` | string | Encrypted; required for L2+ |
| `organization` | string | Relationship context (e.g., "high school friend") |
| `purpose` | text | Reason for access (e.g., "want to stay in touch") |
| `photo_url` | string | Profile image URL from IdP |
| `face_verified_at` | datetime | Timestamp when OpenCV face validation passed |
| `is_admin` | boolean | Master admin flag (for L9) |
| `created_at` | datetime | |

### Vault

| Column | Type | Notes |
|---|---|---|
| `id` | bigint | Primary key |
| `user_id` | bigint | FK → User (owner/discloser) |
| `display_name` | string | Public-facing name |
| `bio` | text | Short introduction (L0 visible) |
| `created_at` | datetime | |

### Content (Disclosure)

| Column | Type | Notes |
|---|---|---|
| `id` | bigint | Primary key |
| `vault_id` | bigint | FK → Vault |
| `title` | string | Encrypted (deterministic for search) |
| `body` | text | Encrypted (non-deterministic) |
| `format` | enum | `markdown` / `html` |
| `required_level` | integer | 0–9 |
| `symbol_type` | string[] | `help_mark`, `rainbow`, `ear_mark`, `maternity`, `custom` |
| `is_antigravity_enabled` | boolean | Apply ABC Shield (video stream blackout) |
| `is_burn_after_reading` | boolean | One-time view; deleted after reading |
| `audio_protection_required` | boolean | Require earphone for TTS |
| `camera_required` | boolean | Require camera capture before viewing |
| `gps_required` | boolean | Require GPS before viewing |
| `permitted_user_ids` | bigint[] | Individual whitelist (overrides level) |
| `created_at` | datetime | |

### Permission

| Column | Type | Notes |
|---|---|---|
| `id` | bigint | Primary key |
| `vault_id` | bigint | FK → Vault (whose vault) |
| `user_id` | bigint | FK → User (the viewer) |
| `granted_level` | integer | 0–9, manually set by vault owner |
| `relationship_context` | string | "colleague", "friend", "business partner" |
| `admin_note` | text | Owner's private note about this viewer |
| `source_access_link_id` | bigint | FK → AccessLink (how they connected) |
| `created_at` | datetime | |

### AccessLink

| Column | Type | Notes |
|---|---|---|
| `id` | bigint | Primary key |
| `vault_id` | bigint | FK → Vault |
| `slug` | string | Unique URL path (e.g., `recruit-nssol-2026`) |
| `preset_context` | string | "Tech Conference 2026", "Friend meetup" |
| `initial_level` | integer | Auto-granted level after L2 completion |
| `welcome_message` | text | Custom greeting shown after scan |
| `template` | string | `professional` / `casual` / `event` |
| `visible_fields` | string[] | Which profile sections to show |
| `max_uses` | integer | Nullable; limit number of activations |
| `use_count` | integer | Current activation count |
| `bound_user_id` | bigint | Nullable; FK → User (bound after first use) |
| `expires_at` | datetime | Nullable |
| `created_at` | datetime | |

### AuditLog

| Column | Type | Notes |
|---|---|---|
| `id` | bigint | Primary key |
| `user_id` | bigint | FK → User (viewer) |
| `content_id` | bigint | FK → Content |
| `action` | enum | `view`, `copy_attempt`, `screen_capture_detected`, `login`, `permission_denied` |
| `ip_address` | string | |
| `user_agent` | string | |
| `latitude` | decimal | GPS |
| `longitude` | decimal | GPS |
| `face_snapshot_url` | string | S3 path to captured photo |
| `access_level_at_time` | integer | Viewer's level when action occurred |
| `utc_timestamp` | datetime | BK Time (NTP-synced) |
| `created_at` | datetime | |

!!! warning "Immutable Logs"
    AuditLog records are **write-only**. `before_update` and `before_destroy` callbacks raise exceptions to prevent modification or deletion at the application level.

### Notification

| Column | Type | Notes |
|---|---|---|
| `id` | bigint | Primary key |
| `recipient_id` | bigint | FK → User |
| `sender_id` | bigint | FK → User (nullable) |
| `title` | string | |
| `body` | text | |
| `notification_type` | enum | `level_up`, `disclosure`, `qa_reply`, `greeting`, `system` |
| `link` | string | Deep link to relevant page |
| `is_read` | boolean | |
| `is_urgent` | boolean | |
| `created_at` | datetime | |

### GreetingCard

| Column | Type | Notes |
|---|---|---|
| `id` | bigint | Primary key |
| `vault_id` | bigint | FK → Vault (sender) |
| `recipient_id` | bigint | FK → User |
| `template_body` | text | HTML/Markdown with `{{variables}}` |
| `rendered_body` | text | Personalized output |
| `format` | enum | `markdown` / `html` |
| `unlock_at` | datetime | UTC time-lock |
| `timezone_override` | string | e.g., `Asia/Tokyo` |
| `preloaded_at` | datetime | When client downloaded encrypted content |
| `opened_at` | datetime | When recipient first viewed |
| `created_at` | datetime | |

### QaContent

| Column | Type | Notes |
|---|---|---|
| `id` | bigint | Primary key |
| `vault_id` | bigint | FK → Vault |
| `question_text` | text | |
| `answer_text` | text | Encrypted |
| `asker_uid` | bigint | FK → User |
| `visibility` | enum | `direct` (asker only) / `tiered` / `global` |
| `required_level` | integer | For `tiered` visibility |
| `is_answered` | boolean | |
| `created_at` | datetime | |

### Invitation

| Column | Type | Notes |
|---|---|---|
| `id` | bigint | Primary key |
| `vault_id` | bigint | FK → Vault |
| `email` | string | |
| `target_page_id` | bigint | FK → Content (nullable) |
| `token` | string | Secure random token |
| `initial_level` | integer | |
| `status` | enum | `pending` / `accepted` / `expired` |
| `expires_at` | datetime | |
| `created_at` | datetime | |

### FeatureFlag

| Column | Type | Notes |
|---|---|---|
| `id` | bigint | Primary key |
| `name` | string | Unique key (e.g., `nfc_handshake`) |
| `enabled` | boolean | Global toggle |
| `user_ids` | bigint[] | Specific users for beta testing |
| `created_at` | datetime | |

## Encryption Strategy

```ruby
class Content < ApplicationRecord
  encrypts :body, :medical_note, :private_comment  # Non-deterministic
  encrypts :title, deterministic: true              # Searchable
end
```

All sensitive fields use **Active Record Encryption** (Rails 7+). Face snapshots stored in S3 use **SSE-KMS** server-side encryption.
