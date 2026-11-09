# Social sign-in setup

The iOS app supports Google, Facebook and Apple through a system authentication browser. Until credentials are configured, `/auth/providers` omits those providers and the app disables their buttons. Email/password login remains available. No credentials belong in the app bundle or GitHub.

## Backend configuration

Set these in the hosting provider's secret/environment settings, then restart the backend:

| Variable | Value |
| --- | --- |
| `OAUTH_PUBLIC_URL` | The backend's public HTTPS origin, e.g. `https://api.your-domain.com` (no path) |
| `GOOGLE_CLIENT_ID` | Google OAuth web application client ID |
| `GOOGLE_CLIENT_SECRET` | Google OAuth web client secret |
| `FACEBOOK_APP_ID` | Meta app ID |
| `FACEBOOK_APP_SECRET` | Meta app secret |
| `FACEBOOK_GRAPH_VERSION` | Supported Graph API version for your Meta app; default `v25.0` |
| `APPLE_SERVICE_ID` | Sign in with Apple Services ID associated with your primary App ID |
| `APPLE_CLIENT_SECRET` | Apple-signed client-secret JWT generated with your Sign in with Apple private key; rotate before expiry |

The iOS release build must also have `APIBaseURL` configured to the HTTPS backend. Localhost alone cannot receive provider callbacks. Never commit `.env` files, Apple private keys, or client-secret JWTs.

## Provider dashboards

1. Google: configure the OAuth consent screen and a **Web application** OAuth client. Add `https://api.your-domain.com/auth/google/callback` as an authorized redirect URI. Add testers while the consent app is in testing, then complete Google's publishing requirements.
2. Meta: create an app with Facebook Login, configure the app domain and valid OAuth redirect URI `https://api.your-domain.com/auth/facebook/callback`, and configure email/public-profile permissions. Supply the required privacy and data-deletion URLs and complete Meta's review/live-mode requirements before public release. Testers must be allowed by the app while in development mode.
3. Apple: enable Sign in with Apple for the primary App ID, associate a Services ID, and register the backend domain and return URL `https://api.your-domain.com/auth/apple/callback`. Generate the client-secret JWT using the Apple key ID, team ID, and Services ID as documented by Apple. This implementation uses Apple's web flow, not a native authorization entitlement. Apple's first-login name is currently not imported; new accounts use “Explorer”.

## Verification before enabling public access

- Test each provider with real developer test accounts on a physical iPhone. Complete sign-in, sign-out, returning sign-in, denied consent, and cancellation.
- Confirm a real Apple token validates, including private-relay email, and schedule Apple client-secret renewal.
- Existing email accounts are intentionally not automatically merged: use the original login method. Account linking is not implemented.
- A newly created social account uses the tourist/guide role selected in the app. Returning accounts retain their existing role. Guides still complete and publish their own listings.
- Confirm current provider branding/review requirements and account-deletion requirements before App Store submission. This feature does not by itself make the app release-ready.

## Security and storage

Provider authorization codes are exchanged only by the backend. App handoff codes expire in one minute and are consumed atomically with a SHA-256 PKCE verifier. Provider state expires in ten minutes and is single-use. Apple signatures, issuer, audience, expiry and nonce are validated with `jose`. Google profiles are obtained from Google's authenticated OpenID user-info endpoint using the server-exchanged token; Facebook profiles use the server-exchanged token and app-secret proof. Provider access/refresh tokens are not persisted. App sessions use the existing expiring, hashed-token session store and iOS Keychain.

The SQLite database stores provider/subject-to-user mappings and short-lived OAuth requests. Back up this database alongside existing accounts. Run one backend instance with this SQLite database; database-hosting/multi-instance migration remains separate work.

## Sharing memories

`You → Share a Memory` supports up to five selected photos, a caption, caption copy, and the iOS share sheet. It requires neither social login nor posting permissions. Photos are resized to a maximum dimension of 2048 pixels and rendered without the original metadata. Drafts are not persisted. Receiving apps control accepted content and final publishing; some ignore captions or don't appear in the share sheet. No automatic Instagram/Facebook posting or server photo storage is implemented.

References: [Google web-server OAuth](https://developers.google.com/identity/protocols/oauth2/web-server), [Facebook manual login flow](https://developers.facebook.com/docs/facebook-login/guides/advanced/manual-flow/), [Apple user verification](https://developer.apple.com/documentation/signinwithapple/verifying-a-user).
