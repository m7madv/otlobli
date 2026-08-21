# Final release preflight

Verified on 2026-08-21 before production behavior changes.

## Tested device/source mapping

- Physical device: iPhone 16 Pro Max (`iPhone17,2`).
- Last installed build that was mapped from the device before this release task:
  `86.205/1067`.
- Installed-build behavior commit:
  `23282957a14ddc363f430379105780098ce057e9`.
- Preserved branch HEAD for that build:
  `846de3798e5decc4e46fb9e7ca40e90c74e201f7` on
  `codex/ios-v86-205-shein-clean-room-selector-fix`.
- Physical result after updating the same phone to the newer iOS 27 beta:
  the owner reports roughly 30 repeated SHEIN entry, exit, product, cart,
  navigation, and verification flows without the old inert-page freeze.
- Evidence boundary: this post-update pass is an owner-reported physical test;
  no synchronized CDP/unified-log bundle was captured for it.

`86.205` is not a production baseline. It contains a clean-room mode selector
and diagnostic browser paths. Its legacy store path derives from the same
production browser line, but the release must not retain those diagnostics.

## Selected production baseline

- Branch: `codex/ios-v86-201-double-home-store-switch`.
- Commit: `0b462a93030b5c7114012d5848ce61eac49b8b17`.
- Version/build at baseline: `86.201/1063`.
- Reason: this is the last clean application line before v86.202 root-cause
  probes, v86.203 cache experiments, and v86.204-v86.206 clean-room/forensic
  modes. It contains the accepted root-Back behavior, single store exit
  controls, double-Home store chooser, current Otlobli UI, and the same product
  capture internals used by v86.205.
- `86.207/1069` was searched across local and remote code refs and was unused
  at branch creation time. It is reserved for this one release candidate.

## Isolated release line

- Branch: `codex/otlobli-final-production-release`.
- Worktree: `C:\Users\MOHAMMAD\Projects\otlobli-final-production-release`.
- Initial HEAD: `0b462a93030b5c7114012d5848ce61eac49b8b17`.
- Worktree was clean at creation.

## Product-capture freeze

The protected capture files and hashes are recorded in
`PRODUCT_CAPTURE_BASELINE.md`. The core capture implementation is identical
between the selected v86.201 baseline and the mapped v86.205 build.

## Diagnostic code excluded from the release application

- Store-script mode flags and the customer-visible isolation panel.
- `SHEIN_IOS_FREEZE_DIAGNOSTICS` and recovery-bypass options.
- Tap/freeze/region diagnostic injected scripts.
- Native LOG/COPY diagnostic buttons and rings in the patched iOS browser.
- Clean-room RAW/cache-guard/capture/blocking/control modes.
- v86.202 root-cause heartbeat/CDP bridges.
- v86.203 raw-prefetch cache rule experiment.
- v86.206 final-forensics controller and mode identities.
- GitHub workflow inputs that can turn diagnostics on in a release artifact.

Historical branches, reports, scripts, and evidence remain preserved in Git.

## Existing authentication architecture

- Backend: Supabase Edge Functions plus project-specific customer sessions.
- Android Google client: `@capgo/capacitor-social-login` in online mode.
- Backend verification: `google-auth` verifies issuer, audience, expiry, and
  the signed Google subject before issuing/linking an Otlobli session.
- Identity model: `customer_identities`, linked to the same `customers` row
  used by phone login. No second iOS account system is needed.
- iOS gap at preflight: `VITE_GOOGLE_IOS_CLIENT_ID` is absent from GitHub
  Secrets, so the Google action is intentionally hidden; the callback scheme
  is injected only when that missing value exists.

## Existing notification architecture

- Android transport: FCM through the Capacitor Push Notifications plugin.
- iOS transport selected for production: direct APNs, matching the existing
  `send-push` Edge Function. A second Firebase transport will not be added.
- Token registry: Supabase `device_tokens` through `upsert_device_token`.
- Preflight break point on iOS: permission UI exists, but the Xcode target has
  no push entitlement and `AppDelegate` does not forward APNs registration
  callbacks to Capacitor. The APNs key/team/bundle secrets are also absent.
- GitHub has no Apple signing, APNs, or iOS Google OAuth secret names at
  preflight. Those portal actions are documented separately and no secret will
  be committed.
