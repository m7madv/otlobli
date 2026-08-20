# SHEIN v86.202 captured root-cause report

Capture date: 2026-08-20

## Verdict

The captured cold-launch freeze has a proven resource/cache causal sequence. It
is not a dead touch surface, stopped JavaScript scheduler, hidden document,
BFCache restoration, duplicate browser, or terminated WebContent process.

On the working launch, SHEIN loaded these required Webpack chunks as real
`Script` resources with HTTP 200 JavaScript bodies:

- `68498-29797320c657aeb6f070.js`: 4,451 encoded bytes;
- `26652.9fad62278dae07661792.js`: 5,361 encoded bytes.

After the page became functional, SHEIN's own `prefetchJs` implementation
requested the same canonical `.js` URLs again as `XMLHttpRequest`. WebKit does
not support `rel=prefetch` in this WKWebView, so SHEIN deliberately selected its
XHR fallback. The CDN answered those revalidation requests with HTTP 304 and no
JavaScript response body. SHEIN's prefetch code considers both 200 and 304 a
successful prefetch.

On the next cold process, the initial `<script>` loads for the same canonical
URLs received HTTP 304 with no executable body. WebKit first exposed an empty
MIME type, then `text/plain` on the bounded retries. SHEIN immediately raised
genuine `ChunkLoadError` rejections, never completed its application hydration,
and remained at root `#app` rather than the working `#shein-branch`. Trusted
touch input continued to arrive, but there was no healthy SHEIN application
runtime left to handle it.

The on-device WebKit network-cache records corroborate the transition: both
canonical chunk records contain `text/plain` metadata and neither has a body
blob. This is the mechanism behind the observed "first launch works, next cold
entry renders but freezes" phenotype: SHEIN's XHR prefetch/revalidation and
WKWebView's shared canonical resource cache combine to replace or persist a
bodyless representation that the next process cannot execute.

This report proves the cause of the captured v86.202 cold-launch freeze. It
does not claim that every possible future SHEIN freeze must have the same
cause. It also does not prove whether any conditional Otlobli `clearCache()`
path ran before some older reports, because v86.202 did not log that call.

## 1. Repository, version, and artifact identity

- Worktree: `C:\Users\MOHAMMAD\Projects\otlobli-ios-v86-202-root-cause-timeline-diagnostic`
- Branch: `codex/ios-v86-202-root-cause-timeline-diagnostic`
- Exact behavioral baseline: v86.201 commit
  `0b462a93030b5c7114012d5848ce61eac49b8b17`
- Diagnostic application code commit:
  `a56c2e3d342eee285bde1659064ef6204ca1b8b5`
- Pre-capture documentation HEAD:
  `b8f17f4ac038318cabd4a0fefdfadd3d4de107f8`
- Version/build: `86.202/1064`
- GitHub/Xcode run: `32402979859`
- Artifact ID: `9419317843`
- IPA:
  `C:\Users\MOHAMMAD\Desktop\otlobli-ios-v86.202-root-cause-timeline-diagnostic\otlobli-v86.202-ipad-iphone-universal-unsigned.ipa`
- IPA SHA-256:
  `8F93DD8390DBF454070AFA709B631C69FCB6D19BB188C6E75F11D78C17489548`

Device:

- iPhone 16 Pro Max (`iPhone17,2`)
- iOS 27.0 beta (`24A5380h`)
- UDID `00008140-001E6D581E11801C`

The protected v86.193 and v86.195 diagnostic history was not reset, rewritten,
merged, or modified by this capture.

## 2. Exact diagnostic additions

The diagnostic application added one document-start probe,
`window.__otlobliRootCauseProbe`, and correlated Swift logging. It records:

- run, PID, browser, WebView, navigation, and document identities;
- page lifecycle and BFCache metadata;
- Promise, microtask, timeout, interval, rAF, MutationObserver, and
  MessageChannel heartbeats;
- bounded real interaction targets and +50/+250/+1000 ms reaction snapshots;
- safe DOM/runtime fingerprints;
- cookie/storage key metadata, IndexedDB names/versions, Cache Storage names,
  and Service Worker metadata;
