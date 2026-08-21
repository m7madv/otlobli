# Exact remaining portal and device actions — v86.208

## Apple Developer and GitHub Actions

1. Apple Developer → Certificates, Identifiers & Profiles → Identifiers →
   `com.otlobli.app` → enable **Push Notifications** and **Sign in with Apple**.
   Regenerate the App Store profile. This unblocks correct production
   entitlements.
2. Apple Developer → Keys → create/reuse an APNs key; obtain secret `.p8`, Key
   ID, and Membership Team ID. In Supabase Edge Function secrets set
   `APNS_KEY`, `APNS_KEY_ID`, `APNS_TEAM_ID`, and
   `APNS_BUNDLE_ID=com.otlobli.app`. Verify with
   `node scripts/send-test-push.mjs --installation <exact-id>` and then the same
   command with `--send`. This unblocks direct APNs delivery.
3. Apple Developer → Keys → create/reuse a Sign in with Apple key attached to
   `com.otlobli.app`. In Supabase set secret `APPLE_SIGN_IN_KEY`, plus
   `APPLE_SIGN_IN_KEY_ID`, `APPLE_TEAM_ID`,
   `APPLE_CLIENT_ID=com.otlobli.app`, and
   `APPLE_CLIENT_IDS=com.otlobli.app`. This unblocks Apple token exchange and
   deletion revocation.
4. Export the known Apple Distribution identity as a secret `.p12` and obtain
   the matching App Store `.mobileprovision`. GitHub → repository Settings →
   Secrets and variables → Actions: set `APPLE_TEAM_ID`,
   `IOS_DISTRIBUTION_CERTIFICATE_BASE64`, `IOS_CERTIFICATE_PASSWORD`, and
   `IOS_PROVISIONING_PROFILE_BASE64`. Run **Final Release Candidate** and verify
   its entitlement/profile reports and SHA-256. This unblocks signed IPA.

## Google Cloud, Supabase, and GitHub

5. Google Cloud Console → APIs & Services → Credentials → Create credentials →
   OAuth client ID → iOS → Bundle ID `com.otlobli.app`. Add the exact returned
   `*.apps.googleusercontent.com` value to GitHub Actions secret
   `VITE_GOOGLE_IOS_CLIENT_ID`. Append the same ID to Supabase secret
   `GOOGLE_CLIENT_IDS` while preserving the existing Web and Android IDs.
   Rebuild once; CI writes `GIDClientID` and the reversed callback scheme. This
   unblocks physical Google iOS login.

## Android signing and Play

6. From the existing Google Play upload keystore, set GitHub Actions secrets
   `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`,
   `ANDROID_KEY_ALIAS`, and `ANDROID_KEY_PASSWORD`. Confirm Play Console → Setup
   → App integrity identifies the corresponding upload certificate. Run
   **Final Release Candidate**, then verify `apksigner`, `jarsigner`, package
   report, and SHA-256 outputs. This unblocks signed AAB/APK.

## Store records and acceptance

7. App Store Connect and Google Play Console: provide public Privacy Policy and
   Support URLs; complete actual App Privacy/Data Safety declarations; prepare
   iPhone/iPad/Android screenshots without personal data; complete age rating,
   notification purpose, authentication, human-verification, restriction, and
   account-deletion review notes. Do not submit without explicit owner approval.
8. Install the signed candidate on the exact devices in
   `COMPATIBILITY_MATRIX.md`, execute every counter and interaction, record
   median/p95/slowest opening time, send targeted foreground/background/
   terminated notifications, run Google and Apple authentication, and delete a
   dedicated test account. Attach sanitized results to the reports.

Supabase migration `20260821090000_production_auth_push.sql` and functions
`google-auth`, `send-push`, `apple-auth`, and `account-lifecycle` are already
deployed; do not redeploy them merely to satisfy this checklist.

