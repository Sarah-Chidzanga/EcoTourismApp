# Shanya backend

Express/SQLite backend for the Zimbabwe travel app. This repository contains the source, schema setup, dependency lockfile, and automated tests. Live databases and credentials stay out of Git.

## Run locally

Install Node.js 22 or newer from https://nodejs.org/en/download, then run from the repository root:

```sh
cd backend
npm ci
npm test
npm start
```

The server listens at `http://127.0.0.1:3000`; `GET /health` reports its status. The first start creates `backend/ecotourism.db`. Existing accounts are preserved when adding the guide-language column and guide/booking tables. Tests use isolated temporary databases.

Optional environment variables: `PORT`, `HOST`, `DATABASE_PATH`. The default database location is relative to server.js. Authentication attempts are limited to 30 per IP per 15 minutes; this in-memory limit resets on restart. Proxy trust is disabled until configured for a specific host.

## App connection

Debug app builds use `http://localhost:3000`. Set `ECOTOURISM_API_URL` in the Xcode Run scheme to change it. For an iPhone on the same trusted Wi-Fi network, use the Mac's local hostname, such as `http://your-mac.local:3000`, and start the server with `HOST=0.0.0.0`. Local-network permission is required on the phone.

Release builds require an HTTPS `APIBaseURL` in the app Info.plist; they don't fall back to localhost. The app permits local networking and has a localhost HTTP exception, not a blanket HTTP exception.

Tokens are saved in device-only Keychain items, separately for each service URL. On launch the app validates the token with `/me`. Network failures preserve the token and offer retry. Logout revokes the server session and removes the saved token. Tokens expire after seven days; SQLite stores only their SHA-256 hashes. Passwords are bcrypt hashed and never logged.

## Authentication API

- `POST /register`: `name`, `email`, `password`, `role` (`tourist` or `guide`), optional `nationality`, `bio`, `languages`. Returns 201 with `id` and `message`.
- `POST /login`: `email`, `password`. Returns `id`, `name`, `role`, `token`, `expiresAt`.
- `GET /me`: current account profile.
- `POST /logout`: revoke the current session.

Protected endpoints require `Authorization: Bearer <token>`. Invalid/expired credentials return 401. Registration requires at least 8 characters and at most 72 UTF-8 bytes in a password. Email matching is case insensitive. Duplicate registration returns 409. Validation errors return 400.

## Guide and booking API

- `GET /guides`: public listings, only from guides who explicitly publish. Includes `id`, `name`, `title`, `location`, `bio`, `languages`, `dailyRate`, `maxGuests`. Does not expose email.
- `GET /guide-profile`: signed-in guide's listing or a private initial draft.
- `PUT /guide-profile`: guide-only update with `title`, `location`, `bio`, `languages`, `dailyRate` (USD), `maxGuests` (1–20), `published` (boolean). Publishing requires all text fields and a price of at least 1 USD. Turning publication off pauses new requests; existing bookings remain accessible.
- `GET /bookings`: only requests where the signed-in person is the tourist or guide.
- `POST /bookings`: tourist-only. Supply `guideId`, `tourDate` (`YYYY-MM-DD`, interpreted as a Zimbabwe calendar day), `guests`, `note`, `expectedPrice`, and a unique `requestId` (UUID). Returns the saved pending booking. Retrying the same ID and payload returns the original booking. A changed quoted price, conflicting active request, or unavailable day returns 409.
- `PATCH /bookings/:id`: body `status`. The assigned guide can accept (`confirmed`) or decline a pending request. Either participant can cancel pending/confirmed requests. Other users cannot access or change it.

A booking is a request for one guide for one calendar day, for the whole group. Its USD guide fee is captured when requested; later profile price edits do not change it. One confirmed booking per guide/date is enforced by a unique database index, including simultaneous acceptance attempts. Invalid dates, past dates, and groups over the guide's capacity are rejected. Pending requests do not reserve the date.

Contact emails are visible to the two participants only after acceptance. The app does not collect payments or send confirmation emails/notifications. Refresh My Trips or Requests for updates. Guests and guides must agree directly on itinerary, meeting point, entry fees, transport, meals, and payment arrangements.

## Pilot walkthrough

1. Register a guide account. In Workspace, open the guide listing editor, add locations/languages/bio/day rate, then publish.
2. Register a tourist account (or browse as a guest first). Find the guide, choose a date and group size, then submit a request.
3. Sign in as the guide. Open Requests, select the request, and accept or decline it.
4. Sign in as the tourist. My Trips shows the response; accepted requests expose an email contact link. Cancel a request to verify both sides see the updated status.
5. Restart the server and relaunch the app: accounts, sessions, profiles, and requests should remain. Never use real user data in the test suite.

## Travel catalogue

