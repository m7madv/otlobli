# SHEIN policy engine — v86.208

## Contract

`src/services/sheinPolicyEngine.ts` defines policy version
`2026.08.21-v86.208-policy-v1`. The same main-frame decision is enforced in
the iOS `WKNavigationDelegate` and Android `WebViewClient`.

| Route class | Decision |
| --- | --- |
| `allowed-public`, `home`, `category`, `search`, `product` | allow |
| `human-verification` | allow unconditionally |
| `blocked-login`, `blocked-signup`, `blocked-account` | cancel |
| `blocked-country`, `blocked-region`, `blocked-language`, `blocked-currency` | cancel |
| `blocked-checkout` | cancel |
| `external` | leave the store boundary; never load in the SHEIN WebView |
| `unknown` | preserve browsing and emit only bounded sanitized evidence |

The last confirmed safe public URL is retained by both native implementations.
Root Back, product/category Back, store chooser, double-Home store switching,
browser ownership, and product capture were not rewritten.

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
Physical confirmation of every blocked control and allowed interaction remains
required before release acceptance.
