# Exact remaining TestFlight enablement actions — v86.213 / 1075

This checklist is for one internal TestFlight build. It is not authorization to
submit the app for App Store review. Do not create Apple resources, upload a
build, or invite testers without the owner's explicit confirmation immediately
before that external action.

## Current proven blockers

- The updated Apple agreement was personally reviewed; the pending banner is
  gone and membership resources are accessible under `mhm1981dx@gmail.com`.
- Services ID `com.otlobli.app.signin` exists with the correct primary App ID,
  but its Website URLs list is empty. The exact domain/return URL still must be
  saved.
- Existing SIWA key `Y8K8B23VK6` was already downloaded once, its download
  button is disabled, and no matching `.p8` was found locally. A usable new key
  must be created and downloaded once; do not revoke the old key unless Apple
  requires it and the owner explicitly confirms that destructive step.
- A Distribution certificate exists and `distribution.cer` is downloaded, but
  no matching private key/P12 exists locally. Create a new usable certificate
  from a retained private key if Apple allows another certificate; otherwise
  obtain separate approval before revoking anything.
- There is no Otlobli App Store provisioning profile and no Otlobli App Store
  Connect app record.
- GitHub has the App Store Connect API key/ID/issuer, but still lacks the three
  usable distribution certificate/password/profile secrets.
- Google iOS, the Supabase migrations/functions, and the hardened phone backend
  are now live-configured. Physical Google/Apple/phone acceptance is still
  required; backend readiness is not a device-test claim.

## 1. Apple Developer resources

After the owner gives explicit action-time creation/modification approval:

1. Keep the existing explicit App ID `com.otlobli.app`, Team ID `36D743K87T`,
   Push Notifications, and primary Sign in with Apple assignment unchanged.
2. Keep the existing Services ID `com.otlobli.app.signin` and association with
   primary App ID `com.otlobli.app`, then add and save:
   - domain: `dcicqdprtyhwmhegabay.supabase.co`
   - return URL:
     `https://dcicqdprtyhwmhegabay.supabase.co/functions/v1/apple-oauth-callback`
3. Register a new usable Sign in with Apple key attached to the same primary
   App ID. The
   downloaded `.p8` is one-time-only secret material; never commit or print it.
4. Create a usable Apple Distribution certificate from a newly retained CSR
   private key kept outside Git, then
   export the matching identity/private key as an encrypted P12.
5. Create an **App Store** provisioning profile for `com.otlobli.app` using that
   distribution certificate. This is distinct from the existing development
   profile and contains no device list.

Set these Supabase Edge secrets without printing their values:

```text
APPLE_SIGN_IN_KEY=<entire SIWA p8/private key>
APPLE_SIGN_IN_KEY_ID=<SIWA key id>
APPLE_TEAM_ID=36D743K87T
APPLE_CLIENT_IDS=com.otlobli.app,com.otlobli.app.signin
APPLE_REDIRECT_URIS_JSON={"com.otlobli.app.signin":"https://dcicqdprtyhwmhegabay.supabase.co/functions/v1/apple-oauth-callback"}
```

The existing `AuthKey_M8GFL27JUT.p8` is an App Store Connect API key. It is not a
Sign in with Apple key and must not be used for `APPLE_SIGN_IN_KEY`.

## 2. Google iOS OAuth — complete configuration, device test pending

Google Cloud project `otlobli-1ccf5` now has the iOS client for
`com.otlobli.app`, GitHub has `VITE_GOOGLE_IOS_CLIENT_ID`, and Supabase keeps the
Web, Android, and iOS audiences. The exact iOS client configuration check is
live `configured=true`. Only the new signed-build physical flow remains.

## 3. Database and Supabase Functions — deployed

Migrations were applied in order through:

```text
20260821090000_production_auth_push.sql
20260821183000_apple_authorization_client_id.sql
20260821193000_harden_identity_rpc_permissions.sql
```

The current branch versions are deployed:

```text
google-auth
apple-auth
apple-oauth-callback --no-verify-jwt
account-lifecycle
```

`supabase/config.toml` records `verify_jwt=false` for the Apple callback. Google
returns `configured=true`; Apple will remain fail-closed until the new SIWA key
and key ID are stored.

## 4. Production phone/WhatsApp authentication — deployed and live-ready

The hardened `server/` backend described in the root `WHATSAPP_SETUP.md` is live
on Oracle. Its explicit `dotenv` bootstrap is committed, the independent
secrets stay only on the host, and the existing session reconnected without a
new QR. Required release properties are:

- `VITE_WHATSAPP_AUTH_MODE=real`; `inbound` and production mock are rejected.
- HTTPS API URL and a persistent, owner-controlled Baileys credential volume.
- `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, and a random
  `OTP_HASH_SECRET` of at least 32 characters.
- Admin/session/QR operations are protected by a separate strong secret and no
  raw linking QR is public or sent to a third-party QR renderer.
- Protected operations use the new independent admin secret; the existing
  WhatsApp credentials were preserved and reconnected.

The exact `/health` gate for this internal test is:

```json
{
  "status": "ok",
  "whatsappConnected": true,
  "sessionStoreReady": true,
  "authContract": "customer-session-v1",
  "otpSecurityReady": true,
  "whatsappSenderReady": true
}
```

## 5. GitHub TestFlight secrets

Add only encrypted repository Actions secrets. The App Store Connect API trio,
Apple Team ID, Google iOS, and public Android Apple values are already set.
Never reuse development secret names for distribution material. Remaining
distribution inputs are:

```text
IOS_DISTRIBUTION_CERTIFICATE_BASE64
IOS_DISTRIBUTION_CERTIFICATE_PASSWORD
IOS_APP_STORE_PROVISIONING_PROFILE_BASE64
```

Already set for matching Android builds:

```text
VITE_APPLE_ANDROID_CLIENT_ID=com.otlobli.app.signin
VITE_APPLE_ANDROID_REDIRECT_URL=https://dcicqdprtyhwmhegabay.supabase.co/functions/v1/apple-oauth-callback
```

The existing App Store Connect key values are Key ID `M8GFL27JUT` and Issuer ID
`631dc2f6-b1d1-423e-8617-d3d37fc4514a`; handle its private `.p8` only as a
secret. Do not commit it.

## 6. App Store Connect and internal TestFlight

After the agreement is accepted and with explicit upload approval:

1. Create the `Otlobli` App Store Connect record using Bundle ID
   `com.otlobli.app` and a unique owner-approved SKU.
2. Trigger the registered iOS workflow on this branch with
   `signing_mode=testflight`.
3. The workflow must preflight all three login providers, archive Release,
   verify distribution signature/profile/entitlements, `86.213/1075`, arm64,
   iOS 15+, iPhone/iPad families, validate with App Store Connect, upload, then
   preserve the verified IPA and dSYMs as workflow artifacts.
4. Wait for Apple processing and answer export-compliance truthfully. The app
   declares no non-exempt encryption because it uses platform/standard HTTPS
   cryptography only; revisit this if custom cryptography is added.
5. Add the owner account to an **internal** TestFlight group. Internal testing
   does not require Beta App Review. Send the invitation only after another
   explicit confirmation, then install from Apple's TestFlight app/email—not
   Sideloadly or 3uTools.

## 7. Physical acceptance before any App Store release

On both iOS and Android, verify phone/WhatsApp, Google, and Apple login; new-user
onboarding; linking all methods to one account; logout/relogin; account deletion;
push registration/delivery; and the protected store/order flows. For the iPhone,
also perform the standing five background/resume cycles and a separate
force-quit/cold-launch test. This internal TestFlight work does not by itself
declare the app App Store production-ready.