`GET /catalog` publicly serves `EcoTourismApp/travel-catalog.json`. Keep that file at its repository-relative location when deploying the backend. The same resource ships with iOS for offline browsing. The app refreshes on first exploration and pull-to-refresh, caches valid responses, and retains offline information if the service is unavailable.

The expanded directory includes 20 destinations, 39 activities, 29 venues and 18 operators or visitor authorities, plus six wildlife entries. New listings were researched on 2026-11-06 and 2026-11-07 using official park, heritage, hotel and operator sources; indexed official listings were used where automated access was blocked. Khayalethu uses a clearly labelled business-directory source. Kumusha is a day-visit listing until overnight facilities are confirmed. This is a growing directory, not an exhaustive business register or a guarantee of licensing or availability.

Catalogue schema 2 adds `venues` (Stays, Food, Day visits) and `wildlife`. Venue destinations may be null for standalone listings; wildlife activities must belong to one of the wildlife entry's destinations. The iOS app uses a versioned cache, rejects incompatible or older catalogues, and retains its bundled directory if an older server is still running. Deploy the updated catalogue with this app version. The backend serves the JSON loaded at startup.

The app includes searchable stays and food, wildlife-to-activity links, a game-drive filter, and a unified Saved tab. Settings under You supports System/Light/Dark appearance, directory refresh, and confirmed clearing of local saved destinations and venues. Individual guide profiles remain opt-in account data; guides can register from the directory and publish their own listing. Company reservations still happen on the provider website.

To update the directory, edit the JSON, preserve stable IDs, check official sources, update `reviewedAt`, run `npm test`, and restart/redeploy the backend. CI validates destination/provider relationships and HTTPS links when the catalogue changes. There is no public editing endpoint. Do not add unconfirmed prices, contacts or credentials.

Company enquiries open external websites; they do not create Shanya bookings. Registered guide requests remain a separate flow. Map links search for the destination rather than a verified entrance. Destinations without a photo use an illustration. Saved places stay on the device, with aliases preserving older saved names. The old sample guide contacts and unverified price ranges have been removed.

## Before inviting a public audience

This is a development milestone, not a deployed service. A supervised pilot still needs a reachable HTTPS backend and persistent, backed-up database. Before public distribution:

- Recruit actual guides and check destination content and guide credentials; profiles currently contain self-reported information, with no verified badge.
- Add email verification, password recovery, account deletion, and support/reporting tools.
- Decide cancellation/payment policies and provide privacy information and terms for the actual service.
- Add request notifications and guide calendar/blocked-date management; today accepted full-day requests reserve dates and guides can pause their listing.
- Configure hosting, monitoring, rate limits appropriate for the hosting proxy, backups, and restore drills. Move off the archived sqlite3 driver to a maintained database integration before production.
- Complete physical-device, accessibility, and TestFlight checks with both user roles.

GitHub preserves code and schema setup; it does not back up accounts and bookings. Use a separate SQLite-consistent backup process or a managed database backup service. Do not put live databases in this public repository.

## Social sign-in and memory sharing

See [SOCIAL_SIGN_IN_SETUP.md](SOCIAL_SIGN_IN_SETUP.md) for Google, Facebook and Apple configuration, callback URLs, activation checks, and the iOS memory-sharing behavior. Providers remain unavailable until configured.

## Explore, games, notifications and feedback

Explore now opens separate directories instead of listing every destination on its home screen. Play contains a local photo tile puzzle, wildlife memory pairs, and Zimbabwe place-name scramble. Photos are selected with the system picker and are not uploaded; game rounds are not persisted.

Restart/deploy the updated backend to create `notifications` and `suggestions` tables and booking triggers. Existing requests are not backfilled into the inbox; new requests and subsequent status changes generate updates atomically. `GET /notifications` returns the signed-in user's latest 100 updates. `PATCH /notifications/:id/read` checks ownership. The app refreshes the inbox when opened or pulled to refresh; this is not remote push delivery.

Local phone reminders are opt-in, support up to ten pending reminders, and can be removed in Notifications → Reminder Settings. They are independent of booking cancellations or itinerary edits. APNs device registration, push delivery, and physical-device delivery verification remain deployment work.

Signed-in users can submit ideas, problems, or listing corrections to `POST /suggestions`. Submissions are validated, rate-limited, and deduplicated by a client request ID. The app retains an unsent draft on the device. There is no public endpoint exposing submissions. On the backend host, an operator can review the latest 200 submissions with:

```sh
node review-suggestions.js
```

Set `DATABASE_PATH` if the deployment uses a different database file. Treat this output as private user feedback. An admin review dashboard, status workflow, and replies are not implemented.

For the persistent App Store rating action, add the published numeric app ID as the `AppStoreID` string in the iOS Info.plist. Until configured, the action explains that reviews become available after publication. It does not create local ratings or pretend to submit reviews. Apple controls the review page: https://developer.apple.com/documentation/storekit/requestreviewaction
