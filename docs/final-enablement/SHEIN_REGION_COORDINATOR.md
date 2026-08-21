# SHEIN region coordinator — v86.208

## Authoritative values

On 2026-08-21 the deployed `app-settings` endpoint returned the live
`store_region_shein` value:

```json
{"countryCode":"QA","currency":"USD","language":"ar","addressPath":[]}
```

Therefore the live required state is **QA / USD / ar**. The client continues
to consume the validated administration setting; it does not hardcode Qatar as
a new release constant. The source fallback remains the pre-existing
SA/USD/ar Riyadh address only for an unavailable or invalid settings response.
The backend validator accepts supported countries, USD, Arabic, an empty path
outside Saudi Arabia, and the exact existing Saudi path when SA is selected.

## State model

`src/services/sheinRegionCoordinator.ts` keeps these states independent:
country, region, currency, language, login, human verification, policy, and
capture. Its lifecycle is:

`IDLE → OPENING → INSTALLING_POLICY → APPLYING_REQUIRED_STATE → NAVIGATING →
HUMAN_VERIFICATION → VERIFYING → READY`, with `REPAIRING_ONCE`, `FAILED`, and
`CLOSED` terminal/exception paths.

The session script uses URL, site-owned storage/cookie, document language, and
visible shipping-region signals where available. Partial/unknown evidence does
not falsely become ready or fail early. One explicit mismatch may trigger the
existing state repair once. A second mismatch or a bounded timeout shows native
Otlobli Retry/Close while retaining the same browser; there is no reload loop,
store switch, WebView recreation, or SHEIN-login requirement.

Automated correct/mismatch/one-repair/no-loop/human/failure/independent-field
tests pass. Physical verification against the live QA setting remains pending.

