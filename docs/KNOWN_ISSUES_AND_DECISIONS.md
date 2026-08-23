# Otlobli — سجل المشاكل والقرارات الدائم

## v86.229 — Temu Back follows the iOS WebView URL event (2026-08-24)

- **Physical evidence:** v86.228 fixed the reported SHEIN Qatar region issue.
  In the remaining 58.54-second Temu recording, native Back is present on first
  entry, correctly hidden on the PDP, and absent after the PDP returns to the
  listing/Home surface.
- **Cause:** native provisional navigation hides the button. v86.224 re-published
  it only from `didFinish` and `pageshow`, but Temu's SPA product/Home history
  changes `WKWebView.url` without guaranteeing those callbacks.
- **Decision:** the existing URL KVO branch re-publishes the current document's
  deduplicated Back state. This is the authoritative event boundary; do not add
  a timer, route polling, DOM observer, reload, or duplicate HTML/native button.
- **Boundary:** preserve Temu-owned inner navigation, root-only Otlobli exit,
  SHEIN v86.228 region/policy behavior, lifecycle timing, transactions, and
  orders. Signed run `32667383788` delivered exact `86.229 (1094)` internally as
  `VALID`/`IN_BETA_TESTING` with no public submission. Builds and distribution
  prove packaging only; real iPhone product → Back → Home acceptance remains
  pending.

## v86.224 — prepare SHEIN region on Home; republish Temu Back natively (2026-08-23)

- **Physical evidence:** `86.223 (1088)` improved some Temu speed/blocking but
  still loses native Back after product -> Home, and did not fix SHEIN region.
  This rejects JS `pageshow` alone and the existing Add/product-oriented region
  topology.
- **Recovered reference:** commit `9cea927` (`v86.68`) is the remembered fast
  path: use SHEIN Home's semantic area selector to complete a signed address
  before product browsing. The later product-spinner incidents do not require
  abandoning Home preparation; they require keeping it out of PDP navigation.
- **Region decision:** every queued SHEIN product enters the configured Home
  first and waits for full signed coordinator readiness before same-document
  PDP navigation. Remove the Home-repair bypass. Normal PDP browsing cannot
  start repair; explicit Add remains a fail-closed fallback.
- **Temu decision:** native provisional navigation owns the hide, so native
  `didFinish` owns one state republish from the completed document. This is an
  event, not a new retry/timer/polling/scan mechanism.
- **Performance decision:** confirmed Temu product identity ends repeated
  vitals/blank checks. Unreachable diagnostics, header-wake restoration,
  forced scroll/resize, and entry cleaner waves stay deleted.
- **Boundary:** do not change the protected native recompose timing, active-
  region equality check, payment/wallet/order completion, or backend. Local
  gates pass. Run `32657648658` delivered exact `86.224 (1089)` internally as
  `VALID`/`IN_BETA_TESTING` without public submission; real iPhone acceptance
  remains pending.

## v86.223 — retire temporary diagnostics and use one production path (2026-08-23)

- **Physical result:** the user reports the v86.222 tested flow is working and
  explicitly requests a clean App Store release. This is functional acceptance
  of the reported issue, not evidence that the separately required five resume
  cycles/cold launch or weak-Android test was performed.
- **Production decision:** delete the flight recorder, build flag/alias/input,
  host state/listeners, standalone freeze/tap/price/region probes, injected
  region logging, and the rejected document-start protection scans/timer.
  There is now one runtime composition, matching v86.222 customer defaults.
- **Preserved behavior:** document-start viewport/bar, post-load blockers,
  capture/add, session, native iOS Back, SHEIN-owned product navigation, and
  Add-only signed-region repair remain. Do not restore early DOM scans or
  diagnostic feature switches.
- **Release path:** `86.223/1085` adds an explicit App Store review action after
  signed upload/processing. It may create/link the version and submit it, but
  must surface missing Apple metadata/screenshots/privacy/review information
  exactly and must never fabricate owner/legal data.
- **Validation boundary:** local build, all guards/budgets, both native syncs,
  generated-asset scans, and Android assembly pass. Run `32611345045` passed
  Apple validation/upload/processing and internal distribution for exact
  `86.223/1085` (delivery `98370121-bfc3-4e6e-943c-90ceaad9021b`). The existing
  `1.0` draft was safely renamed to `86.223` and linked to `1085` without
  deleting metadata. Review is blocked only on owner storefront prerequisites:
  description/keywords/support and privacy URLs, required iPhone/iPad
  screenshots, category, review contact/details, copyright/content rights,
  privacy data usages, pricing, and all age-rating answers. Do not guess these.

## v86.221 — isolate Navigation sublayers with one flight recorder (2026-08-23)

- **Physical correction:** the user installed `86.220/1082` and reproduced the
  same PDP spinner. The prior A-D result classified the broad Navigation group,
  not its removed product fallback/chunk bridge. The exact sublayer is still
  unknown; do not ship another speculative fix.
- **Experiment:** start from N0 capture+blocking with Navigation and Session off,
  then cumulatively add viewport, runtime bar, nav-button touch, Back, early bar
  mount, and early protection as N1-N6. R1 adds Session/Region only after the
  navigation boundary. The first physical failure is the responsible boundary.
- **Evidence:** an event-driven four-node flight recorder observes the product
  tap, URL change, document completion, and PDP paint. It uses three bounded
  post-tap checkpoints, caps trace/errors, persists only through the Otlobli
  host, and generates a copyable report. It never wraps history, prevents a
  product event, writes SHEIN storage, or adds recurring work.
- **Gate correction:** the session interaction branch must not repaint
  `#otlobli-nav` when `navigationBar` is off. Granular flags inherit the broad
  flag in customer builds; the new split is diagnostic-only behavior.
- **Release boundary:** normal builds alias the flight recorder to a marker-free
  stub. Guards, normal+diagnostic builds, WebKit visual QA, native syncs, and
  Android assembly pass at `86.221/1083`.
- **Internal delivery:** run `32606619539` passed Apple validation/upload and
  verified exact `86.221 (1083)` as `VALID`/`IN_BETA_TESTING` in the internal
  all-builds group with the expected tester `INSTALLED`. No public submission
  occurred. Physical N0-N6/R1 evidence remains pending; preserve every native
  freeze and transaction invariant.

## v86.220 — rejected product-navigation hypothesis (2026-08-23)

- **Group classification:** with Navigation disabled, the same list-to-PDP flow
  opened; with it enabled the spinner returned. This proved the broad group,
  not an individual listener.
- **Rejected hypothesis:** v86.220 removed the iOS product `touchend` fallback,
  500ms `location.assign`, and chunk bridge while retaining the rest of
  Navigation. The user installed the exact build and reproduced the spinner,
  so those removed components are not the exact cause.
- **Region cause and decision:** automatic repair exhaustion was keyed by
  country plus pathname, so every PDP rearmed the same cascade. Persist one
  namespaced exhaustion key per required country for the current SHEIN session.
  Only an explicit Add action may request one fresh repair; checkout remains
  fail-closed until signed region readiness.
- **Boundary:** no lifecycle/native recompose timing, WebView ownership,
  region-equality comparison, capture, blocking, payment, wallet, order, auth,
  or budget was changed. Native fatal WebKit recovery remains.
- **Delivery/rejection:** run `32604307896` delivered exact `86.220/1082` to the
  verified internal group/tester with no public submission. The subsequent
  physical result rejects the candidate and requires granular Navigation
  isolation before another fix.

## v86.219 — diagnostic cover must follow coordinator availability (2026-08-23)

- **Physical rejection:** v86.218 stayed on the native Otlobli loading cover,
  so stage A never became visible and did not classify the raw SHEIN PDP.
- **Cause:** React accepted the diagnostic painted-page event, but the native
  cover independently requires the full safe coordinator payload. A-C omit the
  session coordinator by definition and can never satisfy that production
  contract.
- **Decision:** do not weaken the native gate. Explicit diagnostic A-C open
  without the cover; D and every ordinary customer build keep it. This is one
  open-time Boolean with no recurring work or native/lifecycle change.
- **Acceptance:** first prove A itself is visible on the iPhone, then test the
  same PDP. No inference about the original spinner is valid before that.
- **Internal delivery:** run `32600407694` passed Apple validation/upload and
  verified `86.219/1081` as `VALID`/`IN_BETA_TESTING` in the internal
  all-builds group with the expected tester `INSTALLED`. This proves delivery
  only; no public App Store submission or physical acceptance occurred.

## v86.218 — isolate before another SHEIN fix (2026-08-22)

- **Physical decision:** `86.217/1079` is rejected; neither live-only human
  verification nor the v86.213-style region gate fixed the PDP spinner.
- **Next experiment:** one internal build exposes ordered A raw, B capture, C
  capture+blocking, and D full region/navigation profiles. Every transition
  recreates one JavaScript/WebView surface but preserves site-owned persistent
  website data and verification proof.
- **Interpretation:** A failure assigns the PDP problem below normal injected
  runtime (SHEIN/native/network). A success followed by the first B/C/D failure
  assigns the responsible Otlobli layer. Do not patch before that device result.
- **Release boundary:** the panel is build-gated and replaced with a marker-free
  stub in ordinary customer assets. v86.218 is not a production fix.
- **Internal delivery:** signed run `32598213562` passed Apple validation and
  upload for `86.218/1080`. API verification run `32599164674` then proved the
  build is `VALID`/`IN_BETA_TESTING`, `Otlobli Internal` is an internal
  all-builds group without a public link, and the expected tester membership is
  `INSTALLED`. No App Store review submission was made. This proves delivery,
  not physical acceptance of A-D or a fix for the PDP/region failures.

## v86.216 — warm Home must not own region repair (2026-08-22)

- **Physical rejection:** the user's 34.92-second iPhone video rejects
  `86.215/1077`; it shows a successful area choice followed by an automatic
  close/reopen/reselect loop, with the original product spinner still present.
- **Cause:** warm recovery retained the PDP until full signed address readiness.
  Home reached visual readiness only, so the queued PDP never navigated. Its
  automatic region repair then timed out and was eligible to restart on the
  same route. Tap/chunk correlation was also too broad and too late.
- **Decision:** recovered Home is only a same-site launch pad. Skip Home repair
  for that state and navigate the queued PDP at policy-safe visual readiness.
  Exhaust a timed-out automatic repair for the same country/path. Arm the tap at
  validated `touchend` and accept only a post-tap chunk failure within 15s.
- **Boundary:** no new recurring work, WebView, lifecycle change, region
  equality change, or transaction relaxation. Real-device acceptance remains
  mandatory and unperformed.

## v86.215 — recorded pre-route chunk recovery and warm-home replay (2026-08-22)

- **Physical rejection:** App Store Connect confirms `mhm1981dx@gmail.com`
  installed `86.214 (1076)` on an iPhone 16 Pro Max running iOS 27. The user
  immediately reproduced the same list→product spinner, so v86.214 is not an
  accepted device fix.
- **Exact missed edge:** a chunk error can fire after the physical product tap
  but before SHEIN changes `location.pathname`. v86.214 stored that error for a
  bounded stalled-tap recovery, yet its 500ms tap fallback never called the
  stored-error helper. It treated a matching product URL as success even while
  the recorded chunk failure left only the spinner.
- **Decision:** the existing 500ms callback makes one cheap stored-error probe
  before its route decision. A hit enters the existing iOS-only/60-second/cache-
  only recovery; a miss continues unchanged. No timer, polling, observer, DOM
  scan, replay click, lifecycle mutation, or broad listing recovery was added.
- **Recovery topology:** after the bounded cache reset, open SHEIN Home first
  and retain the queued PDP. Only after Home is verified does the app navigate
  to the PDP inside that same WebView. Cold-loading the deep PDP immediately
  after clearing HTTP cache did not reproduce the user's proven Temu→SHEIN
  recovery and could strand the new browser on the same spinner.
