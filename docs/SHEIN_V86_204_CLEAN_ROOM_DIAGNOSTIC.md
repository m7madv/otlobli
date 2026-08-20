# SHEIN v86.204 clean-room diagnostic browser

Status: implementation candidate. Local TypeScript/static guards pass. Xcode,
GitHub artifact, IPA inspection, and all physical-device modes remain pending
until recorded below. This document does not claim that the SHEIN freeze is
fixed.

## 1. Preflight state

- Source worktree before changes:
  `C:\Users\MOHAMMAD\Projects\otlobli-ios-v86-203-shein-prefetch-cache-fix`
- Source branch: `codex/ios-v86-203-shein-prefetch-cache-fix`
- Source HEAD: `de255a935ce3a985c05694f36899ff34d7585103`
- Source status: clean.
- Latest physically tested evidence source: `86.202/1064`, branch
  `codex/ios-v86-202-root-cause-timeline-diagnostic`, preserved HEAD
  `2d7332cd5b6a3a3d87b4d1bab32efe8cb9919df0`.
- Latest built but not physically tested source: `86.203/1065`, application
  behavior commit `c914b52c2dbc539a196d4d74385b350fffd20577`.
- Protected branches were not reset, rebased, merged, moved, or deleted.

Protected diagnostic history remains:

- `codex/ios-v86-193-passive-native-foreground` at
  `a6e0ca943c4d9a2722b5962a4193d3e34d2da248`.
- `codex/ios-v86-194-root-cause-diagnostic` at
  `9a91e9f6680d1dce48ae5a04bfe6544d8d26b954`.
- v86.202 evidence branch at preserved HEAD `2d7332c`.
- v86.203 behavior commit `c914b52`.

## 2. Isolated branch and worktree

- Branch: `codex/ios-shein-clean-room-browser`
- Worktree: `C:\Users\MOHAMMAD\Projects\otlobli-ios-shein-clean-room-browser`
- Base: exact handoff commit `de255a935ce3a985c05694f36899ff34d7585103`.

No local or remote branch with this name, no target worktree directory, and no
`86.204`/`1066` marker existed before creation.

## 3. Version and build

- Marketing version: `86.204`
- Build number: `1066`
- Diagnostic marker: `2026.08.21-v86.204-shein-clean-room`
- Feature flag: `VITE_SHEIN_CLEAN_ROOM_DIAGNOSTICS`; it defaults to `true` on
  this diagnostic branch and must be explicitly `false` for a customer build.

## 4. Architecture

The clean module is parallel to the legacy plugin:

```text
OtlobliBridgeViewController
├── OtlobliSheinBrowserPlugin          legacy control, unchanged
└── SheinCleanBrowserPlugin            diagnostic selector/session boundary
    ├── SheinCleanModeSelectorViewController
    └── UINavigationController (full screen)
        └── SheinCleanBrowserViewController
            └── exactly one WKWebView
```

The clean controller is presented normally and dismissed normally. It is never
parked behind the Capacitor WebView, detached/re-attached, hidden at 1×1,
reloaded, recreated during a session, or switched to Temu. Its native chrome
owns Close, Back, and the optional capture button. Back calls `goBack()` only
when WebKit has a back item and the current path is not a canonical SHEIN root.

The controller owns its `WKWebView`, `WKNavigationDelegate`, `WKUIDelegate`,
message handlers, mode, run identity, navigation identity, website-data
identity, and diagnostics. A WebContent termination is logged only; no recovery
action runs.

The clean plugin ignores the URL/options supplied by the legacy host and loads
the public guest landing URL `https://m.shein.com/`. It rejects host `setUrl`
and `executeScript`, acknowledges `postMessage` without evaluating it, and
never clears a mode container. Host region changes, readiness recovery,
foreground VPN recovery, and post-load production-script dispatch are skipped
while a clean session is active. Mode 5 delegates the original full options to
the legacy plugin.

## 5. Locked mode implementation

