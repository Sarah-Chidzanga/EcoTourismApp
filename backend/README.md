# EcoTourism backend

Recovered Express/SQLite backend for the Shanya iOS app. Source and dependency lockfile live alongside the app so the backend can be restored from Git. The original iCloud folder and database are untouched.

## Run locally

Install a supported Node.js LTS release from https://nodejs.org/en/download (Node 22 or newer), then run from the repository root:

```sh
cd backend
npm ci
npm test
npm start
```

The server listens at `http://127.0.0.1:3000`. Verify with `curl http://127.0.0.1:3000/health`.

A fresh `backend/ecotourism.db` and users table are created automatically on first start. Database files, dependencies, and local environment files are ignored by Git. Never commit real user databases. Tests create and remove their own temporary database.

Optional environment variables: `PORT`, `HOST`, and `DATABASE_PATH`. The default database path is relative to server.js, not the terminal's working directory. An existing database with duplicate emails differing only in case must be reconciled before the unique email index can be created; startup fails rather than deleting data.

## API

- `GET /health`: 200 with `{"status":"ok"}`.
- `POST /register`: JSON containing `name`, `email`, `password`, and `role` (`tourist` or `guide`); optional `nationality` and `bio`. Returns 201 with `id` and `message`. Invalid input returns 400; duplicate email returns 409.
- `POST /login`: JSON containing `email` and `password`. Returns 200 with `id`, `name`, `role`, `token`, and `expiresAt`; incorrect credentials return 401. Existing identity fields remain compatible with the tourist screens.
- `GET /me`: send `Authorization: Bearer <token>` to read the signed-in user profile.
- `POST /logout`: send the same authorization header to revoke that session. Missing, invalid, revoked, or expired tokens return 401.

Registration requires a password of at least 8 characters and at most 72 UTF-8 bytes. Passwords are hashed with bcrypt. Email matching is case insensitive. The old unauthenticated account deletion route has been removed.

## iOS integration and remaining work

The existing tourist screens already call `http://localhost:3000/register` and `/login` and use the matching success status codes. These endpoints have been preserved. Run the server separately while using the iOS simulator. On a physical iPhone, localhost refers to the phone: a configurable Mac LAN address and appropriate local network/transport configuration are still needed.

The current app Info.plist uses an incorrectly named transport setting; simulator connectivity must be verified and any exception scoped to local development. Login failures currently appear only in the Xcode console. Guide forms still need wiring to the backend.

Sessions last seven days and survive server restarts. Only SHA-256 token hashes are stored in SQLite; raw bearer tokens are returned at login. Logout revokes the current session. Expired sessions are cleaned up during login. The iOS app still needs to store tokens in Keychain and send them to protected endpoints; it currently ignores the new session fields.

Authentication endpoints share a limit of 30 requests per IP per 15 minutes, returning 429 and Retry-After when exceeded. Limits are in memory and reset on restart; deployment across multiple processes needs a shared store. Proxy trust remains disabled; configure it deliberately for your hosting platform before deploying behind a reverse proxy.

GitHub Actions runs backend tests for pull requests and changes to main. Use `npm test` locally before pushing.

## Remaining product work

- Wire guide registration/login and persist guide languages and availability.
- Add bookings with stable guide IDs, tourist ownership, guide access rules, and status transitions.
- Connect app sessions, logout, profile, and user-facing errors.
- Add email verification and password recovery through a configured email provider.
- Set up hosting, HTTPS, monitoring, and automated database backups before production use.
- Plan migration from the recovered sqlite3 driver to a maintained SQLite driver or hosted database before production; its upstream repository is archived.

GitHub preserves source code and database creation logic, not live accounts or bookings. Back up the SQLite database separately using SQLite's backup API or a managed hosting backup service. Never upload a live user database to this public repository. This remains a local development backend until the deployment work above is complete.
