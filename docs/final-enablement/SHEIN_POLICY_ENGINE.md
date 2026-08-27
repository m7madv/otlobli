# SHEIN policy engine — v86.244

## Contract

`src/services/sheinPolicyEngine.ts` defines the bounded DOM policy version
`2026.08.27-v86.244-login-later-v4`. Native route enforcement is versioned
`2026.08.27-v86.244-challenge-commit-v1` in both iOS and Android. Main-frame network
navigations are enforced by iOS `WKNavigationDelegate` and Android
`WebViewClient`; same-document History API changes are enforced by the existing
iOS URL observation and Android `doUpdateVisitedHistory` callback.

| Route class | Decision |
| --- | --- |
| `allowed-public`, `home`, `category`, `search`, `product` | allow |
| `human-verification` | allow unconditionally |
| `blocked-login`, `blocked-signup`, `blocked-account` | cancel |
| `blocked-country`, `blocked-region`, `blocked-language`, `blocked-currency` | cancel |
| `blocked-checkout` | cancel |
| `external` | never load in the SHEIN WebView; cancel it when sourced by a blocked auth route |
| `unknown` | preserve browsing and emit only bounded sanitized evidence |

The full `/ar/user/login` page is not the optional login-later interstitial. If
SHEIN enters any blocked route through History API, native code performs one
Back action. One bounded check after `200ms` falls back to Home only if Back did
not leave the blocked route; missing Back history uses Home immediately.
iOS/Android also reject every popup from that blocked page before internal or
external popup handling, preventing OAuth from escaping to Safari or another
app. Public-page external-link behavior is unchanged.

Human verification temporarily owns navigation. While its trusted lock is
active, internal SHEIN top-level/popup navigation is allowed in the same
WebView, and every blocked-route recovery/Back/Home action waits. A complete
coordinator snapshot unlocks navigation; only then is the existing recovery
run once if the resulting route remains blocked. Full-page `/risk/challenge`
success is the fresh redirected document, while same-document success is
settled only after the exact clearance proof or its bounded conservative
fallback. Verification is never clicked, solved, reloaded, or cleared.

The last confirmed safe public URL remains retained by both native
implementations, while a blocked route is never persisted as iOS `savedURL`.
Root Back, product/category Back, store chooser, double-Home store switching,
browser ownership, product capture, region, session, and human verification
were not rewritten.

## UI policy

The document-start script installs under one versioned namespace. Confirmed
forbidden controls receive minimal CSS before first paint. Matching order is
href/path, aria-label, stable `data-*`, role/semantic structure, then exact
Arabic/English text as a fallback. It covers login/signup, account/profile,
country/region/language/currency, and the third-party cart/checkout surface.

There is one MutationObserver. Work is animation-frame batched and bounded to
96 roots and 320 inspected nodes per batch. A newer installer disconnects an
older observer. It never adds a document-wide click/pointer listener, calls
`preventDefault`, patches fetch/XHR/console/history, hides a human challenge,
or modifies nodes owned by Otlobli capture/cart integration. An uncertain match
is left functional and can emit no more than eight sanitized mismatch codes.

## Verification

Host readiness now requires independent policy, country, region, currency,
language, interaction, and capture states. Automated route, installation,
observer, interception, native ordering, and protected-capture guards pass.
The exact locale-prefixed `/ar/user/login` case, clean patch application,
native recovery ordering, outbound fail-closed behavior, and absence of new
recurring work are guarded. Physical confirmation on the target iPhone remains
required before release acceptance.