| Mode | Foundation | Cache guard | Capture | Blocking | Browser |
| --- | --- | --- | --- | --- | --- |
| RAW | unguarded RAW | absent | absent | absent | clean controller |
| RAW_WITH_CACHE_GUARD | RAW | attached before WKWebView | absent | absent | clean controller |
| CAPTURE_ONLY | unguarded RAW | absent | enabled | absent | clean controller |
| BLOCKING_ONLY | unguarded RAW | absent | absent | enabled | clean controller |
| CAPTURE_AND_BLOCKING | unguarded RAW | absent | enabled | enabled | clean controller |
| LEGACY_BROWSER_CONTROL | legacy-owned | legacy-owned | legacy-owned | legacy-owned | unchanged legacy plugin |

Capture and Blocking deliberately start from unguarded RAW in the first IPA.
Physical evidence has not proved that the guard is required and working, so it
is not silently promoted into those modes. If RAW fails and guarded RAW passes,
finish Tests 0/1 first and prepare a later evidence-driven foundation change
before Tests 2–4.

The selected mode is immutable for the browser lifetime. Changing modes always
dismisses the one controller and begins a new session from the selector; no
script is enabled or disabled inside an existing document.

## 6. Website-data isolation

Each clean mode uses a persistent iOS 17+ `WKWebsiteDataStore(forIdentifier:)`
profile before the WKWebView is created:

| Mode | Persistent identifier |
| --- | --- |
| RAW | `720b1500-0a4b-4a00-9000-000000000000` |
| RAW_WITH_CACHE_GUARD | `720b1500-0a4b-4a00-9000-000000000001` |
| CAPTURE_ONLY | `720b1500-0a4b-4a00-9000-000000000002` |
| BLOCKING_ONLY | `720b1500-0a4b-4a00-9000-000000000003` |
| CAPTURE_AND_BLOCKING | `720b1500-0a4b-4a00-9000-000000000004` |
| LEGACY_BROWSER_CONTROL | the legacy default store, not shared with a clean profile |

This preserves RAW cache across process kills while preventing one mode from
inheriting another mode's cache/cookies/storage. Clean modes explicitly fail on
iOS below 17 instead of falling back to a shared default or nonpersistent
store. The selector displays the exact container identity. No test step clears
a profile between its cold-launch cycles.

## 7. Exact RAW configuration

RAW constructs:

- one default-user-agent `WKWebView`;
- its dedicated persistent profile;
- one passive diagnostic `WKUserScript` at document start/main frame only;
- two passive native diagnostic handlers;
- default WebKit navigation;
- Web Inspector access (`isInspectable=true`) in this diagnostic branch;
- native Close and guarded Back controls.

RAW does not install the capture or blocking module, the content rule, mobile
bridge, `SHEIN_CAPTURE_SCRIPT`, session/region code, navigation bootstrap,
privacy compatibility code, login code, product-tap fallback, history wrapper,
text-selection suppression, synthetic input, reload/recovery, or legacy runtime
bundle.

The passive probe follows the v86.202 limits: one 400 ms heartbeat, one
aggregated one-second report, a detached Text-node MutationObserver heartbeat,
passive trusted-click reaction, real error/rejection/resource/CSP observation,
resource timing, root fingerprint, and lifecycle observation. It does not patch
console, XHR, fetch, history, events, or storage and does not mutate page DOM.

## 8. Exact cache-guard rule

`RAW_WITH_CACHE_GUARD` differs from RAW only by this rule, compiled and added to
the user-content controller before WKWebView creation and the first request:

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

Identifier:
`com.otlobli.shein.clean.raw-js-prefetch-block.v1`. A missing content-rule store,
compile failure, or missing compiled rule rejects the open. `script` is not in
the rule and XHR/fetch are not monkey-patched.

## 9. Clean capture module

The capture module is a new small document-start module with one per-document
guard and version `1.0.0`. It adds no observer, timer, listener, CSS, click
interceptor, history wrapper, or navigation behavior. The native `Add to
Otlobli` button invokes one bounded snapshot only on explicit user intent.

The snapshot:

- recognizes a product only from the `-p-<id>` path or exact product metadata;
- reads title/image/price/currency from exact metadata or two narrow price
  fallbacks;
- reads color/size only from exact semantic selected-radio containers;
- emits protocol version, module version, `documentId`, native `navigationId`,
  product/SKU, and an origin+path link with no query/fragment;
