# Final release report — v86.207/1069

## Release identity

- Baseline: `codex/ios-v86-201-double-home-store-switch` at
  `0b462a93030b5c7114012d5848ce61eac49b8b17`.
- Release branch: `codex/otlobli-final-production-release`.
- Worktree: `C:\Users\MOHAMMAD\Projects\otlobli-final-production-release`.
- Candidate version/build: `86.207/1069`.
- Product capture changed: **no**. Protected capture hashes pass.

## Implemented

- Removed/compiled out release diagnostic modes, panels, probes, inspector
  access, verbose native diagnostic controls, and environment toggles.
- Preserved working SHEIN blocking, region/session, navigation, product
  capture, Temu, root Back, single exit controls, and double-Home selection.
- Added iOS APNs entitlement/registration forwarding, token registry v2,
  rotation, direct APNs send, safe payload routes, badge/Settings handling, and
  logout detachment without changing Android's FCM transport.
- Added iOS Google configuration around the existing account model.
- Added Sign in with Apple with server verification/code exchange/revocation.
- Added in-app account deletion, anonymization, session/push invalidation, and
  declared transaction-record retention.
- Added manual signed iOS/Android release-candidate workflow and production
  asset/security guards.

## Local gates

Passed: release-service tests, protected production hashes, diagnostic asset
scan across dist/iOS/Android, release hardening, SHEIN guard, Temu guard, store
surface guard, TypeScript, Vite build, performance budget, Capacitor iOS sync,
Capacitor Android sync, ESLint with 0 errors (17 pre-existing warnings),
`git diff --check`, Android unit tests, and Android Debug assembly.

Xcode cannot run on Windows. Signed IPA/AAB/APK builds are blocked by missing
portal/signing secrets. The unsigned iOS GitHub build will be recorded after
the branch is pushed.

## Acceptance boundary

The owner attributes the old freeze to the previous iOS 27 beta/WebKit build
and reports repeated success after updating the same phone. This release does
not claim a new WebView freeze fix. Apple announced only that iOS 27 is coming
in fall 2026; no exact public release day is announced as of 2026-08-21.

Release ready: **no** until physical iPhone APNs, real Google and Apple login,
account deletion, Android push regression, the required device matrix, live
backend deployment, signed artifact validation, and store portal actions pass.