- **Validation boundary:** the executable guard now reproduces a pre-route
  error followed by SPA product navigation, full build/performance guards pass,
  both native syncs pass, and Android debug builds at `86.215/1077`. Unsigned
  Xcode run `32538249134` also passes from `05b81a1`; unsigned IPA SHA-256 is
  `272C92DB84FB826140D5687A2098D03923731A3CE5F6BF7C5BCA4B800BC2FD0B`.
  Real iPhone acceptance remains mandatory; do not describe this as fixed until
  the same product opens and the protected resume/cold-launch checks pass.
- **TestFlight delivery:** signed run `32538654061` from `6246ca8` passed Apple
  validation/upload with delivery UUID
  `d2d4a5d0-a03b-4a17-be81-3e13de802dea`. App Store Connect shows build 1077
  in `Otlobli Internal` and Installed by the exact tester on iPhone 16 Pro Max /
  iOS 27. This proves delivery only, not physical acceptance of the fix.

## v86.214 — live SPA chunk recovery and safe visual readiness (2026-08-22)

- **Device/evidence:** The supplied iPhone recording paints a SHEIN list shell,
  then a product route remains on its spinner. The separate screenshot shows
  Otlobli's native `جاري تجهيز المتجر…` cover persisting on first open.
- **Product cause:** The chunk bridge captured `product=false` when installed on
  Home. SHEIN later changed `location.pathname` through SPA navigation; the
  subsequent real `ChunkLoadError` had neither a live product classification nor
  the tap timestamp used by the 500ms fallback, so the host recovery was silent.
- **Product decision:** Classify the live pathname only when a real chunk error
  fires. Preserve iOS-only one-shot host recovery, the 60-second incident guard,
  the target URL/back target, and the cache-only reset that retains cookies,
  storage, service-worker registration, and signed address. No polling,
  observer, synthetic click, broad scan, or eager listing recovery.
- **Opening cause:** JS posted `sheinPageInteractive` after region repair timed
  out, but native and React accepted only full signed-region readiness. A safe,
  localized and policy-verified page could therefore remain hidden indefinitely.
- **Opening decision:** Add a separate visual-ready predicate: currency/language
  matching, policy verified, capture ready, interactive, no mismatch, no login
  route, and no human challenge. Country/region may remain unknown while repair
  continues; transaction READY and add-to-cart still require both matching. Reuse
  the single coordinator; low-end checks wait 2.8s and run no more than every
  900ms until the current route is released.
- **Validation boundary:** Exact coordinator and Home→SPA-product fixtures,
  production build, unchanged performance budgets, freeze guard, both native
  syncs and Android debug assembly pass at `86.214/1076`. Unsigned Xcode run
  `32535587249` passes from `04d274f`; the universal IPA SHA-256 is
  `1E9E380FD35F40ECDC247EA00E562B4F39D0C8D063207598462EE2BA237D47FB`.
  Real iPhone acceptance later failed on the same list→product spinner; weak-
  Android acceptance remains pending. Preserve the 0.25s iPhone
  16 recompose, Android resume defense, and JSON region equality invariant.

## v86.201 decision — injected double-Home was missing, not intermittent (2026-08-20)

The double-Home store-switch gesture existed only in the Android personal-Temu React path. Injected SHEIN/Temu navigation could not recognize it because the first tap navigated immediately and the bridge's 450ms touch/click dedupe rejected the physical second tap. v86.201 uses a 320ms single-tap timer and separately deduplicates synthetic post-touch clicks. Double Home emits the existing `closeStore` path, preserving the same-store session and fixed React bottom navigation.

## v86.200 decision — native button owns iOS; Temu root can exit (2026-08-20)

- **Observed:** SHEIN displayed green native and dark HTML Back controls together; Temu Home displayed none.
- **Cause:** the HTML maintenance loop always repainted SHEIN Back even after publishing state to the native layer, while `shouldShow` excluded Temu root.
- **Decision:** native WebKit handler presence suppresses HTML paint only, never state publication. Temu participates in root visibility and exits through `closeStore`; App parks its InAppBrowser. Search and non-root history behavior remain ordered and unchanged.
- **Invariant:** one visible Back control per store surface. Preserve v86.198 root URL authority and v86.199 inactive scheduling.

## v86.199 decision — keep root Back fix; background freeze is separate (2026-08-20)

- **Accepted on device:** v86.198 prevents the Home Back reload and permits store exit/switching. Preserve it.
- **Still failing:** ordinary app background/return freezes the retained SHEIN page even though the unsafe root-history action is no longer taken.
- **Decision:** create a combined candidate from v86.198 and add only WebKit's battery-preferred `.throttle` inactive scheduling policy on iOS 17+. Do not contaminate the result with any other lifecycle or data-store mutation.
- **Acceptance split:** app-switch background/resume and swipe-away process death are different tests and must be reported separately.

## v86.198 decision — native URL wins over stale Back target (2026-08-20)

- **Reproduction:** Home → product → Back to Home → Back again deterministically reloads/redirects Home into an inert state, entirely while foreground and visible.
- **Exact sender/action:** the custom plugin's native `UIButton` receives the tap. The injected script publishes an asynchronous target; the native default branch used `storeWebView.canGoBack` and `goBack()`. A nonempty `WKBackForwardList` may contain SHEIN redirect/login/verification items that are not valid app destinations.
- **Decision:** on tap, preserve cart priority, then classify the live native URL. Canonical `/ar/` or `/` emits `closeStore` before history and parks the session behind the picker. Only non-root routes may enter the existing history/fallback path.
- **Isolation:** v86.198 is cut from exact v86.193 and excludes v86.197 scheduling policy, so its device result measures only Back-at-root. No scripts, storage, cookies, cache, Service Worker, VPN, region, product, or WKWebView lifecycle behavior changed.
- **Proof boundary:** the trigger and unsafe command are source-proven. Why SHEIN becomes internally inert after that redirect/history traversal remains unproven and is no longer required to prevent the user-facing failure.

## v86.189 disposable iOS render-surface contract (2026-08-14)

- **Measured rejection of v86.188:** the modern iPhone's first entry worked but its second visible list stopped accepting taps. iPhone 6 loaded Home completely but did not complete the next list route. Android remained fully interactive. A dedicated owner alone was insufficient because it still reused a WebKit render instance.
- **Single architecture decision:** rendering is disposable; site session is durable. No WKWebView may survive hide/background. Re-entry creates one new WKWebView at the saved URL using `WKWebsiteDataStore.default()`. Do not add same-instance render repairs.
- **Single navigation decision:** every settled same-site path transition that SHEIN performs without a committed load, plus top-level link path transitions, replaces the surface and makes a full document request. This applies to all iPhones; no OS or model branch and no product-specific exception.
- **Forbidden complexity:** process pools, hidden surfaces, CADisplayLink, snapshots, recompose, reload, delay bursts, cookie/storage clearing, and repeated recovery loops. The executable guard requires exactly one WKWebView constructor and zero display-link repairs.
- **Acceptance boundary:** commit `6830a04`, run `31834669885`, and all local/Xcode/archive checks pass at `86.189/1051`. Unsigned IPA size `6,557,711`, SHA-256 `8F5D73D105483733BF9D03817300429D2D79CFC2D2A50A77C8A6572BC0B874AF`. Device gate is intentionally minimal: modern second entry + one resume; iPhone 6 Home → list → product tap.

## v86.188 dedicated iOS SHEIN browser boundary (2026-08-14)

- **Measured classification:** on a clean v86.187 install, all five normal injected-script groups were off and remained off; the first store view worked, then background/return froze it. The normal runtime cannot cause code it never evaluated. This assigns the resume fault to the generic native WKWebView owner/lifecycle and closes the injection-isolation branch for this symptom.
- **Architecture decision:** iOS SHEIN must not use the generic modal Capgo browser. `storeBrowser.ts` routes iOS SHEIN to an app-owned Capacitor plugin with one permanent host-child WKWebView, default persistent website data store, shared process pool, explicit message bridge, and explicit lifecycle. Android and non-SHEIN remain on Capgo. Reimplementing SHEIN's UI/API is rejected because it would couple the app to private third-party behavior and be less stable than the real site.
- **Session decision:** keep the same WKWebView, DOM, cookies, storage, and verification proof across normal hide/show and background/return. Cache clearing may remove only memory/disk HTTP cache. Never clear cookies or local storage for lifecycle recovery and never reload merely because the app became active.
- **Render-lifecycle decision:** after a recorded background and `didBecomeActive`, a visible attached store may perform one same-instance rebind across a real display frame and restore scroll. No `willEnterForeground`, no delay array/burst, and no repeated detach/reattach. A terminated WebContent process is a distinct fatal event and must take the host's bounded clean-recovery lane.
- **Acceptance boundary:** TypeScript, architecture guard, diagnostic build, hardening, store/Temu/performance gates, iOS sync, Xcode run `31832999429`, and archive inspection pass at `86.188/1050` from commit `a9ae9e1`. The unsigned ARM64 iPhone/iPad artifact is `6,554,404` bytes with SHA-256 `7F92FAE968BBB51CAFA8F2C533119D9EB7654A5D2F1DBBDEC91DADC1A34619A4`. Device acceptance remains pending. Raw/off must pass ten resumes with interaction and Home → list → PDP; full mode must then pass the shopping path and five resumes on both affected iPhones before calling the symptom fixed.

## v86.187 script isolation and same-store re-entry (2026-08-14)

- **Observed sequence:** first SHEIN entry works; leaving and entering SHEIN a second time can freeze the whole store, while Temu→SHEIN creates a fresh request and recovers it. v86.186 fixed the matching host race by queuing a same-store request while the exact native WebView is still closing, ignoring the old delayed close event, and replaying once after close.
- **Isolation decision:** do not keep shipping speculative combined fixes. A diagnostic-only `فحص` panel exposes raw/all profiles and Runtime, Navigation, Blocking, Capture, and Session/Region switches. Each change rebuilds only the current store surface and preserves website cookies, storage, and human-verification proof.
- **Raw invariant:** raw mode retains only the panel/readiness bridge. It must not evaluate the full runtime coordinator, recurring work, or region diagnostic. The panel is compile-time excluded unless `VITE_STORE_SCRIPT_DIAGNOSTICS=true` and must remain disabled in customer production.
- **Decision tree:** full and raw must be tested with the identical enter→leave→same-store re-entry→category/product sequence. A raw failure assigns investigation to native WebView/plugin lifecycle. Raw success assigns it to injection; restore all and disable Blocking, Session/Region, Navigation, then Capture one at a time. Do not patch before obtaining this result.
- **Validation boundary:** static/executable guards, both diagnostic builds, performance gates, visual QA, Android ARM64, and isolated Xcode pass at `86.187/1049`. APK SHA-256 is `DC1EB324B9C01B434D2BF64836958D9359CE2F0F3563278403AD10B5E253E394`. Isolated commit `7259faf` and run `31830165263` produced the inspected unsigned IPA with SHA-256 `87560FCF9C09DA39E922BD489EDF07670876722C86148471A504E5F5C86625D5`. Physical-device classification remains pending on both affected iPhones.

## v86.185 store runtime ownership and persistent verification session (2026-08-14)

