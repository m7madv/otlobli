# Authentication acceptance report

Status: **implementation complete; portal and physical acceptance pending**.

## Implemented

- One shared native social-login initializer.
- Google iOS client/server-client configuration and CI callback scheme.
- Existing Google backend verification and Otlobli session model retained.
- Generic verified external identity registration for Google and Apple.
- Duplicate provider identity, verified email, and delivery-phone prevention.
- Sign in with Apple button on iOS, 256-bit random nonce, SHA-256 nonce claim,
  Apple JWKS verification, authorization-code exchange, and stored refresh
  authorization for later revocation.
- Link Google/Apple from the authenticated account screen.
- In-app account deletion with two confirmations, session invalidation, push
  detachment, address/identity deletion, customer anonymization, required
  transaction-record retention, Apple revocation, and native provider logout.
- Third-party Apple provider token/profile logging and plaintext UserDefaults
  token persistence removed by a reproducible `patch-package` patch.

## Automated evidence

TypeScript, lint (0 errors), production build, release-service assertions,
Capacitor sync, and Android unit/debug compilation pass.

## Required physical evidence

Google: first login, cancel, offline/error, logout/login, existing Android user,
duplicate email prevention, linked token ownership, and deletion.

Apple: normal email, Hide My Email, cancel, existing-account link, logout/login,
revocation/deletion, and review-compatible button/presentation.

No real OAuth client, Apple capability/provisioning, production Edge Function,
or physical backend session was available in this task. Therefore neither
Google nor Apple is marked accepted yet.
