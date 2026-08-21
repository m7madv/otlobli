# v86.208 validation summary

Validated on 2026-08-21 before the single internal candidate build.

- `npm run test:release-services`: pass.
- `npm run verify:no-secrets`: pass, 414 source files scanned.
- Production, release-hardening, SHEIN freeze, Temu size/cart, and store-surface
  guards: pass.
- ESLint: 0 errors, 18 warnings; the protected source already contained 19
  warnings including one error from an old extracted artifact.
- `npx tsc -b` and `npm run build`: pass.
- Performance budgets: startup JS 651,657/720,000 bytes; total JS gzip
  266,604/370,000; CSS 69,965/70,000; store scripts 241,937/470,000.
- `npx cap sync ios` and `npx cap sync android`: pass.
- Android `compileDebugJavaWithJavac testDebugUnitTest`: 141 tasks, pass.
- Diagnostic scan of `dist`, iOS public assets, and Android public assets: pass.
- `git diff --check` and PrivacyInfo.xcprivacy XML parse: pass.
- Six protected capture hashes match the recorded v86.207 baseline.
- Live Supabase setting: QA/USD/ar. Migration applied. Active functions:
  `google-auth` v6, `send-push` v6, `apple-auth` v1, and
  `account-lifecycle` v1.

No physical-device, signed iOS, signed Android, APNs delivery, OAuth, or
destructive account-deletion result is represented by this file.

## Internal iOS compile candidate

GitHub Actions run `32476867979` completed successfully for commit
`b679bcad28a0d17c9d33a825af4758dca0c90f1f`; artifact ID `9444682658`.
The extracted unsigned IPA is 6,557,365 bytes with SHA-256
`430A76756C4433719AAADB0EFF03D2E3442D491D24058E1ECDB1201836DB76EF`.
Inspection confirms `com.otlobli.app`, `86.208/1070`, iPhone/iPad `[1,2]`,
iOS 15.0 minimum, Privacy Manifest present, no source maps/forbidden markers,
and deliberately no code signature or embedded provisioning profile. The run
also confirmed the missing Google iOS client, so its action remains hidden.
