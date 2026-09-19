# Pastel theme and feature integration

The uploaded LPU-APP-main(1).zip was treated as a visual and feature reference. The working Cloudflare application, existing authentication, persistent data, and earlier bug fixes were preserved.

## Theme

The dashboard uses the reference’s white rounded cards, mint/indigo/peach accents, campus tower illustration, segmented controls and opportunity carousel. The same phone-sized frame and bottom navigation are used on both desktop and mobile. Global color tokens update existing screens consistently. The launch delay is removed; map transforms no longer animate behind drag input. Zoom increments use consistent precision, and nearby pins group into a selectable cluster. Reduced-motion settings are respected. Dialogs render above scrolling panels, trap keyboard focus and restore focus without interrupting typing.

## Connected features

| Reference feature | Implemented behavior | Database |
|---|---|---|
| Opportunities, search, filters, card/list view | Real skill-overlap sorting, saved/applied views, sample badges, user-created listings | career_catalog, career_profiles, career_saved |
| Applications | Consent and note required; duplicate-safe submission; only poster can see applicants or change status; closed listings reject applications | career_applications |
| Skills and learning tracks | User-entered skills, four suggested tracks, enrollment and module completion with stale-write protection | career_profiles, career_progress |
| Academic roadmap | Editable term, CGPA/goal, attendance, internship hours/goal, certification targets | career_profiles |
| Resume assistance | Actual keyword coverage against a selected opportunity, saved draft, saved assessment, printable resume with browser Save as PDF | career_profiles, career_attempts |
| Mock interview | Three stored practice questions; keyword coverage based on submitted answers, saved private history | career_catalog, career_attempts |
| Skill/opportunity map pins | Skill, bounty, team and study types; position, block, room, duration, reward and details; join/leave; message creator; creator removal; schematic meeting-point line; server expiry; nearby-pin chooser | skill_beacons, skill_beacon_members |
| Dashboard metrics | Existing real member/open-café/event counts, event calendar and vendor list | users, vendors, events |

## Database and upgrade

There are 33 application tables. New migration `0004_organic_post.sql` appends eight tables; existing migrations remain unchanged. The career-v1 seed adds four tracks, three clearly marked example opportunities and three practice questions only once. Users start with zero skills, no completed modules and no invented grades. Existing member accounts and passwords are unchanged.

All data mutations validate the authenticated session and input server-side. Private career profiles, drafts, scores and progress are scoped to their owner. A user deliberately applying to a listing shares name, course, email and application note with the poster. No external employer is contacted by this workflow. R2 remains the storage for existing chat attachments.

## Honest limits

Skill matches are requirement overlap, not AI scores. Resume/interview feedback is keyword coverage and cannot judge whether an answer is correct or whether a candidate will pass an ATS. Academic information is self-reported, with no university portal, verified CGPA, credit award or certification-voucher integration. Sample listings are examples; real opportunities can be posted by signed-in members. The map is schematic, not a surveyed indoor/GPS route. Rewards are arranged between members, with no payment processing. Real hardware IoT and real email/SMS delivery still require configured external services.

## Verification scope

Automated tests exercise actual local Cloudflare D1/R2 emulation, not a browser-storage substitute. Coverage includes authentic vs zero keyword matches, profile isolation, duplicate applications, poster-only application review, closed listings, stale module writes, answer-dependent feedback, invalid map coordinates, duplicate joins, expired pins and persisted state after Worker restart. Browser checks cover existing navigation, password sign-in, directory, career forms, saved resume and printable view, map pin creation/selection, zoom and phone/desktop overflow. External image hosts may be unavailable in the test network; existing image fallback components remain in place. Production rollout is confirmed separately from local browser tests.
