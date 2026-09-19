# Pre-deployment handoff review

## Source comparison

- GitHub `main` inspected at `5d3ae93711758bb0502a73504b14098613a41bea` (September 14).
- Intended source: uploaded `Uni-connect360-main(1).zip`, SHA256 `35d0325f04e3ec4c9c5326a23f8b00d4d050a49f25b7326bc6d5386ab2d330b4`.
- All 175 files in that ZIP matched the previously prepared update before this review. The original update differs from GitHub in 70 files, including two additive migrations.
- The fixes below are additional corrections to that ZIP. The phone layout and Workers/D1/R2 architecture remain.

## Corrections

1. Removed leftover global-restriction UI in Profile and Buddies and its obsolete request-error handling.
2. Removed the API lookup that associated a whole account with an expired conversation. Compatibility response fields are always `false`/`null`. The old database column remains so existing data/schema stay compatible; the old flag-clearing function never restricts anyone.
3. Simplified chat refresh/demo-expiry behavior so it depends on conversation state, not an account restriction.
4. Replaced official-university-verification claims in Profile, sign-in and marketplace UI. An app account reference is no longer mislabeled as a college registration number. The actual college registration field remains in student profile settings.
5. Removed unsupported claims of university complaint handling and university-admin gender verification.
6. Restored `wrangler.json` exactly to the working GitHub configuration and replaced the previous manual Worker-deploy instructions with the existing GitHub-triggered Cloudflare workflow.
7. Added a migration-upgrade test and browser assertions against the misleading Profile wording. Added private database-export ignore patterns.

## Migration review

Migrations 0000–0005 remain unchanged. Migrations 0006 and 0007 contain only CREATE TABLE/INDEX statements; they do not drop, alter, update or delete existing data. ON DELETE clauses define future relationships in the new tables; they do not delete rows when these migrations run.

The upgrade test starts from 0000–0005 with a representative existing account, password-hash record, session, login-attempt record, event, cafe, community record, career listing and R2 object. It compares every old application table's rows and schema before/after 0006/0007, checks foreign keys, checks all 11 new tables and confirms the old object is unchanged. This is a local D1 emulator test, not a backup or verification of the live database.

Run `npm run test:migration-upgrade` to repeat it. The application database/browser suites additionally test actual account login, conversation-only expiry and recipient reopening, encrypted message/media round trips, tamper rejection, key-backup recovery, student workflows and persistent storage.

## Security and feature limits reviewed

- Chat uses client ECDH/HKDF/AES-GCM with encrypted backup support. It remains unaudited, lacks forward secrecy and automatic key rotation/device revocation, and depends on browser key storage. Both participants need keys. Existing plaintext history stays plaintext. Compare fingerprints separately; this is not a Signal-level security claim.
- Email verification confirms mailbox access only. For real sending, configure server secrets `RESEND_API_KEY`, a private stable `OTP_SIGNING_SECRET`, and sender `EMAIL_FROM` in the existing Cloudflare Worker. `EMAIL_FROM` must be a sender authorized by the email provider. No email provider credentials were available for live delivery testing.
- Optional signup bot challenge needs private `TURNSTILE_SECRET_KEY` and public `TURNSTILE_SITE_KEY`, configured for the actual app hostname. Do not enable only the secret without its matching public site key.
- Room gaps come from shared timetable entries, not official university room occupancy. This is stated in the UI. No official UMS complaint integration exists.
- Receipts/QRs are evidence. The courier must check their actual bank/UPI balance before confirming payment. There is no payment-gateway verification.
- Reminders run while the app is open. Calendar export is available; system push notifications are not implemented.
- Existing accounts without a new student_profiles row can still sign in; they fill the new optional profile details later. Their email/password records are not replaced.

## Validation result

Build, TypeScript, migration-upgrade, database integration, signup/login browser and student-platform browser suites passed. Lint completed with zero errors and seven existing image-optimization advisories. Browser checks include the corrected Profile wording. The build still emits the framework middleware-convention deprecation warning. These are local checks, not a live-production verification.

## Production status and next step

No GitHub push, live D1 migration, R2 change, resource recreation or Worker deployment was performed in this review. The supplied live row counts are handoff information, not counts independently read here. There is no authenticated Cloudflare account connection in this session.

First, back up the real database from the owner's authenticated terminal. In PowerShell:

```powershell
Set-Location D:\App
npx wrangler d1 export uni-connect-db --remote --output D:\uni-connect-db-before-student-update.sql
```

This writes the backup outside the repository. Keep its contents private. Export may briefly block database requests while it runs. If authentication is requested, sign in to the Cloudflare account that owns this database. Share the completion/error message, not the SQL contents. Do not apply migrations or push yet.

Source: [Cloudflare D1 export documentation](https://developers.cloudflare.com/d1/best-practices/import-export-data/).

After a successful backup, review the remote pending-migration list, apply only 0006/0007, compare existing counts and check the existing account still works. Then configure required secrets, finish local verification, and push the reviewed source so Cloudflare deploys through the existing pipeline. Check that build and the same live URL. Do not manually redeploy the Worker or import the combined schema into production.
