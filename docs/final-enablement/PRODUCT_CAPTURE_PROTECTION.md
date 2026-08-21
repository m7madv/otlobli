# Product-capture protection — v86.208

The authoritative pre-edit hashes below were recorded from clean
`c18363c9a5712239d53bdf97880058036f9b2198`. The extraction implementation and
its public message contract are frozen for this release.

| File | Capture role | Pre-edit SHA-256 | Final rule |
| --- | --- | --- | --- |
| `src/services/sheinBrowserScript.ts` | Runtime composition boundary | `6793A8C52D46A8B4F29722A6A6E22B9ABB9B1C35FD95C1A77D0BD14DB46272FC` | Byte-identical |
| `src/services/storeProductCaptureScript.ts` | Product ID, SKU, image, price, color, size, variant extraction and cart message | `5A5E2E99A3656E143C108DC2E56463B5214FBDFC4EB030D120806E79BAF41788` | Byte-identical |
| `src/services/sheinSkuTap.ts` | Existing option-drawer activation used by capture | `F675AF9D4FC75595914DF97D907FEE2472691204EEF89F89844871662F676619` | Byte-identical |
| `src/services/storeCaptureBundle.ts` | Lazy host composition and region input | `117FB0023A22CE4A529F26075E79CB42C40DA95AA6F71BBADE0214D5BAB780F7` | Public capture interface unchanged; any composition-only diff must be audited |
| `src/services/storeBrowser.ts` | Native/Capgo browser bridge used to deliver capture messages | `A54E19DF8E66B2D49C7B227DD24C7C6B43B2593E97C88047D76D5827DC5452B7` | Byte-identical |
| `src/services/storeRuntimeCoordinator.ts` | Scheduler that invokes capture alongside other store responsibilities | `A06E41D1504C2DA20DA8CA7F23E057F1DC51E0AB940417AAD18F0C4890EC8C6B` | Capture calls and timing contract unchanged; policy-only diff must be audited |
| `src/App.tsx` | Receives, validates, acknowledges, and nacks `addToCart` | `E3F4186881586CD8E38CE49DBDDD13A6C78EB4BDCA7E2A0812CD474C70794EC6` | Capture receive/ack/nack block unchanged; unrelated host changes require focused diff audit |
| `src/domain/types.ts` | Product, option, variant, and cart contracts | `5FA37D5ABB06BEBD0ED6B9E6ED62393A70A2F18556D44172259598387FC59175` | Byte-identical |
| `ios/App/App/OtlobliSheinBrowserPlugin.swift` | iOS script-message transport | `4A72552E68D5E80BFC209422A44B6E5ED53D6208FDF06233691B288C9CBB71AF` | Capture message schema/forwarding unchanged; native route-policy-only diff must be audited |
| `patches/@capgo+capacitor-inappbrowser+8.6.25.patch` | Android/native Capgo message transport | `4CE6DEEC8E14629A1D1E7329E37CA6AC2220B2203BEC35B0DC89F321BD031928` | Capture message schema/forwarding unchanged; Android route-policy-only diff must be audited |

## Frozen interface

- Message names `addToCart`, `addToCartAck`, and `addToCartNack` are immutable.
- Product fields, extraction priority, option selection, SKU/image/price logic,
  cart transfer, and error behavior are immutable.
- Policy, region, push, authentication, deletion, and signing code must consume
  existing public messages and must not import or rewrite capture internals.
- Final validation must compare the three core capture hashes, inspect focused
  diffs for composition/transport files, run the existing store guards, and
  scan generated iOS/Android assets.

Initial product capture changed: **no**.

## Final verification status

The six core extraction/bridge/type files remain byte-identical. Focused diffs
in `storeCaptureBundle.ts`, `App.tsx`, and native transport files are confined
to policy composition, readiness, opening timestamps, and main-frame route
enforcement; `addToCart`, `addToCartAck`, `addToCartNack`, extraction fields,
and option/variant behavior are unchanged. Automated capture, SHEIN, Temu,
surface, and generated-asset guards pass.

Final product capture changed: **no**.
