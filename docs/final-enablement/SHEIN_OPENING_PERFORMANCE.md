# SHEIN opening performance — v86.215

The physical `86.214/1076` result is rejected: the internal tester installed it
on iPhone 16 Pro Max / iOS 27 and reproduced the list→product spinner. The
failure was not the initial visual-ready predicate; the 500ms product callback
never consumed a chunk failure recorded before SPA changed the URL.

v86.215 adds one event-driven stored-error probe inside that existing callback.
On a hit, the bounded recovery now warms SHEIN Home before replaying the queued
PDP inside the same verified WebView. It adds no recurring work and does not
change transaction readiness, region ownership, or lifecycle.

The release records bounded client-side timestamps for user tap, browser-open
request, native browser create/show, policy installation, required-state
application, navigation start/commit/finish, human verification, region and
policy verification, capture ready, and store visible/interactive.

The host starts the deferred store bundle load and VPN eligibility check in
parallel after the user taps SHEIN. The visual/transaction milestones remain:

- **Visual ready:** Arabic and USD match, policy and capture are ready, content
  is interactive, no login/human challenge is active, and country/region are not
  mismatched. An unknown signed country/region may continue repairing behind the
  lightweight indicator.
- **Transaction ready:** the existing full coordinator also requires signed
  country and region to match. Add-to-cart remains fail-closed until this state.

The interactive check reuses the single runtime coordinator and stops for the
current route after success. During active repair, low-end devices get a 2.8s
grace and at most one check per 900ms; normal devices use 1.8s/450ms. No fake
progress, reload, second browser, observer, new recurring timer, capture
weakening, or transaction-state weakening was added.

Acceptance target on the critical iPhone, normal connection, and already-valid
session: median at or below 8 seconds, p95 at or below 12 seconds, and slowest
at or below 15 seconds across 30 openings, while all readiness fields pass.
This is a measurement target, not a shipping claim.

| Metric | v86.215 physical result |
| --- | --- |
| median | unavailable — 0 physical samples |
| p95 | unavailable — 0 physical samples |
| slowest | unavailable — 0 physical samples |

The previously reported 10–11 seconds is an observation from an earlier build,
not a measured v86.215 baseline. Physical timing data must be exported from the
bounded local records during acceptance. Also record clean-install time to
visual ready separately from time to full signed transaction readiness.