- real JavaScript errors, rejections, resource errors, CSP violations, and
  resource timing;
- native hierarchy, visibility, interaction, gesture, history, navigation,
  website-data-store, and WebContent-termination state;
- `isInspectable=true` for passive Web Inspector/CDP capture.

Post-build forensic utilities added or extended in this worktree:

- `scripts/capture-shein-cdp-network.mjs` passively auto-attaches to the iOS
  Web Inspector bridge and records Network, Runtime, Log, and Page events;
- `scripts/analyze-shein-cdp-network.mjs` compares the relevant chunk responses,
  completion sizes, and real `ChunkLoadError` records across sessions;
- `scripts/decode-shein-root-cause-log.mjs` and
  `scripts/analyze-shein-root-cause.mjs` accept explicit output paths so raw
  evidence does not need shell redirection.

## 3. Passivity proof

The v86.202 app does not include a freeze fix. Its probe:

- does not call `preventDefault`, `stopPropagation`, or synthetic click APIs;
- does not patch `fetch`, `XMLHttpRequest`, console, or history;
- does not navigate, reload, hide, show, detach, reattach, recreate, or close
  the WebView;
- does not change cookies, local/session storage, IndexedDB, Cache Storage,
  Service Workers, the website data store, or cache policy;
- does not modify the SHEIN DOM; the MutationObserver heartbeat changes a
  detached Text node only;
- does not contain the contaminated v86.194/v86.195 tap context or reference
  `SHEIN_REQUIRED_COUNTRY`.

The CDP recorder enables read-only protocol domains and records events. It does
not enable cache disabling, request interception, emulation, or debugger pause.
The WebDAV/AFC cache access was read-only. No website data was cleared.

## 4. First-good timeline

CDP session `9C92FE1A-8FDD-4130-832B-D8E867EF42E1` attached at
`2026-08-20T19:14:34.080Z`.

| Time (UTC) | Evidence |
| --- | --- |
| 19:14:34.913 | Initial Script request for chunk 68498. |
| 19:14:34.914 | Initial Script request for chunk 26652. |
| 19:14:34.989 | Chunk 26652: HTTP 200, `application/javascript`, completed with 5,361 encoded bytes. |
| 19:14:35.004–.006 | Chunk 68498: HTTP 200, `application/javascript`, completed with 4,451 encoded bytes. |
| 19:14:38.153 | SHEIN `prefetchJs` begins XHR prefetches for canonical asset URLs, including chunk 68498. |
| 19:14:39.229–.535 | Chunks 68498 and 26652 prefetch XHRs receive HTTP 304 and finish with zero body bytes. |
| 19:14:41.632–.690 | SHEIN repeats both XHR prefetches; both receive HTTP 304 again and complete with only 87/72 transport bytes, not JavaScript bodies. |

There were 46 SHEIN `.js` XHR prefetch requests in this working session: 22
responses were 200 and 24 were 304. Their initiator stacks converge on
`prefetchJs` in SHEIN CDN chunk
`33851-0d6c66ff1c7d0b5cfd35.js`.

The working runtime reached `#shein-branch`, product navigation worked, and 13
of 15 bounded interaction-reaction snapshots detected a URL/path/history/root
change.

## 5. Frozen timeline

After App Switcher termination, CDP session
`208D87C4-9ABA-4A29-A364-DC10147FB319` attached at
`2026-08-20T19:15:44.111Z`.

| Time (UTC) | Evidence |
| --- | --- |
| 19:15:45.044–.045 | New-process Script requests for the same two canonical chunks. |
| 19:15:45.104–.107 | Both Script requests receive HTTP 304, empty MIME, and complete with zero body bytes. |
| 19:15:45.160 | Genuine SHEIN `ChunkLoadError` entries for chunks 68498 and 26652, only 53–56 ms later. |
| 19:15:48.038–.039 | SHEIN performs bounded Script retries. |
| 19:15:48.066–.083 | Both retries receive HTTP 304 as `text/plain`; completion sizes are only 196/83 transport bytes. The same `ChunkLoadError` entries repeat. |