- **Measured session fault:** live SHEIN stores `currency` as structured JSON and shipping state in a signed `addressCookie`. Otlobli had been replacing `Storage.prototype.setItem` and forcing guessed plain scalar aliases across cookies, localStorage, and sessionStorage. That can corrupt a third-party schema and cause reinitialization independently of the installed app version.
- **Ownership decision:** SHEIN exclusively owns cookies and web storage. Otlobli may read the signed address and visible shipping label, and may drive SHEIN's native shipping UI, but must not forge, delete, coerce, or clear site state. Human verification is never auto-clicked/reloaded and the iOS WebView remains on `WKWebsiteDataStore.default()`.
- **Navigation decision:** do not reload a valid product to append missing region aliases. Entry URLs carry only `currency`, `localcountry`, and `lang`; natural store navigation may omit them. Explicit conflicting region UI is repaired through the native flow.
- **Architecture decision:** keep navigation, session, product capture, blockers, Temu, and runtime coordination in named modules, with a composition-only entry. Verifiers must load the module graph and production-minified output rather than reading one monolith.
- **Performance decision:** one due-time coordinator owns recurring work; no full-document mutation observer. Preserve the `120/650 ms` blocker lane, bounded document-start protection, and bounded selected-SKU price observer.
- **Acceptance boundary:** builds/guards/Xcode pass at `86.185/1047`, run `31827354199`, IPA SHA-256 `AA75998F5CAF2C7B82CAEDDF61D84C11D1D3573DC54B07613403A61A4F45DBEE`. This is not physical-device acceptance. Both affected iPhones must prove Home → list → PDP and one-time manual verification persistence; iPhone 16 also needs five resumes and a cold launch.

## v86.184 SHEIN live verification compatibility (2026-08-14)

- **Measured cause:** a direct mobile-browser reproduction completed Home → Super Deals → canonical PDP; product static/realtime BFF calls returned 200. SHEIN then rendered its current legitimate human check as `.sui-dialog__wrapper` with `.risk-one-pass-*` and `أنا إنسان`. Otlobli's detector knew older one-pass/captcha wrappers and gated its text fallback on a `challenge` class, so the new surface was missed and normal cleanup continued. This server-side markup change explains a clean old `86.134/994` install failing today; v86.183 routing was not the terminal fault.
- **Security decision:** detect current exact risk surfaces and, for rename tolerance, inspect only the last 12 painted dialog/security surfaces for explicit human-verification semantics. Enter existing challenge safe mode before any page cleanup. Never click, solve, bypass, reload, mutate the response, or seed region state while a verification token is pending. An ordinary promotion/login dialog and hidden stale template must remain negative fixtures.
- **Routing decision:** a card class name is advisory, not identity. Within at most 12 ancestors and 16 descendant PDP links, accept the nearest container only if all qualifying links share one product ID. Refuse ambiguous multi-product containers; retain the constrained role/class requirement for numeric metadata-only routes. No observer, polling, synthetic click, broad scan, or item-specific rule.
- **Compatibility boundary:** literal permanent compatibility with arbitrary third-party changes is not technically promiseable. The durable policy is bounded semantic detection, fail-visible user-controlled verification, canonical product identity, and regression fixtures. Any future break must first be reproduced in a normal browser and classified as navigation, product API, security UI, or Otlobli intervention before patching.
- **Acceptance boundary:** builds and static fixtures pass at `86.184/1046`; isolated commit `e74a6fab45fcc1bbe32ebaffcbb843d58dc98973` and run `31824376802` produced the inspected unsigned Universal IPA with SHA-256 `F4CD547901E1D5675BD3E3C9BBC9E263F2765F86B049D678672F015CCC7B002D`. No phone was connected. Both affected iPhones must pass Home → list → PDP and manual verification when offered; iPhone 16 also needs five resumes and one cold launch.

## v86.183 SHEIN live product-card targeting correction (2026-08-14)

- **Correction:** both connected phones were on `86.182/1044` and still showed the same failure. A complete deletion and clean install of `86.134/994` was then device-verified on the iPhone 16 Pro Max and reproduced the same failure. This excludes a post-v86.134 regression and stale app data; source comparison shows v86.134 and v86.182 share the relevant live-card selector blind spot. The v86.182 diagnosis was incomplete and its artifact is superseded.
- **Measured live DOM mismatch:** the reported Batman search/list uses `.bs-product-card.multi-product-card`; the tapped image is not inside the canonical product anchor, which is a sibling. Other real grid cards use `.flash-sale__product-item` with numeric `data-id` and no direct anchor. The prior ancestor/exact-class resolver therefore did not arm. It could also treat any SPA URL change as success even when the destination was another non-product list/brand route.
- **Routing decision:** recognize only bounded actual product-card shapes that expose a direct descendant/sibling `-p-<id>` link or numeric product metadata. Use `/<locale>/product-p-<id>.html` for metadata-only cards. After the existing single 500 ms window, skip only when the current URL already contains the same product ID; override a wrong non-product route once. Leave no-ID/no-PDP `sd-ccc-products__item` collection navigation untouched.
- **Guard decision:** fixtures must cover live `.bs-product-card`, data-ID-only flash-sale cards, generic collection non-intervention, same-product natural navigation, and wrong-list override. Do not add synthetic clicks, polling, observers, broad scans, extra timers, or item-specific rules. Preserve all iOS recompose/freeze invariants.
- **Validation boundary:** all static/build guards pass at `86.183/1045`; isolated commit `05f123e` and GitHub run `31818768808` produced the inspected unsigned Universal IPA with SHA-256 `D1931BDDCB4AC3BCF1458F8FDE781BE81346F4A27173B071DC47719CFF1FCF8C`. This is not a claim of device acceptance. Both phones must pass Home → collection/list → exact PDP; iPhone 16 additionally needs five background/resume cycles and one cold launch.

## v86.182 SHEIN iPhone collection-to-PDP routing (2026-08-14)

- **Observed path:** SHEIN Home loads correctly; the first tap legitimately opens a collection/list; the second tap on the actual item is the transition that fails. This was reproduced on iPhone8,1 / iOS 15.8.8 and is also customer-reported on iPhone 16.
- **Root-cause decision:** a generic `sd-ccc-products__item` is not proof of a direct PDP. SHEIN SPA navigation may succeed without changing `location.href`, so replaying `.click()` on that container can redirect to a brand/category route and must not be used as the iOS fallback.
- **Routing decision:** preserve natural Home-to-collection behavior. Arm the bounded fallback only when the tap exposes a direct SHEIN `-p-<id>` href; after 500 ms, assign it once only if the route is still unchanged. Ignore generic/no-href cards. Do not restore synthetic card clicking, no-href chunk recovery, polling, observers, broad DOM scans, or product-specific exceptions.
- **Guard decision:** retain fixture coverage for direct-PDP fallback, generic-card non-intervention, and no duplicate assignment after natural navigation. Keep `otlobliForceRecompose`, the 0.25-second `appDidBecomeActive` recompose, and `JSON.stringify` region equality unchanged.
- **Acceptance boundary:** build and static guards pass at `86.182/1044`, but physical-device acceptance is pending on the old iPhone and iPhone 16. Both must prove Home → collection → exact PDP; iPhone 16 additionally needs five background/resume cycles and one force-quit/cold launch.

## v86.179 Personal Temu return and capture acknowledgement (2026-08-14)

- **Return decision:** while Personal Temu is visible, React's first bottom tab is an explicit `المتاجر` destination. It hides the current Gecko layer and opens the store chooser in one press; it must not call `goHome()`, reload Temu, destroy Gecko, or set the session inactive during this ordinary in-app hide. The one-time `بدّل هنا ↑` cue is persisted and has no animation, observer, or timer.
- **Measured capture gap:** the old four-second escape timer was created only inside `postProduct()`. If product parsing threw after the blocking overlay appeared but before `postProduct()`, no safety timer existed, so the spinner/scroll lock could remain forever.
- **Capture decision:** start one bounded five-second safety timer immediately after the overlay appears and catch every delayed capture attempt. Failure or native rejection must display a retry state and release the overlay/scroll lock. Do not add a permanent watcher or product-specific exception.
- **Acknowledgement decision:** Gecko's `sendNativeMessage()` result for `addToCart` remains pending until React has accepted and synchronously persisted the cart update, then `acknowledgeAdd()` completes it. The extension may show `addToCartAck` only after that completion and must surface rejection as `addToCartNack`. Native timeout is 3.5 seconds. Keep capture on the PDP; do not auto-navigate to Cart.
- **Validation boundary:** Android 15 emulator proved the one-time cue and one-press store return. Exact product `CA5773086` was reached and its red-gradient/M options were confirmed before the patch, but the v86.179 debug reinstall triggered Temu's visual CAPTCHA. It was not solved/bypassed, so exact post-fix product acceptance remains pending on a real device.

## v86.174 Temu layer geometry, not CSS colour or window dim (2026-08-13)

- **Measured cause:** MainActivity had one normal app window, no lingering dim, and SurfaceFlinger reported sRGB with dimming ratio `1.0`; stable Temu white pixels were `255`. The embedded layer nevertheless ended at `y=2164` while React nav began at `y=2102`, overlapping 62px. Its explicit `24dp` elevation then cast a grey gradient over the rest of the bar (`204/212/233/249` measured down the centre).
- **Decision:** never compensate this compositor fault by changing Otlobli CSS colours. Keep the store layer at zero elevation and reserve `90dp + navigationBars.bottom`, using the pre-R system-window inset fallback. On the installed fixed build the surface ends at `y=2101`, nav begins at `y=2102`, and its blank rows remain `255`.
- **Guard:** `verify:store-surface` locks navigation inset handling, absence of store elevation/dim, alpha restoration, session-preserving hide, and `SurfaceView`-first report capture with window fallback.
- **Boundary:** no payment/wallet/order, SHEIN lifecycle, Temu context/session, SKU, injected-script, or report transport behaviour changed. Emulator acceptance passed; Note 8 and iPhone acceptance remain unperformed.

## v86.173 Temu size dialogs and Android product screenshots (2026-08-13)

- **Measured size-dialog cause:** exact Temu product `601101949689075` opened its real SKU drawer, but the first-paint promo blocker hid it because the same dialog repeats `خصم 75%`. Text alone is not sufficient classification. A genuine option dialog is now structurally allowlisted by `role=dialog` plus radio/spec/SKU descendants.
- **Size decision:** preserve Arabic `الحجم`, Temu's current `.specTypes-*` markup, template-literal regex escaping, and the authoritative expanded radio group over a duplicate collapsed dimension. The exact product proved that an unselected add says `حدد المقاس أولاً` without closing the drawer and a selected radio captures normally. `scripts/verify-temu-size-gate.mjs` guards these invariants.
- **Measured screenshot cause:** Android window PixelCopy produced black content for personal Temu because GeckoView paints through a separate `SurfaceView`. Shake reports must capture the largest visible store `SurfaceView` before opening the native dialog, with window capture only as the normal-screen fallback.
- **End-to-end proof:** production report `1e108393-d2ea-4676-a7a5-3cdba6713dbb` was triggered while a real Temu product was visible. Its signed JPEG was read back and visually confirmed to contain the product image, title, price, quantity controls, and page state. The report is left as a clearly labelled resolved acceptance record.
- **Open visual issue:** the user reports that entering Temu makes the Otlobli bar look pale while the Temu surface looks darker. No cause is established yet. Reproduce before editing and compare pixel/color state before entry, after entry, after shake-dialog dismissal, and after app resume. Check native window dim flags/scrims, Gecko/SurfaceView alpha, overlay visibility, and focus restoration; do not guess by changing CSS colors. Preserve product screenshots, the persistent Gecko session, navigation, SKU gate, and iPhone freeze guards.

## Temu multi-size must never use visual selection heuristics (v86.166, 2026-08-12)

