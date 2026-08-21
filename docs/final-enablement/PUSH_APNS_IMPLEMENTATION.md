# Direct APNs implementation — v86.208

The iOS client uses Capacitor push registration and direct APNs provider
delivery. Debug resolves `aps-environment=development`; Release resolves
`aps-environment=production`. The target carries Push Notifications and Sign in
with Apple entitlements.

The client handles permission status without repeated prompting, registration
success/error callbacks, token rotation, installation identity, authenticated
backend upsert, foreground presentation, background/terminated tap events,
safe versioned route parsing, cold-launch route buffering, badge clear, Settings
shortcut, logout ownership detachment, and later-session reattachment.

The deployed `send-push` function uses ES256 provider JWT, exact topic
`com.otlobli.app`, sandbox/production hosts, alert push type, priority 10,
one-hour expiration, sanitized APNs IDs/reasons, permanent-token cleanup, and at
most three attempts for network/429/500/503 failures. Its public invocation is
protected by `PUSH_TRIGGER_SECRET`; raw provider responses and private keys are
not logged. `scripts/send-test-push.mjs` is dry-run by default and requires an
exact installation or customer plus explicit `--send`.

The function is deployed and unauthenticated smoke testing correctly returned
401. Delivery cannot be proven until APNs key secrets, a production-enabled
profile, and a physical device token exist.
