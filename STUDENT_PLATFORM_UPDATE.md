# Uni-connect360 student platform update

This update targets the latest Uni-connect360 repository and its Cloudflare deployment. The phone frame and existing navigation remain. Older documents describing account-wide chat restrictions or 33 database tables are superseded here.

## Where to find the features

| Request | Implementation and limits |
| --- | --- |
| 48-hour chat restriction | Only the expired pair is blocked from restarting that conversation. Other conversations remain available. Its recipient can reopen it by accepting. The account-wide popup and restriction banner are removed. |
| Events, timetable, assignments, CA reminders | Home → **Plan your day · Campus desk** → Planner. Private entries persist in D1; shared events appear to other students. Reminders appear while signed in with the app open. Export calendar entries to get reminders through your calendar app while this app is closed. |
| Free classrooms | Campus desk → Rooms calculates gaps from overlapping, shared lecture entries. This is incomplete student-entered information, not the official university room inventory or booking system. Enter individual lecture occurrences; recurring timetable import is not implemented. |
| Classroom complaints | Rooms saves seat, AC, cleanliness or other reports with an optional photo. Recent issue categories accompany room results. Reports are stored here; there is no UMS integration or administrative resolution console. |
| Forum | Campus desk → Forum supports questions, answers and deletion of your own content. |
| Student identity and profile | Profile supports editable name, optional age, college, unique registration number, photo, bio, work availability and saved PDF resume. Signup requires a registration number. Uniqueness is enforced by the database, but does not prove university enrollment. |
| Career matching | Existing opportunities retain posting, matching, applications and status controls, with saved resume/profile sharing and a Referred status. Posters can represent student/alumni opportunities; no alumni identity verification or guaranteed referral is implied. |
| Solo Zone | New subtitle and a small degree-family question bank used in Solo flashcards and interview practice. It is a starter bank, not a complete curriculum. |
| Buddies scrolling | The heading and Solo/Duo/Squad controls scroll with the page. |
| Encrypted messages | New updated-client text, image and voice messages are encrypted before upload. See the encryption section below. Existing plaintext history is not retroactively encrypted. |
| Email verification | Profile offers email-code verification. Resend sender/API configuration is required. Codes expire after 10 minutes, allow five attempts and cannot be reused. Email ownership is distinct from student verification. |
| Parcels | Request → courier claim → parcel photo and payment QR → receiver receipt upload → courier confirms actual full payment → handover → receiver confirms delivery. Late/damaged/payment complaints retain optional evidence. Screenshots do not verify bank settlement. |
| Delete account | Profile requires current password and typing DELETE. Associated database rows and owned R2 files are removed. Previously downloaded copies, device key backups and provider backups cannot be recalled. |
| Site essentials | Privacy/terms pages, cookie choice, aggregate analytics endpoint, metadata, social image, favicon, sitemap, robots, custom 404, HTTPS redirection and response headers, validation, upload limits/compression, and optional Turnstile signup protection. |

## Database and files

Apply additive migrations `0006_rare_slayback.sql` and `0007_chubby_blue_blade.sql` after existing migrations. There are now **44 application tables**. Do not import the combined schema into an existing database; use migrations.

| New table | Purpose |
| --- | --- |
| student_profiles | One profile per user; unique registration, age, college, bio, availability, photo/resume references and email verification time |
| student_files | Owner, purpose, filename, MIME type, bytes and private R2 object key |
| planner_items | Entry type, owner, title, notes, time interval, reminder, room, sharing and completion |
| forum_questions / forum_answers | Authored questions and related replies |
| facility_complaints | Room, issue category, report and optional evidence reference |
| parcels | Requester/courier, locations, deadline, integer-paise cost/fee, state, evidence, payment/delivery timestamps and concurrency version |
| parcel_complaints | Participant, parcel, category, report and optional evidence |
| verification_challenges | HMAC of email OTP, expiry and attempt counter; no plaintext code |
| analytics_daily | Aggregate date/event/count; no user ID in this table |
| chat_identity_keys | One immutable public ECDH key per account; no private key |

The authoritative field definitions are in `src/db/student-schema.ts`. `database/schema.sql` includes all migrations for reference/new empty databases. User-owned records use foreign-key cascades. File access is checked server-side; a saved resume is available to its owner and a poster receiving that owner's application. Applications share the **current saved resume**, not an immutable historical copy.

## Encryption and recovery