The frozen document never reached the stage that schedules SHEIN's 46 XHR JS
prefetches. It was already broken while trying to load the required chunks.
The page completed HTML lifecycle events and remained visually rendered, but
its application root stayed `#app` with structure hash `87ea8993`.

A separate unified-log capture of the same phenotype independently recorded
the same errors while `document.readyState` was still `interactive`, before the
page's `load` event:

- chunk 68498 at performance time 1,976–1,977 ms;
- chunk 26652 at performance time 1,977 ms;
- the same errors again at 4,956–4,959 ms after the retry.

## 6. Earliest divergence

The earliest measured good-versus-frozen divergence is the body of the initial
required Script response:

| Resource | Working cold entry | Frozen cold entry |
| --- | --- | --- |
| chunk 68498 | 200, JavaScript, 4,451 encoded bytes | 304, no executable body, then `text/plain` retry |
| chunk 26652 | 200, JavaScript, 5,361 encoded bytes | 304, no executable body, then `text/plain` retry |

This divergence precedes the first `ChunkLoadError`, page `load`, user touches,
store navigation, and visible report of the freeze. It is therefore causal,
not merely correlated with the final inert state.

## 7. Event-loop health

All seven schedulers remained healthy in the frozen snapshot:

| Heartbeat age | Working | Frozen |
| --- | ---: | ---: |
| Promise | 158 ms | 351 ms |
| `queueMicrotask` | 158 ms | 351 ms |
| `setTimeout` | 149 ms | 344 ms |
| `setInterval` | 158 ms | 351 ms |
| `requestAnimationFrame` | 144 ms | 351 ms |
| MutationObserver | 158 ms | 351 ms |
| MessageChannel | 157 ms | 350 ms |

No heartbeat was stale. The probe continued for hundreds of samples. This
rules out a stopped JavaScript event loop or WebKit scheduling suspension as
the captured root cause.

## 8. Page lifecycle comparison

Both documents were new, visible, online, and completed normal document
lifecycle:

- `DOMContentLoaded`, `load`, and `pageshow` fired;
- `pageshow.persisted=false`;
- `document.wasDiscarded=false`;
- `document.visibilityState=visible` and `document.hidden=false` in the frozen
  snapshot;
- the frozen document reported focus and the native app/scene were active.

No `pagehide`, `freeze`, or BFCache restore preceded the frozen state. Focus
differences are not causal: the working page could navigate while unfocused,
whereas the frozen page was focused and still inert.

## 9. SHEIN click-reaction comparison

Working process PID 26295:

- 33 bounded pointer/touch/click events recorded;
- 28 were trusted and all 33 were initially `defaultPrevented=false`;
- 15 delayed reaction groups were retained, and 13 changed path, URL, history,
  or root fingerprint;
- product navigation and return-to-home were observed.

Frozen process PID 26316:

- 60 bounded events recorded;
- 47 were trusted and all 60 were initially `defaultPrevented=false`;
- `elementFromPoint` and the event target were real SHEIN product images;
- all 45 delayed reaction snapshots showed no path, URL, history, or root
  change.

Input reached the DOM. The missing chunk runtime explains why SHEIN produced
no application reaction.

## 10. Native view hierarchy comparison

At both the working and frozen labeled snapshots:

- exactly one PID/browser/WebView existed in that process;
- the WebView and WebKit content surface had windows and superviews;
- both were visible, alpha 1, and interaction-enabled;
- WebView frame was `0,62,440,894`;
- surface frame was `0,0,440,956`;
- app and scene state were active;
- no loading cover was present;
- no second WebView, close-before-freeze, or
  `webViewWebContentProcessDidTerminate` occurred.

The expected object identities differ between the two cold processes. There
is no same-process duplicate or stale parked surface in the frozen process.

## 11. Navigation and BFCache comparison

Both compared top-level loads were ordinary new navigation:

- native navigation type: `other` for initial main-frame policy;
- Performance Navigation Timing type: `navigate`;
- new `documentId` and new process/WebView identity after App Switcher kill;
- `pageshow.persisted=false` and `wasDiscarded=false`;
- frozen main page completed `didStart`, `didCommit`, and `didFinish`;
- frozen back list count was zero.

