# Audit & Forensics

## Overview

BK records every meaningful interaction as an immutable audit log. This serves dual purposes: **deterrence** (viewers know they are being watched) and **traceability** (if information leaks, the source can be identified).

## Forensic Data Collection

Every time a viewer accesses L5+ content, the following data is captured server-side:

| Data Point | Source | Storage |
|---|---|---|
| User identity | Firebase UID | AuditLog record |
| UTC timestamp | BK Time (NTP-synced) | AuditLog record |
| IP address | Request headers | AuditLog record |
| GPS coordinates | Geolocation API (client) | AuditLog record |
| Device info | User-Agent header | AuditLog record |
| Face snapshot | Camera capture (client → S3) | AuditLog `face_snapshot_url` |
| Action type | Controller context | AuditLog `action` enum |
| Access level at time | Permission lookup | AuditLog record |

## Immutability

Audit logs are **write-only**. No record can be updated or deleted, even by the vault owner (L9).

```ruby
class AuditLog < ApplicationRecord
  before_update { raise ActiveRecord::ReadOnlyRecord }
  before_destroy { raise ActiveRecord::ReadOnlyRecord }
end
```

All audit log writes originate from **server-side** (Cloud Functions / Rails controllers), not client requests. The server auto-attaches IP, timestamp, and request metadata to prevent client-side tampering.

## Incident Detection & Alerts

The system automatically flags anomalous behavior and notifies the vault owner:

| Trigger | Detection Method | Response |
|---|---|---|
| Rapid multi-page access | Rate analysis | Temporary account lock + owner notification |
| Location jump | GPS delta in short timeframe | Session termination + re-authentication required |
| Suspicious browser | DevTools-enabled UA, virtual machine | ABC Shield escalation + warning screen |
| Screenshot attempt | OS-level capture shortcut detection | Log entry + watermark brightness increase |
| Camera/GPS denial | Permission API rejection | Permanent content block for that user |

## Viewer-Facing Transparency

Viewers are explicitly informed that their access is monitored:

- Page footer displays: *"This access is recorded along with your IP address and GPS location."*
- Users can view their own access history on their profile page
- This transparency serves as a **psychological deterrent** against misuse

## BKC Admin Dashboard (Forensic Monitor)

The vault owner's admin panel provides:

- **Live Activity Feed:** Real-time stream of access events ("User X opened L7 content from Minato-ku")
- **Geo Map:** Active sessions plotted on a world map with GPS coordinates
- **User Timeline:** Per-viewer chronological history showing which pages were viewed, for how long, and from where
- **Face Snapshot Archive:** Grid view of captured face photos organized by user and timestamp
- **Incident Alerts:** Red-flagged entries requiring owner review

## Analytics Integration

Audit data feeds into BK Analytics (from beta launch onward):

- **Trust Transition Analysis:** Time between level upgrades, trigger events
- **Content Engagement:** View duration, scroll depth, repeat visits
- **Security Events:** Screenshot attempts, GPS denials, authentication failures
- **Accessibility Metrics:** Earphone connection rate, TTS usage frequency
- **Greeting Metrics:** Open rate after time-lock, preload success rate
