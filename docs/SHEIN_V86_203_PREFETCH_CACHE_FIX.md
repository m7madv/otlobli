# SHEIN v86.203 raw-prefetch cache-poisoning fix experiment

## Status

v86.203/1065 is one single-variable physical-device experiment built from the
exact v86.202 diagnostic baseline `2d7332cd5b6a3a3d87b4d1bab32efe8cb9919df0`.
The code, WebKit rule compilation, local guards, Xcode build, archive creation,
and archive inspection pass. Physical-device acceptance has not run, so this
document does not claim that the customer-visible freeze is fixed.

- Worktree: `C:\Users\MOHAMMAD\Projects\otlobli-ios-v86-203-shein-prefetch-cache-fix`
- Branch: `codex/ios-v86-203-shein-prefetch-cache-fix`
- Code HEAD built by GitHub: `c914b52c2dbc539a196d4d74385b350fffd20577`
- GitHub Actions run: `32412740745`
- Artifact ID/name: `9422864423` / `otlobli-ios-v86.203-ipad-iphone-universal`
- IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-ios-v86.203-shein-prefetch-cache-fix\otlobli-v86.203-ipad-iphone-universal-unsigned.ipa`
- IPA size: `6,601,350` bytes
- IPA SHA-256: `73884D2E045DA72108FA2D000BA3070AAC4452CF755CF398DCED09137623B259`

The earlier superseded workflow `32411247101` was cancelled before Xcode and
created no artifact. Compile-check workflow `32412384200` stopped before IPA
packaging and also created no artifact. Therefore the successful run above is
the only v86.203 IPA produced by this experiment.

## Baseline and protected history

Preflight proved that the source worktree was clean on
`codex/ios-v86-202-root-cause-timeline-diagnostic` at exact commit `2d7332c`.
The protected pointers remained:

- v86.193: `a6e0ca943c4d9a2722b5962a4193d3e34d2da248`
- v86.195: `9a91e9f6680d1dce48ae5a04bfe6544d8d26b954`

No reset, rebase, merge, or history rewrite was used. The new worktree was
created directly from the exact v86.202 commit.

## The only production behavior change

The custom `OtlobliSheinBrowserPlugin` compiles or retrieves one versioned
`WKContentRuleList` and installs it on the custom SHEIN
`WKUserContentController` before any user script, `WKWebView` creation, or first
load. Its exact JSON is:

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

Identifier: `com.otlobli.shein.raw-js-prefetch-block.v1`.

The rule has `raw` only. It does not contain `script`, `fetch`, a JavaScript
`XMLHttpRequest` patch, or a broad SHEIN-domain block. Real Script loads are
therefore outside the rule. The filter is limited to
`sheinm.ltwebstatic.com/pwa_dist/assets/*.js` and does not hardcode the two
captured chunk numbers.

`WKContentRuleListStore.default()` is looked up first and compiled only on a
miss. If the store, compilation, or resulting rule is unavailable, the SHEIN
browser open is rejected explicitly; an unprotected experiment is never
silently loaded. Existing user scripts, handlers, website data store, cache
policy, user agent, scheduling policy, navigation, Back behavior, store
parking, lifecycle, cookies, storage, Service Workers, region/session, product
capture, readiness, and Temu code remain unchanged.

## Safe diagnostics retained and extended

The passive v86.202 probe and Web Inspector access remain enabled. Native
events use `[OTLOBLI_PREFETCH_FIX]` and include the rule identifier, SHA-256 of
the JSON, lookup/compile state, safe errors, attachment timestamp, PID, runId,
browserId, webViewId, and explicit before-WebView/before-first-load flags. They
do not include URLs, query strings, cookies, tokens, or storage values.

The external CDP recorder now asks WebKit for response-body metadata after
matching loads and records only byte length, SHA-256, and executable/non-HTML
classification rather than persisting the body. The analyzer aggregates every
matching CDN JavaScript request with type, timestamps, status, MIME type,
encoded and transfer sizes, completion/failure, blocked reason, initiator
stack, Script-versus-speculative classification, following ChunkLoadError,
`#shein-branch`, and interaction changes. It accepts decoded native evidence
through `--native=`; use one CDP/native file pair per cold process.

## Changed files

- `.github/workflows/ios-unsigned-build.yml`
- `android/app/build.gradle`
- `ios/App/App.xcodeproj/project.pbxproj`
- `ios/App/App/OtlobliSheinBrowserPlugin.swift`
- `scripts/analyze-shein-cdp-network.mjs`
- `scripts/capture-shein-cdp-network.mjs`
- `scripts/validate-shein-content-rule.swift`
- `scripts/verify-shein-freeze-guard.mjs`
- `src/config.ts`
- `src/services/sheinFreezeDiagnostics.ts`

The Android/config edits are version markers only. Analyzer, recorder, guard,
and workflow edits are diagnostic/build validation only.

## Validation completed before device testing

- `npm run verify:shein-freeze-guard`: pass
- `npm run verify:release-hardening`: pass
- `npm run verify:temu-size-gate`: pass
- `npm run verify:store-surface`: pass
- `npm run build`: pass, including TypeScript, Vite production build, release
  hardening, and all performance budgets
- `npx cap sync ios`: pass; no generated/dependency diff
- `git diff --check`: pass
- WebKit compiled the exact raw-only JSON on the GitHub macOS runner: pass
- Xcode Release/iphoneos ARM64 build: pass
- IPA inspection: `com.otlobli.app`, `86.203/1065`, iOS 15+, iPhone/iPad
  families `[1,2]`, ARM64, unsigned, unprovisioned, zero source maps, zero relay
  placeholders, and the rule identifier/log prefix present in the native binary
- Contaminated tap-diagnostic context (`SHEIN_TAP_DIAGNOSTIC_CONTEXT_JS` and
  `window.__otlobliTapDiagnosticContext`) remains absent. The legitimate private
  region variable inside `SHEIN_CAPTURE_SCRIPT` remains scoped as before.

The upgraded analyzer was regression-tested against the preserved v86.202
capture and correctly reported 46 successful speculative requests, 57
bodyless/text-plain records, five CDP runtime ChunkLoadError records, and the
failed prevention/body/error assertions. This proves analyzer discrimination;
it is not v86.203 device evidence.

## Physical Test A — clean preventive proof

Delete the installed app once before this test because the current v86.202
container may already contain poisoned WebKit cache records. Install v86.203,
start unified-log and CDP capture before launch, and preserve one separate pair
of evidence files for every process/runId. Exercise Home/categories/search,
three categories, five products, product Back, root Back, chooser hide/show,
login, cart, capture/add-to-Otlobli, region/verification, Temu switching, and
double-Home. Then swipe-kill from App Switcher, cold-launch, open SHEIN, and
repeat ten times without another reinstall or data clear.

Acceptance requires all ten cycles to show:

1. `[OTLOBLI_PREFETCH_FIX] rule-attached` before WKWebView creation and a
   protected first load.
2. No successful matching XHR/raw 200 or 304 response; it is blocked or absent.
3. Matching Script requests are never blocked and retain executable bodies.
4. No bodyless/text-plain cache record and no real ChunkLoadError.
5. `#shein-branch` is reached and trusted interactions change route/history/root.
6. No new fatal rejection from SHEIN reacting to the blocked speculative load.
7. All SHEIN, Temu, and Otlobli store flows remain functional.

Current result: **pending physical device**. v86.203 ChunkLoadError count, CDP
comparison, cache-record inspection, and ten-cycle result are therefore not yet
available and must not be represented as zero/pass.

## Physical Test B — upgrade over poisoned cache

Separately reproduce the poisoned v86.202 installation, then install v86.203 as
an in-place upgrade without deleting the app. Capture fresh CDP/unified logs.
This determines whether prevention also lets normal Script loading repair or
bypass old entries.

Current result: **pending physical device**. Whether a separate one-time,
version-gated memory/disk HTTP-cache-only migration is needed is unknown. Do
not add that migration to v86.203. If clean Test A passes but Test B remains
frozen, propose it in a later version while preserving cookies, localStorage,
sessionStorage, IndexedDB, and authentication state.
