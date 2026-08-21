# SHEIN region and currency status

## Release decision

The working region mechanism is preserved; no new `SheinRegionCoordinator` was
introduced. The owner explicitly confirmed that admin-controlled region
changes currently propagate correctly and prohibited changes to that behavior.

- `src/services/sheinSessionScript.ts` is byte-identical to the selected
  baseline (Git blob `bab736a86918dda86bc630e1d3690221f58743ba`).
- `src/services/storeBlockingScript.ts` is also unchanged.
- Admin values continue to come from `app-settings` keys
  `store_region_shein` and `store_region_temu`.
- The bundled safe fallback remains SHEIN `SA / USD / ar`; the live admin value
  remains authoritative when fetched successfully.
- SHEIN receives the existing `currency`, `localcountry`, and `lang` entry
  parameters. Its site-owned signed `addressCookie` remains the shipping-state
  authority; the app does not rewrite guessed cookies or storage.
- Region, currency, login, human verification, and product capture remain
  separate states in the existing scripts. Human verification is left visible.
- The existing bounded native selector flow is retained. No website-data
  clearing, repeated reload, artificial delay, new repair loop, or session
  recreation was added.

## First-open observation

The owner reports that on some first SHEIN opens the native region selector is
visible while automation proceeds and total opening time can be 10–11 seconds.
This release removes diagnostic runtime/panel overhead, but it does not claim a
measured improvement: changing the proven selector or hiding/blocking scripts
was explicitly out of scope. A real first-install timing capture is still
required on iPhone and Android before any optimization is approved.

## Acceptance still required

On physical devices verify admin propagation, first install, cached return,
required country/currency, blocked manual changes, human verification, product
capture, and a controlled visible error if the required state cannot complete.
No region/currency regression is claimed solely from source guards.
