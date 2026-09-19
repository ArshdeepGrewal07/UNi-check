# Verification report — persistent database edition

## Checked in this implementation

- Generated and applied the SQLite/D1 migrations in an isolated local Worker database.
- TypeScript check passed.
- Production Vinext/Worker build passed.
- Source lint passed with zero errors and seven existing image-optimisation recommendations.
- Three demo accounts authenticated against D1.
- All community catalog reads passed; a lecture note written by one user was read by another.
- Focus start/pause/resume persisted privately, and the record owner received an in-app activity notice.
- Core profile, buddies, chats, events, vendors, home, telemetry and matching reads succeeded.
- A pin created by one account was visible to another; repeated joins did not add duplicate members.
- A non-owner could not delete another user's pin.
- Private preferences could not be read anonymously or retrieved by a different account.
- A stale preference version was rejected rather than overwriting newer progress.
- Two simultaneous marketplace reservations resulted in one success and one conflict.
- Accepted-chat text and image messages were stored; the recipient could read the R2 image and a third account could not.
- Private guardian check-ins rejected updates from a different account.
- Destroying and recreating the Worker retained sessions, pins, private progress, messages, media and guardian status.
- Headless browser navigation exercised Home, Buddies, Exchange, Pulse, Academics, Campus and Chats without page exceptions. Some third-party images failed to load in the test environment.

## Boundaries

Tests use isolated data and local D1/R2 emulation. They are not live-site load tests. No external OTP provider, real campus sensor, vendor/payment service or emergency notification provider was tested or provisioned. Earlier microphone/GPS device simulations were performed before the D1 migration; this database suite verifies the new media storage/access path, not every physical device format.

The source contains additional safeguards and operations beyond those explicitly exercised above. Passing these checks does not mean every possible defect, race, browser difference or production security requirement has been eliminated.


## Pastel theme and career integration — 2026-09-12

Build and TypeScript passed. Local D1/R2 tests passed, including password/session regressions, all new career mutations, ownership and isolation, pin expiry, duplicate handling and Worker restart persistence. Mobile 390×844 and desktop 1280×900 browser checks passed: stable modal typing, skill/roadmap save, resume checks, printable saved resume, clustered pin creation/selection, zoom round trip to 100%, career navigation, member directory, password sign-in and no horizontal document overflow. No page errors were recorded. External image requests returned network errors in the local test environment; image fallbacks were retained. Screenshots were visually reviewed. These are local runtime checks; hosting status is verified separately.

## Email signup and phone layout validation — 2026-09-12

Typecheck and production build pass. ESLint has zero errors and five existing image-optimization warnings. Full D1/R2 regression and browser tests pass. Dedicated `node tests/signup.mjs` verifies email-only registration, normalized email login, duplicate/concurrent email rejection, secure password records, account isolation, demo-login/OTP restrictions, logout, 30-day session expiry, and persistence after Worker restart. Browser tests create an account through the signup link, log out, log back in using that email, and verify the same phone frame and bottom navigation at 390px and 1280px widths. The signup link uses normal navigation so its register query is reliably applied. These are local runtime/browser checks; deployment success is tracked separately.
