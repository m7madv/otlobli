# SHEIN final-forensics build

Status: source-validated forensic candidate; physical scenarios are pending.
This document does not claim either incident is fixed.

## Identity

- Branch: `codex/ios-v86-206-shein-final-forensics`
- Version/build: `86.206/1068`
- Base: exact v86.205 handoff commit
  `846de3798e5decc4e46fb9e7ca40e90c74e201f7`
- Device target: `00008140-001E6D581E11801C`, iPhone 16 Pro Max
  (`iPhone17,2`), iOS 27.0 beta (`24A5380h`).

## Authorized diagnostic differences

The Windows controller writes one validated scenario file into the app's
Documents directory before launch. The native clean browser then:

1. validates the scenario/mode pairing;
2. uses its new persistent UUID with
   `WKWebsiteDataStore(forIdentifier:)` before constructing the WebView;
3. reuses that UUID and run ID across the same scenario's later process;
4. displays and logs the exact container identity;
5. appends sanitized native/runtime records to one scenario-specific JSONL
   file in Documents.

Capture and Blocking retain their business behavior. Added messages measure
only their own install/scan/snapshot/dispose operations, including duration,
bounded match/change counts, document ID, and root fingerprints. No browser API
is monkey-patched.

The cache guard remains the exact pre-existing raw-only rule. The forensic log
now records its exact identifier/filter/resource type, compilation success, and
attachment before WebView construction and first navigation. CDP determines
the actual physical request classification.

## Preserved boundaries

- No website data, cookie, storage, or cache clear.
- No reload, WebView recreation, store switching, or recovery.
- No request interception or cache disabling by the controller.
- No new freeze fix.
- No legacy browser edit; the protected plugin hash remains
  `6A6D6A16A5EED040618988C9D5B5AC6D8F88DDD187F4BC095C0F1C1AA710382E`.
- The controller pulls only the selected custom store's `NetworkCache`; it
  does not preserve Cookies, LocalStorage, IndexedDB, or CacheStorage.

## One-command controller

From the repository root:

```powershell
pwsh -NoProfile -File scripts/run-shein-final-forensics.ps1 -Scenario A1
```

Valid scenarios are `A1`, `A2`, `A3`, `A4`, `B0`, `B1`, `B2`, and `B3`.
The controller verifies the USB UDID, installed `86.206/1068`, mounted DDI,
and tool version `10.10.0`; generates a never-reused persistent UUID; starts
unified log, CDP, PID/WebContent polling, and screenshots; gives one manual
instruction at a time; pulls read-only evidence; analyzes it; and hashes the
preserved bundle.

Each result is stored at:

`artifacts/shein-final-forensics/<timestamp>-<scenario>/`

## Local validation before Xcode

- PowerShell AST parse: pass.
- New Node scripts syntax: pass.
- Cache inspector smoke test against preserved v86.202 data: pass.
- Analyzer smoke execution against preserved v86.202 material: pass (the smoke
  input intentionally lacks current scenario markers and therefore remains
  insufficient evidence).
- TypeScript: pass.
- Full production build and all release/SHEIN/Temu/store/performance gates:
  pass.
- Capacitor iOS sync: pass.
- Xcode/IPA and physical results: pending.