The captured cold freeze is not a back-forward entry, reload, SPA popstate, or
BFCache-restored document. The earlier unsafe root-Back behavior was a real
trigger and remains correctly guarded, but it is not this cold-launch cause.

## 12. Storage and session metadata

The good/frozen snapshots differed in expected per-page session metadata, but
none precedes the proven chunk failure:

- cookies: 6 versus 5 names; `branchpwarar` was absent on frozen home;
- localStorage: 53/~76,578 characters versus 54/~83,800;
- sessionStorage: 45/~71,945 versus 19/~1,448, expected for a new home
  document versus a browsed PDP session;
- both had the same six IndexedDB database names/versions;
- both had no Cache Storage names;
- Service Worker was unsupported and no registrations/controllers existed.

There was no auth/risk/challenge redirect in the failing navigation. Storage
differences remain secondary evidence, not the cause of this capture.

## 13. Real JavaScript, network, and cache evidence

The diagnostic-contamination hash `3ce0b2a11d15fff2` did not occur and is not
part of this causal chain. The decisive errors are genuine SHEIN Webpack
rejections with full chunk URLs and stacks through SHEIN's runtime.

CDN metadata captured on the working and frozen requests:

- `Cache-Control: public, max-age=691200` (eight days);
- chunk `68498` Age approximately 1,103,713 seconds;
- chunk `26652` Age approximately 1,235,891 seconds;
- both CDN objects were already older than their eight-day freshness period,
  making conditional revalidation expected;
- the CDN correctly returned 304 with no body, which is safe only when the
  client retains a valid cached body for that canonical resource.

SHEIN source behavior, observed in official CDN chunk
`33851-0d6c66ff1c7d0b5cfd35.js`:

1. `prefetchJs` tests `link.relList.supports(relType)`.
2. Runtime evaluation on the frozen WKWebView returned:
   `prefetch=false`, `preload=true`, and no `prefetchViaByAjax` override.
3. For unsupported `prefetch`, SHEIN issues `XMLHttpRequest GET` to the same
   canonical JavaScript URL.
4. Its `onload` resolves both HTTP 200 and HTTP 304 as success.

On-device cache records:

- 68498 record ID:
  `422B6E31BCDB2E6B8D6B5772531161AF36209677`
- 26652 record ID:
  `D476CCEE3937275E0F18598B185FFF7C2152B26A`
- cache partition:
  `Library/Caches/WebKit/NetworkCache/Version 17/Records/8C268DEB2D2E1CDCB4C6E3E73BF2DF14D22EBFCA/Resource`
- both records contain their canonical URL, 304-era headers, and MIME
  `text/plain`;
- both corresponding `-blob` resources were absent/404.

Preserved copies:

- `C:\Users\MOHAMMAD\Desktop\Otlobli-v86.202-frozen-network-cache\68498-cache-record.bin`
  — 13,085 bytes — SHA-256
  `93673AE71EC2ED5870A7D207EFD2DACC969FE155787BA33D1A0FD59DD68B70AF`
- `C:\Users\MOHAMMAD\Desktop\Otlobli-v86.202-frozen-network-cache\26652-cache-record.bin`
  — 13,085 bytes — SHA-256
  `A346B7B024D3A2F83BBD33D80494A51B9867F8BE13263E6B78FA1B7491B5E4F5`

## 14. Ranked hypotheses after capture

