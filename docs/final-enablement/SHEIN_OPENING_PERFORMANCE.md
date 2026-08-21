# SHEIN opening performance — v86.214

The release records bounded client-side timestamps for user tap, browser-open
request, native browser create/show, policy installation, required-state
application, navigation start/commit/finish, human verification, region and
policy verification, capture ready, and store visible/interactive.

The host starts the deferred store bundle load and VPN eligibility check in
parallel after the user taps SHEIN. v86.214 separates two truthful milestones:

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

| Metric | v86.214 physical result |
| --- | --- |
| median | unavailable — 0 physical samples |
| p95 | unavailable — 0 physical samples |
| slowest | unavailable — 0 physical samples |

The previously reported 10–11 seconds is an observation from an earlier build,
not a measured v86.214 baseline. Physical timing data must be exported from the
bounded local records during acceptance. Also record clean-install time to
visual ready separately from time to full signed transaction readiness.
