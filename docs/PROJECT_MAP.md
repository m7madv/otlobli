# Otlobli project map

Use this map before editing unfamiliar parts of the repository. The current
release state is always in `CURRENT_STATE.md`; implementation handoff is in
`AI-HANDOFF.md`; this file names ownership, not release history.

## Customer application

- `src/App.tsx` — customer application orchestration: screens, store WebView
  lifecycle, cart-to-product preparation, and native browser events.
- `src/services/sheinBrowserScript.ts` — the injected SHEIN/Temu integration.
  Treat this as a performance-sensitive boundary: no polling, broad DOM scans,
  storage purges, or unbounded retry loops.
- `src/services/sheinFreezeDiagnostics.ts` — temporary iPhone diagnostic probe.
- `src/domain/` — customer business types and pricing rules.
- `src/infrastructure/` — device storage and app persistence.
- `src/components/` — reusable customer UI components.

## Native shells

- `android/` — Capacitor Android shell. `android/app/build.gradle` is the
  Android release version source.
- `ios/App/` — Capacitor iOS shell. The Xcode project is the iPhone release
  version source.
- `patches/@capgo+capacitor-inappbrowser+8.6.25.patch` — required native
  WebView patch. It includes the guarded iPhone recompose fix; never weaken it
  without the real-device acceptance stated in `docs/SHEIN_IOS_FREEZE_GUARD.md`.

## Services and deployments

- `admin/` — Otlobli administration application.
- `server/` — active WhatsApp/OTP server. This is the only active WhatsApp
  server directory.
- `server-whatsapp/` — historical copy; do not modify for production behavior.
- `supabase/` — database migrations, functions, and schema reference. Verify
  live schema with Supabase before assuming `schema.sql` is current.
- `worker/` — edge/relay code, separate from the customer app.

## Engineering operations

- `scripts/verify-shein-freeze-guard.mjs` — release invariant checks for the
  SHEIN/iPhone path; `npm run build` invokes it.
- `docs/SHEIN_IOS_FREEZE_GUARD.md` — mandatory constraints before changing
  WebView, SHEIN, lifecycle, region, or injected scripts.
- `docs/LOW_END_DEVICE_PERFORMANCE_GUARD.md` — low-end performance release
  limits and acceptance requirements.
- `docs/KNOWN_ISSUES_AND_DECISIONS.md` — permanent incident log: confirmed
  causes, rejected fixes, current safeguards, and maintenance rules. Do not
  delete it; update it when a new recurring issue is investigated.
- `CURRENT_STATE.md`, `AI-HANDOFF.md`, `SESSION_SUMMARY.md` — keep only the
  newest factual state at their top; older detail belongs in Git history.

## Local artifacts

Temporary device screenshots matching `tmp-*.png` are intentionally
ignored. They are local evidence, not source assets; never delete them during
cleanup unless their owner explicitly asks.
