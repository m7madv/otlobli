# Exact remaining TestFlight enablement actions — v86.212 / 1074

This checklist is for one internal TestFlight build. It is not authorization to
submit the app for App Store review. Do not create Apple resources, upload a
build, or invite testers without the owner's explicit confirmation immediately
before that external action.

## Current proven blockers

- The updated Apple Developer Program agreement is still pending. The Account
  Holder must read and accept it personally.
- App Store Connect has no `Otlobli` app record for `com.otlobli.app` yet.
- GitHub has development signing material only. The TestFlight workflow is
  missing every distribution/profile/upload secret listed below.
- Google Cloud is open under an account that cannot access project
  `otlobli-1ccf5`; the owner must switch to the Google account that owns it.
- The live phone backend at `https://84-8-100-128.sslip.io/health` is still the
  old deployment and reports `whatsappConnected=false`. It does not expose the
  required v86.212 readiness contract, so CI correctly refuses to upload.
- The v86.212 migrations, Edge Functions, and hardened WhatsApp server are local
  only until explicitly deployed. Do not describe authentication as live before
  those deployments and physical tests succeed.

## 1. Apple Developer resources

After the Account Holder accepts the agreement and the owner gives explicit
creation approval:

1. Keep the existing explicit App ID `com.otlobli.app`, Team ID `36D743K87T`,
   Push Notifications, and primary Sign in with Apple assignment unchanged.
2. Register Services ID `com.otlobli.app.signin` with description
   `Otlobli Android Sign in with Apple`, associate it with primary App ID
   `com.otlobli.app`, then configure:
   - domain: `dcicqdprtyhwmhegabay.supabase.co`
   - return URL:
     `https://dcicqdprtyhwmhegabay.supabase.co/functions/v1/apple-oauth-callback`
3. Register a Sign in with Apple key attached to the same primary App ID. The
   downloaded `.p8` is one-time-only secret material; never commit or print it.
4. Create an Apple Distribution certificate from the CSR kept outside Git, then
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

## 2. Google iOS OAuth

In Google Cloud project `otlobli-1ccf5`, create an iOS OAuth client whose Bundle
ID is exactly `com.otlobli.app`. Set the returned client ID as GitHub secret
`VITE_GOOGLE_IOS_CLIENT_ID`. Keep the existing Web client ID in the backend
allowlist because iOS configures it as `serverClientID`, so the actual Google ID
token audience can be the Web client. Supabase secret `GOOGLE_CLIENT_IDS` must
contain the existing Web and Android audiences plus the new iOS client ID.

## 3. Database and Supabase Functions

Apply timestamped migrations in order through:

```text
20260821090000_production_auth_push.sql
20260821183000_apple_authorization_client_id.sql
20260821193000_harden_identity_rpc_permissions.sql
```

Then deploy the current branch versions of:

```text
google-auth
apple-auth
apple-oauth-callback --no-verify-jwt
account-lifecycle
```

`supabase/config.toml` records `verify_jwt=false` for the Apple callback. The
provider configuration checks must return `configured=true` and schema contract
`auth-v86.212-1` before the TestFlight workflow may archive or upload.

## 4. Production phone/WhatsApp authentication

Deploy the hardened `server/` backend described in the root
`WHATSAPP_SETUP.md`. Required release properties are:

- `VITE_WHATSAPP_AUTH_MODE=real`; `inbound` and production mock are rejected.
- HTTPS API URL and a persistent, owner-controlled Baileys credential volume.
- `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, and a random
  `OTP_HASH_SECRET` of at least 32 characters.
- Admin/session/QR operations are protected by a separate strong secret and no
  raw linking QR is public or sent to a third-party QR renderer.
- The previous exposed admin PIN is rotated and the WhatsApp sender is paired
  again after deployment.

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

Add only encrypted repository Actions secrets. Never reuse development secret
names for distribution material:

```text
APPLE_TEAM_ID
IOS_DISTRIBUTION_CERTIFICATE_BASE64
IOS_DISTRIBUTION_CERTIFICATE_PASSWORD
IOS_APP_STORE_PROVISIONING_PROFILE_BASE64
APP_STORE_CONNECT_API_KEY_BASE64
APP_STORE_CONNECT_API_KEY_ID
APP_STORE_CONNECT_ISSUER_ID
VITE_GOOGLE_IOS_CLIENT_ID
VITE_SUPABASE_URL
VITE_SUPABASE_ANON_KEY
VITE_WHATSAPP_API_URL
VITE_WHATSAPP_AUTH_MODE=real
```

For matching Android builds also set:

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
   verify distribution signature/profile/entitlements, `86.212/1074`, arm64,
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
