# SHEIN policy status

## Release decision

The release does **not** introduce a new `SheinPolicyEngine`. The application
owner explicitly froze the currently working SHEIN hiding/blocking behavior and
product flow after the broader specification was written. Replacing it with a
new rules engine, content world, selector set, or route classifier would create
an untested store experiment and conflict with that instruction.

The production result is therefore preservation plus verification:

- `src/services/storeBlockingScript.ts` is byte-identical to baseline
  `0b462a93030b5c7114012d5848ce61eac49b8b17` (Git blob
  `ad53da4f4930bb1f1348b5834acd35c3fe6c67b7`).
- `src/services/sheinNavigationScript.ts` is byte-identical (Git blob
  `2248fe7069528a49d4d11d56e4c4e816b6347441`).
- Product capture, option selection, cart messages, human verification,
  categories, search, products, variants, images, scrolling, product Back,
  root Back, and double-Home store selection retain the v86.201 behavior.
- Existing blocking still targets login/signup/account and the country,
  region, language, and currency controls. Existing checkout/cart restrictions
  remain aligned with the Otlobli cart flow.
- Human-verification surfaces are not hidden or bypassed.
- No fetch/XHR patch, synthetic click, global `preventDefault`, reload loop,
  remote JavaScript, or new route experiment was added.

## Diagnostic cleanup around the policy

Customer-facing diagnostic mode selectors, policy panels, touch overlays,
freeze probes, diagnostic navigation buttons, and runtime feature flags are
not composed into the release. Production injected-script emission also
retires the two historical optional diagnostic hook names without changing the
navigation source. `scripts/verify-production-release.mjs` scans `dist`, iOS
public assets, and Android public assets and fails if those markers return.

## Verification

Passed locally:

- protected source/hash guard;
- SHEIN lifecycle/root-Back guard;
- store surface geometry guard;
- Temu size/cart/hidden-session guard;
- generated-asset diagnostic scan;
- production web build and performance budget.

Not yet proven for v86.207: physical blocking and navigation acceptance on the
target iPhone and Android devices. No release-ready claim is made until that
matrix is completed.
