# Authentication setup

## Implemented

The repository supports Supabase email/password, verification-aware user state, password reset, local sign-out, account deletion, native Apple identity-token exchange with SHA-256 nonce, native Google Sign-In v7 ID-token exchange on Android, Supabase Google OAuth with PKCE on iOS, and `voicebrief` deep links. It never merges identities by email text.

## Apple owner/dashboard work

1. Register the final Runner bundle ID and enable **Sign in with Apple**.
2. Register a Service ID for Android/web fallback, domain, and return URL; create and rotate the Apple key outside Git.
3. Put only `APPLE_SERVICE_ID` and `APPLE_REDIRECT_URI` in Dart defines. Keep Team ID, Key ID, `.p8`, and generated client secret in the provider/Supabase dashboard.
4. Configure the native bundle in Supabase Apple provider. Test first sign-in, cancellation, hidden-email relay, logout/relogin, and revoked authorization.

Apple registration status on 2026-08-25:

- Native App ID `app.voicebrief.mobile` is registered under team `36D743K87T` with Sign in with Apple and App Group `group.app.voicebrief.mobile`.
- Share Extension App ID `app.voicebrief.mobile.share` is registered with the same App Group.
- Separate App Store profiles for the Runner and Share Extension were created, installed in GitHub Actions, embedded, and entitlement-verified in TestFlight build `0.1.0 (5)`.
- This completes Apple-side native registration and signing, not the Supabase provider. Public project settings still report Apple disabled, so the button must not be described as working until the Apple client secret/provider is configured and a physical signed-device exchange passes.

## Google owner/dashboard work

1. Create iOS, Android, and web OAuth clients. Android requires the final application ID plus debug/release/play-app-signing SHA-1/SHA-256 fingerprints.
2. Configure the final iOS bundle ID and URL scheme/reversed client ID required by Google.
3. Enable Google in Supabase using the web client credentials. Put public iOS/web client IDs in Dart defines; no client secret belongs in mobile.
4. Test provider cancellation, account picker, reinstall, token expiry, and redirect return.

Use the certificate fingerprints recorded in `ANDROID_RELEASE_SIGNING.md`. The current upload certificate is SHA-1 `43:89:D6:0A:58:EA:21:08:5E:65:37:27:47:6D:7A:E9:42:42:ED:E7`; the local debug certificate is SHA-1 `97:1C:7E:FE:3D:10:09:BD:80:0B:8A:EA:2C:A5:9F:64:7C:E1:68:A3`. Add the separate Google Play App Signing fingerprint after Play creates it.

On 2026-08-24, the owner switched Google Cloud to `mhm1981x@gmail.com`, explicitly authorized project creation, and then authorized completion of the Google API Services: User Data Policy step. Project `VoiceBrief Production` has ID `voicebrief-prod-mhm1981x` and number `872187920899`.

Configured public clients:

- Web/server: `872187920899-epoadbtkgum88ve5noopd47jpce4vaqv.apps.googleusercontent.com`, callback `https://jyehqpdbayslhzebdycj.supabase.co/auth/v1/callback`.
- Android upload/release: `872187920899-1gsgfgq8g37849u2qbfafip3qe7n279g.apps.googleusercontent.com` for `app.voicebrief.mobile` and SHA-1 `43:89:D6:0A:58:EA:21:08:5E:65:37:27:47:6D:7A:E9:42:42:ED:E7`.
- Android debug: `872187920899-jiav7m2knch328k8m3lmr166v6muf3vp.apps.googleusercontent.com` for the same package and SHA-1 `97:1C:7E:FE:3D:10:09:BD:80:0B:8A:EA:2C:A5:9F:64:7C:E1:68:A3`.
- iOS: `872187920899-72jkr1l4pb84u6umrkhdkidun1iieapd.apps.googleusercontent.com` for `app.voicebrief.mobile`; the reversed scheme is committed in `ios/Runner/Info.plist`.

Supabase Google Auth is enabled and the web client secret is stored only in hosted Auth configuration. A live `/auth/v1/authorize?provider=google` probe redirects to `accounts.google.com` with the correct web client and Supabase callback. Branding includes the public home, privacy, and terms URLs plus authorized Supabase/Vercel domains. Publishing status remains External/Testing and `mhm1981x@gmail.com` is the sole test user. Native Google picker/cancel passed on API 35 and `SM_N950F`; the phone only exposes `mhm1981d@gmail.com`, so no wrong account was selected and a real X-account token exchange remains pending. Add the Play App Signing SHA after Play creates it.

Build 4 uses the Supabase-hosted Google OAuth/PKCE flow on iOS and returns through `voicebrief://auth/callback`. This intentionally avoids relying on the native iOS OAuth client association after an unsigned IPA is re-signed by a sideloading service that may rewrite the app identifier. Android keeps the native token exchange. The controller observes Supabase auth events so both warm and callback sign-in complete without storing or logging provider tokens. The live provider redirect still reports the expected web client and callback. A physical signed-iPhone callback remains required.

## Supabase redirects

Allow at least:

```text
voicebrief://auth/callback
voicebrief://auth/reset
```

Configure production/development schemes separately if identities diverge. Confirm email templates use the allowlisted URL and that universal/app links, if later added, validate host/path—not only scheme.

## Verification

- Create an email user, verify it, sign in, request reset, follow the deep link, and restore the session after restart.
- Complete Apple and Google on physical iOS/Android devices.
- Delete the account and verify Auth user, database rows, temporary Storage objects, and local Drift rows are gone.
