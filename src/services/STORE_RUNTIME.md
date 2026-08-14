# Store runtime map

The WebView runtime is composed in `sheinBrowserScript.ts`, but each source
file owns one responsibility:

| File | Responsibility |
| --- | --- |
| `sheinNavigationScript.ts` | Document-start navigation and bounded early concealment only. |
| `sheinPrivacyCompatScript.ts` | Always-on, bounded SHEIN privacy-layer compatibility; rejects optional tracking and releases a confirmed invisible iOS touch shield. |
| `sheinSessionScript.ts` | Shared runtime foundation, challenge-safe session rules, and native SHEIN shipping-region flow. |
| `storeProductCaptureScript.ts` | Product identity, option/price reading, and the Otlobli add action. |
| `storeBlockingScript.ts` | Store chrome, native add buttons, popups, and other explicitly blocked controls. |
| `temuBrowserScript.ts` | Temu-specific browsing and capture behavior. |
| `storeRuntimeCoordinator.ts` | One recurring scheduler that invokes the other responsibilities. |
| `storeScriptDiagnostics.ts` | Diagnostic-build-only side panel and validated feature flags; unavailable in customer builds. |
| `sheinBrowserScript.ts` | Composition only; no page behavior belongs here. |

## Session invariants

- SHEIN owns its cookies, `localStorage`, and `sessionStorage` schemas.
- Otlobli never replaces `Storage.prototype` and never clears a solved human
  verification session.
- The configured shipping country is selected through SHEIN's native shipping
  UI and verified from its signed `addressCookie`; Otlobli does not forge it.
- Human-verification pages are user-controlled: no auto click, reload, or
  region write runs while a challenge is active.
- SHEIN privacy consent is handled by one independent compatibility prelude,
  including in raw-store diagnostics. It prefers "Reject all" and only the
  native iOS app may neutralize a still-blocking, full-viewport SHEIN privacy
  layer after bounded rejection attempts.

## Performance invariants

- The full runtime uses one recurring coordinator timer.
- No full-document `MutationObserver` may schedule general scans.
- The product-price observer is local, bounded, and disconnected after its
  short capture window.
- Document-start timers are bounded and stop as soon as the full runtime is
  ready.

## Diagnostic isolation build

- `VITE_STORE_SCRIPT_DIAGNOSTICS=true` adds one customer-visible side panel.
- The raw-store preset injects only the panel, a painted-page readiness signal,
  and the mandatory privacy compatibility prelude; the normal navigation,
  blocking, capture, session, and coordinator runtime is not evaluated in the
  store page.
- Changing a flag recreates one native WebView without clearing cookies,
  storage, cache, or the store's solved verification proof.
- Normal customer builds keep the flag false and never inject or accept this
  control surface.
