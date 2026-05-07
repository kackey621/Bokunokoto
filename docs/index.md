# Bokunokoto (BK) — Design Document

> *"To the right person, at the right time, in the right amount — I will tell you about me."*

## Executive Summary

**Bokunokoto (僕のこと / BK)** is a personal identity management platform that enables progressive self-disclosure under strict privacy controls. It allows individuals to share sensitive personal information — such as disabilities, LGBTQ+ identity, grief, chronic illness, and other topics that are socially difficult to discuss — with trusted people in a controlled, secure, and accessible manner.

**BKC (Bokunokoto Command Center)** is the administrative backbone, built as a Rails monolith, providing content management, user-trust control, greeting card distribution, and forensic monitoring.

## Design Principles

| Principle | Description |
|---|---|
| **Non-Community** | BK is not a social network. It facilitates independent 1-to-1 or 1-to-N trust relationships. Users cannot discover or interact with each other through the platform. |
| **Graduated Disclosure** | Information is organized across 10 security levels (L0–L9), each requiring progressively stronger authentication and trust. |
| **Symbolic Communication** | Visual symbols (Help Mark, Rainbow Symbol, Ear Mark, etc.) convey identity traits at a glance, reducing the burden of verbal explanation. |
| **Accessibility First** | The system is designed so that visually impaired users can safely receive sensitive information via secure audio (earphone-only TTS). |
| **Vault Isolation** | Every disclosure space is isolated in a private encrypted Vault. A user may own a vault and also receive access to other users' vaults from the same account. |
| **One-Person Account** | A `User` is a person, not a fixed discloser/viewer role. Product context comes from vault ownership and permission relationships. |

## System Name

| | |
|---|---|
| **Japanese** | 僕のこと |
| **English** | Bokunokoto |
| **Abbreviation** | BK |
| **Admin System** | BKC (Bokunokoto Command Center) |

## Target Users (Beta)

The beta phase targets **close personal relationships** — friends, colleagues, and acquaintances who interact face-to-face or through direct referral. It is not designed for anonymous or mass public use.

## Document Structure

This design document is organized into the following sections:

- **Architecture** — System overview, tech stack, account model, data model, and API design
- **Security** — 10-level trust system, ABC Shield, authentication, audit logs, NTP sync
- **Features** — QR/NFC handshake, greeting engine, symbolic disclosure, notifications, burn-after-reading, bank account display, dynamic access links
- **Accessibility** — Secure audio output, inclusive design principles
- **BKC Admin** — Command center, content editor, trust controller, analytics
- **Roadmap** — System plan, account-role replan, beta milestones, and release phase
