# Push notifications implementation

## Transport decision

Otlobli uses one provider per platform:

- Android: existing Firebase Cloud Messaging (FCM HTTP v1).
- iOS: direct APNs token-based delivery through the existing `send-push` Edge
  Function. Firebase Messaging was not added to iOS, avoiding two competing
  iOS transports.

## iOS client pipeline

`@capacitor/push-notifications` now covers permission status, one-time prompt,
native registration, token rotation, foreground presentation, notification tap
events, and delivered-notification/badge clearing. `AppDelegate.swift` forwards
APNs success/failure notifications to Capacitor. The Xcode target includes Push
Notifications and `aps-environment`; Debug registers a sandbox token and
Release registers a production token. Native `getPushContext` reports that
environment and the iOS version to the token registry, preventing a sandbox
token from being sent to production APNs.

Denied permission is recorded locally and is not repeatedly prompted. The app
provides a native Settings shortcut. Logout detaches and invalidates the
installation token.

## Backend registry and sending

Migration `20260821090000_production_auth_push.sql` extends `device_tokens`
with installation, provider, environment, app/OS version, locale, timezone,
permission state, last-seen time, and invalidation time. Registration is an
authenticated custom-session RPC, rotates the active installation token, and
does not expose registry rows through RLS.

`send-push` remains protected by `PUSH_TRIGGER_SECRET` or `ADMIN_PIN`. It can
target customer, phone, or installation, supports a bounded broadcast and dry
run, sends Android tokens only through FCM and iOS tokens only through APNs,
and invalidates provider-rejected tokens.

Payloads are version 1 and accept only these routes:
`notifications`, `orders`, `orders/details`, `wallet`, and
`payment-methods`. External URLs and arbitrary deep links are rejected by both
backend and client.

## Files

- `src/services/pushNotifications.ts`
- `src/services/pushPayload.ts`
- `ios/App/App/AppDelegate.swift`
- `ios/App/App/OtlobliBridgeViewController.swift`
- `ios/App/App/App.entitlements`
- `supabase/functions/send-push/index.ts`
- `supabase/migrations/20260821090000_production_auth_push.sql`

Portal secrets and physical delivery acceptance are listed in
`REQUIRED_PORTAL_ACTIONS.md` and `PUSH_NOTIFICATIONS_TEST_REPORT.md`.