- sends the existing structured `addToCart` message to Otlobli.

If no product/title exists, native UI reports that fact and sends nothing. It
does not guess a first variant or synthesize a click.

## 10. Clean blocking module

Business scope is deliberately one category: confirmed semantic SHEIN native
purchase controls, so a shopper cannot enter SHEIN checkout outside Otlobli.
The allowlist contains only exact English/Arabic `aria-label` values and the
exact `product-detail-add-to-bag` test ID. It contains no wildcard class search.

The module uses one document guard and an event-driven MutationObserver. Each
callback inspects at most 48 added nodes and at most 32 exact matches per root.
It marks and hides only a matched purchase control and reports only category,
count, and sanitized path. Cleanup disconnects the observer on `pagehide`.

It has no global click handler, `preventDefault`, propagation stop,
`pointer-events` change, login/risk/privacy selector, main-root change, or broad
CSS.

## 11. Diagnostics and privacy

All native records use `[OTLOBLI_SHEIN_CLEAN]` and include run/mode/app PID,
browser/WebView/navigation identities, persistent-profile identity, rule state,
navigation lifecycle, sanitized path, lifecycle/hierarchy, WebContent
termination, and safe web-probe data. Public WebKit does not expose WebContent
PID, so it is explicitly recorded as `unavailable-public-api`; CDP target
identity supplies the external process boundary when available.

The external CDP recorder records every matching asset's type, initiator,
status, MIME, encoded/transfer/body length, completion/failure, blocked reason,
and following ChunkLoadError. It stores body length/SHA-256/executable-body
classification, not body content. URLs are reduced to origin+path and all
headers, cookie values, authorization/token/signature fields, storage values,
addresses, and account data are excluded.

## 12. Automated proof commands

```powershell
npm run verify:shein-clean-room
npm run verify:shein-freeze-guard
npx tsc -b
git diff --check
```

The clean-room guard proves:

- exact six-mode identities;
- RAW's diagnostic-only user-script list;
- capture/blocking conditional independence;
- exact raw-only rule and absence of a Script rule;
- guest URL, one-WebView/root-Back/termination boundaries;
- persistent per-mode identifiers and iOS availability failure;
- host region/recovery/script isolation;
- version/project membership;
- byte-for-byte unchanged legacy Swift implementation using SHA-256
  `6a6d6a16a5eed040618988c9d5b5ac6d8f88ddd187f4bc095c0f1c1aa710382e`.

The blocking source is checked for login/captcha/privacy/risk selectors, global
event cancellation, and pointer-event changes. The entire clean source is
checked for old runtime-bundle markers. This is source proof only; IPA
inspection must repeat it against the final archive.

## 13. Exact physical-device test instructions

Use the same iPhone 16 Pro Max/iOS 27 beta when possible. Sign the single
v86.204 IPA through the owner's normal path. Enable the same working VPN before
LEGACY_BROWSER_CONTROL comparisons; the clean menu itself does not make browser
decisions from the old VPN/region host state.

1. Delete any older Otlobli install once, then install v86.204.
2. Enable Settings → Safari → Advanced → Web Inspector and trust the host.
3. Mount the developer image and start one continuous native log:

   ```powershell
   & 'C:\Users\MOHAMMAD\.codex\tools\ios-usb-diagnostics\Scripts\pymobiledevice3.exe' mounter auto-mount --userspace
   & 'C:\Users\MOHAMMAD\.codex\tools\ios-usb-diagnostics\Scripts\pymobiledevice3.exe' syslog live --userspace --subsystem com.otlobli.app --category SheinCleanBrowser --label --out 'C:\Users\MOHAMMAD\Desktop\Otlobli-v86.204-clean-room-native.log'
   ```

4. Expose the existing iOS Web Inspector bridge at `http://127.0.0.1:9222`.
5. Open Otlobli → SHEIN. The native selector appears before SHEIN. Select a
   mode and copy its `runId` and exact container identity from the native log.
6. Start a separate CDP file for that locked run (example RAW):

   ```powershell
   npm run capture:shein-clean-room -- --endpoint=http://127.0.0.1:9222 --mode=RAW --run-id=<RUN_ID> --container=720b1500-0a4b-4a00-9000-000000000000 --output='C:\Users\MOHAMMAD\Desktop\v86.204-raw-cdp.jsonl'
   ```

