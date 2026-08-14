# Store runtime map

The WebView runtime is composed in `sheinBrowserScript.ts`, but each source
file owns one responsibility:

| File | Responsibility |
| --- | --- |
| `sheinNavigationScript.ts` | Document-start navigation and bounded early concealment only. |
| `sheinSessionScript.ts` | Shared runtime foundation, challenge-safe session rules, and native SHEIN shipping-region flow. |
| `storeProductCaptureScript.ts` | Product identity, option/price reading, and the Otlobli add action. |
| `storeBlockingScript.ts` | Store chrome, native add buttons, popups, and other explicitly blocked controls. |
| `temuBrowserScript.ts` | Temu-specific browsing and capture behavior. |
| `storeRuntimeCoordinator.ts` | One recurring scheduler that invokes the other responsibilities. |
| `sheinBrowserScript.ts` | Composition only; no page behavior belongs here. |

## Session invariants

- SHEIN owns its cookies, `localStorage`, and `sessionStorage` schemas.
- Otlobli never replaces `Storage.prototype` and never clears a solved human
  verification session.
- The configured shipping country is selected through SHEIN's native shipping
  UI and verified from its signed `addressCookie`; Otlobli does not forge it.
- Human-verification pages are user-controlled: no auto click, reload, or
  region write runs while a challenge is active.

## Performance invariants

- The full runtime uses one recurring coordinator timer.
- No full-document `MutationObserver` may schedule general scans.
- The product-price observer is local, bounded, and disconnected after its
  short capture window.
- Document-start timers are bounded and stop as soon as the full runtime is
  ready.
