# Required portal actions

Bundle ID for every Apple/iOS item: `com.otlobli.app`.

The Apple Team ID was not present in the repository or GitHub Secrets. Obtain
the exact 10-character value from Apple Developer → Membership details. Use
that same value everywhere below; never guess it.

## Apple Developer — capabilities and signing

1. Certificates, Identifiers & Profiles → Identifiers → `com.otlobli.app` →
   enable **Push Notifications** and **Sign in with Apple** → Save.
2. Keys → create one APNs key with Apple Push Notifications enabled. Download
   the `.p8` once. Record Key ID and Team ID. The file and value are secret.
3. Keys → create/use a Sign in with Apple key associated with
   `com.otlobli.app`. Download its `.p8`; record Key ID and Team ID. Secret.
4. Profiles → regenerate the App Store distribution profile after enabling
   both capabilities. Verify its application identifier is
   `<TEAM_ID>.com.otlobli.app` and entitlements include production APNs and
   Sign in with Apple.
5. Export an Apple Distribution `.p12` with a strong password.

GitHub repository → Settings → Secrets and variables → Actions:

- `APPLE_TEAM_ID` (sensitive account identifier)
- `IOS_DISTRIBUTION_CERTIFICATE_BASE64` (secret)
- `IOS_CERTIFICATE_PASSWORD` (secret)
- `IOS_PROVISIONING_PROFILE_BASE64` (secret)
- `VITE_GOOGLE_IOS_CLIENT_ID` (public OAuth identifier, stored as a secret for
  controlled release configuration)

## Google Cloud — iOS OAuth client

Google Cloud Console → APIs & Services → Credentials → Create credentials →
OAuth client ID → **iOS**. Set Bundle ID exactly to `com.otlobli.app`. Use the
same Google Cloud project as Android and the existing Web/server client. Copy
the resulting `*.apps.googleusercontent.com` value into
`VITE_GOOGLE_IOS_CLIENT_ID`. CI derives the reversed callback scheme.

In Supabase Edge Function secrets set `GOOGLE_CLIENT_IDS` to the comma-separated
existing Web, Android, and new iOS client IDs. Verify a physical iPhone login
creates the normal Otlobli session for an Android-created account. OAuth client
IDs are not private keys; do not add any OAuth client secret to the app.

## Supabase — Edge Functions and secrets

Deploy migration `20260821090000_production_auth_push.sql`, then deploy
`google-auth`, `apple-auth`, `account-lifecycle`, and `send-push` with the
project's existing JWT-verification policy preserved.

Set these secrets:

- `APPLE_SIGN_IN_KEY` = full Sign in with Apple `.p8` contents (secret)
- `APPLE_SIGN_IN_KEY_ID` = its Key ID
- `APPLE_TEAM_ID` = Membership Team ID
- `APPLE_CLIENT_ID` = `com.otlobli.app`
- `APPLE_CLIENT_IDS` = `com.otlobli.app`
- `APNS_KEY` = full APNs `.p8` contents (secret)
- `APNS_KEY_ID` = APNs Key ID
- `APNS_TEAM_ID` = Membership Team ID
- `APNS_BUNDLE_ID` = `com.otlobli.app`
- existing `FCM_SERVICE_ACCOUNT_JSON` for Android (secret)
- existing `PUSH_TRIGGER_SECRET` (secret; required for backend callers)

Verify with a protected `send-push` dry run, inspect only token counts, then send
to one installation in sandbox and production as appropriate. Never paste
device tokens or private keys into Git, issues, or chat.

## Android release signing

GitHub Actions also lacks the Android production signing values:

- `ANDROID_UPLOAD_KEYSTORE_BASE64`
- `OTLOBLI_APP_STORE_PASSWORD`
- `OTLOBLI_APP_KEY_ALIAS`
- `OTLOBLI_APP_KEY_PASSWORD`

Use the existing Google Play upload key, not a new identity. After the secrets
are present, manually run **Final Release Candidate**. It builds artifacts but
does not submit them.

## Store listing/review values

Provide and verify a public privacy-policy URL and support URL, screenshots,
age rating, privacy/data-safety declarations, notification purpose, demo
account if required, account-deletion instructions, and review notes explaining
human verification and the intentional unavailability of SHEIN login/account/
region/currency controls.