- **Evidence:** On a real Note 8 PDP, Temu displayed `S/M/L/XL/XXL` with no selected size, yet the former capture path could treat one option as selected. Source inspection found two visual fallbacks (`otlobliTemuSku()` and `temuSelectedSize()`) and deterministic retry chains that delayed rejection/addition by 5–10 seconds.
- **Cause:** Default borders/backgrounds in some Temu templates are presentation, not selection. Treating them as size state creates a false size. Repeated `500ms` polling and duplicate image preloading then made both rejection and valid addition slow.
- **Decision:** Multi-size selection requires explicit Temu ARIA state or a same-product recorded user click that is still visible and available. Visual fallback is color-only; one size remains automatic. Reject missing dimensions immediately, bound Temu capture to `3 × 150ms`, and do not preload an already-painted Temu image.
- **Guard:** `scripts/verify-temu-size-gate.mjs` checks source invariants and fixtures for unselected/selected multi-size, single-size, no-variant, and unavailable states. It forbids delayed option watchers and diagnostic traces.
- **Validation boundary:** Real Note 8 showed immediate `حدد المقاس أولاً`, preserved a selected `M` and the PDP across background/resume, and logged no FATAL/ANR. A Temu-owned advance-reservation modal intercepted selected-size add taps on that product, so isolated timing through the modal is not claimed. Android builds and syncs pass; iOS device acceptance remains pending.

## Temu loaded PDP was covered by a false blank-page notice (v86.161, 2026-08-12)

- **Evidence:** The visible Arabic copy uniquely matched Otlobli's `#otlobli-temu-product-loading`. Gecko logs remained on the same real product route without `/login`. On Note 8, the product had already painted and exposed Otlobli's add action before the notice appeared.
- **Cause:** `otlobliTemuBlankProductNotice()` used current-viewport image/price visibility as whole-page readiness. Temu carousel/DOM changes or normal content movement can leave no qualifying hero/price in the viewport while the product DOM and route remain valid, so the app placed an opaque fixed notice over a healthy PDP.
- **Decision:** After the existing stable product-readiness gate, remember the product identity. A loading notice requires both an unconfirmed identity and no product DOM; blank-page reload exits for a confirmed identity. Keep true empty-new-route recovery, but never demote a confirmed PDP based on viewport visibility.
- **Boundary:** No new timer, observer, scan, retry, WebView rebuild, or lifecycle action. Preserve the embedded Otlobli nav/add/blocking UX, coherent Android Gecko identity, persistent guest context, and all payment/cart logic.
- **Validation:** The dedicated four-case guard passes. `86.161/1021` is installed on real Note 8; product `606482062007357` stayed open for five minutes while gallery state changed, with `LOADING_TEXT_COUNT=0`, `LOGIN_TEXT_COUNT=0`, no login navigation, FATAL, or ANR. Both web builds, freeze/performance guards, native syncs and Android standard/ARM64/x86_64 builds pass. iOS device acceptance was not performed.

## Post-v86.118 SHEIN startup regression (v86.121, 2026-08-10)

- **Device/evidence:** v86.120 showed the corrected supported-Qatar preparation
  screen but never entered SHEIN. The user identified v86.118 as the last IPA
  that actually opened the store.
- **Cause:** The direct v86.118→v86.120 comparison found two post-baseline
  runtime changes: v86.119 increased recurring concealment work on two-core
  iPhones and v86.120 armed cache reset on every successful supported geo/store
  diagnosis. The latter forced healthy opens onto a cold-cache path.
- **Decision:** Preserve v86.118's SHEIN capture runtime exactly. A supported
  geo or successful reachability probe authorizes opening but never arms cache
  reset. Keep cache reset confined to the existing bounded stuck/chunk recovery
  and explicit Temu→SHEIN fresh-session path. Keep the correct supported-region
  copy and coordinated manual retry from v86.120.
- **Boundary:** Preserve native back behavior, iPhone 16 recompose timing,
  Android resume defense, region JSON comparison and all order/payment logic.
  No new timer, loop, observer, scan, lifecycle burst or React effect.
- **Validation:** Production/freeze/performance builds, native syncs, Android
  debug assemble and Xcode run `31340886636` pass for `86.121/981`. Inspected
  IPA SHA-256 is
  `43C31B9BEBECA834DD74DACA038CCD7EAB774CA73D2AB7462316A7A4D81303BF`.
  Real-device entry and lifecycle acceptance remain pending.

## Fast concealment without duplicate scans (v86.119, 2026-08-10)

- **Evidence:** Real iPhone 6 use rejects v86.118's slower two-core intervals.
  SHEIN creates some native actions after document start, so the fallback
  hider's `950ms` interval left a forbidden control visible too long.
- **Decision:** Restore low-end general/critical concealment to `650ms`, nav to
  `2200ms`, and security inspection to `1600ms`. Reduce CPU work by routing the
  critical hider: product routes scan only native product actions and other
  routes scan only listing quick-add controls. Run it once immediately and
  remove the duplicate product-action scan from the general tick.
- **Boundary:** Keep document-start CSS, active-interaction pauses, the approved
  native back appearance/action and all protected iPhone 16 lifecycle code.
  No new timer, observer, React render or DOM scan was added.
- **Validation boundary:** Guards, production build, native syncs, Android debug
  assemble and Xcode run `31339488536` pass for `86.119/979`. Inspected IPA
  SHA-256 is
  `342DF62836C855FBB5A57FE813DFFE960C5E2D42183281883F667B3DF442DBB0`.
  Real-device iPhone 6 concealment/speed and iPhone 16 lifecycle acceptance
  remain pending.

## iPhone 6 preparation false negative and sticky-price back cover (v86.116, 2026-08-10)

- **Device/evidence:** v86.115 real iPhone 6 screenshots show the host
  `تعذّر تجهيز المتجر` screen despite a supported connection, and a SHEIN
  sticky price/header layer covering the back button only after product scroll.
- **Preparation causes:** Home readiness required three visible semantic
  controls, while current SHEIN product cards can use non-semantic clickable
  wrappers. A painted home could be rejected until recovery failed. Confirmed
  WebKit termination and unexpected ready-view close also went directly to the
  host failure instead of using the existing bounded runtime recovery.
- **Decision:** A SHEIN home is visually ready only with two decoded images and
  either one semantic control or 500 characters of page content. Fatal WebKit
  and unexpected ready-view closure reuse the existing iOS/SHEIN-only recovery,
  preserve the current product URL and website data, clear HTTP runtime cache
  only, and retain the 60-second incident guard. Preparation UI does not offer
  VPN diagnosis; actual network/VPN failures still do.
- **Back cause/decision:** In old WebKit, a composited sticky descendant of
  `body` can paint above a fixed direct child of `html` despite equal maximum
  z-index. Keep the button as a top-level body child; after a real point-hit
  proves coverage, reclaim last paint order and suppress entrance animation.
  Reuse the existing post-interaction tick—no new scroll listener/timer/scan.
- **Validation boundary:** Executable fixture adds a sticky-price layer after
  the button and proves last-body reclamation, max z-index, no animation and
  pointer events. Production build, freeze/performance guards, native syncs and
  Android debug build pass for `86.116/976`. Xcode run `31336148034` produced
  the inspected unsigned IPA on Desktop, SHA-256
  `A3E8741247DD9F80FAEF98ED2EA6D1F81E1E0B9E72045D8E73342308D0FD920C`.
  Real iPhone 6 and iPhone 16 acceptance remains pending; do not claim it from
  build, archive inspection or the fixture.

## iPhone 6 product entry restores SHEIN's black cart-success bar (v86.112, 2026-08-09)

- **Clarified symptom:** The remaining black element is SHEIN's compact
  “added to shopping cart successfully” toast above Otlobli nav, not Otlobli's
  green add button and not the iPhone 16 dead-tap issue. Pressing Otlobli add
  made it disappear; opening Otlobli cart hid the whole store surface.
- **Cause:** `hideSheinCartSuccessToast()` already had the correct exact-text,
  geometry and Otlobli-exclusion checks, but its deadline was armed only by
  `addToCartFlow()`. On product entry it therefore returned before inspecting
  the black bar. The user action appeared to “fix” it because it enabled the
  existing seven-second guard.
- **Decision:** Arm the same scan for 15 seconds on each new `-p-<id>` entry,
  run it before exposing Otlobli add, and reset the route key off product pages.
  Reuse the low-end tick; do not add a timer, observer or permanent DOM scan.
- **Validation boundary:** Executable injected-script fixture at 375×667 proves
  product entry hides the Arabic success toast without an add click and home
  does not arm it. Production build, freeze/performance guards and native sync
  pass. Xcode run `31331834857` produced inspected `86.112/972` IPA on Desktop,
  SHA-256 `8FCFD6E90D70AC32F8726B6FD0CB3A30716E2EDA4A71AB750861263488D2CE71`.
  Real iPhone 6 acceptance is pending.

## iPhone 6 exposes SHEIN's product add action before Otlobli acts (v86.109, 2026-08-09)

- **Cause:** The listing quick-add cleaner intentionally rejects controls wider
  than 96px. SHEIN's older iPhone 6 product action is a wide/obfuscated bottom
  control, so it was visible until Otlobli's add flow changed the product UI.
- **Decision:** On SHEIN product routes only, install a document-start CSS guard
  for stable add classes and use exact add text plus bottom geometry for old
  obfuscated markup. Keep Otlobli nodes excluded and retain the click interceptor
  as defense in depth.
- **Performance:** Reuse existing loops; cap each scan at 140 candidates and a
  3×3 point probe. Do not move geometry/text work into MutationObserver.
- **Validation boundary:** 375×667 browser fixture and production guards/build/
  sync pass. Xcode run `31328598144` produced the inspected `86.109/969` IPA on
  the desktop. It is unsigned/unprovisioned; Google iOS OAuth and APNs signing/
  entitlement are still absent, so it is not publish-ready. Real iPhone
  acceptance and required lifecycle tests are not yet performed.

## Preserve SHEIN's genuine verification session (v86.108, 2026-08-09)

- **Decision:** Never mint, extend or replay a verification certificate. Reuse
  only SHEIN's own persistent cookie state for as long as the store accepts it.
- **Android:** Enable verifier-frame third-party cookies only when the initial
  host is SHEIN, then flush the cookie jar on the existing
  `humanCheckResolved` event. This is event-driven and adds no polling.
- **iOS/cache boundary:** Keep `WKWebsiteDataStore.default()`. Cache recovery
  may clear memory/disk cache but must not clear cookies or local storage.
- **Promise boundary:** App close and store switches should retain verification;
  expiry, revocation and risk changes remain SHEIN-controlled and may require a
  new check. “Once forever” is not a supportable claim.
- **Validation:** Production build, both guards/syncs, clean patch apply,
  Release compile, DEX marker and real Note 8 in-place install pass. Real
  complete-check → relaunch → Temu-switch reuse and iPhone lifecycle acceptance
  remain to be performed.

## SHEIN human check falls through to “product removed” (v86.107, 2026-08-09)

- **Cause:** SHEIN moved the visible verifier to `.one-pass-dialog` beside a
  zero-sized custom-element host, so checking only painted custom hosts missed
  it. Closing the verifier then lands on SHEIN's misleading removed-product
  page. A second detector call inside one tick could also hit the scan throttle.
- **Decision:** Detect the visible dialog, cache the bounded scan result for the
  tick, and reuse the existing store loop. Do not add polling and never solve,
  click or bypass the verification.
- **UX:** Keep the challenge visible, show a compact Arabic instruction, block
  Otlobli's product action, and preserve bottom navigation. If verification is
  skipped and the removed-product signature appears, explain it and return to
  the listing/cart; successful verification resumes normally.
- **Validation boundary:** Production build, freeze/performance guards and both
  native syncs pass. Real Note 8 DOM inspection confirmed the challenge shape;
  a controlled diagnostic confirmed guide/action gating. Final Android Release
  packaging/install and real iPhone lifecycle acceptance remain pending.

## Android nav text/system controls differed across WebViews (v86.106, 2026-08-09)

