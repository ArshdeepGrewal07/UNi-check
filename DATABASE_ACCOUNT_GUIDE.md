> Pastel theme and career/map additions: see [THEME_AND_FEATURES.md](THEME_AND_FEATURES.md). The database now has 33 tables; existing demo login credentials are unchanged.

# Database and login guide

This is a demonstration app with a real persistent Cloudflare D1 (SQLite) database, not an official LPU student register. R2 holds uploaded image/audio bytes; D1 holds their metadata and ownership.

## Open and sign in

Open https://lpu-campus-buddies-app.arshdeepsinghgrewal1.chatgpt.site/login using the owning ChatGPT account. Choose University Email and enter one of the emails below, with password `QuadDemo!2026`.

These are sample application login IDs, not created email inboxes. The phone numbers are illustrative and must not be called or treated as verified student contact details. Every sample account initially has this shared demo password; Profile → Account password lets you change it. Demo accounts are for testing only and remain accessible using the explicit demo account switcher while DEMO_MODE=true.

## Actual records and counts

There are 13 sample users. Signing in as one leaves 12 other discoverable buddies (less if profiles are hidden or blocked). This is not a count of online people or accepted friendships. There are 11 vendors, 10 marked open and Green Bowl Café marked closed. Open/closed flags are stored sample status, not automatic live opening-hours detection.

Home → View all members & account details reads the member directory from D1. It shows sample member names, registration IDs, emails, phone numbers, course and year. Real members' contacts and registration IDs are only returned to that member. Hidden/blocked people are excluded. The directory supports additional pages. Café cards, menus, coordinates and reviews read the vendors/reviews tables. No rows were deleted to force an incorrect café count.

| Name | Registration ID | Login email | Sample phone |
|---|---|---|---|
| Anya Sharma | REG-D-1001 | student0@demo.campus.ac.in | 9000001000 |
| Aarav Mehta | REG-D-1002 | student1@demo.campus.ac.in | 9000001001 |
| Ishita Rao | REG-D-1003 | student2@demo.campus.ac.in | 9000001002 |
| Kabir Anand | REG-D-1004 | student3@demo.campus.ac.in | 9000001003 |
| Meera Pillai | REG-D-1005 | student4@demo.campus.ac.in | 9000001004 |
| Dev Sharma | REG-D-1006 | student5@demo.campus.ac.in | 9000001005 |
| Sana Sheikh | REG-D-1007 | student6@demo.campus.ac.in | 9000001006 |
| Rohan Iyer | REG-D-1008 | student7@demo.campus.ac.in | 9000001007 |
| Tara Kulkarni | REG-D-1009 | student8@demo.campus.ac.in | 9000001008 |
| Advait Nair | REG-D-1010 | student9@demo.campus.ac.in | 9000001009 |
| Niki Joshi | REG-D-1011 | student10@demo.campus.ac.in | 9000001010 |
| Priya Menon | REG-D-1012 | student11@demo.campus.ac.in | 9000001011 |
| Arjun Bhatt | REG-D-1013 | student12@demo.campus.ac.in | 9000001012 |

## Vendors

| Name | Stored status | Menu entries |
|---|---|---|
| Main Canteen | Open | 4 |
| Night Canteen | Open | 3 |
| Chai Tapri | Open | 3 |
| Green Bowl Café | Closed | 3 |
| Momos Corner | Open | 3 |
| Dahi House | Open | 3 |
| Rolls Mania & Kathi Point | Open | 3 |
| UniMall Waffle & Cafe Express | Open | 3 |
| Amritsari Kulcha Dhaba | Open | 3 |
| Madras Dosa Corner | Open | 3 |
| Fresh Juice & Shake Oasis | Open | 3 |

## Connections and persistence

| Screen/action | Persistent data |
|---|---|
| Login/profile | users → user_credentials; auth_sessions; login_attempts; otp_codes |
| Buddy discovery and chat relationships | users → chat_sessions; blocks |
| Messages and attachments | chat_sessions → messages; media_files → R2 objects |
| Cafés, menus, map and reviews | vendors, places, reviews → users |
| Event attendance | events → event_rsvps → users |
| Community features | community_records → community_interactions/community_activity → users |
| Saved settings and personal progress | user_preferences → users |
| Focus timers and safe walk check-ins | focus_sessions, guardian_sessions → users |
| Notifications | notifications → users and community records |
| IoT snapshots | telemetry_readings with explicit demo/live source |

There are now 33 application tables. A feature does not require a separate database: related tables share one database and link by stable IDs. Community feature types share community_records with a kind discriminator; their interactions reference the record and user.

Migration 0003 adds user_credentials and login_attempts without changing old applied migrations. Sample credentials are inserted idempotently on the next auth request, including upgrades with the older catalog-v1 seed marker. They never overwrite changed passwords. Database stores uniquely salted PBKDF2-SHA256 hashes, not plaintext passwords. Password changes require the old password once set, revoke previous sessions, and create a new session. Password attempts are capped at 10 per email per 15-minute window. New registration requires a password alongside both verified contacts; existing accounts can set a first password while signed in.

## Limits that must be explained to the mentor

Real email/SMS delivery and official enrollment checks are not connected. Demo OTP is displayed on screen. A mail service/institutional integration is required to verify real users. Hardware IoT requires a real feed; storing sample readings does not make them live measurements. Home's illustrative rhythm/hotspot charts are now labeled accordingly. Guardian check-ins do not send emergency SMS. Café data, menus, coordinates and sample student identities are illustrative, not verified official records. The site remains owner-private.

## Verification

Integration tests run against local Cloudflare D1/R2 emulation: all 13 password hashes; correct and wrong passwords; password changes; old-session revocation; login throttling; directory vs buddy/home counts; changing a vendor's stored flag changes Home; shared/private data permissions; Worker restart persistence. Production deployment success confirms rollout, not an interactive live password session.

## Email signup and phone layout update

Choose **Create Student Account**, enter your email, a password of 12–128 characters and confirm it, then complete your profile. No phone number is required. Use **Email → password sign-in** with the same email after logout. Different emails create separate accounts. Duplicate email signup cannot overwrite an existing account. Email ownership and university enrollment are not verified by this signup; it does not create an email inbox.

Accounts and salted password hashes are stored in D1. Logout or the 30-day session expiry removes access, not the account or saved data. Demo OTP and the sample-account switcher cannot sign into these new accounts. Existing demo credentials remain unchanged. Profile data and personal progress remain scoped to their owner; public campus content remains shared.

The phone frame and Home/Buddies/Campus/Chats bottom tabs now stay the same on wider screens. Migration 0005 adds nullable `users.phone_number`, preserving existing records and foreign keys. Existing phones are backfilled once; new email-only accounts have no phone number. The legacy `mobile` column remains an internal unique contact key for migration compatibility and is not exposed as a phone.
