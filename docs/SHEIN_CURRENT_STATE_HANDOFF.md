# SHEIN current-state handoff

Verified through 2026-08-21. This file records current evidence only. It does
not declare a universal SHEIN fix.

## v86.204 clean-room implementation state

- Version/build: `86.204/1066`.
- Branch/worktree: `codex/ios-shein-clean-room-browser` at
  `C:\Users\MOHAMMAD\Projects\otlobli-ios-shein-clean-room-browser`.
- Base: exact documentation handoff commit
  `de255a935ce3a985c05694f36899ff34d7585103`.
- Implemented: parallel native `SheinCleanBrowser` with locked RAW,
  RAW_WITH_CACHE_GUARD, CAPTURE_ONLY, BLOCKING_ONLY,
  CAPTURE_AND_BLOCKING, and unchanged LEGACY_BROWSER_CONTROL paths.
- Isolation: a different persistent iOS 17+ WebKit profile identifier for each
  clean mode; no clean/default/legacy cache sharing.
- Local result: TypeScript, production web build, hardening, performance,
  SHEIN freeze/clean-room, Temu, and store-surface guards pass; iOS sync passes.
- Pending: Xcode/GitHub artifact, IPA inspection, and all physical mode tests.
- Full architecture/protocol:
  `docs/SHEIN_V86_204_CLEAN_ROOM_DIAGNOSTIC.md`.

The v86.204 source state is not physical evidence. RAW stability, physical
content-rule classification, ChunkLoadError count, `#shein-branch` result, and
the first causal layer all remain unknown.

## Latest tested and latest built states

### Latest physically tested, evidence-bearing version

- Version/build: `86.202/1064`
- Branch: `codex/ios-v86-202-root-cause-timeline-diagnostic`
- Application code commit installed on the device:
  `a56c2e3d342eee285bde1659064ef6204ca1b8b5`
- Current preserved branch HEAD:
  `2d7332cd5b6a3a3d87b4d1bab32efe8cb9919df0`
- GitHub/Xcode run: `32402979859`
- Artifact ID: `9419317843`
- Device: iPhone 16 Pro Max (`iPhone17,2`), iOS 27.0 beta
  (`24A5380h`)
- Result: one working process and the next cold process were captured with
  unified logs, CDP network events, interaction snapshots, and read-only
  WebKit cache records. The second process reproduced the inert SHEIN page.

### Latest built but not physically tested candidate

- Version/build: `86.203/1065`
- Branch: `codex/ios-v86-203-shein-prefetch-cache-fix`
- Application behavior commit built by GitHub:
  `c914b52c2dbc539a196d4d74385b350fffd20577`
- GitHub/Xcode run: `32412740745`
- Artifact ID: `9422864423`
- IPA SHA-256:
  `73884D2E045DA72108FA2D000BA3070AAC4452CF755CF398DCED09137623B259`
- Result available: the exact raw-only content-rule JSON compiled through
  WebKit on macOS; local guards, production build, Xcode ARM64 build, and IPA
  inspection passed.
- Result not available: no v86.203 physical-device run, ten-cycle report, CDP
  comparison, ChunkLoadError count, or post-test cache inspection has been
  recorded. The cache-guard fix is therefore unaccepted and its effect on the
  freeze is unknown.

## Exact reproduced freeze sequences

### Captured v86.202 cold-process sequence

1. Install/open v86.202 and enter SHEIN in a fresh process.
2. SHEIN becomes interactive; categories/products navigate normally.
3. Leave the working page alive long enough for SHEIN's normal `prefetchJs`
   phase to issue its XHR requests.
4. Swipe-kill Otlobli from App Switcher.
5. Cold-launch Otlobli and enter SHEIN again.
6. SHEIN renders a plausible Home surface, but category/product interactions
   do not change URL, path, history, or root state. The runtime remains at
   `#app` rather than reaching `#shein-branch`.

This is the sequence for which the v86.202 cache-poisoning mechanism is proven.

### Foreground root-Back sequence

1. Open SHEIN Home.
2. Open a product.
3. Press Back to return to Home; product/Home navigation can be repeated and
   continues to work.
4. While already on canonical SHEIN Home, press Back once more.
5. The old handler enters WebKit history, Home reloads/redirects, and the
   returned page becomes inert.

The root-Back command was a real independent defect. v86.198 changed canonical
Home Back to leave the store picker before WebKit history, and that behavior
was physically accepted. A later cold/background freeze still occurred, so
root Back is not the cause of the captured v86.202 cold-process failure.

