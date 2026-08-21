# Product capture baseline

Baseline: `codex/ios-v86-201-double-home-store-switch` at
`0b462a93030b5c7114012d5848ce61eac49b8b17`.

The capture internals listed below are byte-identical in the mapped v86.205
build. They are frozen for this release. UI blocking and SHEIN session/region
logic are also outside the scope of any capture refactor.

| File | Role | SHA-256 at baseline |
| --- | --- | --- |
| `src/services/sheinBrowserScript.ts` | Runtime composition boundary | `6793A8C52D46A8B4F29722A6A6E22B9ABB9B1C35FD95C1A77D0BD14DB46272FC` |
| `src/services/storeProductCaptureScript.ts` | Product/SKU/variant/image/price/size/color extraction and add message | `5A5E2E99A3656E143C108DC2E56463B5214FBDFC4EB030D120806E79BAF41788` |
| `src/services/sheinSkuTap.ts` | Existing SHEIN option-drawer activation | `F675AF9D4FC75595914DF97D907FEE2472691204EEF89F89844871662F676619` |
| `src/services/storeCaptureBundle.ts` | Host composition interface | `07D13CB5CE7789973B568849F9801F97B9DB63FD13A108613F4BAE82B2126230` |
| `src/services/storeBrowser.ts` | Native/Capgo browser bridge boundary | `A54E19DF8E66B2D49C7B227DD24C7C6B43B2593E97C88047D76D5827DC5452B7` |
| `src/services/storeRuntimeCoordinator.ts` | Bounded runtime scheduling | `A06E41D1504C2DA20DA8CA7F23E057F1DC51E0AB940417AAD18F0C4890EC8C6B` |
| `src/App.tsx` | Receives `addToCart` and acknowledges/nacks the existing bridge schema | `B83516429BC83EDB9972F276E050DB557D33A918DD4EC9D5CC79E19EFACF02E4` |
| `src/domain/types.ts` | Product, variant, and cart data contracts | `5FA37D5ABB06BEBD0ED6B9E6ED62393A70A2F18556D44172259598387FC59175` |
| `ios/App/App/OtlobliSheinBrowserPlugin.swift` | iOS WKScriptMessage/native bridge | `B4D09531FE392A6D9BA8025559F9E8F8BBCC733EC362CBA180A1325A8C70F6D9` |
| `patches/@capgo+capacitor-inappbrowser+8.6.25.patch` | Shared Capgo bridge modifications used by non-dedicated paths | `FB263EB42932B609879B3478C5D290CFB51BE862F70C781EECEBC32115CF5218` |

## Allowed release changes around the boundary

- Diagnostic-only code may be compiled out of the host composition and native
  patch without changing extraction, fields, bridge messages, or cart logic.
- Sanitizing native logs is permitted when navigation and message behavior are
  unchanged.
- Authentication, notification, signing, and release-hardening work must stay
  outside the capture algorithm.

## Regression contract

- `storeProductCaptureScript.ts`, `sheinSkuTap.ts`, `sheinBrowserScript.ts`,
  `storeRuntimeCoordinator.ts`, and `domain/types.ts` must retain these hashes.
- `addToCart`, `addToCartAck`, and `addToCartNack` message names and payload
  schema must remain unchanged.
- Any changed host/native composition file must be audited to prove its diff is
  limited to diagnostic removal, notification/auth, safe logging, signing, or
  version metadata.
- Existing SHEIN/Temu guard scripts and final hash verification must pass.

Product capture changed: **no**.