| Rank | Hypothesis | Result | Evidence |
| ---: | --- | --- | --- |
| 1 | SHEIN XHR prefetch + stale 304 + shared WKWebView canonical cache leaves required chunks bodyless | Proven for captured freeze | Good 200 bodies → SHEIN XHR 304s → device bodyless/text-plain records → next Script 304/no body → immediate `ChunkLoadError` → inert `#app`. |
| 2 | Generic SHEIN SPA/runtime failure | Consequence, not initiator | Runtime does not hydrate because required chunks are missing. |
| 3 | Session/auth/risk state | Weakened | No challenge redirect; same IndexedDB/Service Worker state; resource failure occurs first. |
| 4 | Page lifecycle or scheduling mismatch | Ruled out for capture | Visible/focused page and seven healthy heartbeat types. |
| 5 | Native hosting/parked hierarchy | Ruled out for capture | Fresh cold process, attached visible interactive single WebView/surface. |
| 6 | BFCache/history restoration | Ruled out for capture | New navigate/document/process, `persisted=false`, zero back list. |
| 7 | Duplicate/mistimed Otlobli injection | Ruled out for capture | One probe installation and three expected user scripts; chunk failure precedes interaction. |
| 8 | Input interception/overlay | Ruled out for capture | Trusted events reached expected elements, initially unprevented. |
| 9 | `forceStoreVpnRecheck()` race | Real separate defect, not this capture | No browser close/duplication before the resource failure. |

The fact that old app builds can now exhibit the same first-good/next-frozen
behavior is consistent with this result: the triggering SHEIN/CDN asset and
prefetch behavior is remote and shared across those builds.

## 15. Minimal fix proposed, not implemented

The narrowest evidence-based candidate is to prevent only SHEIN's XHR/raw
prefetch requests for hashed JavaScript assets from writing/revalidating the
same canonical cache entries used by actual Script loads. Real Script requests
must remain untouched.

The preferred first implementation experiment is a native
`WKContentRuleList`, installed before the SHEIN WebView loads, restricted to:

- domain `sheinm.ltwebstatic.com`;
- path `/pwa_dist/assets/*.js`;
- resource type `raw` (and only expand to `fetch` if device evidence shows the
  XHR classification requires it);
- action `block`.

This uses WebKit's own resource-type filtering and avoids a JavaScript
`XMLHttpRequest` monkey patch, synthetic input, reload, browser recreation,
website-data clearing, cookie/session changes, or lifecycle changes. It should
block the speculative XHR prefetch only; actual `Script` resources continue to
load and cache normally.

This candidate is not implemented in v86.202. Before release it must be proved
with CDP and physical testing:

1. first launch receives required Script bodies and has zero chunk errors;
2. no `.js` XHR/raw prefetch reaches the canonical asset URLs;
3. ten App Switcher kill/cold-launch cycles remain interactive;
4. category, search, PDP, Back, login, cart, and store-picker flows pass;
5. no actual `Script` request is blocked;
6. CDN changes or non-hashed script URLs do not broaden the rule unexpectedly.

Changing the main request cache policy is not an adequate fix because the
failure is in subresources. Clearing all website data, reloading after failure,
rebuilding the browser, or switching stores would mask or recover the symptom
but would not prevent the proven cache poisoning sequence.

## Preserved evidence

- Raw unified log:
  `C:\Users\MOHAMMAD\Desktop\Otlobli-v86.202-root-cause-raw.log`
  — SHA-256
  `C631A88843ECEE42FCE6A52F21837A99B9F6798B1421D210C9689EB4951E9C67`
- Decoded unified log:
  `C:\Users\MOHAMMAD\Desktop\Otlobli-v86.202-root-cause-decoded.jsonl`
- Runtime transition report:
  `C:\Users\MOHAMMAD\Desktop\Otlobli-v86.202-transition-working-vs-frozen-report.json`
  — SHA-256
  `6C1ADFF5B3EBB96E4D3B9A58BB3C3B873A161FF9D6EC539A3BFC5C16B34B511A`
- Raw CDP network capture:
  `C:\Users\MOHAMMAD\Desktop\Otlobli-v86.202-cdp-network.jsonl`
  — SHA-256
  `0C10A637A91E804816CAA8FF6294CDC2C693BA1351D6DDF30EC25BEE63E27A3D`
- CDP comparison report:
  `C:\Users\MOHAMMAD\Desktop\Otlobli-v86.202-cdp-working-vs-frozen-report.json`
  — SHA-256
  `BEC5CA6F15DC827469FED6F83BBB7D17F46E471A51487C2E51F67DFF5921F2D7`