7. For RAW: browse Home, three categories, five products, Back from products,
   Close, reopen RAW, background/foreground, App-Switcher kill, and cold launch.
   Repeat ten kill/cold-launch cycles without reinstalling or clearing RAW.
8. Repeat the identical sequence in RAW_WITH_CACHE_GUARD using its different
   container and evidence filenames.
9. Do not start Tests 2–4 until the RAW foundation decision is known. If RAW is
   stable, run CAPTURE_ONLY and test metadata, color/size selection, native Add,
   and the Otlobli cart row. Run BLOCKING_ONLY and verify only the confirmed
   purchase controls disappear. Then run CAPTURE_AND_BLOCKING with ten cold
   launches, categories, search, ten products, product/root Back, natural login,
   Back from login, Close/reopen, background/foreground, Otlobli cart, store
   chooser, and Temu unaffected.
10. Run LEGACY_BROWSER_CONTROL last with the shortest reproduced sequence under the
    same VPN/remote state. Do not clear or share a clean mode's profile.
11. If SHEIN naturally shows login/risk/verification, record it and use native
    Back/Close. Do not bypass, hide, auto-close, or classify it as a browser
    failure without the network/runtime evidence.

## 14. Decode and analyzer commands

Stop the recorder with Ctrl+C, then:

```powershell
npm run decode:shein-clean-room -- 'C:\Users\MOHAMMAD\Desktop\Otlobli-v86.204-clean-room-native.log' > 'C:\Users\MOHAMMAD\Desktop\v86.204-clean-native.jsonl'
npm run analyze:shein-clean-room -- 'C:\Users\MOHAMMAD\Desktop\v86.204-raw-cdp.jsonl' --native='C:\Users\MOHAMMAD\Desktop\v86.204-clean-native.jsonl' --output='C:\Users\MOHAMMAD\Desktop\v86.204-raw-report.json'
npm run analyze:shein-clean-room -- 'C:\Users\MOHAMMAD\Desktop\v86.204-guard-cdp.jsonl' --native='C:\Users\MOHAMMAD\Desktop\v86.204-clean-native.jsonl' --output='C:\Users\MOHAMMAD\Desktop\v86.204-guard-report.json'
```

The report answers whether RAW reproduced poisoning, whether the guard blocked
only speculative raw/XHR requests, whether Script loads continued, whether
their bodies remained executable, and whether `#shein-branch` was reached.
Inspect the ordered requests as well; an aggregate final state is not by itself
a causal proof.

## 15. Causal result matrix template

| Observation | Strict conclusion | Result/evidence |
| --- | --- | --- |
| RAW fails with bodyless-304 + ChunkLoadError; guarded RAW passes | Cache poisoning is independent of legacy scripts and the narrow guard prevents the captured mechanism | Pending |
| RAW and guarded RAW fail with the same ChunkLoadError | Rule classification/path mismatch or another affected asset; inspect actual request before changing rule | Pending |
| RAW fails without ChunkLoadError | A separate SHEIN/WebKit mechanism exists; report earliest divergence | Pending |
| RAW stable; legacy freezes | Legacy hosting/lifecycle/injected runtime is required | Pending |
| RAW foundation passes; CAPTURE_ONLY fails | The first causal capture operation is responsible | Pending |
| RAW foundation passes; BLOCKING_ONLY fails | The exact first selector/mutation is responsible | Pending |
| Capture and Blocking pass alone but fail together | The two clean modules interact; locate first observer/selector/timing conflict | Pending |
| All clean modes pass; legacy fails | Propose a separate flagged production migration; do not delete legacy yet | Pending |

## 16. Delivery fields still pending

- Final changed-file list: populate from the final commit.
- Build/test results: local gates in progress; Xcode/physical pending.
- Commit hash: pending.
- GitHub Actions run: pending.
- Artifact ID: pending.
- IPA path/size/SHA-256: pending.
- Physical causal matrix: pending.

No production replacement or legacy deletion is authorized by this diagnostic
implementation.
