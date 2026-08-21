# Google Sign-In on iOS

## Architecture

iOS reuses the Android identity and Otlobli session system. It does not create
a Firebase/Supabase-auth user silo. `@capgo/capacitor-social-login` obtains a
Google ID token; `google-auth` verifies issuer, allowed audience, expiry, and
Google subject before finding/linking the existing `customers` record and
issuing the normal custom customer session.

The iOS OAuth client is bundle-bound to `com.otlobli.app`. The Web/server client
ID remains the server audience. CI inserts `GIDClientID` and the reversed client
ID URL scheme after Capacitor sync. The iOS Google action stays hidden when
`VITE_GOOGLE_IOS_CLIENT_ID` is absent, rather than presenting a broken login.
No Google client secret is embedded in the app.

Verified-email collision checks prevent silent duplicate accounts. An existing
Android-created account can use the same linked Google subject on iOS. A user
with an existing phone/other-provider account must authenticate first and then
link Google; accounts are not merged merely from client-supplied email.

## Apple review compliance

Because Google authenticates the primary Otlobli account, an equivalent Sign in
with Apple option is included on iOS. It uses a random nonce, server-side Apple
JWKS verification, issuer/audience/expiry/nonce checks, server-side
authorization-code exchange, refresh-token revocation on account deletion, and
the same customer/session model. Apple relay email is retained as a verified
provider address where supplied.

## Required configuration

Create the iOS OAuth client and add `VITE_GOOGLE_IOS_CLIENT_ID` to GitHub. Add
the Web, Android, and iOS client IDs to the backend `GOOGLE_CLIENT_IDS` secret.
Exact steps are in `REQUIRED_PORTAL_ACTIONS.md`.

Real Google login, cancellation, restoration, existing Android-account login,
and backend session creation remain physical-device acceptance items.