### Retained-session background/re-entry sequences

- A retained SHEIN session can work, go to the background for several seconds,
  return successfully on some cycles, and become inert on a later repeat.
- Earlier device testing also reproduced: first SHEIN entry works, leave to the
  Otlobli chooser, enter the same SHEIN session again, and the rendered store
  can be inert. In the older split-store design, switching to Temu and back to
  SHEIN created a fresh surface/session path and could recover interaction.

These sequences are verified user/device phenotypes, but they do not have the
same complete CDP/cache causal proof as the captured v86.202 cold-process pair.

## Proven v86.202 cache-poisoning sequence

1. The working process requests required SHEIN Webpack chunks as real `Script`
   resources. Chunks `68498-29797320c657aeb6f070.js` and
   `26652.9fad62278dae07661792.js` return HTTP 200,
   `application/javascript`, with executable bodies of 4,451 and 5,361 encoded
   bytes respectively.
2. The affected WKWebView reports `rel=prefetch` unsupported. SHEIN's official
   `prefetchJs` fallback consequently requests canonical `.js` URLs through
   `XMLHttpRequest`.
3. The CDN returns HTTP 304 with no response body for those stale canonical
   resources. SHEIN treats both 200 and 304 as successful prefetch results.
4. Read-only inspection of the device's WebKit NetworkCache finds canonical
   records with 304-era/`text/plain` metadata and no corresponding body blob.
5. In the next cold process, the real `Script` requests for the same URLs
   receive HTTP 304 without an executable cached body.
6. Genuine SHEIN `ChunkLoadError` rejections occur 53–56 ms after those empty
   responses and repeat after the bounded retry.
7. SHEIN does not hydrate, remains at `#app`, and trusted DOM input produces no
   route/history/root reaction even though the page and event loop are alive.

This sequence is proven for the captured v86.202 phenotype. It does not prove
that every historical or future inert SHEIN page has the same cause.

## WKContentRuleList experiment result

v86.203 adds one rule to the custom SHEIN `WKUserContentController` before any
user script, `WKWebView` construction, or first load:

```json
[
  {
    "trigger": {
      "url-filter": "^https://sheinm\\.ltwebstatic\\.com/pwa_dist/assets/.*\\.js",
      "url-filter-is-case-sensitive": true,
      "resource-type": ["raw"]
    },
    "action": {
      "type": "block"
    }
  }
]
```

The rule deliberately excludes `script`, fetch/XHR JavaScript patches, cache
deletion, reload, WebView recreation, lifecycle changes, and navigation
changes. WebKit compilation and build/archive validation passed. No physical
test result exists. It is not known whether the device classifies the exact
offending request as blocked `raw`, whether SHEIN tolerates the speculative
request failure, whether clean installs avoid cache poisoning, or whether an
already-poisoned installation recovers.

## Hypotheses ruled out or weakened

For the captured v86.202 cold-process freeze:

- Touch interception and a fixed overlay are ruled out: trusted touch/click
  events reached the tested SHEIN product elements with
  `defaultPrevented=false` and no reaction followed.
- A stopped JavaScript scheduler is ruled out: Promise, microtask, timeout,
  interval, rAF, MutationObserver, and MessageChannel heartbeats remained
  healthy.
- A hidden, detached, transparent, or interaction-disabled native surface is
  ruled out: one visible, attached, alpha-1, interaction-enabled WKWebView and
  host surface existed.
- Duplicate WKWebViews, an `InAppBrowser.close()`, and
  `webViewWebContentProcessDidTerminate` are ruled out for the captured process.
- BFCache/history restoration is ruled out: it was a new process/document and
  ordinary `navigate`, with `pageshow.persisted=false`,
  `document.wasDiscarded=false`, and an empty back list.
- Service Worker mediation is ruled out for the capture: no controller,
  registration, or Cache Storage entry was present.
- The `3ce0b2a11d15fff2` / `SHEIN_REQUIRED_COUNTRY` error is ruled out as a
  cause. It was v86.194/v86.195 diagnostic contamination and is absent from
  v86.202.
- `forceStoreVpnRecheck()` contains a separate real lifecycle race, but it is
  ruled out for this capture because no close or duplicate preceded the chunk
  failure.
- Root-Back history navigation was a separate real defect and trigger; it is
  not the captured cold-process cause.
- Authentication/risk/session state is weakened: no challenge redirect
  preceded the failure, and missing executable chunks are the earliest measured
  divergence.
