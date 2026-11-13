# Deployment and account operations

The repository now includes account recovery, email verification, account deletion, online SQLite backups and a Docker image definition. These are implementation tools, not a running production service. Deployment requires an actual host, persistent disk, HTTPS domain and mail service.

## Single-instance deployment

Run one backend instance against one local persistent disk. Do not use ephemeral storage, shared network SQLite files, or multiple app replicas. The SQLite database uses WAL mode. The runtime account needs write access to the database directory, including its WAL and shared-memory files.

Build from the repository root with `docker build -t shanya-api .`. The image runs as the unprivileged `node` user and serves port 3000. Mount a persistent writable volume at `/data`; the default database is `/data/ecotourism.db`. Supply secrets through your host's secret settings. The Docker build has not yet been exercised on a deployment host.

Terminate HTTPS at the hosting proxy, restrict direct backend access, and point the iOS Release `APIBaseURL` to the public HTTPS origin. The current server does not trust forwarded IP headers: behind a proxy its in-memory rate limits may group users together. Configure a precise trusted-proxy policy for the chosen host before inviting users; never enable unrestricted proxy trust. Monitor `/health`, request failures, disk space and backup age. Rate limits reset on restart.

## Mail and account recovery

Use `backend/.env.example` as a variable reference. The server does not automatically read `.env`; for local use run `node --env-file=.env server.js`. Set `SMTP_HOST`, `SMTP_PORT` (default 465), `SMTP_USER`, `SMTP_PASSWORD`, `MAIL_FROM` and an independently generated `AUTH_CODE_SECRET` of at least 32 characters. Configure the sender domain with your mail provider and test delivery, spam handling and failure alerts. Do not commit credentials.

- `GET /account/features` reports whether email codes are configured.
- `POST /account/password/request` accepts an email and returns a generic response to avoid disclosing account existence.
- `POST /account/password/confirm` accepts `requestId`, `code`, `password`. Success changes the password, verifies the email and revokes all sessions.
- Authenticated `POST /account/verification/request` and `/account/verification/confirm` verify the signed-in account's email.
- Codes expire after 15 minutes, allow five guesses, are stored as keyed hashes and cannot be replayed. A new code invalidates older codes for the same purpose. Recovery email delivery failures are logged without exposing whether the account exists.
- Authenticated `DELETE /account/delete` requires `confirmation: "DELETE"` and a sign-in within the previous ten minutes. It removes personal fields, sessions, listings and suggestions, cancels active requests and preserves anonymised counterpart booking history. Apple access must be revoked first; failed revocation leaves the account intact.

Social provider settings and the separately protected Apple token-encryption key are described in [SOCIAL_SIGN_IN_SETUP.md](SOCIAL_SIGN_IN_SETUP.md). Email verification is displayed in the profile; it is not currently a prerequisite for requesting a guide.

## Private backups and recovery

Run on the backend host, using a new private destination for each snapshot:

```sh
DATABASE_PATH=/data/ecotourism.db node backup.js /private-backups/snapshot-2026-11-10.db
```

The command uses SQLite's online backup API, checks integrity and refuses to overwrite existing files. Files are created with owner-only permissions. A raw copy of the live `.db` file can omit WAL transactions; use this command instead. Schedule it through the host, encrypt and copy backups off-host, choose a documented retention period, and alert on failures. GitHub stores code, not user databases.

For a restore drill, copy a snapshot into a separate private directory, set `DATABASE_PATH` to that copy and start an isolated backend with a different port. Confirm expected record counts and synthetic account/bookings flows. Never run tests against production accounts. For an actual restore, stop the service, preserve the current database and sidecars for rollback, restore into a fresh directory, then restart against that directory. Do not mix an old WAL file with the restored database. Protect the Apple encryption key separately; the database backup alone cannot recover encrypted tokens.

Backups may contain personal data removed from the live service. Establish a retention/deletion policy and a process to reapply deletions after restoring an older backup before serving traffic.

## Remaining release gates

Actual hosting and mail delivery; real Google/Meta/Apple provider checks; published operator privacy policy, terms and support contact; guide verification and blocked-date management; APNs remote notifications; physical-device/accessibility/TestFlight tests; App Store identifier and release signing. Local reminders and the in-app inbox already work independently of APNs. No online payment processing is implemented.
