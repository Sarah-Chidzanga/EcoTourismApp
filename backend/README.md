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

Destination inspiration remains bundled in the app. Saved places are local to the device. Sample guide records in the old destination model are no longer shown as bookable guides.

## Before inviting a public audience

This is a development milestone, not a deployed service. A supervised pilot still needs a reachable HTTPS backend and persistent, backed-up database. Before public distribution:

- Recruit actual guides and check destination content and guide credentials; profiles currently contain self-reported information, with no verified badge.
- Add email verification, password recovery, account deletion, and support/reporting tools.
- Decide cancellation/payment policies and provide privacy information and terms for the actual service.
- Add request notifications and guide calendar/blocked-date management; today accepted full-day requests reserve dates and guides can pause their listing.
- Configure hosting, monitoring, rate limits appropriate for the hosting proxy, backups, and restore drills. Move off the archived sqlite3 driver to a maintained database integration before production.
- Complete physical-device, accessibility, and TestFlight checks with both user roles.

GitHub preserves code and schema setup; it does not back up accounts and bookings. Use a separate SQLite-consistent backup process or a managed database backup service. Do not put live databases in this public repository.