- Inactive scheduling is weakened as a complete explanation: the foreground
  root-Back phenotype and the fresh cold process do not require suspension, and
  the frozen v86.202 event loop was healthy.
- Otlobli's normal injected script groups are weakened as the sole cause of the
  retained-session phenotype because a prior RAW device run with the normal
  groups disabled still froze after background/return. Individual Capture and
  Blocking interactions have not been clean-room isolated against the current
  remote SHEIN runtime.

## Protected branches and commits

Do not reset, move, rebase, merge into, rewrite, or delete:

- `codex/ios-v86-193-passive-native-foreground` at
  `a6e0ca943c4d9a2722b5962a4193d3e34d2da248`.
- `codex/ios-v86-194-root-cause-diagnostic` at
  `9a91e9f6680d1dce48ae5a04bfe6544d8d26b954` (the preserved
  v86.194/v86.195 diagnostic history).

Preserve as evidence-bearing source/candidate history:

- `codex/ios-v86-202-root-cause-timeline-diagnostic` at
  `2d7332cd5b6a3a3d87b4d1bab32efe8cb9919df0`.
- v86.203 application behavior commit
  `c914b52c2dbc539a196d4d74385b350fffd20577` on
  `codex/ios-v86-203-shein-prefetch-cache-fix`.

## Current SHEIN investigation worktrees

| Worktree | Checked-out branch/state | Current role |
| --- | --- | --- |
| `C:\Users\MOHAMMAD\Projects\otlobli-ios-v86-185-build` | `codex/ios-v86-194-root-cause-diagnostic` at `9a91e9f6680d1dce48ae5a04bfe6544d8d26b954` | Protected diagnostic history |
| `C:\Users\MOHAMMAD\Projects\otlobli-ios-v86-193-audit` | `codex/ios-v86-196-clean-runtime-diagnostic` at `12b0c528f4e3f51eba0ab3a263ab1e44f3bc19da` | Despite its directory name, it is no longer the v86.193 branch checkout |
| `C:\Users\MOHAMMAD\Projects\otlobli-ios-v86-197-inactive-scheduling-fix` | `codex/ios-v86-197-inactive-scheduling-fix` at `c4c6025c9560aa9bdc12f1954fd4fbcaadf40014` | Historical scheduling candidate |
| `C:\Users\MOHAMMAD\Projects\otlobli-ios-v86-198-root-back-fix` | `codex/ios-v86-198-shein-root-back-guard` at `16f582422e4cb73977a0cbbb0d410c6157e871c2` | Accepted root-Back behavior history |
| `C:\Users\MOHAMMAD\Projects\otlobli-ios-v86-199-combined-fix` | `codex/ios-v86-199-root-back-scheduling` at `bd25bf6db08ab0cd410b8a134831c8718c0d7996` | Root-Back plus scheduling history |
| `C:\Users\MOHAMMAD\Projects\otlobli-ios-v86-200-store-exit-buttons` | `codex/ios-v86-200-store-exit-buttons` at `ed75aab5171b911634447928572d6519e06d64b4` | Single store-exit control history |
| `C:\Users\MOHAMMAD\Projects\otlobli-ios-v86-201-double-home-store-switch` | `codex/ios-v86-201-double-home-store-switch` at `0b462a93030b5c7114012d5848ce61eac49b8b17` | v86.202 behavioral baseline |
| `C:\Users\MOHAMMAD\Projects\otlobli-ios-v86-202-root-cause-timeline-diagnostic` | `codex/ios-v86-202-root-cause-timeline-diagnostic` at `2d7332cd5b6a3a3d87b4d1bab32efe8cb9919df0` | Proven root-cause evidence source |
| `C:\Users\MOHAMMAD\Projects\otlobli-ios-v86-203-shein-prefetch-cache-fix` | `codex/ios-v86-203-shein-prefetch-cache-fix`; behavior commit `c914b52c2dbc539a196d4d74385b350fffd20577` plus documentation | Canonical untested content-rule candidate and this handoff |
| `C:\Users\MOHAMMAD\Projects\otlobli-ios-v86-203-shein-prefetch-cache-guard` | `codex/ios-v86-203-shein-prefetch-cache-guard` at `a8ebaec3896a58755b4fc47fcac9b355030a4df9` | Superseded pre-instruction draft; not the canonical v86.203 candidate |

## Relevant reports, logs, cache evidence, and artifact paths

