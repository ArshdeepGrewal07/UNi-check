> Pastel theme and career/map additions: see [THEME_AND_FEATURES.md](THEME_AND_FEATURES.md). The database now has 33 tables; existing demo login credentials are unchanged.

> Login and exact member/café counts: see [DATABASE_ACCOUNT_GUIDE.md](DATABASE_ACCOUNT_GUIDE.md). Email/password login is now supported; older demo-only sign-in notes are superseded.

# Database implementation

## Storage decision

This edition uses **Cloudflare D1**, a persistent SQLite database, with **R2** for image/audio bytes. It replaces the previous pg-mem fallback throughout the core application. A missing binding produces an error; the server never silently falls back to memory or localStorage.

The app contains 33 tables. The existing UI remains; save handlers wait for a successful API response before closing creation forms or reporting successful claims.

## Table-to-feature mapping

| Tables | Features/data |
| --- | --- |
| users | Accounts, profile, course, year, interests, privacy and restriction flags |
| otp_codes | Contact verification codes and expiry/usage timestamps |
| auth_sessions | Durable login sessions; server lookup enforces a 30-day lifetime |
| chat_sessions, messages | Chat requests, acceptance, deadlines, media access and messages |
| events, event_rsvps | Campus events and participation records |
| places, vendors, reviews | Map locations, vendor/menu data and reviews |
| reports, blocks | Private report evidence references and block relationships |
| announcements | Campus notices |
| community_records | Typed collections of campus/community records and illustrative catalogs |
| community_interactions | Unique user/record/action memberships, proposals, reservations and votes |
| community_activity | Durable history of community mutations, including lecture-note text |
| user_preferences | Private account settings, checklists, quests, XP and practice scores |
| focus_sessions | Solo/duo timer start, pause, resume, completion and today's totals |
| guardian_sessions | Private route/check-in history and deadlines |
| notifications | In-app activity notices addressed to record owners |
| media_files | File owner, permitted conversation, object key, MIME type and size |
| telemetry_readings | Demo/live snapshots, retained for seven days |
| seed_versions | Idempotent catalog initialization markers |

`community_records.kind` covers beacons, pins, practice spaces, games, equipment, posts, bounties, barter offers, marketplace, surplus food, culture, flash events, schedules, lecture rooms, projects, chai meetups, duel questions, quiet spots, quests, flashcards, indoor rooms, AR destinations, guardian route presets and sample leaderboards.

Shared records have stable IDs, owner references, sample flags, version numbers, optional expiry and timestamps. Their feature-specific fields are JSON because the preserved screens have different shapes. Identity, ownership and interactions are relational; this is a mixed relational/document model, not 25 independently normalized domain tables. Read-only catalog collections cannot be created by ordinary users through the public API.

## API surface

Existing `/api/auth`, `/api/me`, `/api/buddies`, `/api/chats`, `/api/events`, `/api/vendors`, `/api/home`, `/api/safety` now use D1.

- `/api/community?kind=...`: read up to 300 current records of one kind.
- `POST /api/community`: create permitted user content; join, vote, claim, reserve, propose, add lecture notes, or delete your own record.
- `/api/preferences?key=...` and `PUT /api/preferences`: read/write allowed private settings with expected version checks.
- `/api/focus`: persistent timer state and completion totals.
- `/api/guardian`: private walk/check-in state and history.
- `/api/matches`: computes recommendations from stored courses/interests; invitations use actual chat requests.
- `/api/media/:id`: authenticated access to stored attachments.
- `/api/telemetry`: validated feed or labelled samples, plus snapshot history in the database.

## Example request

```json
{
  "action": "create",
  "kind": "pins",
  "data": {
    "title": "Library study group",
    "locationName": "Central Library",
    "x": 42,
    "y": 14,
    "category": "study",
    "duration": 45
  }
}
```

The server reads the authenticated user from the session; it does not trust a submitted owner name or user ID. Another account can retrieve the shared pin. Its join is stored once per user, even if the request is retried. Expiry is evaluated using server timestamps.

## Concurrency and permissions

- Community mutations use version-conditional updates and bounded retries. Interaction/history/notification statements execute in the same D1 batch and are gated by a unique mutation token.
- Conflicting reservations return HTTP 409 instead of double-claiming an item. Food quantities cannot fall below zero through this API.
- Private preference saves include an expected version; stale writes return 409 and refresh the client's state instead of silently overwriting another device.
- Only a record's owner can delete it. User IDs and display names for actions come from the server session.
- Chat media requires membership in the associated conversation. Report media is visible only to the reporter in the current app; no moderator console has been implemented.
- R2 bytes are not publicly readable through a raw bucket URL. Media responses are private/no-store and include content-type protection.
- Browser polling loads shared records approximately every ten seconds. Changes are shared, but this is not a WebSocket service.
- Focus records store absolute deadlines; a reload does not restart the countdown. Completion totals are computed from saved sessions, using the India date boundary.

## Setup, migrations and operations

`npm start` runs the built Worker locally, applies unapplied migration files and opens port 5173. The local database and R2 emulator persist to `.wrangler/state`. Local demo OTP signing uses a generated secret under the ignored local runtime directory.

For the hosted app, Sites manages D1/R2 provisioning and applies `drizzle/*.sql` before publishing the Worker. There is no SQLite database file to upload manually to the hosted app.

`database/schema.sql` is an inspectable combined schema for a new, empty database. It is not an upgrade script. Use generated migration history for existing deployments. Generated SQL contains schema only; sample content is seeded separately using deterministic IDs and INSERT OR IGNORE so retries do not overwrite user edits.

Sample catalogs are initialized once. Expired sample meetups do not automatically reappear. Existing in-memory records and browser-local pins from the old version are not migrated. Backups, restore drills, account deletion/export and data-retention policies still need operational planning before public launch.

## Boundaries

Storage does not supply real students, hardware sensors, verified vendors, payment rails, live campus maps, timetable integrations or emergency contacts. The app remains a prototype with sample catalogs. Real delivery needs an authorised external provider. OTP brute-force protection, moderation workflows, fine-grained administrative access, larger-scale pagination, robust chat idempotency and production load/security testing remain future work.

## Email signup and phone layout update

Choose **Create Student Account**, enter your email, a password of 12–128 characters and confirm it, then complete your profile. No phone number is required. Use **Email → password sign-in** with the same email after logout. Different emails create separate accounts. Duplicate email signup cannot overwrite an existing account. Email ownership and university enrollment are not verified by this signup; it does not create an email inbox.

Accounts and salted password hashes are stored in D1. Logout or the 30-day session expiry removes access, not the account or saved data. Demo OTP and the sample-account switcher cannot sign into these new accounts. Existing demo credentials remain unchanged. Profile data and personal progress remain scoped to their owner; public campus content remains shared.

The phone frame and Home/Buddies/Campus/Chats bottom tabs now stay the same on wider screens. Migration 0005 adds nullable `users.phone_number`, preserving existing records and foreign keys. Existing phones are backfilled once; new email-only accounts have no phone number. The legacy `mobile` column remains an internal unique contact key for migration compatibility and is not exposed as a phone.