- **v86.105 correction:** Equal UIAutomator bounds were not acceptance; they
  belonged to the preserved hidden store WebView. The user's screenshots still
  showed larger React labels and white SHEIN system controls.
- **Text cause:** On the Note 8, SHEIN opts out of Android text adjustment and
  renders 12px. React respected `font_scale=1.1`, producing 13.2px. Icon, cell,
  bar and safe-area geometry matched.
- **Text decision:** One Android-only pre-mount probe calculates a CSS variable
  for the four fixed labels. Preserve accessibility scaling everywhere else;
  do not disable root text adjustment or add a timer/layout loop.
- **System-bar cause/decision:** The foreground store dialog lacked
  `LIGHT_NAVIGATION_BAR`; the hidden host had it. Apply the same light surface
  and dark controls to both the dialog and activity.
- **Release decision:** Production builds fail closed without a dedicated key.
  Do not sign with the debug or ShamCash listener identity. The owner must
  explicitly approve a new upload identity or provide the existing one, then
  its SHA must be registered in Firebase before Google device acceptance. The
  app/listener guards are task-scoped so neither module incorrectly demands the
  other module's key.
- **Device validation:** The user narrowed delivery to the existing Note 8, so
  a non-debuggable Release was signed with its matching registered certificate
  to preserve data. `86.106/966` installed over v86.105. Home/Orders have dark
  system controls; inactive `حسابي` pixels are identical (`79×35`, 489 pixels),
  cold launch has no fatal/ANR/push-registration errors, and the user accepted
  the visual fix. Nothing was published.
- **Publication boundary:** The device-update certificate is not the claimed
  Play upload identity. Store publication still requires explicit approval for
  a permanent key and access to the Firebase owner account to register both
  upload and Play app-signing certificates.

## SHEIN bottom nav moves after the first product frame (v86.104, 2026-08-09)

- **Cause:** The document-start nav could paint with its 90px/16px fallback
  before SHEIN installed `viewport-fit=cover`; WebKit then exposed the real
  iPhone bottom inset and increased the nav height, producing the visible jump.
- **Decision:** Read the already settled host `.bottom-nav` padding once before
  opening the store, pass the bounded `16…60` value to document start, and let
  nav CSS use the maximum of host inset, WebKit env inset and 16px. This avoids
  timers, repeated layout reads, native frame nudges and WebView reconstruction.
- **Diagnostic release ended:** The customer path explicitly sets
  `otlobliTapDiagnostics: false` and excludes the tap script/context, so the
  top `نسخ` button is absent. v86.103 recovery remains active.
- **Validation boundary:** Build/freeze/performance/native sync pass. A
  `440×932` browser fixture with 34px host inset measured a stable 108px nav
  from the first frame. Commit `b7f6d27` is pushed; Xcode run `31313269405`
  passed. Inspected unsigned IPA is `86.104/964`, 7,044,634 bytes, SHA-256
  `70D1EC898C8C4244A3D787642DC5C815D293FF553F55BEA1C1C95E0AE3D23AE4`;
  its customer bundle has the inset marker and no tap diagnostic script. Real
  iPhone product-open and lifecycle acceptance is still required; no
  simulator/browser/CI result can claim it.

## Cart-origin SHEIN session loses product navigation on iPhone (v86.103, 2026-08-09)

- **Confirmed sequence:** Open an old SHEIN item from Otlobli cart, leave and
  return to the app, then SHEIN can still paint its shell/categories while all
  product navigation stops. Temu → SHEIN restores the store.
- **Evidence boundary:** v86.102 reported a healthy attached/visible/interactive
  `440×894` WKWebView, stable QA region state and scroll movement `0→734`.
  Absence of a product event was inconclusive because the old diagnostic first
  required a product DOM match and logged document-start executions from
  third-party iframes.
- **Decision:** Mark only iOS SHEIN sessions opened from Otlobli cart. When the
  app resumes or that session exits to an Otlobli destination, close it once
  and use the existing runtime-cache reset before a fresh SHEIN open. This is
  the same recovery proved by Temu → SHEIN. Preserve cookies, localStorage,
  signed address, cart/payment logic and the native 0.25s resume recompose.
- **Diagnostic correction:** Top frame only; raw touch/click attempts no longer
  depend on product recognition; href/label/scroll and touchcancel are included;
  after-URL is scheduled from capture; final cancellation is read in a zero-
  delay task after page listeners. No polling or page-wide scan was added.