The browser generates a P-256 ECDH identity. A pair derives an AES-GCM key through HKDF-SHA256. Each message has a fresh 96-bit IV and authenticated participant identifiers. The server receives ciphertext, public keys and metadata. Encrypted image/voice envelopes use private R2 storage. Both students must open the updated app once to establish keys before they can exchange encrypted messages.

Private keys live in IndexedDB. Profile → Chat security exports a password-encrypted backup using PBKDF2-SHA256 (250,000 iterations) and AES-GCM. Restore that backup on another device. Losing all key copies loses access to encrypted history. Compare fingerprints through another trusted channel to detect public-key substitution.

This is a custom, **unaudited** implementation with static identity keys, **no forward secrecy**, no automatic multi-device key sync and no device revocation/key rotation. Browser compromise can expose local keys. System status messages and old messages may remain plaintext. Demo-only API traffic may use plaintext for the existing seeded test flows. Do not describe this as Signal-equivalent or independently security-certified.

## Cloudflare deployment

The existing `wrangler.json` from GitHub is retained, including worker name `lpu-campus-local`, the real `uni-connect-db` ID and R2 bucket `site-creator-r2`. The live site remains the existing `uni-connect360` workers.dev URL through the owner's current Cloudflare build configuration. Do not rename resources or replace the working build settings.

**Use the existing GitHub → Cloudflare automatic deployment. Do not manually deploy the Worker.** First export a backup of the real D1 database. Review and apply only the pending migrations 0006 and 0007 to that database, confirm successful application and preserved account/data counts, configure the required server-side secrets, and run local build/typecheck/tests. Only then push the reviewed code to the deployment branch. Watch the automatic build and test the existing live URL.

This source package has not been pushed or deployed. The current session has no authenticated access to the live Cloudflare D1/R2 account. Local `npm start` applies migrations to its own local database, not production. Do not import `database/schema.sql` into the live database or reset D1/R2.

See [HANDOFF_REVIEW.md](HANDOFF_REVIEW.md) for the comparison, fixes and next small step.

Configure these server-side values with Wrangler secrets / the Cloudflare dashboard:

- `OTP_SIGNING_SECRET`: a stable, private, high-entropy signing secret.
- `RESEND_API_KEY` and `EMAIL_FROM`: a configured email sender. No actual email delivery was exercised without owner credentials. Provider free-tier limits and sender requirements apply.
- `TURNSTILE_SECRET_KEY` and public `TURNSTILE_SITE_KEY`: configure both to require the signup challenge. Honeypot and request throttles are present independently; this is not a full moderation service.
- `DEMO_MODE=false` for real student use. Demo profiles are samples, not verified students. Existing seeded listings remain sample data until the owner curates them.

Do not put private secrets into public/client-prefixed environment variables or commit `.dev.vars`. The repository includes only an example configuration. Email verification currently happens in Profile; unverified accounts are not automatically blocked from all features.

## Quality checks and operational limits

- Database integration checks cover isolated chat expiry/reopening, room gaps, private planner entries, forum ownership, unique registration, file access, concurrent courier claims, payment gating, evidence and restart persistence.
- Browser checks exercise cross-account encrypted text/attachments, tamper rejection, encrypted backup restore, Campus desk and the phone frame at mobile/desktop widths.
- Signup checks cover different accounts, case-insensitive email login, duplicate races, password hashing, logout/login, session expiry and persistence.
- Uploads compress images to a maximum 1600-pixel side, with 2 MB image and 5 MB PDF server limits. Uploaded PDFs are attachments, not active HTML. There is no antivirus scanning service.
- Aggregate analytics require the optional consent choice; no third-party analytics SDK is installed. Query `analytics_daily` through the authenticated owner database console. There is no analytics dashboard.
- Browser checks are local and do not establish production Core Web Vitals, every external link's availability, a complete accessibility audit, or live Cloudflare service health. Existing image lint advisories remain.
- The social preview illustration in `public/og.png` was generated for this project with ImageGen (mint campus illustration, Uni-connect360 name and study/connect/grow tagline).
- Policy pages are project notices and need the owner's review and a private support channel before broad public launch.

## Run checks

```sh
npm run build
npm run typecheck
npm run lint
npm run test:database
npm run test:signup
npm run test:student
```

The two browser suites require Playwright and an installed Chromium; `BROWSER_EXECUTABLE` can point to a local Chromium binary. Tests create isolated temporary databases/R2 stores and do not access the production database.
