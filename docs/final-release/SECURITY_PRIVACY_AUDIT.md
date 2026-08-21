# Security and privacy audit

## Passed source/artifact checks

- Release Web Inspector is disabled; only `#if DEBUG` sets inspectable true.
- Diagnostic modes, panels, heartbeat/tap markers, cache experiments, and
  customer-visible forensic controls are absent from generated web/iOS/Android
  assets.
- Protected product-capture hashes are unchanged.
- Vite source maps are disabled and the generated assets contain no maps.
- Android has `usesCleartextTraffic=false`, `allowBackup=false`, and a
  non-exported FileProvider. The launcher/deep-link activity is the expected
  exported component.
- iOS has no arbitrary ATS exception in `Info.plist`.
- Notification payload routing uses a strict internal allowlist and never opens
  an arbitrary external URL.
- APNs keys, Apple private keys, service-account JSON, signing certificates,
  provisioning profiles, keystores, and passwords are not committed.
- Apple provider logs that could expose tokens/profile data were removed, and
  provider tokens are no longer persisted in plaintext UserDefaults.
- Direct APNs, Apple token exchange/revocation, and provider send credentials
  exist only in Edge Function environment secrets.
- Account deletion is available inside the app and revokes sessions/push
  ownership. Orders/payments/wallet ledger are retained only as declared
  transaction records while the customer profile is anonymized.

The in-app bounded issue-report card remains a customer support feature, not a
diagnostic mode. It states its data boundary and does not send store cookies,
tokens, passwords, addresses, or page contents. Production log changes use
bounded error codes instead of full SHEIN URLs.

## Open release/compliance items

- A public privacy-policy URL and support URL were not discoverable and must be
  supplied and verified in App Store Connect/Play Console.
- Store privacy declarations, SDK privacy manifests, age rating, screenshots,
  notification purpose text, and review notes require portal review.
- Signed IPA/AAB inspection is pending missing signing credentials.
- Live Edge Function deployment/configuration and physical OAuth/push tests are
  pending.
- The current custom `otlobli://` scheme is intentionally narrow in app code,
  but production association files for `https://otlobli.app/group` must be
  verified from the deployed domain.

No release-ready security claim is made until the open items are closed.
