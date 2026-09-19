> Latest student-platform update: see [STUDENT_PLATFORM_UPDATE.md](STUDENT_PLATFORM_UPDATE.md) for the 44-table database, conversation-only restrictions, new features, encryption limitations and Cloudflare setup. This supersedes older feature/count notes below.

> Pastel theme and career/map additions: see [THEME_AND_FEATURES.md](THEME_AND_FEATURES.md). The database now has 33 tables; existing demo login credentials are unchanged.

> Login and exact member/café counts: see [DATABASE_ACCOUNT_GUIDE.md](DATABASE_ACCOUNT_GUIDE.md). Email/password login is now supported; older demo-only sign-in notes are superseded.

# LPU Campus App — persistent database edition

The original UI is retained. Core accounts, chats, profiles, events and reports now use persistent Cloudflare D1 (SQLite), replacing the in-memory PostgreSQL emulator. Images, audio and report screenshots use private R2 object storage. Community and study screens now read/write authenticated APIs.

## Run the complete project locally

Use Node.js 22.13 or newer (Node 24 recommended).

```sh
npm ci
npm run build
npm start
```

Open **http://127.0.0.1:5173**. `npm start` applies unapplied local migrations and preserves the database/media under `.wrangler/state`. Stopping and restarting does not erase them. Do not delete that folder if you need local data. `start-dev.bat` runs this flow on Windows.

The local launcher enables demonstration accounts explicitly. Optional `.dev.vars` overrides are described in `.env.example`. This is a private demonstration app; sample profiles/catalog entries do not establish university identity or official vendor offers.

## Included database files

- `db/schema.ts`: migration schema entrypoint.
- `src/db/schema.ts`: core relational tables.
- `src/db/community-schema.ts`: community, private preferences, activity history, media, notifications, focus, guardian and telemetry tables.
- `drizzle/*.sql`, `drizzle/meta/`: generated, versioned migrations.
- `database/schema.sql`: combined schema for reading/import into a **new empty** SQLite database only.
- `src/db/seed.ts`, `core-seed.json`, `community-seed.json`: idempotent sample catalog initialization.
- `DATABASE.md`: table/feature mapping, security, persistence and setup details.
- `MENTOR_DATABASE_NOTES.md`: explanation of what changed and remaining limitations.

## Checks

```sh
npm run typecheck
npm run lint
npm run build
npm run test:database
```

The database suite uses an isolated local Worker and database, tests multiple users, concurrent claims, media access and a Worker restart. It never writes test data into the live site. Optional browser coverage uses Playwright; set `BROWSER_QA=1` and optionally `BROWSER_EXECUTABLE` before running the same suite.

## Live hosting

The existing private Sites app uses the logical `DB` and `BUCKET` bindings in `.openai/hosting.json`. Sites provisions the actual database/bucket and applies generated migrations during publication. Do not copy a PostgreSQL URL into this edition: the old PostgreSQL adapter is removed.

Local and hosted databases are separate. The ZIP includes source, schema and migration files, not live users, chat contents, credentials or a live database export. Existing data from the previous in-memory version cannot be recovered after its server was replaced; old browser-only pins are not automatically imported.

For further schema edits, run `npm run db:generate`, review the generated SQL, then rebuild and publish. Once deployed, applied migration files must remain unchanged; add another migration for later changes. Back up existing live data before destructive schema work.

## Real external integrations

Real SMS/email requires your own `OTP_DELIVERY_URL`, optionally `OTP_DELIVERY_TOKEN`, and a stable private `OTP_SIGNING_SECRET`. Hosted demo mode is explicit, not a claim of genuine university verification. Set `DEMO_MODE=false` only after configuring delivery and genuine account access. Demo peers no longer automatically reply unless `SIMULATE_DEMO_REPLIES=true` is explicitly configured.

Real IoT still requires `IOT_API_URL` and optionally `IOT_API_TOKEN`. The feed shape remains `{updatedAt,machines,rooms,noise}`. Telemetry snapshots are stored with their demo/live source for seven days. The UI checks freshness and does not turn failed live feeds into sample values.

Sample campus maps, room layouts, vendor offers, schedules and learning catalogs remain illustrative. Persisting an offer does not create a vendor contract, payment, real booking or university registration. Guardian stores private walks/check-ins; it does not track GPS continuously or notify emergency services. Community notifications are in-app records, not email/SMS/push messages.

## Email signup and phone layout update

Choose **Create Student Account**, enter your email, a password of 12–128 characters and confirm it, then complete your profile. No phone number is required. Use **Email → password sign-in** with the same email after logout. Different emails create separate accounts. Duplicate email signup cannot overwrite an existing account. Email ownership and university enrollment are not verified by this signup; it does not create an email inbox.

Accounts and salted password hashes are stored in D1. Logout or the 30-day session expiry removes access, not the account or saved data. Demo OTP and the sample-account switcher cannot sign into these new accounts. Existing demo credentials remain unchanged. Profile data and personal progress remain scoped to their owner; public campus content remains shared.

The phone frame and Home/Buddies/Campus/Chats bottom tabs now stay the same on wider screens. Migration 0005 adds nullable `users.phone_number`, preserving existing records and foreign keys. Existing phones are backfilled once; new email-only accounts have no phone number. The legacy `mobile` column remains an internal unique contact key for migration compatibility and is not exposed as a phone.
