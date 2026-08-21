# Final release acceptance — v86.208/1070

## Completed

- Isolated release branch/worktree from protected v86.207 HEAD.
- Product-capture core byte-identical; capture contract and Temu preserved.
- Versioned, bounded SHEIN policy and independent region/readiness coordinator.
- Live admin setting verified as QA/USD/ar.
- Opening timeline instrumentation and avoidable host waterfall reduction.
- Direct APNs code/provider hardening, Google iOS/Apple/deletion code paths,
  privacy manifest, fail-closed signing automation, and release scans.
- Supabase production migration and four required Edge Functions deployed;
  safe smoke responses are 401 for unauthorized/invalid sessions and 503 for
  Apple's intentionally missing credential state.
- Local TypeScript, tests, guards, production build, Capacitor sync, Android
  compile/unit tests, lint without errors, XML parse, and generated scans pass.
- GitHub/Xcode unsigned run `32476867979` passed; artifact `9444682658` has
  SHA-256 `430A76756C4433719AAADB0EFF03D2E3442D491D24058E1ECDB1201836DB76EF`.
  It is unsigned/unprovisioned compile evidence, not an installable release.

## Submission drafts

Arabic release notes: "حسّنا فتح المتاجر وسياسة التصفح والمنطقة، وطوّرنا
الإشعارات وتسجيل الدخول وحذف الحساب، مع الحفاظ على التقاط المنتجات والتنقل."

App Review/Play notes: Otlobli displays public SHEIN/Temu browsing for product
selection into Otlobli's cart. Third-party login/account/checkout/region/
currency controls are unavailable by policy. SHEIN human verification remains
interactive and is never bypassed. Notifications are optional and used for
orders, payments, wallet and service updates. Account deletion is available at
Profile → حذف الحساب نهائياً and requires two confirmations. Supply a demo
account only after its actual sign-in method passes the release environment.

Checklist still required: public privacy/support URLs, current data
declarations, screenshots, age rating, permission explanations, review/demo
instructions, signed-artifact validation, and physical acceptance.

## Decision

Release ready: **no**. Exact remaining work is limited to the credentials,
portal configuration, signed builds, and physical tests enumerated in
`MANUAL_PORTAL_ACTIONS.md`. No App Store, TestFlight, or Google Play submission
was performed.
