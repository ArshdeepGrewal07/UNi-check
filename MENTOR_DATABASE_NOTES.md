> Pastel theme and career/map additions: see [THEME_AND_FEATURES.md](THEME_AND_FEATURES.md). The database now has 33 tables; existing demo login credentials are unchanged.

> Login and exact member/café counts: see [DATABASE_ACCOUNT_GUIDE.md](DATABASE_ACCOUNT_GUIDE.md). Email/password login is now supported; older demo-only sign-in notes are superseded.

# Updated mentor notes — database edition

This file supersedes the storage descriptions in the earlier mentor notes.

## What I can say

“Initially, much of our community data lived in React state or browser localStorage, and the backend used a temporary database. The new version uses persistent Cloudflare D1 for structured data and R2 for media. AI helped implement the migration and connect the screens. I am learning the schema, request flow, permissions and test evidence.”

## The main distinction

- React state still controls open menus, selected tabs and unsent inputs.
- D1 now stores authoritative account, chat, community and learning records.
- R2 stores image/audio bytes; D1 stores their ownership and access metadata.
- A ZIP includes the code and database definition, not the live users' private records.

## How a shared pin works now

The browser sends the title, location, category and duration. The server determines the owner from the session, generates an ID and expiry, and inserts a community record. Other signed-in accounts retrieve that record. Joining updates membership on the server. The displayed pin survives a Worker restart because D1 owns the data.

## Why there are 33 tables

Core entities such as users, messages, events, blocks and reports have their own relational tables. Community collections share a typed records table because their card data has different shapes. User actions, audit history, notifications and ownership remain separately queryable. Explain the mixed relational/JSON design honestly; do not call it a completely normalized schema with a dedicated table for every screen.

## Preventing conflicting claims

The server checks the version of a record when changing it. If another user saved first, it rereads the record and either retries safely or reports that the item is taken. The database operation updates the record and its related interaction/history entries together. A test with two competing accounts confirmed that only one marketplace reservation succeeded.

## Private records

Settings, study progress, focus sessions and guardian check-ins are tied to the authenticated account. A user cannot choose someone else's identity in the request. A third account was denied access to another conversation's media in the database test.

## What changed beyond storage

Matching now reads courses/interests from actual database user rows; the score is a simple rule, not a trained AI model. Demo chat replies are disabled unless explicitly enabled. Guardian no longer claims it sent SMS/security alerts; it saves a private walk and arrival record. Community owner notices appear in-app.

## Evidence and limits

The local Worker tests applied real generated migrations, authenticated multiple accounts, tested shared records, private preferences, conflicts, chat/media access and restart persistence. The browser navigation check exercised the main screens. These are local checks; a successful live deployment alone does not prove every browser, real-device permission, external service or high-load scenario.

Physical IoT, university verification, real vendors, payments and emergency delivery remain separate integrations. Sample catalog entries stay illustrative even though their storage is real. A completed backend should not be described as a completed campus partnership.

## Questions to practise

1. What is stored in D1 versus R2?
2. Why does localStorage not share a pin across phones?
3. What is a primary key and a foreign key?
4. How does the server identify the current user?
5. How does a reservation avoid being claimed twice?
6. What is a migration, and why should an applied migration remain unchanged?
7. Which records are shared and which are private?
8. What did the restart test demonstrate, and what did it not demonstrate?
9. Which features still need real external data or services?
10. Which parts did AI generate, and which parts can I explain independently?

Read DATABASE.md next, then trace one handler in src/app/api/community/route.ts with the related schema and UI hook open.

## Email signup and phone layout update

Choose **Create Student Account**, enter your email, a password of 12–128 characters and confirm it, then complete your profile. No phone number is required. Use **Email → password sign-in** with the same email after logout. Different emails create separate accounts. Duplicate email signup cannot overwrite an existing account. Email ownership and university enrollment are not verified by this signup; it does not create an email inbox.

Accounts and salted password hashes are stored in D1. Logout or the 30-day session expiry removes access, not the account or saved data. Demo OTP and the sample-account switcher cannot sign into these new accounts. Existing demo credentials remain unchanged. Profile data and personal progress remain scoped to their owner; public campus content remains shared.

The phone frame and Home/Buddies/Campus/Chats bottom tabs now stay the same on wider screens. Migration 0005 adds nullable `users.phone_number`, preserving existing records and foreign keys. Existing phones are backfilled once; new email-only accounts have no phone number. The legacy `mobile` column remains an internal unique contact key for migration compatibility and is not exposed as a phone.
