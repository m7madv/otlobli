# Authentication setup

## Implemented

The production app supports provider-only authentication: native Apple identity-token exchange with a SHA-256 nonce, native Google Sign-In v7 ID-token exchange on Android and iOS, local sign-out, and account deletion. Email/password signup, login, reset, UI, repository methods, and the hosted Supabase email provider are disabled. It never merges identities by email text.

## Apple owner/dashboard work

1. Register the final Runner bundle ID and enable **Sign in with Apple**.
2. Register a Service ID for Android/web fallback, domain, and return URL; create and rotate the Apple key outside Git.
3. Put only `APPLE_SERVICE_ID` and `APPLE_REDIRECT_URI` in Dart defines. Keep Team ID, Key ID, `.p8`, and generated client secret in the provider/Supabase dashboard.
4. Configure the native bundle in Supabase Apple provider. Test first sign-in, cancellation, hidden-email relay, logout/relogin, and revoked authorization.

Apple registration status on 2026-08-26:

- Native App ID `app.voicebrief.mobile` is registered under team `36D743K87T` with Sign in with Apple and App Group `group.app.voicebrief.mobile`.
- Share Extension App ID `app.voicebrief.mobile.share` is registered with the same App Group.
- Separate App Store profiles for the Runner and Share Extension were created, installed in GitHub Actions, embedded, and entitlement-verified through TestFlight build `0.1.0 (7)`.
- Supabase Apple is enabled for native client ID `app.voicebrief.mobile`. Key `N4FK6753YL` is bound to the VoiceBrief primary App ID; its `.p8` is stored outside Git under the owner's private local credential directory. The generated client secret expires on `2027-02-21T22:07:34Z` and must be rotated before then.
- The previous hosted values incorrectly referenced Damanak and the provider was disabled. Auth logs confirmed `provider_disabled` before correction. After correction, signed TestFlight build 7 completed an Apple `Login / INFO` event on the physical iPhone at `2026-08-26 01:08:42` Asia/Riyadh.

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

Supabase Google Auth is enabled and the web client secret is stored only in hosted Auth configuration. Google OAuth is External/In production, so any Google account can authorize the app. The native iOS token path uses the web server client as its audience. Supabase `Skip nonce checks` is enabled because Google Sign-In on iOS can issue an ID token with a nonce that the client plugin cannot return for the `/token` request. Before this correction, live Auth logs recorded `Passed nonce and nonce in id_token should either both exist or not.` after Google had already completed consent. After correction, signed TestFlight build 7 completed a Google `Login / INFO` event on the physical iPhone at `2026-08-26 01:06:16` Asia/Riyadh. Native picker/cancel also passed on API 35 and `SM_N950F`. Add the Play App Signing SHA after Play creates it.

Builds `0.1.0 (6)` and later use native Google Sign-In on iOS and send the ID/access token pair directly to Supabase. The App Store-signed bundle keeps `app.voicebrief.mobile`, its registered reversed Google scheme, and the expected server client ID. Provider tokens are neither persisted nor logged.

## Supabase redirects

The provider-only production flow does not require email/reset redirects. Keep the app callback only for compatibility with any deliberately reintroduced web OAuth fallback:

```text
voicebrief://auth/callback
```

Configure production/development schemes separately if identities diverge. Confirm email templates use the allowlisted URL and that universal/app links, if later added, validate host/path—not only scheme.

## Verification

- Confirm email auth remains disabled in hosted Supabase settings.
- Complete Apple and Google on physical iOS/Android devices, then verify successful `/token` entries and restored sessions after restart.
- Delete the account and verify Auth user, database rows, temporary Storage objects, and local Drift rows are gone.
