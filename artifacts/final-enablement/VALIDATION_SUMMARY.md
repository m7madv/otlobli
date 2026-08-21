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
