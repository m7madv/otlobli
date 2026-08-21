# SHEIN opening performance — v86.208

The release records bounded client-side timestamps for user tap, browser-open
request, native browser create/show, policy installation, required-state
application, navigation start/commit/finish, human verification, region and
policy verification, capture ready, and store visible/interactive.

The host now starts the deferred store bundle load and VPN eligibility check in
parallel after the user taps SHEIN. Readiness is event driven and no longer
accepts `pageInteractive` alone. No fake progress, reload, second browser,
capture change, or weakened state check was added.

Acceptance target on the critical iPhone, normal connection, and already-valid
session: median at or below 8 seconds, p95 at or below 12 seconds, and slowest
at or below 15 seconds across 30 openings, while all readiness fields pass.
This is a measurement target, not a shipping claim.

| Metric | v86.208 physical result |
| --- | --- |
| median | unavailable — 0 physical samples |
| p95 | unavailable — 0 physical samples |
| slowest | unavailable — 0 physical samples |

The previously reported 10–11 seconds is an observation from an earlier build,
not a measured v86.208 baseline. Physical timing data must be exported from the
bounded local records during acceptance.