- **Validation:** Playwright passed known and unknown targets, late event
  cancellation, synthetic touchstart/touchend, after-URL and iframe exclusion.
  Build, freeze/performance guards, native syncs and Android APK pass. APK
  `86.103/963` SHA-256:
  `1EDC0BFED9DF367F6046F30DE9432F9695F13033AD22E1A464B049B2DBB8897B`.
  Commit `49b734e` is pushed; GitHub/Xcode
  [run `31310138809`](https://github.com/m7madv/otlobli/actions/runs/31310138809)
  passed. Inspected unsigned IPA:
  `release-artifacts/ios-v86.103-run-31310138809/otlobli-v86.103-iphone16-unsigned.ipa`,
  7,046,214 bytes, SHA-256
  `E83EF7ECDD885E8CBB6FD49C9BDB1888411C444EA2708BFE5487503DFC2C712F`.
  Archive metadata and recovery/diagnostic/recompose markers passed; the app
  root has no signature or embedded provisioning profile.
- **Acceptance:** iPhone must reproduce cart-product → leave/resume → ordinary
  product entry, then pass five background/resume cycles and cold launch. Keep
  the diagnostic enabled only until this evidence is collected.

## iPhone SHEIN product taps can stop after cart navigation (v86.102 diagnostic, 2026-08-09)

- **Symptom:** The page still paints and a long press reaches iOS, but ordinary
  product activation/navigation can stop, most often after opening a SHEIN
  item from the Otlobli cart. Temu → SHEIN recreates the session and restores
  taps, but is evidence only and must not become the fix.
- **Decision:** Ship an observation-only diagnostic before changing behavior.
  Record touchstart/touchend/click capture+bubble, post-dispatch cancellation,
  target/painted element, eight ancestors, bounded fixed layers, URL, actual
  region/transition and native WKWebView/lifecycle/recompose state in a
  180-entry in-memory ring. Copy only on demand with the native `نسخ` button.
- **Fallback boundary:** Preserve `otlobliInstallIosProductTapFallback()` and
  its exact timing. Report whether it armed, scheduled, invoked `.click()`,
  skipped after a natural route change or invoked `location.assign()`; do not
  delete or retime it before the device trace proves responsibility.
- **Why this choice:** A passive event-driven trace distinguishes an overlay,
  cancellation/propagation fault, fallback race, region transition and native
  WebView state without adding polling, DOM-wide scans, reloads or another
  lifecycle path. Native records stay in memory to avoid disk I/O on touch.
- **Validation:** Playwright identified a synthetic 1%-opacity fixed layer as
  target/top layer while also finding the product below; capture+bubble and
  touchstart/touchend shared one attempt and no event was prevented by the
  diagnostic. Build, freeze/performance guards, Android/iOS sync and APK build
  pass. APK SHA-256 is
  `30DBE8CF87AAF04098CDE6F3101DEC6DD40DE23858E53703F7A806AF44E3E643`.
  Note 8 was ADB unauthorized. Commit `b5a6e7a` is pushed; GitHub/Xcode
  [run `31308844558`](https://github.com/m7madv/otlobli/actions/runs/31308844558)
  passed. The inspected unsigned IPA is
  `release-artifacts/ios-v86.102-run-31308844558/otlobli-v86.102-iphone16-unsigned.ipa`,
  7,045,998 bytes, SHA-256
  `3E9C88CFF994D64C4688F904737E8CDE34FAA0DB319A46716B158121E4FA96E4`.
  Archive metadata and diagnostic/recompose markers passed; the app root has
  no signature or embedded provisioning profile. Real iPhone acceptance does
  not exist yet.
- **Acceptance:** On first real failure press `نسخ` before store switching,
  then complete the five-path reproduction matrix, five background/resume
  cycles and a separate force-quit/cold launch. Do not claim a fix from build,
  simulator or diagnostic presence alone.

## Hidden SHEIN colour template falsely blocks a no-option product (v86.101, 2026-08-09)

- **Symptom:** A no-option SHEIN nail product showed `حدد اللون أولاً` from
  Otlobli even though the visible product contained quantity only and no
  colour selector.
- **Root cause (confirmed on live Note 8):** `findOptionContainer('color')`
  assigned `fallback` before checking that the candidate was rendered. SHEIN
  may retain hidden colour/recommendation templates in the DOM. A temporary,
  hidden two-button colour fixture reproduced the old result exactly:
  `getColorState()` changed from `{exists:false}` to
  `{exists:true, selected:''}`.
- **Decision:** Evaluate `rendered = sheinElementIsVisible(el) &&
  !sheinCovered(el)` once and admit an option-container fallback only when it
  is rendered. The visible/in-viewport ranking remains unchanged.
- **Why this choice:** It rejects only an impossible customer choice; it does
  not auto-select a colour, remove the real visible-colour guard, scan more
  DOM, add timers, or risk an incomplete cart item.
- **Do not do:** Do not restore the unconditional fallback or suppress every
  colour requirement. A real visible unselected colour must still block add.
  Do not change the iPhone recompose timing, region guard, cache policy, or
  WebView lifecycle for this capture-only issue.
- **Validation:** Production build, iPhone-freeze guard, performance budget,
  Android/iOS sync and Android debug build passed. Android 86.101/961 was
  installed on the connected Note 8. The original no-option diagnostic was
  false both before and after; the hidden-fixture reproduction is true before
  the patch and false after it. No cart write was performed. The unsigned
  iPhone 86.101/961 build completed in [run 31305701128](https://github.com/m7madv/otlobli/actions/runs/31305701128),
  with SHA-256 `D9AC194F1EBA2594F82B68103701A58830289259C95930474EE4F30785B00F4D`.
  Real iPhone product and required iPhone 16 resume acceptance remain pending.

## iPhone launch video: system transition, not Otlobli navigation flash (2026-08-09)

- **Evidence:** The supplied 60-fps video shows the black home-to-app card
  from roughly 0.07 to 0.22 seconds. At 0.25 seconds the Otlobli loading
  surface already contains the complete bottom navigation, which remains
  unchanged through store paint at 2.4 seconds.
- **Decision:** Make no app lifecycle, WebView, recompose, timer, or navigation
  change for this phase. It is SpringBoard's launch animation before app code
  can render; attempting to hide it with another app layer would introduce the
  real visual flicker the project is avoiding.

## App-first store handoff, not a raw browser (v86.100, 2026-08-09)

- **Symptom:** The Android opening could begin with a blank/static strip, then
  repaint Otlobli, then start the store. When the native Otlobli layer faded
  over the React Otlobli layer, a recorded Note 8 frame visibly doubled the
  wordmark and all bottom tabs. The user explicitly requires the app itself
  to open first, then the SHEIN/Temu browser only after that app shell exists.
- **Root cause (confirmed at 10 fps on Note 8):** The fade was a compositing
  transition between two matching Otlobli surfaces—not a SHEIN page,
  networking, region routing, or iPhone rendering fault. Android also needs a
  drawable before Java can create the full native app surface.
- **Decision:** Use the exact local Otlobli loading surface as the Android
  starting-window drawable, retain the matching native surface while the
  Capacitor app renders, then remove the native surface atomically after the
  existing two-render-frame readiness handoff. Keep the store WebView opening
  separately behind the existing region/VPN gate. Android 12+ uses the
  platform SplashScreen API before BridgeActivity initialization.
- **Why this choice:** It removes the observable duplicate draw instead of
  hiding it with more timeouts, reloads, opacity animations, WebView creation,
  or a separate browser screen. It costs one 55 KB local image and adds no
  startup network, JavaScript, polling, or work to weak devices.
- **Do not do:** Do not reintroduce the native alpha fade, replace the
  app-first surface with SHEIN/Temu UI, or trigger a WebView rebuild as part of
  the visual handoff. Do not touch iPhone recompose timing, Android resume,
  or the unchanged-region guard for this incident.
- **Validation:** Android 86.100/960 was built, installed, and recorded on
  the connected Note 8. The post-fix frame series has one stable full Otlobli
  surface before store preparation, without the previously observed double
  wordmark. Production build, iPhone freeze guard, low-end budget,
  Android/iOS sync, and Android debug build passed. APK SHA-256:
  `5D8C52CE73A26DC6C94C3E2E3A0493967814BD84AE6EEB18FB33B062DFC0104F`.
  The unsigned iPhone build completed successfully at
  [run 31304414080](https://github.com/m7madv/otlobli/actions/runs/31304414080)
  from the same source. IPA SHA-256:
  `5DAD64EFB8620B8C5677A97A80A809EB3C61EE3D65199F80C3874EA776A59BFC`.
  Real iPhone device acceptance remains pending.

## Compressed Android SHEIN opening cover (v86.98, 2026-08-09)

- **Symptom:** On Android, startup could show a compact top-aligned Otlobli wordmark/nav, then jump into the intended centred loading screen. This made the customer perceive several different opening screens even after the spinner had been removed.
- **Root cause (confirmed frame-by-frame on Note 8):** `WebViewDialog.presentWebView()` created the native loading cover while the Dialog root still had its transient wrap-content size. The same view later expanded with the Dialog, creating the apparent re-layout. This is not an iPhone remote-layer freeze, a region switch, a font download, or a SHEIN network problem.
- **Decision:** Start the native cover from `WebViewDialog.show()` only, and gate its first paint on 70% of `DisplayMetrics.heightPixels`. The screen is portrait-only, so this display-relative threshold is more reliable than the failed fixed-dp test on the scaled Note 8. Keep the 120dp lower reserve for the real injected navigation. Use one generic preparation line and the same system font/weights across static HTML, React, Android, iOS, and the injected tab bar.
- **Why this choice:** It removes the invalid first render rather than hiding it with an animation, a delay, a second overlay, or a WebView rebuild. System typography also matches the injected SHEIN bar without reintroducing the removed embedded Cairo payload and startup retry.
- **Do not do:** Do not call `showOtlobliLoadingCover()` from `presentWebView()`, reduce its display-height gate to a fixed dp value, or replace it with a spinner/header. Do not alter any protected iPhone recompose timing, the Android resume defense, or store-region comparison as part of this visual fix.
- **Validation:** Android 86.98/958 was built and installed on Note 8. A second 0.2-second cold-start capture series showed no compact Otlobli frame; the eventual branded surface was full-height with all four SVG tabs. Production build, low-end budget, iPhone-freeze guard, patch reverse-check, Android/iOS sync and Android debug build passed. APK: android/app/build/outputs/apk/debug/app-debug.apk, 11,234,493 bytes, SHA-256 028C9D1A71B78463546EEBA311B1D5C9B0F35DAF6A9A0366AB0F612CC5E79416. Real iPhone 16 cold-launch plus five background/resume cycles remain required before iOS acceptance.

## Several SHEIN loading screens and clipped first-frame nav (v86.97, 2026-08-09)

- **Symptom:** Opening the app could expose several visually different loading
  screens. The native SHEIN guard showed a static-looking circular spinner,
  and on Note 8 its full-height overlay sometimes left only bottom-tab labels
  visible while their icons appeared later.
- **Root cause (confirmed on device):** Three independent layers painted
  different startup UI: the static HTML boot shell, React's VPN/preparation
  state, and the native InAppBrowser cover. Android's native cover filled the
  whole window; when the early SHEIN nav was underneath, its SVG icon row was
  clipped before the full page became ready.
- **Decision:** Retain the native cover as a touch/raw-SHEIN guard, but render
  it as the same static Otlobli wordmark plus one status line used by the boot
  and React surfaces. Remove the spinner. Reserve 120dp below the Android
  cover for the actual injected SVG nav; retain the equivalent safe-area
  reserve on iOS. Keep native fade as opacity-only.
- **Why this choice:** Removing the guard would expose a raw SHEIN page and
  reintroduce the flash it was built to prevent. A unified static surface is
  cheaper and calmer than another animation, while reserving the real nav
  preserves the customer requirement that icons are present from the first
  visible store frame.
- **Do not do:** Do not change otlobliForceRecompose, its 0.25s foreground
  scheduling, otlobliOnHostResume(), the JSON region comparison, or WebView
  reopening as part of a loading-visual change. Do not replace the native
  cover with a full-screen spinner or remove Android's 120dp reserve.
- **Validation:** v86.97/957 passed patch reverse-check, freeze guard,
  production build, low-end budget, Android/iOS sync and Android debug build.
  It is installed on the connected Note 8. A cold-start capture at 2.2s
  visibly confirmed the single wordmark/status layout and all four complete
  bottom-nav SVG icons; a subsequent capture reached SHEIN home. iPhone
  source is synchronized, but real iPhone 16 cold-launch and five
  background/resume cycles are still mandatory before iPhone acceptance.
  APK: android/app/build/outputs/apk/debug/app-debug.apk, 11,464,241 bytes,
  SHA-256 6925ED05C4AF125FEF1DA623F250C211C5B36EB2F3F9606C8E4E0CCFC6B24BA5.

## Slow cold startup and intermittent icon-less navigation (v86.96, 2026-08-09)

- **Symptom:** The app was usable once open, but initial entry could feel
  delayed; the customer specifically required the bottom navigation and its
  icons to be visible immediately rather than appearing later.
- **Root causes (confirmed in source):** Startup waited for the remote region
  response even when a valid cached region existed. Its VPN decision started a
  direct selected-store check in parallel but always awaited the separate geo
  service first. In addition, the SHEIN injected nav embedded a full Cairo font
  as a base64 payload and used `font-display:block`, plus a brief font-style
  retry loop. Those are unnecessary first-paint dependencies for a four-tab
  bar whose icons are already inline SVG.
- **Decision:** Show a static local boot shell in `index.html` before React
  parses; it contains the permanent four SVG tabs and is replaced on React's
  first render. Release cached regions immediately and preserve the existing
  JSON comparison before any rebuild. Treat the first decoded image from the
  selected storefront as a successful startup gate; retain geo only as
  non-blocking diagnostic information. Replace the injected-nav font with the
  platform system font and remove the embedded font/retry.
- **Why this choice:** It removes startup waits and payload instead of masking
  them with extra timers, a WebView restart, an optimistic VPN bypass, or a
  delayed navigation mount. It keeps a deliberate first-install safety path
  and every existing region/failure guard.
- **Do not do:** Do not reintroduce a remote/blocking nav font, remove the
  boot shell, await geo before a proven store connection, or open from the
  default region when no cache exists. Do not touch protected iPhone
  recompose/cache-recovery code for this performance change.
- **Validation:** v86.96/956 passed emitted-script parsing, freeze guard,
  production build, low-end budget, Android/iOS sync, Android debug build and
  Note 8 install. The app cold activity launch measured 1.741 s. Passive live
  inspection found a loaded Qatar SHEIN page with visible `#otlobli-nav` and
  four SVGs; the React shell had four SVG bottom-nav icons too. Bundle size
  fell from `1,196,613` to `1,155,517` raw JS bytes and from `353,786` to
  `320,778` gzip JS bytes. This is not iPhone device acceptance.
- **iPhone build:** [run 31288703952](https://github.com/m7madv/otlobli/actions/runs/31288703952)
  was triggered from `a9a1701` and is in progress. It is source/native build
  validation only; real iPhone 16 acceptance remains required.

## SHEIN SKU quantity option was omitted from the cart label (v86.95, 2026-08-09)

- **Symptom:** For the pink three-makeup-bag product `p-216351093`, the cart
  line could show the colour and `M` but omit the selected `1PC` option.
- **Live evidence:** The connected Note 8 page exposed selected `M` beneath
  the `مقاس` heading and selected `1PC` beneath the separate `الكمية` heading.
  They are sibling SKU controls in the same product form.
- **Root cause (confirmed):** v86.91 correctly narrowed size selection so
  that `1PC` could not be mis-recorded as the size. That corrected the old
  first-match bug, but no separate product-quantity field was retained for the
  cart description.
- **Decision:** `sheinSelectedQuantityOption()` reads only selected option
  nodes whose own group is `الكمية`/quantity. The capture payload carries it
  as `quantityOption`; `App.tsx` appends it after the actual size in the stored
  display text, for example `M · 1PC`.
- **Non-negotiable meaning:** `quantityOption` is a SHEIN SKU descriptor, not
  `CartItem.quantity`. The cart stepper remains `1`, and neither price nor
  item count is multiplied. Do not combine this with `bundleCount` or use the
  old generic first `.goods-size` match.
- **Performance/freeze safety:** The helper performs one local selected-node
  read at capture time. It adds no interval, mutation observer, whole-document
  recurring scan, retry, WebView rebuild, cache action, or native lifecycle
  change.
- **Validation:** v86.95/955 passes emitted-script parsing, freeze guard,
  production build, low-end budget, Android/iOS sync, Android build and Note
  8 installation. User acceptance remains: add the selected product after the
  update, confirm `M · 1PC` in the new cart row, and confirm the stepper and
  price still represent one package. An existing row cannot be repaired
  without re-adding because the earlier event never stored this data.
- **iPhone build:** [run 31288237127](https://github.com/m7madv/otlobli/actions/runs/31288237127)
  was triggered from `8d3120b` and is in progress. It verifies build sync only;
  the real iPhone 16 cold launch and five background/resume cycles are still
  required.

## SHEIN human-check bar lost its icons (v86.94, 2026-08-09)

- **Symptom:** The Otlobli bottom bar sometimes began with labels only, then
  looked normal later. On the connected Note 8, the active page was the real
  SHEIN `/ar/risk/challenge` route.
- **Root cause (confirmed):** `otlobliEnsureChallengeNav()` was a separate
  fallback which rendered text-only buttons. Normal store pages use inline SVG
  icons, so the two navigation paths were visually different. This was not a
  failed icon font, a network delay, or an Android paint race.
- **Decision:** Reuse the existing four inline SVG paths and the normal flex
  alignment in the challenge fallback. Inline SVG paints immediately and adds
  no new request, listener, timer, or recompose work.
- **Validation:** v86.94/954 passes the emitted-script parser, freeze guard,
  production build, performance budget, Android/iOS sync, Android build and
  Note 8 install. A cold live storefront showed four visible 22×22 SVG icons.
  The legitimate challenge route was no longer active after restart, so do not
  claim physical challenge-screen acceptance until SHEIN presents it again.
- **iPhone CI:** [run 31287796920](https://github.com/m7madv/otlobli/actions/runs/31287796920)
  was queued from the v86.94 source commit. It cannot validate the required
  real iPhone 16 cold-launch and five background/resume cycles.

## SHEIN human-verification: session preservation, never bypass (2026-08-09)

- **Observed:** SHEIN served `/ar/risk/challenge?captcha_type=909` on the
  Note 8. This is a site-controlled security route, not an Otlobli dialog.
- **Decision:** Do not attempt to disable, hide, auto-click, solve, replay, or
  otherwise evade a human-verification challenge. The app may only preserve a
  real user's successful session and keep the check usable.
- **Current protections:** Android enables SHEIN third-party cookies per
  WebView; normal opens and the bounded HTTP-cache recovery preserve cookies
  and localStorage; the injected script recognizes the challenge, removes its
  own conflicting controls, releases an Otlobli body lock, and stops expensive
  scans until the page itself resolves. No challenge cookie or security header
  is fabricated.
- **Why no permanent guarantee:** challenge systems can vary by request,
  device/session signals, configured duration and site policy. Generic
  challenge documentation describes clearance as time- and behavior-bound, so
  a “never ask again” promise is technically and contractually false.
- **Safe follow-up:** evaluate a single Android `CookieManager.flush()` after
  the user's `humanCheckResolved` signal only. Android documents that this can
  perform blocking I/O, so it must be benchmarked on the Note 8 and never run
  on launch, navigation, or as a retry loop. This is not yet implemented.
- **References:** [Android CookieManager](https://developer.android.com/reference/android/webkit/CookieManager),
  [Android WebView lifecycle](https://developer.android.com/reference/android/webkit/WebView),
  [Cloudflare challenge clearance concept](https://developers.cloudflare.com/cloudflare-challenges/concepts/clearance/).

## SHEIN raw UI + false VPN/preparation message (v86.93, 2026-08-09)

- **Symptom:** Native SHEIN icons/controls reappeared, Otlobli's bottom nav and
  blockers disappeared, then the host showed `تعذر تجهيز المتجر` as if VPN had
  failed.
- **Root cause (confirmed):** The generated capture script was syntactically
  invalid. Source `/\+/g` sat inside a TypeScript template literal and emitted
  `/+/g`, which Chromium rejects. A parse error prevents **every** statement in
  that script from running, including nav/blockers and the ready bridge.
- **Decision:** Emit the literal plus matcher as `/\\+/g`; keep page-loaded
  capture injection as the single path; remove the redundant `preShowScript`
  run. Parse the emitted script in `verify:shein-freeze-guard` before every
  build.
- **Do not do:** Do not diagnose this signature as a VPN/region failure, add a
  WebView restart loop, or weaken native iPhone recompose. Do not write a new
  regex/backslash inside `SHEIN_CAPTURE_SCRIPT` without the emitted-script
  parser passing.
- **Evidence:** Note 8 / v86.93 live home and product had enabled Otlobli nav
  and add button; no raw SHEIN bottom-nav candidate was visible.

## SHEIN quick form: package count is not cart quantity (v86.91, 2026-08-09)

- **Symptom:** The pink bow makeup-bag quick form could store `1PC` instead of
  the chosen `مجموعة (صغير + متوسط + كبير)` option.
- **Evidence:** On the live Note 8 page for `p-216351093`, `1PC` belongs to
  the `الكمية` group, while the three-piece bundle belongs to the separate
  `مقاس` group.
- **Decision:** Scope quick-form selection to the size/measurement group and
  preserve the selected bundle text. Derive the number of items inside a
  bundle for the cart display only (`… · 3 قطع`).
- **Do not do:** Do not set cart `quantity` to the internal bundle count; that
  would place multiple complete packages. Do not return to a first-match
  `.goods-size` selector, because it can read the quantity group first.
- **Acceptance:** Select the three-piece package, add it once, verify the cart
  label shows `3 قطع`, cart quantity remains one package, and price is not
  tripled.

## Native SHEIN loading cover must fail open (v86.91, 2026-08-09)

- **Symptom:** A live storefront could remain covered after a missed ready
  bridge, making it look stuck even though the page had loaded.
- **Decision:** Keep the loading cover visual and dismiss it after 12 seconds
  on Android and iOS if no ready event arrives. This is only a cover timeout;
  it does not reload or recreate the WebView.
- **Do not do:** Do not use this timeout to retime/remove the protected iPhone
  recompose or to add a background retry loop.
- **Build evidence:** Android `86.91/951` APK SHA-256 is
  `5F1C8BE741CB25F1535E4831737EA4091320D8C74DBDE2D84B3E75A1F5AB0B3B`;
  it installed successfully on the connected Note 8.

## زر Curvy: بوابة سابقة كانت تحجب الإصلاح — v86.85 (2026-08-09)

- **الدليل الحي:** في Note 8 كانت قائمة `bsc-quick-add-cart` مفتوحة، و4XL مختار والزر الأخضر ظاهر وقابل للنقر في طبقات DOM.
- **السبب الثاني:** معالج زر Otlobli كان ينفذ `sheinOpenSkuDrawer()` وفحوص اللون/المقاس العامة قبل `addToCartFlow()`؛ لذلك لا يصل أبداً إلى منطق القائمة السريعة الذي أضيف في v86.84.
- **القرار:** إزالة الفحوص المكررة من معالج الزر. `addToCartFlow()` هو نقطة القرار الوحيدة: يقرأ قائمة Curvy إن كانت نشطة، وإلا يطبق منطق صفحة المنتج الطبيعي.
- **ممنوع:** لا تضف حارساً ثانياً في `ensureAddToCartButton()` ولا تعيد `sheinOpenSkuDrawer()` إليه؛ أي تغيير يجب اختباره بإضافة Curvy ومقاس عادي.

## Curvy quick-add فوق صفحة المنتج — v86.84 (2026-08-09)

- **العرض:** فتح «قوام كيرفي» في منتج SHEIN، اختيار `5XL` ثم ضغط زر Otlobli الأخضر لا يضيف شيئاً.
- **السبب:** `bsc-quick-add-cart` نموذج SKU مستقل فوق PDP. كان `addToCartFlow()` يتحقق من المقاس في المستند كله قبل التقاط النموذج السريع، فيرى مقاس الخلفية الفارغ ويرفض العملية، رغم وجود مقاس مختار في النموذج العلوي.
- **القرار:** `sheinQuickAddSelectionState()` هو المصدر الوحيد للحالة أثناء ظهور القائمة السريعة. يجري تمرير جذرها إلى `sheinSizeUnselected(scope)`، ولا يستدعى `sheinOpenSkuDrawer()` أو فحوص الخلفية في هذه الحالة. يظل `sheinQuickAddPayload()` مصدر بيانات المنتج نفسه.
- **التحقق المطلوب:** من جلسة SHEIN مقبولة بالفعل: افتح Curvy، اختر 5XL، اضغط Otlobli، ثم تحقق من السلة أن المقاس 5XL. لم يُنفّذ تجاوز للتحقق الآلي؛ الوصول البرمجي المباشر للمنتج ظهر له تحدي SHEIN.

> **هذا ملف دائم ومتعقَّب في Git. لا تحذفه ولا تستبدله بملخص محادثة.**
> اقرأه مع `CURRENT_STATE.md` و`AI-HANDOFF.md` قبل تغيير WebView أو SHEIN أو
> المنطقة أو السلة أو دورة حياة التطبيق. عند ظهور عطل جديد، أضف له: الجهاز،
> خطوات التكرار، الدليل، السبب بدرجة الثقة، والقرار الحالي.

## تحديث الصيانة الحالي — v86.82 (2026-08-09)

- **لماذا كان البرق يظهر؟** استرداد v86.81 كان يستجيب لأي `ChunkLoadError` حتى في
  الصفحة الرئيسية، وعلى iPhone وAndroid. بعض هذه الأخطاء لا يمنع الصفحة من العمل،
  لكن الاسترداد كان يغلق الجلسة ويفتحها، فيظهر غطاء «جاري إصلاح…» أو برقة بلا فائدة.
  هذا خطأ في **نطاق الاسترداد** وليس دليلاً على أن كل هاتف ضعيف أو أن إعادة إرفاق iOS
  يجب تغييرها.
- **القرار:** الاسترداد الآن لا يعمل إلا على iPhone، وفقط في رابط منتج حقيقي
  `-p-<id>` وبعد خطأ chunk مؤكد. الصفحة الرئيسية وAndroid لا يغلقان ولا يعيدان فتح
  WebView بسبب هذا الحدث. يبقى حد 60 ثانية لمنع أي حلقة.
- **أداء الأجهزة الضعيفة:** أزيل فحص mount الدائم كل 1.5–2.5 ثانية من سكربت بداية
  المتجر. الشريط يعيد التأكد من وجوده فقط عند `pageshow` أو عودة الرؤية، وتفحّصات
  SHEIN/Temu الدورية تتوقف عندما تكون الصفحة مخفية. هذا يقلل CPU والضغط الخلفي عند
  الخروج/الرجوع من دون تعطيل وظائف المتجر وهو ظاهر.
- **ما لا نفعله:** لا نزيد مؤقتات أو مراقبي DOM كحل عام، لا نمسح cache/service worker
  من JavaScript، ولا نجعل أي خطأ صفحة سبباً لإغلاق المتجر. هذه كانت ستخفي العرض
  مؤقتاً وتزيد احتمال عودة العطل، خصوصاً على Note 8.

### اقتراحات عملية قبل إضافة ميزات جديدة

1. افصل أي إصلاح إلى: دليل من LOG أو لقطة، نطاق ضيق، اختبار هاتف، ثم توثيق هنا.
   لا تجمع إصلاح منطقة/سلة/لمس/رسم في تغيير واحد.
2. اعتمد نسخة تشخيص عند الحاجة فقط، لا تجعل التشخيص أو الاسترداد الثقيل يعملان في كل
   جلسة العميل.
3. اختبر كل إصدار حساس على iPhone 16 وNote 8 قبل توسيعه: فتح بارد، منتج من الرئيسية،
   منتج من السلة، عودة من الخلفية، وتبديل المنطقة إن تغير هذا المسار.
4. قسّم `App.tsx` لاحقاً إلى hook خاص بالـWebView عبر دفعات صغيرة مع اختبارات؛ لا
   تنفذ إعادة تنظيم ضخمة أثناء علاج عطل حيّ.

## حالة أدوات التشخيص — v86.83 (2026-08-09)

- أوقف المستخدم أداتي التشخيص الظاهرتين في النسخة العادية: تشخيص السعر/الخيارات
  وتتبع تجمّد iPhone (`LOG`).
- تشخيص السعر لا يُستورد الآن إلى `App.tsx`، لذلك لا يظهر زره ولا يعمل مؤقته ولا
  يدخل كوده في حزمة العميل. المصدر `src/services/sheinPriceDiagnostics.ts` محفوظ
  فقط لنسخة تشخيص مخصصة لاحقاً.
- تتبع التجمّد يبقى مصدره محفوظاً، لكن `SHEIN_IOS_FREEZE_DIAGNOSTICS=false`؛ لا
  يُحقن probe ولا تُفعّل واجهة `LOG`. إصلاح إعادة إرفاق WKWebView والاسترداد المحدود
  يبقيان عاملين؛ إيقاف التشخيص لا يعني إيقاف الحماية.
- حارس الإصدار يفرض أن يكون تتبع iPhone معطلاً وأن ملف تشخيص السعر غير مستورد في
  النسخة العادية. لا تعِد تشغيل أي منهما إلا بإصدار تشخيص منفصل ومطلوب صراحةً.

## قواعد العمل

1. لا نغيّر إصلاحاً مثبتاً لأن عرضاً واحداً بدا مشابهاً. نربط كل تغيير بسجل أو
   تكرار واضح.
2. لا نحل مشكلة أداء بمراقبة مستمرة، مؤقتات متكررة، فحص DOM واسع، أو إعادة فتح
   WebView عند كل عودة. هذه الحلول تؤذي الأجهزة الضعيفة وتخلق ومضات.
3. يحق للاسترداد أن يحدث فقط بعد إشارة فشل مؤكدة، مرة واحدة وبحد زمني، مع حفظ
   بيانات العميل.
4. لا نحذف الكوكيز أو localStorage أو عنوان العميل لعلاج عطل تحميل؛ هي بيانات
   دخول/منطقة. أي تنظيف يجب أن يكون محدداً ومثبتاً.
5. اختبار البناء لا يساوي اختبار الهاتف. أي تعديل في SHEIN/iOS يحتاج iPhone
   حقيقياً، وأي تعديل أداء يحتاج Note 8 أو هاتف Android ضعيف متى كان متصلاً.

## خريطة المشاكل المتكررة

| المجال | العرض | السبب/الدليل | الحل المعتمد | ممنوع |
| --- | --- | --- | --- | --- |
| iPhone / رسم WebView | صفحة ثابتة بعد الخلفية مع بقاء الصفحة حية | مثبت على iPhone 16/iOS 27؛ طبقة رسم WKWebView لا تعود دائماً | إعادة إرفاق واحدة محروسة بعد `appDidBecomeActive` بـ 0.25s، مع حفظ scroll/constraints | إزالة أو إعادة توقيت `otlobliForceRecompose` بلا اختبار خمس دورات حقيقي |
| SHEIN PWA | صورة المنتج أو shell يظهران لكن المنتج يبقى skeleton أو النقر لا يفتح | سجل `ChunkLoadError` لملفات SHEIN versioned ثم `blank`/`ct.html`/`syncframe` | جلسة جديدة محدودة بعد فشل منتج iPhone مؤكد؛ تنظيف HTTP cache فقط ثم إعادة فتح المنتج | إعادة فتح عند كل خطأ صفحة رئيسية، `location.reload`، أو حلقة retry |
| الوميض | رسالة إصلاح/إغلاق-فتح غير ضرورية عند دخول الصفحة أو العودة | v86.81 تعامل مع أخطاء chunks غير حرجة في الصفحة الرئيسية | v86.82 يقصر الاسترداد على iPhone + مسار منتج حقيقي `-p-<id>` | تشغيل الاسترداد على Android أو صفحة SHEIN الرئيسية |
| المنطقة | «جاري ضبط المنطقة» يتكرر أو يظهر متجر قديم | الجلسة القديمة قد تبقي shell/عنوان منطقة سابقة | إغلاق ثم فتح مرة واحدة فقط عند تغير المنطقة الحقيقي؛ native HTTP-cache reset قبل الجلسة الجديدة | polling يعيد البناء عند إعداد لم يتغير أو حذف حارس `JSON.stringify` |
| روابط السلة | صفحة SHEIN Oops ثم صفحة رئيسية تبدو محجوبة | صف quick-add قديم خزّن `/ar/-p-<id>.html` بلا slug | التقاط anchor الحقيقي، fallback `product-p-<id>.html`، إصلاح الرابط القديم عند الفتح | إعادة مولد الرابط الفارغ أو حذف سلال العملاء تلقائياً |
| منتج سريع فوق صفحة أخرى | عنوان/سعر/صورة من الخلفية مع لون/مقاس من نافذة أخرى | درج quick-add منتج مستقل عن PDP الظاهر تحته | التقاط بيانات الدرج النشط فقط | lookup عام حسب pathname أو خلط بيانات الخلفية |
| صورة المنتج واللون | الأيقونة الصغيرة تصبح الصورة الكبيرة | خلط `image` مع `colorImage` | الصورة الكبيرة للمنتج؛ swatch للحقل الصغير فقط | استعمال swatch كصورة أساسية إلا عند غياب صورة المنتج فعلاً |
| الشريط السفلي | ظاهر لكن غير قابل للنقر بجانب drawer/backdrop | فحص مستطيلات قديم اعتبر backdrop تغطية حقيقية | `elementFromPoint` + touch bridge عند document start | تعطيل `pointer-events` للشريط لمجرد وجود backdrop |
| التحقق «لست روبوتاً» | SHEIN قد تطلب تحققاً | قرار من SHEIN، وليس خللاً يجب تجاوزه | الحفاظ على cookies/localStorage وترك صفحة التحقق تعمل | تجاوز أو أتمتة أو وعد «مرة واحدة للأبد» |

## السلسلة الكاملة للمشكلة الأخيرة: لماذا يحصل التحميل المعطّل؟

### ما هو مثبت

1. SHEIN مبني كتطبيق PWA: صفحة HTML/runtime تحمّل ملفات JavaScript كثيرة بأسماء
   وإصدارات متغيرة من `sheinm.ltwebstatic.com`.
2. في التقارير الفعلية كانت الصفحة مرئية وقابلة للتمرير، ثم طلبت runtime ملفات
   versioned لم تُحمّل وأصدرت `ChunkLoadError` عشرات المرات.
3. عند هذا الفشل لا يلزم أن تنهار كل الصفحة: الصورة والصندوق الأول قد يظهران من
   HTML/صور محملة، لكن كود تفاصيل المنتج أو route أو بعض touch handlers لا يكتمل.
4. Temu → SHEIN أصلح الحالة فوراً على الهاتف. الفرق المفيد هو جلسة WKWebView
   جديدة مع تنظيف native لـHTTP memory/disk cache، وليس تغيير البلد أو الحساب.

### ما هو محتمل ولم نسمّه حقيقة مطلقة

SHEIN أو CDN قد ينشر runtime وchunks في لحظات مختلفة، أو قد يحتفظ WebKit/VPN
بنسخة HTML/runtime تشير إلى hash لم يعد الخادم يقدمه لهذه الجلسة. اتصال VPN متذبذب
أو هاتف ضعيف يزيد احتمال تأخر/فقدان تلك الطلبات. هذا خلل في توافق أصول PWA/الشبكة؛
ليس دليلاً أن جهاز العميل ضعيف أو أن منتجاً بعينه سيئ.

كان لدينا عامل تطبيق يزيد الخطر: كود قديم حذف CacheStorage وService Worker داخل
مستند SHEIN عند بداية كل جلسة، وقد ينتج graph مختلطاً أثناء الإقلاع. أزيل نهائياً
في v86.80، ويمنعه فحص الإصدار. لكن ظهور خطأ CDN بعد ذلك يثبت أن الإزالة وحدها لا
تضمن أن SHEIN نفسها لن تفشل في تقديم chunk.

### القرار الحالي

في v86.82 لا نلمس الصفحة الرئيسية ولا Android عند خطأ chunk منفرد. فقط إذا كان
المسار صفحة منتج حقيقية على iPhone وأعلن SHEIN فشل chunk، يطلب الجسر استرداداً
واحداً محدوداً: إغلاق الجلسة المعطوبة، تنظيف native لـHTTP cache فقط، إعادة فتح
الجلسة، ثم إعادة المنتج إن كان الرابط صالحاً. لذلك لا يوجد برق في المسار الطبيعي،
ويبقى علاج المسار الذي أثبت أنه يفشل.

## صيانة وأداء للأجهزة الضعيفة

### ما نفعله

- نبقي `npm run build` تحت حد الأداء؛ لا نرفع الحد لقبول زيادة حجم.
- كل عمل SHEIN الثقيل يتم عند حاجة المستخدم أو حدث حقيقي، لا عند كل frame أو
  كل عودة من الخلفية.
- نستخدم listener واحداً ورسالة واحدة لفشل chunk، وdebounce 60 ثانية؛ لا polling.
- نحافظ على WebView السليم عند العودة؛ إعادة الإرفاق native المحروسة فقط تعالج
  طبقة الرسم على iPhone ولا تعيد تحميل موقع SHEIN.
- نفصل صورة المنتج عن swatch، وبيانات quick-add عن الخلفية، حتى لا نعيد فتح صفحات
  أو نعيد مسح DOM لإصلاح بيانات خاطئة.
- نغلق جلسة المتجر ونفتحها فقط عند تغيير منطقة فعلي أو فشل منتج مؤكد، لا عند كل
  تحديث إعدادات.

### اقتراحات تطوير مستقبلية (لا تنفذ دفعة واحدة)

1. **نسخة تشخيص منفصلة عن نسخة العميل:** اجعل `SHEIN_IOS_FREEZE_DIAGNOSTICS`
   خيار build لنسخة تشخيصية فقط بعد قبول v86.82. إبقاء LOG مفيد للتحقيق، لكنه لا
   يجب أن يصبح حملاً دائماً في كل إصدار طبيعي.
2. **مصفوفة قبول قصيرة ثابتة:** iPhone 16 (خمس عودات + فتح منتج + منتج سلة +
   تشغيل بارد)، وNote 8 (فتح متجر/منتج/سلة وتبديل منطقة). سجّل النتيجة والإصدار
   في `CURRENT_STATE.md` بدل تكرار الاختبار عشوائياً.
3. **تقسيم `App.tsx` تدريجياً:** انقل منطق متصفح المتجر لاحقاً إلى hook مستقل
   (`useStoreWebview`) مع اختبارات. لا تنقله الآن في إصلاح عاجل؛ الملف حساس وفيه
   دورة حياة وسلة ومنطقة مرتبطة.
4. **تنظيف تشغيلي، لا حذف أعمى:** لقطات الأجهزة المحلية تبقى ignored، والسيرفر
   الفعال هو `server/` بينما `server-whatsapp/` تاريخي. لا تحذف مجلدات أو بيانات
   حساب/جلسة لمجرد أن اسمها قديم.

## قالب إضافة مشكلة جديدة

```md
## [تاريخ] — عنوان قصير

- الجهاز/الإصدار:
- خطوات التكرار:
- الدليل: (LOG، لقطة، رابط، خطأ بناء)
- ما هو مثبت:
- ما هو محتمل:
- القرار/الإصلاح:
- ممنوعات لمنع العودة:
- التحقق المنفذ:
- اختبار الهاتف المتبقي:
```
## Android pre-WebView navigation blink (v86.99, 2026-08-09)

- **Symptom:** On a slow Note 8 cold launch, the Otlobli navigation appeared only after a visible 1–2 second white page, even though the React boot shell and the later native SHEIN loading cover each contained tabs.
- **Root cause (confirmed frame-by-frame):** Android's activity starting window happens before Java, Capacitor, React, and WebView construction. `Theme.SplashScreen` was therefore rendering a bare white preview outside the ownership of every existing loading/navigation layer. The earlier attempt to use several positioned children in an Android `layer-list` was rejected by the device renderer: it overlaid the icons in one corner.
- **Decision:** On Android 9 and below, use `AppTheme.NoActionBarLaunch` with `otlobli_starting_window.xml`; it contains one static-vector, four-icon Otlobli strip. `MainActivity.load()` adds an adaptive native surface with full RTL labels before `super.load()` can create the WebView. `OtlobliLaunchSurface.ready()` runs only on Android and only after two React frames. The established SHEIN cover remains responsible for the later store-preparation stage and retains its 120dp nav reserve. Android 12+ keeps its required system splash via `values-v31`, then receives the same native handoff.
- **Why this choice:** It fixes the only phase that JavaScript and the WebView cannot reach. It is deterministic, network-free, has no polling or timer recovery, preserves the existing freeze invariants, and uses a single drawable that the legacy renderer can place correctly.
- **Do not do:** Do not restore `Theme.SplashScreen` as the legacy launch theme, remove the starting-window vector, or replace it with a delayed/animated/remote surface. Do not add a new WebView close/reopen, alter iPhone `otlobliForceRecompose` timing, change Android `otlobliOnHostResume()`, or rebuild a store because of this visual issue.
- **Validation:** Android 86.99/959 passed build, low-end budget, iPhone-freeze guard, Android/iOS sync and Android debug build. It was installed on the connected Note 8; an 8-second cold-start recording sampled at 5 fps showed static tabs in the starting window and the full labelled native bar immediately after, with no app-owned blank/tab-less interval. APK: `android/app/build/outputs/apk/debug/app-debug.apk`, 12,574,241 bytes, SHA-256 `89680514B56FE6FD14992079A2B66D85BFA84CABD9E6BC8B99D7EA050E9D0BA9`. This is not real iPhone acceptance.