Repository reports:

- `C:\Users\MOHAMMAD\Projects\otlobli-ios-v86-203-shein-prefetch-cache-fix\docs\SHEIN_V86_202_ROOT_CAUSE_CAPTURE_REPORT.md`
- `C:\Users\MOHAMMAD\Projects\otlobli-ios-v86-203-shein-prefetch-cache-fix\docs\SHEIN_V86_202_ROOT_CAUSE_TIMELINE_DIAGNOSTIC.md`
- `C:\Users\MOHAMMAD\Projects\otlobli-ios-v86-203-shein-prefetch-cache-fix\docs\SHEIN_V86_203_PREFETCH_CACHE_FIX.md`

Preserved v86.202 device evidence:

- Raw unified log:
  `C:\Users\MOHAMMAD\Desktop\Otlobli-v86.202-root-cause-raw.log`
  (`C631A88843ECEE42FCE6A52F21837A99B9F6798B1421D210C9689EB4951E9C67`).
- Decoded unified log:
  `C:\Users\MOHAMMAD\Desktop\Otlobli-v86.202-root-cause-decoded.jsonl`.
- Runtime comparison:
  `C:\Users\MOHAMMAD\Desktop\Otlobli-v86.202-transition-working-vs-frozen-report.json`.
- Raw CDP network capture:
  `C:\Users\MOHAMMAD\Desktop\Otlobli-v86.202-cdp-network.jsonl`
  (`0C10A637A91E804816CAA8FF6294CDC2C693BA1351D6DDF30EC25BEE63E27A3D`).
- CDP working-versus-frozen report:
  `C:\Users\MOHAMMAD\Desktop\Otlobli-v86.202-cdp-working-vs-frozen-report.json`.
- Read-only copied WebKit cache tree:
  `C:\Users\MOHAMMAD\Desktop\Otlobli-v86.202-frozen-network-cache\NetworkCache`.
- Chunk 68498 cache record:
  `C:\Users\MOHAMMAD\Desktop\Otlobli-v86.202-frozen-network-cache\68498-cache-record.bin`
  (`93673AE71EC2ED5870A7D207EFD2DACC969FE155787BA33D1A0FD59DD68B70AF`).
- Chunk 26652 cache record:
  `C:\Users\MOHAMMAD\Desktop\Otlobli-v86.202-frozen-network-cache\26652-cache-record.bin`
  (`A346B7B024D3A2F83BBD33D80494A51B9867F8BE13263E6B78FA1B7491B5E4F5`).

Untested v86.203 artifact:

- `C:\Users\MOHAMMAD\Desktop\otlobli-ios-v86.203-shein-prefetch-cache-fix\otlobli-v86.203-ipad-iphone-universal-unsigned.ipa`.

## Unresolved questions

1. Does v86.203 prevent successful matching raw/XHR JavaScript prefetches and
   cache poisoning across ten clean App Switcher kill/cold-launch cycles on the
   physical iPhone?
2. Does the physical WebKit network stack classify the offending SHEIN XHR as
   `raw` for `WKContentRuleList`, and is a blocked request visible as blocked or
   absent in CDP?
3. Does SHEIN tolerate the speculative prefetch failure without a new fatal
   rejection or missing feature?
4. Do real `Script` requests remain unblocked and retain executable bodies,
   with zero genuine ChunkLoadError and no new bodyless/`text/plain` records?
5. Does an in-place upgrade from an already-poisoned v86.202 installation
   recover, or would existing users require a separate one-time memory/disk
   HTTP-cache-only migration?
6. Does the proven v86.202 cache sequence also explain retained-session
   background/chooser re-entry freezes, or are multiple inert-page mechanisms
   present?
7. In a browser constructed without legacy state or injections, which exact
   mode first reproduces the current remote SHEIN failure: RAW, cache guard,
   Capture, Blocking, or their combination?

## Next approved task

Finish the one v86.204 Xcode/IPA build and then run the isolated physical mode
matrix, without modifying or replacing the preserved legacy control path:

- `RAW`
- `RAW_WITH_CACHE_GUARD`
- `CAPTURE_ONLY`
- `BLOCKING_ONLY`
- `CAPTURE_AND_BLOCKING`
- `LEGACY_BROWSER_CONTROL`

The implementation exists but has no physical result. The next evidence task is
controlled comparison of those modes against the same reproducible sequences.
It is not authorization to clear mode website data, merge protected history,
or declare the legacy browser replaced before comparative results exist.
