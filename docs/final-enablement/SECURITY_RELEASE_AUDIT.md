# Security and release audit — v86.208

Passed source and generated-asset guards cover production URLs, relay-key
replacement, secret/private-key patterns, diagnostics, Web Inspector/WebView
debugging, source maps, broad notification URLs, cleartext traffic, exported
Android components, policy bypasses, protected capture, Temu, and release
versioning. The extracted `dist`, iOS public assets, and Android public assets
also passed the diagnostic marker scanner.

Release Web Inspector is false and Android WebView debugging is false. The new
policy adds no global input interception, fetch/XHR/console/history patch, or
human-verification suppression. Notification payloads map only to versioned
internal destinations. Push sending requires a server secret and private keys
remain environment-only. Identity and token tables have RLS, revoked client
access, service-role functions, active-token uniqueness, and invalidation.

`PrivacyInfo.xcprivacy` is valid XML, declares no tracking, describes linked
app-functionality data categories, and declares UserDefaults reason CA92.1.
Final App Privacy/Data Safety answers, privacy-policy/support URLs, signed
artifact inspection, and physical behavior remain portal/device gates.

One protected legacy boundary remains intentionally unchanged: the existing
capture/navigation composition still contains its historical document
listeners/history integration. v86.208's new policy layer adds none of those;
removing them would violate the byte-identical product-capture requirement and
requires a separately approved regression project.
