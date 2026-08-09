# Current candidate — v86.120 supported-region SHEIN recovery (2026-08-10)

- Real-device evidence: the host confirmed Qatar but showed the network/VPN
  failure and its retry did not enter SHEIN. Unexpected `closeEvent` wrote
  `network` directly, bypassing the trusted-access conversion. A later supported
  geo result updated `vpnState` only, and retry could race the close listener.
- Keep supported geo/store success/trusted continuity mapped to `preparation`.
  Arm `sheinCacheResetPendingRef` for that user-driven retry; clear HTTP
  memory/disk cache only. Preserve cookies, localStorage, verification and the
  signed address. Never show the VPN diagnostic action for confirmed support.
- The primary retry resets `sheinRecoveryAttemptRef`, suppresses the intentional
  close event only, then opens one fresh WebView after close completion. Do not
  turn it into an automatic open/close loop or add polling/timers/effects.
- Preserve v86.119's 650ms route-aware concealment and no duplicate product
  scan, plus the approved native back control and all protected lifecycle code.
- Version `86.120/980`; diagnostics off. Build, guards, native syncs, Android
  debug assemble and Xcode run `31340352422` pass. Local bundle SHA-256 is
  `5E7E2860003D7C15D6BBAC88B5953650D12DE16E9D57668565E52CEAB3331C6A`;
  debug APK SHA-256 is
  `5D3F7B9214226C269FC374DD488E06F208155D30514DB86ACBE929867E8A5E7E`.
  Repo lint remains red on the unrelated existing 33 errors/16 warnings.
- Desktop IPA:
  `C:\Users\MOHAMMAD\Desktop\otlobli-ios-v86.120-iphone\otlobli-v86.120-iphone16-unsigned.ipa`,
  7,050,591 bytes, SHA-256
  `85B8ED5EBAC73930C44EBED56E9EABD2CFBC2704715EE23795ECCBE323395392`.
  CI JS is `index-D0TTUAIG.js`, SHA-256
  `B6CC7FE4D8FC9F7F2959CA548EDC60A05695D17CBD5166E5424092C244F3EC8A`.
  IPA is unsigned/unprovisioned and lacks production APNs/Google iOS setup.
- Required acceptance: cold entry from Qatar on the pictured device, retry
  after an interrupted open, product/back/concealment, five iPhone 16 resume
  cycles, cold launch and SHEIN → Temu → SHEIN.

# Current candidate — v86.116 iPhone 6 recovery and sticky-price back layer (2026-08-10)

- v86.115 failed on the real iPhone 6: the host still showed a preparation
  screen and SHEIN's sticky price header covered the back button after scroll.
- Keep the broadened but bounded home readiness rule: two decoded images plus
  one semantic control or 500 characters. New SHEIN cards are often clickable
  non-semantic wrappers, so requiring three `a/button/role=button` controls
  falsely rejects a painted store on the old phone.
- Fatal iOS WebKit errors and an unexpected close of a ready SHEIN view reuse
  `recoverSheinChunkLoad()`. It is still iOS/SHEIN-only, one incident per 60s,
  preserves the current product URL, cookies/storage/signed address, and clears
  HTTP runtime cache only. If that bounded recovery is unavailable, the host
  error remains. Preparation errors do not show the VPN diagnostic action.
- Keep `otlobliStabilizeBackOverlay()` under `document.body`, not directly
  under `html`. It reclaims last body paint order only when the existing
  hit-test proves coverage, disables animation before reparenting, and keeps
  the iPhone 6 top at `58px`. The executable guard inserts a synthetic sticky
  price layer after the button and proves the button reclaims the last layer.
- No new listener, timer, observer, scan, WebView loop or native recompose was
  added. The performance approach follows the installed React guidance: reuse
  refs and the existing event-driven bounded recovery instead of new state or
  polling.
- Version `86.116/976`; diagnostics off. Build, freeze/performance guards,
  Android/iOS sync, diff check and Android debug assemble pass. Bundle
  `index-D5vXFFT1.js`, 1,166,461 bytes, SHA-256
  `4C588085CFE27B56B27DDF4A98FEB83376F0D40929C13683DF67D4D2BEFAA9A9`.
  Debug APK is 11,169,400 bytes, SHA-256
  `D3686E905715E41F392459B3A5A750CF3A350F9E2475C69F118D3469540CD734`.
- Xcode run `31336148034` passed from `bbb3143`. Desktop IPA:
  `C:\Users\MOHAMMAD\Desktop\otlobli-ios-v86.116-iphone\otlobli-v86.116-iphone16-unsigned.ipa`,
  7,045,748 bytes, SHA-256
  `A3E8741247DD9F80FAEF98ED2EA6D1F81E1E0B9E72045D8E73342308D0FD920C`.
  It is `com.otlobli.app`, `86.116/976`, arm64/iOS 15+, and contains the body
  back-layer, readiness, push, hidden-reveal and native-recompose markers. CI
  JS is `index-D6AvzqBz.js`, SHA-256
  `F02FD430BC9643D8E442AEC98E7819FCA028A8E49F2E1DF8EC1C4203AC05F416`.
- IPA is unsigned/unprovisioned, lacks APNs entitlement and Google iOS callback
  scheme; do not call it App-Store-ready. Real-device acceptance remains:
  pictured iPhone 6 scroll, longer browsing/recovery, five iPhone 16 resume
  cycles, and one force-quit/cold-launch.

# Previous candidate — v86.115 supported VPN continuity and iPhone 6 back layer (2026-08-09)

- Do not reintroduce false VPN advice after Qatar/another supported location
  or a successful store session is known. A transient geo/store-probe timeout
  now preserves that evidence; explicit Syria still gates, offline stays
  offline, and store switching clears the reachability evidence.
- `showStoreOpenFailure()` maps a network-looking WebView failure to bounded
  store preparation when access is already trusted. This prevents an ordinary
  SHEIN load failure from telling a Qatar user to change VPN.
- The iPhone 6 back issue was stacking order, not its offset. Keep
  `otlobliStabilizeBackOverlay()`: the button is rooted directly under
  `document.documentElement` with fixed/max-important stacking and pointer
  events. Keep the existing `58px` top at widths `<=390px`; modern iPhones keep
  their existing position. The helper is idempotent and adds no timer/scan.
- The freeze verifier contains static VPN/back-layer assertions plus an
  executable reparent/style fixture. Preserve them.
- Version `86.115/975`; diagnostics off. Build, freeze/performance guards,
  Android/iOS sync, diff check and Android debug assemble pass. Synchronized
  bundle `index-DJYgI4go.js`, 1,166,206 bytes, SHA-256
  `7E2302F00879ED6C4C46AE08AF1AFF0EAAB2D8D641860BFE13D14F087F91162F`.
  Debug APK is 11,170,941 bytes, SHA-256
  `31E342B6B8156E5A54453E6E0D1AB43C3E18D0E310ABDF4402503F48E18947F8`.
- Xcode run `31334667716` passed from `d6236e5`. Desktop IPA:
  `C:\Users\MOHAMMAD\Desktop\otlobli-ios-v86.115-iphone\otlobli-v86.115-iphone16-unsigned.ipa`,
  7,045,678 bytes, SHA-256
  `487557AD139DDE8DEF37BCC8E90B6CD0ED13D001334E676878D97953407BB6A5`.
  It is `com.otlobli.app`, `86.115/975`, arm64/iOS 15+, and contains the back,
  VPN-recovery copy, push, hidden-reveal and native-recompose markers. CI JS is
  `index-BSb3bB3x.js`, SHA-256
  `E2827A8BDD1F7FD0375DDF739D3C716901BBE4F58E882EDE5E30BF13CC63D287`.
- IPA is unsigned/unprovisioned, lacks APNs entitlement and Google iOS callback
  scheme. Do not call it App-Store-ready. Real-device acceptance remains:
  iPhone 6 product navigation, five iPhone 16 resume cycles, and one separate
  force-quit/cold-launch test.

# Previous candidate — v86.114 instant SHEIN native add concealment (2026-08-09)

- User symptom: on product entry, SHEIN's own black add-to-cart control remains
  visible until a down/up scroll. This is concealment, not Otlobli button size.
- Live Arabic SHEIN inspection identified the control as
  `j-add-to-bag add-cart__normal-btn productAddBtn`. The bootstrap stylesheet
  matched `add-bag`, not the real `add-to-bag`; the bounded geometry/text scan
  only caught it after later layout work.
- Keep v86.114's fix: `hideEarlySheinProductAdd()` installs the SHEIN-only CSS
  before checking `/-p-\\d+/`, so a home session is already protected when SPA
  navigation creates the product control. Selectors cover `add-to-bag`,
  `add-cart`, equivalent compact variants and exact add-to-cart ARIA hints.
- This is intentionally CSS-only at insertion time: no new interval,
  MutationObserver scan, scroll event, or native recomposition was added. The
  freeze verifier enforces the selectors and ordering.
- Version `86.114/974`; diagnostics off. Build, freeze/performance guards,
  both native syncs, diff check and Android debug assemble pass. Synchronized
  bundle `index-DsS0ZeUp.js`, 1,166,026 bytes, SHA-256
  `0C2F9B163923FB1467313983DA2A0B0FBED7DEDBA29D796EEBE72B703E367520`.
  Debug APK SHA-256 is
  `9678319D4A7762D65F3004079C68421CC0BFF64849B0FF40A642215AD2851AEA`.
- Xcode run `31333940354` passed from `dd45e4f`. Desktop IPA:
  `C:\Users\MOHAMMAD\Desktop\otlobli-ios-v86.114-iphone\otlobli-v86.114-iphone16-unsigned.ipa`,
  7,045,624 bytes, SHA-256
  `4B2A982E5563552C95F0AB4818D7659EEDF7ABF58F171EC099C281D83858856B`.
  Archive is `com.otlobli.app`, `86.114/974`, arm64/iOS 15+, and contains the
  new add-button selectors, push code, `FAKE_VISIBLE`, and native recompose
  marker. CI JS is `index-DMbii6YN.js`, SHA-256
  `58F70542C0A2C45DCF1890DB147A38C47E1983442F288206810D8E7C4C7D067D`.
- IPA is unsigned/unprovisioned, lacks APNs entitlement, and has no Google iOS
  callback scheme. Real-device acceptance is pending; do not describe it as
  App-Store-ready. Preserve v86.113 hidden reveal and iPhone 16 invariants.

# Current candidate — v86.113 host-first iOS SHEIN reveal (2026-08-09)

- The iPhone 6 screenshot showed the native Otlobli loading cover plus only
  two/clipped injected nav tabs for about two seconds. The cover reserved the
  nav gap while the not-yet-presented WKWebView changed from its preparation
  viewport to the actual device frame.
- Keep the chosen boundary: iOS SHEIN opens with `hidden: true` and
  `InvisibilityMode.FAKE_VISIBLE`, so it executes at full window dimensions
  offscreen. React's already-mounted loading screen/nav stays visible until the
  existing readiness path clears `webviewOpeningRef` and sets `sheinReady`.
- Keep the home visibility guard before `InAppBrowser.show()`:
  `if (webviewOpeningRef.current || !sheinReadyRef.current) return undefined`.
  This is essential on recovery reopens where `setSheinReady(false)` can cause
  another render before the new hidden WebView is ready.
- `verify:shein-freeze-guard` now enforces the full-size hidden options and the
  readiness-before-show ordering. Do not replace this with a reveal timeout.
- No plugin/native change was required. Preserve the exact iPhone 0.25-second
  recompose invariant, Android resume defense, store-region JSON comparison,
  cart-session isolation, toast guard, and all verification/payment logic.
- Version `86.113/973`; diagnostics off. Build, freeze/performance guards,
  diff check, Android/iOS sync and Android debug assemble pass. Bundle
  `index-DL3biifD.js`, 1,166,014 bytes, SHA-256
  `67BFFFB018100AE645D37661B6D1C00AA002105AE951119F942ECE6B9C154028`,
  is identical across dist/Android/iOS. Debug APK SHA-256 is
  `8258C347DB214BFABF11141E17C44259C7D6394D5DF7491FDDC533036E44E916`.
- Full lint remains at the pre-existing baseline (33 errors, 16 warnings) and
  reports no v86.113 line.
- Xcode run `31332963586` passed from `247908a`. Desktop IPA:
  `C:\Users\MOHAMMAD\Desktop\otlobli-ios-v86.113-iphone\otlobli-ios-v86.113-iphone16\otlobli-v86.113-iphone16-unsigned.ipa`,
  7,045,681 bytes, SHA-256
  `A767F73D56AB17F3A2FB54A7FCC41CC29E311D31D66A43C3A0FF16BFF140AB43`.
  Archive is `com.otlobli.app`, `86.113/973`, arm64/iOS 15+, and contains
  production Supabase, push, version/`FAKE_VISIBLE`, and native recompose
  markers. CI JS is `index-DguZdE19.js`, SHA-256
  `19A81FF6CB7541FC3533EEC6EA2818274699469F8A7B0E287491A1DF6BD57E51`.
- IPA is unsigned/unprovisioned, lacks APNs entitlement, and has no Google iOS
  callback scheme because that CI secret remains absent. Real-device acceptance
  is still pending; do not describe this artifact as App-Store-ready.

# Previous candidate — v86.112 iPhone 6 black success-toast entry guard (2026-08-09)

- The user clarified the iPhone 6 symptom: the compact black SHEIN “added to
  shopping cart successfully” bar is already visible above Otlobli nav on
  product entry. It disappears after pressing Otlobli add or quickly navigating
  to Otlobli cart. Do not conflate this with the iPhone 16 tap-session defect.
- Exact cause: `hideSheinCartSuccessToast()` was gated by
  `__otlobliCartToastGuardUntil`, but that deadline was assigned only inside
  `addToCartFlow()`. Thus the user's add click was what enabled the already
  correct detector; cart navigation only hid the WebView.
- Preserve v86.112 behavior: track the current `-p-<id>` key, arm the existing
  bounded scan for 15 seconds on new product entry, reset the key off product
  routes, and run the guard before `ensureAddToCartButton()`. The later seven-
  second add-flow rearm remains. No timer or observer was added.
- The freeze verifier evaluates the real emitted helper with a 375×667 Arabic
  black-toast fixture: product entry hides it without an add click, non-product
  entry does not, and static ordering keeps the guard ahead of the add button.
- Version `86.112/972`; diagnostics off. Build/freeze/performance, patch reverse
  check, diff check and both native syncs pass. Bundle `index-CtL87wKm.js`,
  1,165,969 bytes, SHA-256
  `5C4B6FDBFB705FCA400E5EFC924AE92010C52EAC28FC2754C6CB0BC574AC3DBB`,
  is identical across dist/Android/iOS. SHEIN source is `549,734/550,000`, so
  reduce source before any further addition.
- Xcode run `31331834857` passed from `9759e2b`. Desktop IPA:
  `C:\Users\MOHAMMAD\Desktop\otlobli-ios-v86.112-iphone\otlobli-ios-v86.112-iphone16\otlobli-v86.112-iphone16-unsigned.ipa`,
  7,045,614 bytes, SHA-256
  `8FCFD6E90D70AC32F8726B6FD0CB3A30716E2EDA4A71AB750861263488D2CE71`.
  Archive is `com.otlobli.app`, `86.112/972`, arm64/iOS 15+, and contains the
  version/product-entry/15-second/hidden-toast markers, push code and preserved
  native lifecycle/navigation symbols. CI asset `index-BLmbZ9qY.js` is
  1,167,157 bytes, SHA-256
  `AD3A15C15A653970C9C7862CB4182B7AB5B052CEDCED26EACB1B9483C4507614`.
- IPA remains unsigned/unprovisioned, without APNs entitlement or Google iOS
  callback. Real iPhone 6 acceptance is still required.

# Previous candidate — v86.111 iOS SHEIN cart-product fresh session (2026-08-09)

- The user tested v86.110 on both iPhone 16 Pro Max and iPhone 6 and confirmed
  the cart-triggered product-navigation failure remains. Treat that result as a
  rejection of the previous delayed recovery hypothesis.
- Proven reproduction: warm SHEIN → Otlobli cart → open a saved SHEIN product;
  later the SHEIN shell/categories may still paint but product taps do not
  commit. Temu → SHEIN immediately restores product navigation.
- Root code difference: the old cart path reused the hidden active WebView via
  `InAppBrowser.setUrl`; store switching closes the old WebView, clears only
  WebKit disk/memory HTTP cache, and opens a new WebView. v86.111 applies that
  proven boundary automatically before every iOS SHEIN cart-product open.
- Keep `openIosSheinCartProductInFreshSession()`: it closes the tracked
  singleton, invalidates any in-flight session, resets the existing bounded
  cache flag, and opens the target in a new session while the React cart stays
  visible until readiness. Cookies, localStorage and signed region persist.
- Keep the new verifier invariant: the iOS branch must return before warm reuse
  and `setUrl`; the fresh helper must reset cache/reopen and must not contain
  `setUrl`. Do not replace this with another tap timer, reload loop, or native
  recompose burst.
- Version `86.111/971`; diagnostics disabled. Build/freeze/performance,
  persistent patch reverse-check, diff check and both native syncs pass. Bundle
  `index-CcGBMKpA.js` is identical across dist/Android/iOS, SHA-256
  `65324888D9C71274148A93B9319B17260262900401F45B4096901CEAE85CD9C3`.
  Budgets: JS raw `1,165,420/1,200,000`, gzip `322,344/370,000`, SHEIN source
  `549,182/550,000`.
- Xcode run `31330410350` passed from `c2eb127`. Desktop IPA:
  `C:\Users\MOHAMMAD\Desktop\otlobli-ios-v86.111-iphone\otlobli-ios-v86.111-iphone16\otlobli-v86.111-iphone16-unsigned.ipa`,
  7,045,461 bytes, SHA-256
  `A9F04E68C55E7DE5EC9C35701D413B941986165AFA4CE148F5D178E2E1505390`.
  Archive: `com.otlobli.app`, `86.111/971`, arm64, iOS 15+, production
  Supabase input, push code, fresh-session/version markers and preserved native
  lifecycle symbols. CI asset `index-BJBAX-bI.js` is 1,166,608 bytes, SHA-256
  `0FEDE1104A15B0C8C66DCB4A61EA86C135D1ACB47BE98DDAAB344C5722418AA4`.
- The IPA is unsigned/unprovisioned, lacks an APNs entitlement, and GitHub still
  lacks the Google iOS OAuth client. It is not App-Store-ready. Real-device
  acceptance remains: exact saved-cart sequence on iPhone 6 and iPhone 16 Pro
  Max, several listing products, five iPhone 16 resume cycles and one cold
  launch before claiming acceptance.

# Previous candidate — v86.110 SHEIN review guard and stalled-tap recovery (2026-08-09)

- The add button disappearing at ratings/comments was a local false viewer
  classification: the old loose counter regex accepted the `9/5` substring in
  a rating such as `4.9/5`. Keep `sheinViewerHasVisibleCounter()` and the
  review/rating/comment exclusion. The real viewer must still have a visible
  standalone integer counter such as `1/7` plus large media and near-full-screen
  geometry.
- Long-session iPhone product taps can coincide with the already proven SHEIN
  PWA chunk failure. Do not restore eager recovery for every home/listing
  `ChunkLoadError`; v86.81 showed that causes needless close/open flashes.
  `OTLOBLI_SHEIN_CHUNK_FAILURE_BRIDGE_JS` now records that error silently and
  reports it only on a product route or after a real stalled iPhone product
  tap. The tap fallback recognizes direct `-p-<id>` anchors before obfuscated
  card classes and preserves the product URL for the host recovery.
- Preserve the host's existing iOS-only 60-second recovery debounce,
  HTTP-cache-only reset, cookies/localStorage, and product resume URL. No new
  timers/scans were added. Preserve the exact native 0.25-second guarded
  `appDidBecomeActive` recompose and Android `otlobliOnHostResume()` defense.
- The expanded freeze verifier has executable regressions for non-eager listing
  errors, stalled-tap recovery, product URL preservation, direct-anchor routing,
  review/rating false positives and real viewer detection.
- Version `86.110/970`. Build/freeze/performance, diff check and both native
  syncs pass. Bundle `index-D_2Iz6xX.js` is identical across dist/Android/iOS,
  SHA-256 `4E4D026114738DD33E66A0B1BB56F2144F51ED927630A5CA38CEFC6BDA5CFF7E`.
  SHEIN source is `549,182/550,000`; reduce before adding more.
- Xcode run `31329654038` passed from `ecc7224`. Desktop IPA:
  `C:\Users\MOHAMMAD\Desktop\otlobli-ios-v86.110-iphone\otlobli-ios-v86.110-iphone16\otlobli-v86.110-iphone16-unsigned.ipa`,
  7,045,328 bytes, SHA-256
  `2E78266CA7BCB7CFAF2F9D56CAE17E148C256707229AB0C15967E67D41C8A634`.
  Archive is `com.otlobli.app`, `86.110/970`, arm64, iOS 15+, and contains the
  new review/tap markers plus native recompose and push code. App-level signing,
  provisioning, `aps-environment`, and Google iOS OAuth callback are absent;
  do not call it publish-ready. All real-iPhone acceptance remains pending.

# Previous candidate — v86.109 iPhone 6 first-frame SHEIN add concealment (2026-08-09)

- Cause: `hideListingCardAddButtons()` deliberately allowed only controls up to
  96px, so the old iPhone 6 product-width SHEIN add action stayed visible until
  Otlobli's own add flow changed the page.
- `OTLOBLI_NAV_BOOTSTRAP_SCRIPT` now installs product-route CSS before first
  paint for stable add classes and uses the existing bounded protection loop
  for obfuscated controls. `SHEIN_CAPTURE_SCRIPT` maintains the same defense.
  Both use exact Arabic/English add text plus bottom geometry and exclude every
  `[id^="otlobli"]` node. Keep the `للسلة` spelling in `isAddToCartText()`.
- Performance bounds are deliberate: no observer/timer was added; scans are
  capped at 140 candidates plus a 3×3 point stack and throttled to 350/450ms.
  SHEIN source is close to its ceiling at `549,717/550,000`; reduce existing
  code before adding more.
- Browser fixture at 375×667 with an iPhone 6 UA passed: known-class and
  obfuscated native add controls were hidden in bootstrap and full-script
  phases; Otlobli nav remained visible and interactive.
- Version `86.109/969`. Production build/freeze/performance, patch reverse
  apply, diff check and both native syncs pass. Local synchronized bundle
  `index--wBuHHo_.js` is identical in dist/Android/iOS, SHA-256
  `1F659B17400E4909520486A87BCA6D8A1CBBC37C539C5A7B116951775B9ADECF`.
- Xcode run `31328598144` passed from `7504cda`. IPA is
  `C:\Users\MOHAMMAD\Desktop\otlobli-ios-v86.109-iphone\otlobli-v86.109-iphone16-unsigned.ipa`,
  7,045,851 bytes, SHA-256
  `876CA8BB521B24FDC9D0FE2D9E450D259A07C6BF35841FDE5A7309F73EC1FD39`.
  Archive: `com.otlobli.app`, `86.109/969`, arm64, minimum iOS 15, expected
  product-action/push/Supabase markers, no signature or provisioning profile.
- Do not call this publish-ready: `VITE_GOOGLE_IOS_CLIENT_ID` is still absent,
  so Google/callback are hidden; Apple signing, `aps-environment`, provisioning
  and APNs server credentials are also absent. Those owner-controlled values
  are required for the user's Google/push/App Store requirement.
- Real iPhone product acceptance remains pending, as do cold start and five
  background/resume cycles. No recompose/lifecycle/region/payment logic changed.

# Previous candidate — v86.108 persistent SHEIN verification session (2026-08-09)

- Preserve SHEIN's authentic trust state; never manufacture or replay a token.
  Android enables third-party cookies only for a SHEIN-hosted initial URL, so
  the verifier frame can return its genuine result. On
  `humanCheckResolved`, `CookieManager.flush()` persists the resulting jar
  before a store switch/process stop. The string check is bounded to the
  existing event and adds no timer, scan, network request or React render.
- iOS already uses the default persistent `WKWebsiteDataStore`; do not replace
  it with an ephemeral store. `clearCache()` removes disk/memory cache only and
  all current recovery/switch comments deliberately preserve cookies and local
  storage. No app path calls `clearCookies`/`clearAllCookies` for SHEIN.
- This reduces repeat checks after app close and SHEIN → Temu → SHEIN, but
  SHEIN can still demand a new check when its cookie expires/is revoked or the
  risk context changes. Never document this as “once forever.”
- Version `86.108/968`. Build/freeze/performance, both native syncs, persistent
  patch clean-apply, Android Release compile, signature/metadata and DEX marker
  checks pass. APK is 9,179,632 bytes, SHA-256
  `E15B9BF4BC677A4A1F9256AD8A7F79BA133D74FAADD87DAB866C0675D8459AD1`.
- Real Note 8 install passed in place; package is non-debuggable `86.108/968`,
  process is alive and startup log has no fatal/ANR marker. Complete one real
  SHEIN check and retest close/reopen plus Temu switch before claiming actual
  server acceptance. iPhone lifecycle acceptance is also still pending.
- Preserve all v86.107 challenge guide/recovery behavior and the iPhone 0.25s
  recompose, scroll/constraints, Android host-resume defense and unchanged
  region `JSON.stringify` guard.

# Current candidate — v86.107 SHEIN human-check guard (2026-08-09)

- Root cause on the real Note 8: SHEIN's visible verifier is
  `.one-pass-dialog`; its adjacent `#one-pass-custom` host is `0×0`, so the old
  painted-element check missed it. Closing the verifier leads to SHEIN's
  misleading “تمت إزالة المنتج” page. The same tick also called the challenge
  detector twice, so the first call could consume the 1.5-second scan throttle.
- `src/services/sheinHumanCheck.ts` owns the bounded challenge behavior. Keep
  `.one-pass-dialog` and `__otlobliChallengeScanResult`: they are both required.
  No additional timer/observer was added; the existing store tick is reused.
- This is not a CAPTCHA bypass. While the challenge is visible, show the compact
  Arabic guide, suppress Otlobli's product action and preserve bottom navigation.
  Persist pending state for at most 15 minutes. If the user skips the challenge
  and SHEIN shows its removed-product page, notify the host and return to the
  product list or cart. Successful verification clears the gate normally.
- Version `86.107/967`. Production build, freeze guard and performance budget
  pass (`1,161,968` JS raw, `322,563` JS gzip, `63,670` CSS, `81,364` fonts,
  `545,533` SHEIN source). Android/iOS sync passed; final native assets contain
  both the visible-dialog selector and cached scan result.
- Live Note 8 inspection confirmed the real challenge structure and text. A
  controlled diagnostic confirmed guide + action gate + preserved navigation.
  The final post-cache source still needs Android Release packaging and install.
  The temporary debug build was removed; the Note 8 is back on the prior
  non-debuggable v86.107 artifact, which must not be claimed as the final fix.
- Preserve the iPhone `appDidBecomeActive` 0.25-second recompose, scroll and
  constraints, Android host-resume defense and the region `JSON.stringify`
  guard. Real iPhone five-cycle resume and cold-launch acceptance remain pending.

# Current candidate — v86.106 Android nav parity + production signing gate (2026-08-09)

- Treat v86.105 as rejected by the user's two screenshots. Its bounds evidence
  was invalid because UIAutomator saw the preserved hidden InAppBrowser. Real
  Note 8 CDP measured SHEIN `12px/100% text-size-adjust` versus React `13.2px`
  under system `font_scale=1.1`; icon and cell geometry already matched.
- `src/main.tsx` performs one bounded Android-only pre-mount font probe and sets
  `--otlobli-nav-font-size`. Only the four fixed labels are compensated to the
  accepted 12px; the rest of the app still respects the user's font scale. No
  timer, observer, React state or repeated layout work was added.
- `WebViewDialog.java` now applies the same `#F7F9FB` system-navigation surface
  and dark navigation icons to the foreground store dialog. The main app styles
  declare the same light navigation policy. Keep this in the persistent patch.
- Version `86.106/966`. Production build embeds Supabase and enables Google +
  Push. Freeze/performance pass: `1,159,657` largest JS, `322,314` total JS
  gzip, `63,670` CSS, `81,364` fonts, `549,985` SHEIN source. Android/iOS sync
  and Android Release Java/resources compile pass. Generated Release resources
  contain Google app/web client/FCM sender IDs; merged manifest contains FCM,
  notification permission and Social Login.
- Main-app Release signing now fails closed and reads four `OTLOBLI_APP_*`
  values from Gradle/environment or
  `%USERPROFILE%/.android/otlobli-main-upload.properties`. No existing app
  production/upload key or values were found; only debug and the unrelated
  ShamCash listener key exist. Do not use either for the customer release.
  Both modules' fail-closed checks are task-scoped and were dry-run verified:
  building `:app` requests only `OTLOBLI_APP_*`, while building the listener
  requests only `OTLOBLI_LISTENER_*`.
- User narrowed the request to updating the existing Note 8. To preserve its
  data, Android required the same installed certificate. A non-debuggable
  Release APK was therefore signed with the registered debug certificate only
  for that in-place device update; do not call it the Play artifact. APK:
  `android/app/build/outputs/apk/release/app-release.apk`, 9,179,401 bytes,
  SHA-256 `BFB289191B867CD6B2E84E63AE4D433726D8F9015EFC2046C9A51F63E49CEC17`.
  Signature matches v86.105, metadata is `86.106/966`, and production
  Supabase/Google/Push/release markers are embedded.
- Install on real `SM-N950F` passed without clearing data. Home + Orders both
  show dark Android navigation controls. The inactive `حسابي` label is exactly
  identical in both device PNGs (`79×35`, x `96…174`, y `1989…2023`, 489 dark
  pixels). Cold launch: process alive, zero fatal/ANR, zero push-registration
  error markers. User explicitly accepted it as fully fixed.
- Nothing was published. If Play publication is requested later, Firebase CLI
  is expired and the three signed-in accounts lack `otlobli-1ccf5`; obtain the
  owning account and explicit approval for a permanent upload key, then register
  upload and Play app-signing certificates. Never reuse this device certificate
  as the claimed store identity.
- Preserve the iPhone 0.25s recompose, scroll/constraints, Android resume wake,
  region `JSON.stringify` guard, payments, wallet and cart/order logic. Real
  iPhone and signed Android device acceptance remain pending.

# Current candidate — v86.104 stable SHEIN nav from first frame (2026-08-09)

- Device screenshot showed the injected Otlobli nav initially at the 90px/16px
  fallback, then rising when SHEIN's viewport meta made the iPhone bottom safe
  area available. This is a first-frame geometry transition, not the frozen
  WKWebView failure and not a reason to retime native recomposition.
- `readHostSafeBottomInset()` reads the already settled React `.bottom-nav`
  padding once at store open. The value is passed as `window.__otlobliSafeBottom`
  to the real document-start script. `OTLOBLI_NAV_CSS` uses the maximum of that
  value, WebKit's env inset, and 16px, so later viewport hydration cannot move
  the nav. Keep the value bounded to `16…60`; do not add a timer or layout loop.
- The user asked to close the top diagnostic. The release no longer imports or
  injects `SHEIN_TAP_DIAGNOSTIC_SCRIPT`/capture context and passes
  `otlobliTapDiagnostics: false`, so the native `نسخ` button is absent. The
  retained source/native diagnostic helpers are dormant and not customer UI.
- Version `86.104/964`. Build, freeze guard, performance budget and both native
  syncs pass. Budgets: `1,157,905` raw JS, `321,473` gzip JS, `549,920` SHEIN
  source. Playwright at `440×932` with a 34px inset returned height `108px`,
  padding `34px`, top `824`, bottom `932`, `stable=true`. Android debug APK is
  11,167,800 bytes with SHA-256
  `5CE18F7657FE34322E303D1F25A85AA2944C7FE2384C77C1CA83F7C2B0D3B18C`.
- Commit `b7f6d27` is pushed. GitHub/Xcode
  [run `31313269405`](https://github.com/m7madv/otlobli/actions/runs/31313269405)
  passed. Inspected unsigned IPA:
  `release-artifacts/ios-v86.104-run-31313269405/otlobli-v86.104-iphone16-unsigned.ipa`,
  7,044,634 bytes, SHA-256
  `70D1EC898C8C4244A3D787642DC5C815D293FF553F55BEA1C1C95E0AE3D23AE4`.
  Verified desktop copy:
  `C:\Users\MOHAMMAD\Desktop\otlobli-ios-v86.104\otlobli-v86.104-iphone16-unsigned.ipa`.
  Archive metadata is `com.otlobli.app` `86.104/964`; the first-frame marker is
  present, tap diagnostic script is absent, and the built option is false. The
  app root is unsigned/unprovisioned; four vendor frameworks retain signatures.
- Pending only real iPhone acceptance: product-open first frame, five
  background/resume cycles, cold launch, and SHEIN → Temu → SHEIN. None is
  claimed from local/browser/CI checks.

# Current recovery candidate — v86.103 SHEIN cart-session reset (2026-08-09)

- User-confirmed sequence: after opening an old SHEIN item from Otlobli cart
  and leaving/returning to the app, SHEIN still paints its shell/categories but
  product cards no longer navigate. Temu → SHEIN fixes the same session.
- The supplied v86.102 report shows a live WKWebView (`440×894`, attached,
  window=true, interactive, scroll `0→734`) and stable QA region state. It had
  no product event, but the old diagnostic discarded any tap whose DOM did not
  first match its product predicate and also logged third-party iframes, so it
  cannot prove that JavaScript input was absent.
- v86.103 sets `sheinCartProductSessionRef` only for iOS SHEIN products opened
  from Otlobli cart. App resume or navigation from that session to Otlobli
  cart/orders/profile retires the one WebView, sets the existing cache reset,
  and opens a fresh SHEIN session when Home is active. This matches the proven
  Temu → SHEIN recovery without clearing cookies/localStorage/signed address or
  changing native recompose timing. Android and ordinary SHEIN browsing retain
  their current preserve/hide behavior.
- Diagnostic v86.103 is top-frame only and captures raw touch/click attempts
  even with `productDetected=false`; it includes href/label/scroll, touchcancel,
  a capture-scheduled after record, and a true post-dispatch final record via a
  zero-delay task. Keep `SHEIN_IOS_TAP_DIAGNOSTICS=true` only through device
  acceptance, then disable it for a normal customer release.
- Playwright verified known/unknown targets, product href, capture+bubble,
  late `preventDefault`, synthetic touchstart/touchend under one attempt,
  `tap-after`, and no iframe install. Build/freeze/performance, both native
  syncs and Android debug build pass. Budgets: `1,163,553` raw JS, `323,209`
  gzip JS, `549,929` SHEIN source. APK: `86.103/963`, 11,171,342 bytes,
  SHA-256 `1EDC0BFED9DF367F6046F30DE9432F9695F13033AD22E1A464B049B2DBB8897B`.
- Pushed commit: `49b734e` (`49b734e36c0c5ffbafe7b1d03502a5e6288c3548`).
  GitHub/Xcode [run `31310138809`](https://github.com/m7madv/otlobli/actions/runs/31310138809)
  passed. Inspected IPA:
  `release-artifacts/ios-v86.103-run-31310138809/otlobli-v86.103-iphone16-unsigned.ipa`,
  7,046,214 bytes, SHA-256
  `E83EF7ECDD885E8CBB6FD49C9BDB1888411C444EA2708BFE5487503DFC2C712F`.
  A verified identical copy is on the desktop at
  `C:\Users\MOHAMMAD\Desktop\otlobli-ios-v86.103\otlobli-v86.103-iphone16-unsigned.ipa`.
  Archive confirms `com.otlobli.app` `86.103/963`, recovery/diagnostic/recompose
  markers, no app-root signature and no embedded provisioning profile.
- Pending: reproduce the cart path and verify ordinary product entry, five
  resume cycles and cold launch on a real iPhone. If it still fails, copy the
  v86.103 report before switching stores.

# Current diagnostic candidate — v86.102 SHEIN iOS tap-path trace (2026-08-09)

- Pushed branch/commit: `codex/shein-ios-tap-diagnostic` / `b5a6e7a`
  (`b5a6e7a194410b1d774cad3a1a07c52fdb8a4170`). GitHub/Xcode
  [run `31308844558`](https://github.com/m7madv/otlobli/actions/runs/31308844558)
  passed. Inspected IPA:
  `release-artifacts/ios-v86.102-run-31308844558/otlobli-v86.102-iphone16-unsigned.ipa`,
  7,045,998 bytes, SHA-256
  `3E9C88CFF994D64C4688F904737E8CDE34FAA0DB319A46716B158121E4FA96E4`.
  Archive metadata is `com.otlobli.app`, `86.102/962`; web/native diagnostic
  and recompose markers are present. The app root is unsigned/unprovisioned;
  prebuilt Facebook frameworks retain vendor signatures.
- `SHEIN_IOS_TAP_DIAGNOSTICS=true` is diagnostic-only. It installs passive
  product listeners for touchstart/touchend/click in capture+bubble and a
  post-dispatch microtask for final `defaultPrevented`/`bubbleSeen`; it must be
  false again before a normal customer release. Old freeze diagnostics remain
  false.
- Every capture snapshot is bounded: target, painted element, eight ancestors,
  up to twelve fixed/sticky layers from `elementsFromPoint`, styles/rects,
  URL and region state. There is no page-wide scan or persistent diagnostic
  polling. The native ring is in-memory, capped at 180 and copied only with the
  small `نسخ` button; report prefix is `OTLOBLI_SHEIN_TAP_DIAGNOSTIC`.
- The existing `otlobliInstallIosProductTapFallback()` behavior is unchanged.
  Its original freeze-probe markers and `280ms` then `220ms` timings remain;
  the new trace only reports armed/scheduled/click/route-skip/location-assign.
- Native records host `setUrl` (the cart-product path), navigation, active/
  resign-active, recompose requested/completed and WKWebView state. Do not add
  `appWillEnterForeground`: the freeze guard forbids it. Document visibility,
  page show/hide and focus/blur cover the corresponding page events.
- Playwright passed both an actual click intercepted by a 1%-opacity fixed
  layer and touchstart/touchend capture+bubble. The diagnostic did not prevent
  the event. Production/freeze/performance, both native syncs and Android debug
  build pass. APK is `android/app/build/outputs/apk/debug/app-debug.apk`,
  11,548,135 bytes, SHA-256
  `30DBE8CF87AAF04098CDE6F3101DEC6DD40DE23858E53703F7A806AF44E3E643`.
  Note 8 was `unauthorized`; no install/device acceptance occurred.
- Next: install/sign the unsigned IPA as appropriate, then on the real iPhone
  run all five reproduction paths. At the first failure press `نسخ`
  before Temu → SHEIN and paste the complete report. Do not fix anything until
  that report identifies the failing layer/event.

# Previous candidate — v86.101 hidden SHEIN colour-template guard (2026-08-09)

- A no-option SHEIN nail product showed `حدد اللون أولاً`. Diagnose this class
  of bug from the live DOM before changing it.
- Root cause proved on the connected Note 8: `findOptionContainer('color')`
  stored its first class-matching fallback even when that node was hidden. A
  two-button hidden fixture changed the old live diagnostic from
  `{exists:false}` to `{exists:true, selected:''}`.
- v86.101 creates `rendered` once and only permits rendered containers as a
  fallback. It does not select a colour, weaken real visible colour gates,
  write to the cart, add polling, or touch pricing/region/WebView lifecycle.
  Do not restore the unconditional `fallback = fallback || el`.
- Device verification after install: the same no-option page with the same
  hidden fixture reports `{exists:false, selected:''}`. The actual add flow
  was intentionally not fired so the user's cart was not mutated.
- Video evidence: the supplied iPhone video has a stable Otlobli nav from
  0.25 s onward. Its preceding black rounded card is iOS's home-to-app launch
  animation before app code runs, not an app nav flicker. Do not add a timer,
  fade, WebView work, or recompose change to fight it.
- Android 86.101/961 passed build, freeze guard, low-end budget, both native
  syncs, debug build and install on Note 8. APK:
  `android/app/build/outputs/apk/debug/app-debug.apk`, 11,167,224 bytes,
  SHA-256 `957D4D540D81A8162DF501CD9251760AD9F9CC5274349CA52C852E6F9C23FCF1`.
  The unsigned iPhone IPA completed successfully in [run 31305701128](https://github.com/m7madv/otlobli/actions/runs/31305701128):
  `release-artifacts/ios-v86.101/otlobli-v86.101-iphone16-unsigned.ipa`,
  SHA-256 `D9AC194F1EBA2594F82B68103701A58830289259C95930474EE4F30785B00F4D`.
  It is deliberately unsigned/provision-less. Physical iPhone 16 acceptance is still
  required: verify the no-option product, cold launch, and five background/resume cycles.

# Previous candidate — v86.100 Otlobli-first store opening (2026-08-09)

- Product rule: display the complete Otlobli surface first; only after it is
  present may SHEIN/Temu open above it. Do not show raw store UI or add another
  loading layout on the cold path.
- The real Note 8 recording identified duplicated text/tabs as an opacity
  fade between two otherwise matching Otlobli layers. `dismissOtlobliLaunchSurface()`
  intentionally removes its native view immediately after React's existing
  two RAF handoff. Do not restore an alpha animation, delay, or retry there.
- `android/app/src/main/res/drawable-nodpi/otlobli_starting_screen.png` is the
  pre-Activity representation of this exact app surface. It prevents an empty
  pre-Java frame on Android 9. `otlobli_starting_window.xml` must continue to
  reference it; it must not reference a standalone spinner or a raw browser.
- Android 12+ calls `SplashScreen.installSplashScreen()` before `super.onCreate`;
  keep that ordering. The app's own static/native shell then takes over.
- This batch never changes the WebView lifecycle: preserve the iPhone
  `otlobliForceRecompose` 0.25s guard, `otlobliOnHostResume()`, and the active
  `JSON.stringify` region comparison. The user has old iPhone v86.82 where
  SHEIN can stop at skeleton content. v86.100's unsigned IPA built successfully
  at [run 31304414080](https://github.com/m7madv/otlobli/actions/runs/31304414080)
  from `0b387d9`; it is not yet real-device accepted.
- Android 86.100/960 passed production build, freeze guard, low-end budget,
  Android/iOS sync, debug build, Note 8 install, and 10-fps cold-start video.
  APK `android/app/build/outputs/apk/debug/app-debug.apk`: 12,581,116 bytes,
  SHA-256 `5D8C52CE73A26DC6C94C3E2E3A0493967814BD84AE6EEB18FB33B062DFC0104F`.
  The downloaded iPhone IPA is 7,039,678 bytes, SHA-256
  `5DAD64EFB8620B8C5677A97A80A809EB3C61EE3D65199F80C3874EA776A59BFC`.

# Otlobli AI Handoff

## Current candidate — v86.98 stable first store surface (2026-08-09)

- A real Note 8 frame series proved the former opening jump was not a lifecycle/freeze issue: `showOtlobliLoadingCover()` ran in `presentWebView()` while the Android `Dialog` still had a short wrap-content root. It produced a compressed top-aligned Otlobli layout, then the same cover expanded later.
- The permanent patch now invokes the cover after `WebViewDialog.show()` and refuses to paint until the root is at least 70% of the physical display height. Keep this display-relative gate and Android's 120dp nav reserve; do not move the call back to `presentWebView()` or replace it with another timed/retry screen.
- Normal preparation copy is exactly `جاري تجهيز المتجر…` in the static boot shell, React `StoreLoadingScreen`, and Android/iOS native covers. The brand is 24px/pt/sp system bold and copy is 14px/pt/sp system regular; the React bottom tabs intentionally use `system-ui,-apple-system,sans-serif` to match injected SHEIN tabs on Android. Do not restore Cairo just to those tabs: it creates the customer-visible weight switch and risks a first-paint dependency.
- Android 86.98/958 is installed on Note 8. APK: android/app/build/outputs/apk/debug/app-debug.apk (11,234,493 bytes, SHA-256 028C9D1A71B78463546EEBA311B1D5C9B0F35DAF6A9A0366AB0F612CC5E79416). The stable cover and no compact first Otlobli frame were confirmed via repeated cold-start screenshots. Build, low-end budget, patch reverse-check, Android/iOS sync and iPhone-freeze guard pass. iPhone 16 cold launch plus five real background/resume cycles are still mandatory and unperformed.

## Current candidate — v86.97 one loading surface, no spinner (2026-08-09)

- The SHEIN loading guard must remain enabled: it prevents raw/unprepared
  SHEIN from appearing. Its implementation is in
  patches/@capgo+capacitor-inappbrowser+8.6.25.patch, not only node_modules.
- The acceptable normal loading visual is one static surface: green otlobli
  wordmark plus one preparation line, with no circular spinner. index.html,
  StoreLoadingScreen in src/App.tsx, and the Android/iOS native cover are
  deliberately aligned. Do not reintroduce another loading header/spinner.
- Android's native cover must retain its otlobliDp(120) lower reserve. 90dp
  clipped the top half of the document-start inline SVG bar on Note 8, showing
  labels with no icons. Do not make the cover full height again.
- iOS cover keeps the nav-safe-area reserve but this change does not alter
  otlobliForceRecompose, the guarded 0.25s active callback, the Android
  otlobliOnHostResume() defense, cache recovery, or the JSON region guard.
- Android 86.97/957 is installed on Note 8. Cold native-cover capture
  confirmed wordmark + status + four complete icons; freeze guard, patch
  reverse-check, production build, low-end budget and Android/iOS sync pass.
  APK is android/app/build/outputs/apk/debug/app-debug.apk (11,464,241 bytes,
  SHA-256 6925ED05C4AF125FEF1DA623F250C211C5B36EB2F3F9606C8E4E0CCFC6B24BA5).
  Real iPhone 16 cold launch plus five resume cycles remain required.

## Current candidate — v86.96 fast startup without icon gaps (2026-08-09)

- `index.html` now contains a tiny static boot shell with the four exact
  inline-SVG nav icons. It is visible before the bundle evaluates and React
  replaces it on its first render. Do not remove it, replace it with a remote
  font/icon library, or make its boot tabs interactive before React is ready.
- Valid cached store regions now set `storeRegionsReady` immediately; remote
  settings still fetch at launch and the protected `JSON.stringify` region
  comparison remains the sole trigger for a true region rebuild. First install
  still waits for the remote region instead of guessing a country.
- `checkStoreReachable()` resolves on the first real selected-store image, and
  the startup VPN gate races that against geo. Store success opens immediately;
  geo can finish later for diagnostics. Do not restore the geo-first await or
  make a failed probe silently pass.
- The injected SHEIN nav now uses system Arabic text and inline SVG. The
  previous embedded Cairo data URL and its 25 ms startup retry were removed;
  do not reintroduce a blocking font download into the store's first paint.
- Android `86.96/956` is installed on Note 8. One cold activity launch measured
  1.741 s, and passive inspection confirmed four visible SHEIN nav SVGs plus
  four React bottom-nav SVGs. Freeze guard/build/performance/Android+iOS sync
  pass; real iPhone acceptance remains required.
- Unsigned iPhone build [31288703952](https://github.com/m7madv/otlobli/actions/runs/31288703952)
  was triggered from `a9a1701` and is in progress. It verifies build health,
  not the required iPhone 16 cold-launch or five resume cycles.

## Current candidate — v86.95 product `1PC` option retained separately (2026-08-09)

- Live Note 8 DOM evidence for SHEIN `p-216351093`: selected `M` belongs to
  `مقاس`; selected `1PC` belongs to a separate `الكمية` group. They are both
  SKU descriptors, not the Otlobli cart item count.
- `sheinSelectedQuantityOption()` reads only selected SHEIN option nodes,
  filters them through the existing group-heading detector, and emits
  `quantityOption` in both normal PDP and quick-form payloads. `App.tsx`
  appends it to the stored display string, yielding e.g. `M · 1PC`.
- Do not fold this value into `CartItem.quantity`, `bundleCount`, pricing, or
  availability. Cart `quantity` must remain one purchased package. Do not
  return to a first-match size selector: it will again lose one of the two
  independent choices.
- This is deliberately a local capture path: no timer, global DOM scan,
  reload, cache reset, or WebView/lifecycle modification. Keep it that way for
  the protected iPhone freeze invariant and weak devices.
- Android `86.95/955` is installed on the connected Note 8. The build,
  emitted-script parser, performance budget, freeze guard, and Android/iOS
  sync pass. Acceptance still required: add the currently selected product
  once and confirm the new cart row says `M · 1PC` while its stepper remains
one. Older rows cannot retroactively contain data they did not store.
- Unsigned iPhone build [31288237127](https://github.com/m7madv/otlobli/actions/runs/31288237127)
  was triggered from commit `8d3120b` and is in progress. It is build sync
  verification only; real iPhone 16 acceptance remains separately required.

## Current candidate — v86.94 challenge-nav SVG parity (2026-08-09)

- A live Note 8 inspection identified the "bottom-bar icons vanish then
  appear" root cause: on SHEIN `/risk/challenge`,
  `otlobliEnsureChallengeNav()` created text-only tabs. It was not a Cairo
  font load failure. v86.94 gives that fallback the same inline SVGs and flex
  layout as `ensureOtlobliNav()`. Do not replace them with remote icon fonts,
  emojis, or a delayed mount.
- Android `86.94/954` is installed on the Note 8. Cold-launch inspection on a
  normal SHEIN page found all four 22×22 SVG icons visible. The new branch is
  present in the built app; the prior real challenge had cleared, so obtain a
  passive visual confirmation only when SHEIN next legitimately opens it.
- Do not bypass, automate, suppress, or solve SHEIN's human check. Keep the
  current contract: preserve cookies/localStorage, set Android third-party
  cookies for SHEIN, leave the challenge DOM/controls alone, pause Otlobli's
  own scans during it, and resume only after its URL/page changes. A user's
  successful clearance may still expire or be re-evaluated by SHEIN.
- The only researched follow-up worth testing is an Android cookie persistence
  flush once after `humanCheckResolved`; it is not implemented yet because
  `CookieManager.flush()` can perform blocking I/O. Measure it separately and
  never run it on startup, navigation, or before a user completes a challenge.
- Unsigned iPhone build [31287796920](https://github.com/m7madv/otlobli/actions/runs/31287796920)
  was queued from `9562276`; CI is source/native build verification only, not
  iPhone device acceptance.

## Current candidate — v86.93 raw-SHEIN regression repair (2026-08-09)

- The visible raw SHEIN icons, missing Otlobli nav, and false
  `تعذر تجهيز المتجر`/VPN message were one failure: `SHEIN_CAPTURE_SCRIPT`
  failed to parse. In a TypeScript template literal, source `/\+/g` emitted
  invalid `/+/g`; Chromium discarded the whole script before any blocker/nav
  mounted. Do not blame or change the VPN gate for this incident.
- The counter now uses source `/\\+/g`, which emits a valid plus-sign regex.
  `scripts/verify-shein-freeze-guard.mjs` now transpiles the source with inert
  imports and parses the emitted capture script. Keep this guard; TypeScript
  does not otherwise parse the JavaScript hidden inside the template literal.
- The redundant SHEIN `preShowScript` path was removed; normal `browserPageLoaded`
  injection remains the single supported path. This avoids a second heavy run
  before the host bridge is ready.
- Live Note 8 validation after installing `86.93/953`: Otlobli nav and add
  button are visible/enabled on the live home/product; a raw SHEIN bottom-nav
  candidate was absent. APK SHA-256:
  `F4B4A97402DA28DC38F09F0814EA3EF08870A6A0C8958224716C4342AE194339`.
- No native freeze guard/recompose timing/region rebuild logic changed. Do not
  claim real iPhone acceptance; the five resume cycles and cold-launch test
  remain mandatory.
- Unsigned iPhone build run `31287002745` was started from commit `0c6bb29`;
  record its final artifact or failure before the next handoff.

## Current candidate — v86.91 three-piece quick-form bundle (2026-08-09)

- The second reported product is SHEIN `p-216351093` (pink bow makeup bags).
  Its active quick form contains **two** sibling controls: `الكمية / 1PC` and
  `مقاس / مجموعة (صغير + متوسط + كبير)`. Never treat `1PC` as the selected
  size: it is the package purchase quantity.
- `sheinQuickSizeBox()` in `src/services/sheinBrowserScript.ts` selects only
  the group whose heading means size/measurement. `sheinQuickBundleCount()`
  derives the member count from the selected bundle; the host records the
  display label `… · 3 قطع`.
- Keep cart `quantity: 1` for this choice. A value of 3 would mean ordering
  three whole packages, not representing the three items inside one package.
- Live Note 8 DOM confirmed the selected bundle after choosing it. A complete
  physical Otlobli add/cart acceptance is still needed. v86.91 / code 951 is
  installed on the Note 8; build, freeze guard, performance budget, and native
  sync passed. Do not claim iPhone acceptance: five real resume cycles plus a
  cold launch remain required.
- The native loading cover fallback is now 12 seconds on Android/iOS so a
  missed ready bridge cannot block a live storefront for the old 45 seconds.
  It only hides the cover; it does not recreate the WebView or alter protected
  iPhone recompose timing. Note 8 restart inspection saw the storefront with no
  lingering cover.
- Current Android artifact: `android/app/build/outputs/apk/debug/app-debug.apk`,
  `86.91/951`, `11,120,402` bytes, SHA-256
  `5F1C8BE741CB25F1535E4831737EA4091320D8C74DBDE2D84B3E75A1F5AB0B3B`.
  Installed successfully on the connected Note 8 (SM-N950F).
- GitHub unsigned-iPhone run `31286513512` was triggered from `488374d` and
  was in progress at handoff. It does not replace the mandatory five real
  iPhone resume cycles and cold-launch acceptance.

## Current — v86.85 removes the duplicate Curvy pre-gate (2026-08-09)

- Live Note 8 investigation disproved the v86.84 final assumption: the visible Otlobli button was enabled and atop `bsc-quick-add-cart`, but its own handler still ran `sheinOpenSkuDrawer()` plus document-wide color/size gates **before** it reached `addToCartFlow()`. Thus the new form-aware code was unreachable for Curvy.
- v86.85 removes those duplicate pre-checks. The button now calls `addToCartFlow(getColorState(), getSizeState())` directly; that one gate first detects `sheinQuickAddSelectionState()` and only uses normal drawer logic if no active quick-add form exists. Do not restore the caller-side gates—there must be one decision point.
- The Note 8 currently displays the exact Curvy sheet (4XL selected). Rebuild/install v86.85, then test a real user tap: one Otlobli row must appear in the app cart with `4XL فقط 2 بيقي` (or the newly selected size). The touch injection command was not accepted by this device session, so do not call ADB’s failed coordinate taps device acceptance.

## Current — v86.84 Curvy quick-add form isolation + diagnostics disabled (2026-08-09)

- User-reported bug: in the product `IslaSuriya ...` selecting `قوام كيرفي` opens a `bsc-quick-add-cart` overlay, then choosing `5XL` and pressing the Otlobli green button did nothing. Root cause is confirmed from the code path plus the prior real Note 8 overlay inspection: `addToCartFlow()` gated on `getSizeState()` / `sheinSizeUnselected()` across the background PDP before `captureProductPayload()` switched to `sheinQuickAddPayload()`. Background size was blank, while the overlay had the user’s 5XL selection.
- v86.84 adds `sheinQuickAddSelectionState()` and makes the add flow use its form-local color/size state before any normal-PDP drawer/gate. `sheinSizeUnselected(scope)` now accepts the active quick-add root, preventing cross-form reads. Do not simplify this back to a document-wide gate: an active `bsc-quick-add-cart` is a separate product configuration surface.
- Validation: `npm run build`, performance budget and freeze guard pass (`1,192,836 / 1,200,000` raw JS; `546,375 / 550,000` SHEIN source). v86.84 must still be device-tested by opening Curvy from a normal accepted SHEIN session, selecting 5XL, tapping Otlobli add, then verifying the cart records 5XL. Direct automated navigation currently reaches SHEIN’s human-verification page; do not bypass or automate that challenge.
- Marker/version: `2026.08.09-v86.84-curvy-quick-add`, `86.84 / 944`. Includes the v86.83 diagnostics-off work below; iPhone build/artifact and final real-device acceptance remain pending.

## Current — v86.83 diagnostics disabled in normal releases (2026-08-09)

- The customer explicitly stopped the two active diagnostics: SHEIN price/option diagnostic and iPhone freeze trace/`LOG`.
- `src/services/sheinPriceDiagnostics.ts` is retained but no longer imported by `src/App.tsx`; the normal browser script has no price button, panel, timer, or diagnostic code in the customer bundle. Do not restore the import except for a separately requested diagnostic build.
- `SHEIN_IOS_FREEZE_DIAGNOSTICS=false`, so no freeze probe is injected and native `LOG` is off. This does not alter native recompose, iOS lifecycle guards, product-only recovery, region behavior, or Android host-resume defense.
- The freeze guard now requires the disabled iPhone flag and forbids price-diagnostic imports from `App.tsx` so normal releases cannot accidentally regain either tool.
- Marker/version: `2026.08.09-v86.83-diagnostics-off`, `86.83 / 943`. Local build, budget, guard, patch reverse-check and Android/iOS sync pass: raw JS `1,189,850 / 1,200,000`, gzip `351,813 / 370,000`, SHEIN source `543,389 / 550,000`. iPhone build/artifact and physical-device acceptance remain pending.

## Current — v86.82 no-flash recovery and weak-device maintenance (2026-08-09)

- User reported that v86.81 was generally smooth but could show «جاري إصلاح…» / a flash after entering or returning. The root is not a new generic iOS freeze: v86.81 handled every page's `ChunkLoadError`, including home errors that did not actually block SHEIN, and used a close/reopen recovery on both platforms.
- `OTLOBLI_SHEIN_CHUNK_FAILURE_BRIDGE_JS` now reports only if the active SHEIN path is a real product `-p-<id>`. `recoverSheinChunkLoad()` now returns unless the platform is iOS. The same one-per-60-seconds recovery remains available for a confirmed broken **iPhone product** only. Do not broaden it to home, Android, resume, or generic load errors; that reintroduces the flash.
- Do not touch the native recompose. Keep the proven single guarded `appDidBecomeActive` 0.25s detach/reattach, lifecycle generation, active-state checks, scroll/constraints and Android host-resume defense exactly as guarded.
- The injected maintenance loops now exit while `document.hidden`, and the old permanent nav-bootstrap interval was replaced with `pageshow`/`visibilitychange` wake events. This is deliberate low-end maintenance: no polling is added and no customer feature was removed. The freeze guard enforces `restoreOtlobliNavOnWake()` and forbids the old 1.5–2.5s watchdog.
- `docs/KNOWN_ISSUES_AND_DECISIONS.md` is now the permanent, Git-tracked problem log. Never delete or replace it with a chat summary. It carries confirmed vs. suspected causes, rejected fixes, and the incident template. `docs/PROJECT_MAP.md` maps source ownership. Start with these, `CURRENT_STATE.md`, and this file.
- Candidate marker/version: `2026.08.09-v86.82-shein-no-flicker`, `86.82 / 942`. Freeze guard, production build, low-end budget, patch reverse-check, Android/iOS sync and Android `assembleDebug` pass. Android artifact: `android/app/build/outputs/apk/debug/app-debug.apk`, 11,120,162 bytes, SHA-256 `981D11A3C55499793ECDE8A259E3BAB109026F0E0E2AD3BCE11220576456DD93`. iPhone workflow [31283073598](https://github.com/m7madv/otlobli/actions/runs/31283073598) passed from `8d1b20c`; IPA `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-ios-v86.82-no-flicker\otlobli-ios-v86.82-iphone16\otlobli-v86.82-iphone16-unsigned.ipa`, 7,070,839 bytes, SHA-256 `D5571278DB577A2119CD68CB0F2CBB88FAC01B2BF380FD5832B155403EB242E3`, archive `86.82 / 942`. Physical device acceptance remains pending; do not claim real iPhone/Note 8 approval until it is actually performed.

## Current — v86.81 automatic recovery for confirmed SHEIN chunk failures (2026-08-09)

- New device report `C:\Users\MOHAMMAD\.codex\attachments\1475a04c-07db-4a9a-8bb7-61f6b938ceb9\pasted-text.txt` provides the most direct sequence yet. It begins on a **live** `/ar/` document (`perf ≈ 41.7s`, `loading:false`, view attached/visible), then logs repeated `ChunkLoadError` for chunk `72143`; a cart product starts and ends navigation but the product’s route later has more chunk failures. The second home session fails dozens of versioned chunks then enters `blank`, `/ct.html`, and `/syncframe`. Screenshot confirms image + skeleton only. This is a failed SHEIN PWA asset graph, not an Otlobli touch overlay.
- User independently confirmed **Temu → SHEIN heals it immediately**. Existing code for that deliberate switch closes the browser and invokes `InAppBrowser.clearCache()` before a fresh SHEIN session. On iOS that clears only `WKWebsiteDataTypeDiskCache` + `WKWebsiteDataTypeMemoryCache`; it does not clear cookies, localStorage, service workers, or signed address. That is exactly the recovery to reuse after a proven chunk error.
- `OTLOBLI_SHEIN_CHUNK_FAILURE_BRIDGE_JS` is a document-start observer only. It runs only on a SHEIN hostname, recognizes `ChunkLoadError` / `Loading chunk <id> failed`, and posts one `{ type: 'sheinChunkLoadFailure', url }` message. It does not fetch, reload, mutate site storage, change country, or prevent input. It uses the normal mobile bridge with a WK message-handler fallback.
- `recoverSheinChunkLoad()` in `src/App.tsx` ignores other stores/challenges, debounce-loops (one recovery per 60 seconds), preserves a valid `-p-<id>` page for reopening, sets the existing `sheinCacheResetPendingRef`, and closes/reopens through the established singleton path. Do not replace it with a JS `location.reload`, continuous timer, cache purge, or a native recompose change. A hard failure after its one recovery must remain diagnosable rather than looping indefinitely.
- v86.80 invariant remains: never restore `cleanSheinRuntimeCache`, JS service-worker unregistration, or CacheStorage deletion. v86.81 uses only the pre-existing native HTTP cache reset **after** an observed failure.
- Marker/version: `2026.08.09-v86.81-shein-chunk-recovery`, `86.81 / 941`. Build, guard, budget, patch reverse-check and Android/iOS sync pass: raw JS `1,198,435 / 1,200,000`, gzip `354,383 / 370,000`, SHEIN script `543,169 / 550,000`. GitHub/Xcode [run `31282204234`](https://github.com/m7madv/otlobli/actions/runs/31282204234) passed from `98302bc`; ready IPA `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-ios-v86.81-chunk-recovery\otlobli-v86.81-iphone16-unsigned.ipa`, 7,070,838 bytes, SHA-256 `7977DDDB196D531425BD9B272069AC9F2B2597173276F55FF0F120DA5684C5DA`, archive confirmed `86.81 / 941`. Real iPhone acceptance remains pending.
- Native iPhone lifecycle invariant is untouched: retain exactly the one 0.25s guarded recompose, lifecycle generation/state checks, scroll/constraint restoration, and Android resume defense. Do not claim acceptance without the real three-cycle failure reproduction plus five standard background/resume cycles and cold launch.

## Current — v86.80 SHEIN PWA chunk-load root cause (2026-08-09)

- User report: fresh v86.79 install was smooth and challenge-free; after leaving/re-entering, product cards visually remained but short taps stopped routing while long press still worked. The report copied from that failed grid is at `C:\Users\MOHAMMAD\.codex\attachments\109908f3-5973-4aea-8528-bd1faf15bcd1\pasted-text.txt` (truncated JSON, but direct event text is usable).
- **Confirmed first root:** repeated `js:promise` events are `ChunkLoadError: Loading chunk … failed` for SHEIN `https://sheinm.ltwebstatic.com/pwa_dist/assets/...` resources. The view can be visible and scrollable, but SHEIN has lost the JS chunks needed to route a card. Long press only proves the native/context-menu path is alive; it does not prove SHEIN’s click route is available.
- **Cause removed in v86.80:** `src/services/sheinBrowserScript.ts` had document-start code that, on every cold WebView session, unregistered `navigator.serviceWorker` and deleted all CacheStorage keys (`cleanSheinRuntimeCache`). It raced SHEIN’s own versioned PWA asset graph and can cause the recorded chunk failures. Never restore this purge or any equivalent JS-side SHEIN cache/service-worker clearing. SHEIN owns its PWA runtime cache.
- The bounded native `InAppBrowser.clearCache()` remains only for an actual region transition / intentional Temu → SHEIN fresh session before a new WebView starts. It preserves cookies/localStorage. Do not widen it to ordinary resumes or document start.
- **iOS tap guard (not the root fix):** `OTLOBLI_IOS_PRODUCT_TAP_FALLBACK_JS` captures the exact card’s direct product anchor at `touchstart`. After a genuine short stationary touch it waits 280 ms, invokes the same card once, then after 220 ms routes to the saved direct anchor only if URL is unchanged. It excludes swipe and >650 ms long press. Diagnostic events: `product-tap-start`, `product-tap-fallback`, `product-tap-route-fallback`.
- `scripts/verify-shein-freeze-guard.mjs` now rejects `cleanSheinRuntimeCache`, its marker, service-worker registration purges, and cache-delete loops, and requires the iOS fallback markers. Keep `markers: []` on a forbidden-only rule because the verifier iterates `check.markers`.
- Marker/version: `2026.08.09-v86.80-shein-resume-product-tap`, `86.80 / 940`. Local build, freeze guard, budget, patch reverse-check and both native sync pass: raw JS `1,196,768 / 1,200,000`, gzip `353,859 / 370,000`, SHEIN script `542,018 / 550,000`. GitHub/Xcode [run `31281456875`](https://github.com/m7madv/otlobli/actions/runs/31281456875) passed from `c87ced2`; ready IPA `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-ios-v86.80-runtime-cache\otlobli-v86.80-iphone16-unsigned.ipa`, 7,070,345 bytes, SHA-256 `C2EAE54EE018F0BF6A25451765FA430CB11EBE51E3EB729813B4A5CC778CF17E`, archive confirmed `86.80 / 940`. Device acceptance remains pending.
- **Never alter native recompose timing for this fix.** Preserve the proven 0.25 s `appDidBecomeActive` path, lifecycle generation/state guards, scroll/constraints and Android host-resume guard. Five real iPhone background/resume cycles + cold launch remain required before a release can be called accepted.

## v86.79 handoff — repair malformed SHEIN cart product links (2026-08-09)

The latest diagnostic report found a concrete cart-path failure, not a generic new iPhone freeze: a quick-add row saved `https://m.shein.com/ar/-p-57281932.html`. That is an invalid bare product route; SHEIN shows **Oops**, and its return-to-home flow creates the later blank/frame events that leave the visible home blocked. The same report contains the proper long canonical URL for product `57281932`.

`sheinQuickAddProductLink(root, info)` in `src/services/sheinBrowserScript.ts` now chooses a matching drawer anchor first, then uses the authoritative unique `goods_id` in the valid generic `/ar/product-p-<id>.html` route. This deliberately removes brittle URL-field guessing; never restore the old `/ar/-p-<id>.html` generator. `normalizeSheinBrowserUrl()` in `src/App.tsx` repairs already-saved bare links on opening, so do not force-delete customer carts. The freeze verification script enforces both invariants. This release deliberately makes **no** native recompose, foreground/background, region, polling, or challenge-flow change.

SHEIN anti-bot verification is site-owned: do not bypass, automate, suppress, or promise a permanent one-time verification. The app preserves successful SHEIN cookies/localStorage, the bounded cache clear does not delete those, and known challenge URLs are excluded from app reroutes/reloads. That is the safe, reliable behavior; SHEIN decides whether/when it asks again.

Marker `2026.08.09-v86.79-shein-cart-product-link`; native `86.79 / 939`. Local guard/build/budget/patch-reverse/sync pass: `1,198,378 / 1,200,000` raw JS, `354,659 / 370,000` gzip, SHEIN source `543,629 / 550,000`. GitHub/Xcode [run `31280651233`](https://github.com/m7madv/otlobli/actions/runs/31280651233) passed from `0b3ddba`; IPA: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-ios-v86.79-cart-product-link\otlobli-ios-v86.79-iphone16\otlobli-v86.79-iphone16-unsigned.ipa` (7,071,127 bytes; SHA-256 `30A7ECB4BB1FC470B28FCF6F4C4A2BEE185CBB66DC79ED1B053E63F0FF6E64E4`; archive confirms `86.79 / 939`). Real iPhone acceptance remains mandatory: old affected cart row, new quick-add row, five resumes, force-quit/cold launch.

## v86.78 handoff — iPhone resume-race guard (2026-08-09)

The v86.77 trace found a stale-callback lifecycle race: its final foreground transition was followed by `willResignActive` 39 ms later, but the pre-existing 0.25-second recovery callback could still have run while backgrounded. v86.78 increments `otlobliLifecycleGeneration` on every active/resign transition; a delayed recovery must match its captured generation and `UIApplication.shared.applicationState == .active`. `otlobliForceRecompose()` checks active state again at the detach point. Preserve this two-layer guard, the one 0.25-second recovery, saved scroll/constraints, Android host resume and store-region JSON comparison.

The native patch retains a persistent 180-event `UserDefaults` ring and always-native `LOG` button. It records native lifecycle, WebView attachment/window/bounds/scroll/progress/loading, navigation failures, WebContent-process termination and compact JS visibility/error checkpoints. v86.78 keeps logging enabled but does not bypass recovery (`SHEIN_IOS_FREEZE_DIAGNOSTICS_BYPASS_RECOVERY=false`), so it represents real release behavior. The report never leaves the phone; `LOG` copies it to the clipboard, including after a force-quit. Tap it before Temu/SHEIN switching, restart or workaround.

Marker `2026.08.09-v86.78-shein-ios-freeze-race-guard`; `86.78 / 938`. Build, expanded guard, patch reverse-apply check and performance budget pass (`1,198,034 / 1,200,000` raw JS; `543,347 / 550,000` SHEIN source); Android/iOS synchronized. GitHub/Xcode [run `31279659087`](https://github.com/m7madv/otlobli/actions/runs/31279659087) passed from `9eeb630`; IPA: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-ios-v86.78-race-guard\otlobli-ios-v86.78-iphone16\otlobli-v86.78-iphone16-unsigned.ipa` (7,070,988 bytes; SHA-256 `A1160CBF0D6EFDEA3D8D316FD662748721ED8A542FDBBC730624B766A08E00FD`; archive confirms `86.78 / 938`). This trace-enabled candidate must set `SHEIN_IOS_FREEZE_DIAGNOSTICS=false` before a normal production release. Existing quick-add, toast and lazy-size work remains pending behind this iPhone priority.

Read `CURRENT_STATE.md`, then `AGENTS.md`, before editing.

**Work cheap: read `docs/AI_FASTPATH.md` first** (device-debug playbook, `scripts/otlobli-cdp.mjs`, function line-map — never read the 550 KB `sheinBrowserScript.ts` whole).

## Active work — v86.74 SHEIN quick-add product identity (2026-08-08)

The user’s Rafferiza/Franclia screenshots exposed a different bug from v86.73: a live `.bsc-quick-add-cart` recommendation drawer is a distinct product layered above the current Franclia PDP. Before v86.74, drawer colour/size could be paired with the background product’s title/image/price/store cache. `src/services/sheinBrowserScript.ts` now has `sheinActiveQuickAddDrawer()` and `sheinQuickAddPayload()`, used only from the cold `captureProductPayload()` add path. They source title, `goods_id`, hero image, quick price, selected icon, selected size, availability and a normalized direct link from the active drawer itself. `sheinSelectedSkuPricePending()` returns false while this drawer is active so the base PDP mutation cache cannot delay or overwrite it. Do not expand this into a global goods-ID lookup or tick/poll work: the old v86.64 global identity patch regressed iPhone product interaction. Do not alter iPhone recompose, region transition, polling, or product-tap fallback.

Marker: `2026.08.08-v86.74-shein-quick-add-product-identity`; native version `86.74 / 934`. Validation: build, freeze guard, performance budget (`1,199,417 / 1,200,000` raw JS; SHEIN source `545,737 / 550,000`), Android/iOS sync and `assembleDebug`. APK is installed on real Note 8 `988e16384e4f51395230`; a bounded CDP payload test reproducing the inspected live drawer returned Rafferiza, `$13.13`, active gallery image, selected swatch, `XL`, and the direct `p-143690938` link, which was opened successfully on the same device. Artifact: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-android-v86.74\otlobli-v86.74-note8-debug.apk` (SHA-256 `D883F984AF8F96266F988A6B4B1F4F713847029AA0A593E22F28B33BE5B43937`). Existing bad cart entries must be manually removed/re-added and one real interactive quick-add should be completed. iOS source is synchronized but no IPA was built; require real iPhone quick-add plus five resume cycles and a cold launch before calling it accepted.

## Previous work — v86.73 SHEIN product-image / swatch separation (2026-08-08)

v86.72 made a new error: it fed `sheinColorImg` into the large cart `image` field. v86.73 corrects the payload: `image: getMainImage() || sheinColorImg`; `colorImage` remains the selected swatch. The large card therefore stays the product and the small marker stays the colour. Old saved cart rows are not migrated because their original image was not retained; do not clear the cart automatically—user must remove/re-add those rows. The inspected «المزيد من الخيارات» DOM contains only five descriptive `div.goods-size__options-item` elements with no SKU value, selected state, or control; never treat it as a cart variant.

Do not alter the iPhone native recompose burst, region code, polling, or tap fallback for this work. Shared source is at `src/services/sheinBrowserScript.ts`; marker `2026.08.08-v86.73-shein-product-image-separation`; native version `86.73 / 933`. Validation passed: build, freeze guard, performance budget (`1,199,339 / 1,200,000` raw JS; SHEIN source `545,661 / 550,000`), Android/iOS sync and Android `assembleDebug`. APK installed on real Note 8 `988e16384e4f51395230`: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-android-v86.73\otlobli-v86.73-note8-debug.apk` (SHA-256 `43E7726E87CDF4D855E132CD1DAF9A6CC06D4D2ED8A261910DE678FDE5D3E1DE`). Full user cart QA for a newly re-added live icon-based product remains needed; no iPhone IPA was built.

## Previous work — v86.71 automatic SHEIN region-transition recovery (2026-08-08)

Admin exposes only JO/AE/QA/SA for both independent stores. The Edge Function validates the same list, USD/ar, and Saudi's exact address path. Jordan is recognized in SHEIN's live drawer, index shortcut, Arabic label, scroll order, and signed variable-depth readiness.
User proved the failed region switch recovers immediately after Temu → SHEIN. The active region effect already closes/reopens the native session but did not reset WebKit's runtime cache; v86.71 sets `sheinCacheResetPendingRef` on every changed active SHEIN region before that one close/open. `InAppBrowser.clearCache()` removes only WebKit disk/memory cache, preserving cookies/localStorage and the signed address. No region drawer logic, product-tap fallback, polling rate, or native iPhone recompose burst changed.
Validation: `npm run build`, freeze guard, low-end budget, Android/iOS sync and Android `assembleDebug` pass. iPhone workflow [31264563690](https://github.com/m7madv/otlobli/actions/runs/31264563690) passed from `56d1c56`; IPA `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-ios-v86.71\otlobli-ios-v86.71-iphone16\otlobli-v86.71-iphone16-unsigned.ipa`, SHA `D74FD77854A94774119FF1E541B01F4D9CE9630051F8AA363370CBEC3573B948`, 7,066,154 bytes. Do a clean iPhone delete/reinstall then QA → SHEIN and SA → SHEIN: one fresh open only, no recurring pill; then product open + five resumes + cold launch. Note 8 was disconnected for this batch, so no physical Android run.
- Branch in this worktree: `claude/shein-ios-freeze-d75f65`; native version `86.71 / 931`; marker `2026.08.08-v86.71-region-transition-recovery`.
- Exact iPhone symptom: a home card opens a second SHEIN listing, then short taps on that listing do not route while long press shows SHEIN’s native menu. Treat it as an iOS short-tap route failure, not a general freeze.
- Candidate fix in `src/services/sheinBrowserScript.ts`: document-start iOS fallback waits 280 ms for SHEIN, then clicks the unchanged exact card once. It covers `.product-card`, the proven `LI.sd-ccc-products__item[role="link"]`, and narrowly named product/goods card classes. It rejects swipes / >650 ms presses. Preserve its scope: no recompose bursts, polling, reloads, or touch prevention.
- Region: preserve `sheinFindHomeShippingEntryControl()` and its no-geometry gate. `sheinVisibleShippingTabs()` additionally recognizes the real Cascade tabs: `.cascade__tabs [role="tab"]` and `.cascade__tabs .sui-tab-item-mobile`. Note 8 holds the signed Saudi address Riyadh Province/Riyadh/Al Olaya, but clean first-site session remains untested.
- Orientation: iOS `Info.plist` already lists portrait only. Android `MainActivity` now has `android:screenOrientation="portrait"`; do not add WebView rotation work.
- Current validation: `npm run build`, freeze guard, and budget pass (`1,197,893 / 1,200,000` raw JS; SHEIN `544,255 / 550,000`); both native projects synchronized. Android `86.69 / 929` debug build installed on Note 8 `988e16384e4f51395230`. iPhone workflow `31262261007` passed from `53d8191`; IPA `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-ios-v86.69\otlobli-v86.69-iphone16-unsigned.ipa` (SHA-256 `93A5C452200CBC5ACD736DA1A2592FAAE8B970E8D111E7B8C35DCA0A1607D6DC`, 7,066,086 bytes). User must clean delete/reinstall and test home → second listing → product, long press, five resumes, and cold launch.

## ⭐ HEAD OF `main` = `bb75cf8` / v86.67 (2026-08-08)

`main` was fast-forwarded to `679f476` (from `claude/shein-sku-image-freeze-bugs-52b525`), then WhatsApp server fixes landed on top (`bb75cf8`). It carries v86.66/v86.67 SHEIN store-based capture + admin colour swatch + WhatsApp iOS "waiting for this message" fix. The "Current candidate" sections below (v86.64 etc.) are historical — read `CURRENT_STATE.md` top for live status.

Deploy state (2026-08-08): **Vercel admin auto-deployed (live)**; **WhatsApp Oracle server DEPLOYED via SSH + LID fresh-session fix DEPLOYED — user confirmed WhatsApp works** («زبط الواتساب»); **iPhone app reinstall still pending (user-run)**. WhatsApp root cause was LID addressing (not the earlier getMessage/IDLE guess) — fixed by forcing a fresh Signal session per send (`WHATSAPP_FRESH_SESSION_PER_SEND`); full detail + rollback + server access (`ubuntu@84.8.100.128`, key `~/Downloads/ssh-key-2026-07-22.key`, server drifts from repo → manual scp) in `CURRENT_STATE.md`.

## Current candidate (2026-08-07) - v86.64 SKU image/color leak + size-select freeze

- Version `2026.08.07-v86.64-shein-sku-image-freeze-fix`; branch `claude/shein-sku-image-freeze-bugs-52b525` (fast-forwarded onto the v86.63 SKU-capture base — that branch started at v86.61 and was missing v86.62/63).
- **Root cause of both bugs was pathname-keyed state.** Fix 1: added `sheinGoodsId()` (Vue store goods_id → pathname fallback); the colour/image/price stash + `__otlobliSkuMemo` are now keyed/guarded on goods_id, so a quick-add product no longer inherits the previous product's colour, colour image, or memo. Fix 2: `sheinResolvedShippingUiRoot().inspect()` now rejects any candidate holding SKU markers (`[data-attr_value_id],.SIZE_ITEM_HOOK,.j-select-to-buy,.goods-size__sizes`), so the size drawer is never misread as the shipping drawer (that misread was locking the page = the "freeze" + false "close the shipping list first" block).
- Budget: largest JS raw `1,198,401/1,200,000` after condensing three Arabic Temu comment blocks; logic untouched. Freeze guard + budget both OK.
- **Not device-verified yet** (no SHEIN Vue store in the local browser preview). Confirm on Note 8: add product A (correct), then a second quick-add product B — B must show its OWN colour+image, and selecting a size must not freeze or trigger the shipping block.

## Current candidate (2026-08-02) - v86.58 iOS colour text = ring-selected swatch

- Version `2026.08.02-v86.58-...`; Android/iOS `918/86.58`; branch `claude/color-capture-fixes-v8655`.
- User (real iPhone) report: jewelry tray colour IMAGE correct (green) but the TEXT said `أرجواني أحمر`; and "text always follows the hero/default colour" (red hero → red text even when green picked; green hero → correct). Root cause: on iOS the selected swatch is marked ONLY by an outline (no aria/class/dark-bg), so `getSelectedColorSwatchImage()` finds it via `ringScore` (image correct) but `getSelectedWithin()` misses its label, so `getColorState` fell back to the stale main-page `sheinPageColorHeading()` (the hero default).
- Fix: new `sheinRingSelectedLabel(container)` reads the label of the SAME single ring-highlighted swatch the image trusts; `getColorState` uses `getSelectedWithin(container) || sheinRingSelectedLabel(container)`. Logically guaranteed: if the image is the green swatch, the label now is too. Also feeds the v86.57 stash (commit reads getColorState) so drawer-closed capture stays green. INERT on Android (getSelectedWithin returns non-empty there → `||` short-circuits) = no regression to the device-verified v86.57 behavior.
- Budget razor-thin with real `.env`: largest JS raw `1,199,981/1,200,000`. Condensed two Arabic comment blocks (`otlobliCustomTextSignal` header, my own) to fit; logic untouched.
- Not re-verified on a real iPhone yet (no iOS remote-debug here); reasoning is airtight from the user's "image is correct" observation. Confirm on device.

## Current candidate (2026-08-02) - v86.57 drawer colour = committed variant, DEVICE-VERIFIED END-TO-END

- Marker/version: `2026.08.02-v86.57-shein-drawer-color-committed-variant`; Android/iOS `917/86.57`; branch `claude/color-capture-fixes-v8655`.
- **Verified end-to-end on the real Note 8 via REAL `adb shell input tap` (not synthetic DOM clicks) + cart localStorage `talabieh.cartsByStore`.** Final cart: swan `color=لون القرنفل,size=""`; jewelry `color=أخضر داكن,size=14*14*2 سم` with the GREEN swatch image. Screenshot confirms pink swan + green dish.
- v86.56's `sheinCovered()` overlay-ignore attempt was WRONG and has been REVERTED: the jewelry drawer doesn't just get *covered* at add-time, it fully *closes* (device sample: `.SIZE_ITEM_HOOK` count → 0), so ignoring the overlay didn't help. The real fix:
  - `sheinTrackSelectedSkuPrice()`'s price-mutation observer already commits the chosen variant's price+key while the sheet is OPEN (reliable read) - that's why the green PRICE 12.66 was captured even though colour went stale. Extended `commit()` to ALSO stash `__otlobliSelectedSkuColor` + `__otlobliSelectedSkuColorImage` from the same moment.
  - `captureProductPayload()`: for drawer products (`__otlobliSheinDrawerPath === location.pathname`) with a recent committed key for this path, take colour/size/image from the committed stash instead of the stale live read. Size comes from `__otlobliSelectedSkuPriceKey.split('|')[1]`.
- CRITICAL for future device testing: synthetic `dispatchEvent(new MouseEvent('click'))` on a swatch does NOT reliably fire the price observer (savedKey stayed empty) - the stash looked broken until real `input tap` was used. Always verify SKU-selection fixes with real taps, then read `window.__otlobliDiag.saved()` for the committed key.
- Kept from earlier this session: `sheinIsQuantityEl()` ancestor-walk (swan quantity leak) and the size===color dedup.
- Budget is EXTREMELY tight with real `.env`: largest JS raw `1,199,798/1,200,000` (202 bytes). To fit the stash code, condensed two pre-existing Arabic comment blocks (`temuPickSingleSelected`, the Temu group-merge guard) - logic untouched. Trim comments before adding ANY main-bundle bytes.
- No price/payment/wallet/order/region/native-lifecycle changes. See [[project_note8_adb_recovery]].
- Artifacts: iOS workflow run `30749440191` succeeded at commit `a3d7e13`. IPA `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-ios-v86.57\otlobli-v86.57-iphone16-unsigned.ipa` (SHA-256 `826A65E37CC6EA2259C925C07B0DB8B084B6853C36816FD3482B59A2875951D9`, `7,067,505` bytes). APK `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-android-v86.57\otlobli-v86.57-debug.apk` (SHA-256 `E4981A9CBBBF22CF4E6D1C02CB725E89DB820A0127486C1779732CCFB7A6CD02`). The APK verified on-device was the same stash-fix code (built as 86.56 before the version-string bump to 86.57).

## Superseded (2026-08-02) - v86.56 SHEIN quantity + drawer-colour (sheinCovered attempt, reverted)

- Marker/version: `2026.08.02-v86.56-shein-quantity-and-drawer-color-fix`; Android/iOS `916/86.56`; branch `claude/color-capture-fixes-v8655`.
- **Verified on the real Note 8** (serial `988e16384e4f51395230`) via CDP against the live SHEIN WebView + real add-to-cart (hooked `mobileApp.postMessage`). v86.55 was NOT enough - the user retested and both products still failed; device diagnosis found the true DOM shapes.
- Three fixes, all `sheinBrowserScript.ts` only:
  1. `sheinIsQuantityEl()` - swan tray `p-517537202`: the quantity group's `goods-size__title` ("الكمية") is neither a descendant NOR a direct sibling; an intermediate no-class wrapper sits between them, and only the shared `goods-size__wrapper` (grandparent+) holds both الكمية and مقاس. v86.55's direct-sibling check missed it. Now walk ancestors and take the nearest level with a title PRECEDING this group as its heading (stop there). Live-validated: quantity hook → true, colour hook → false.
  2. `captureProductPayload()` dedup (unchanged from v86.55): SHEIN size===color ⇒ blank size. Sent payload now `color=لون القرنفل, size=""` (was `1PC|1PC`).
  3. `sheinCovered()` - jewelry tray `p-534350565`: the add-to-cart "جاري الإضافة" overlay (`#otlobli-overlay`, pointer-events:auto) sat over the open SKU drawer for the first ~450ms; `elementFromPoint` returned the overlay so `sheinCovered(drawerGroup)` was true → `sheinDrawerCompoundSizeState()` null → `getColorState()` fell back to the STALE main-page heading (`sheinPageColorHeading`), shipping the green drawer pick as `أرجواني أحمر %12-`. Fix: `sheinCovered()` treats any otlobli-owned layer (`[id^="otlobli-"]`) as NOT covering. Device-sampled the overlay hit at t=156/309/455ms to confirm. Sent payload now `color=أخضر داكن, colorImageFound=true` (green swatch), was `أرجواني أحمر %12-` + red hero.
- No price, payment, wallet, order, region, native lifecycle changes.
- Budget is VERY tight with real `.env` VITE values baked in: largest JS raw `1,199,946/1,200,000` (54 bytes headroom), SHEIN source `545,145/550,000`. Trim comments before adding any main-bundle bytes. Windows worktree `autocrlf=true` inflates the local SHEIN-source measurement; keep the file LF.
- Device debugging recipe used (works, keep): copy `.env*` from main repo root into the worktree, `node scripts/inject-relay-key.cjs`, `npm run build` → `npx cap sync android` → `android/gradlew assembleDebug` (needs `android/local.properties` with `sdk.dir`) → `adb install -r`. CDP: `adb forward tcp:9222 localabstract:webview_devtools_remote_<pid>`, then a global-WebSocket Node client (`Page.navigate` + `Runtime.evaluate`). `window.__otlobliDiag` exposes color/size/key/find. See [[project_note8_adb_recovery]].

## Current candidate (2026-08-02) - v86.55 SHEIN quantity-as-size leak fix

- Marker/version: `2026.08.02-v86.55-shein-quantity-size-leak-fix`; Android/iOS `915/86.55`; branch `claude/color-capture-fixes-v8655` (cut from `claude/shein-drawer-open-fix`, the newest v86.54 branch).
- Ground truth came from the on-device `تشخيص` overlay, NOT from screenshots. Swan tray `p-517537202`: live capture on v86.54 already reads color `لون القرنفل` correctly (Codex's fix works), but size captured `1PC` — the quantity. DOM: two `SIZE_ITEM_HOOK goods-size__sizes` groups with identical classes; the quantity group's `goods-size__title` ("الكمية") is a SIBLING of the options, not a descendant, so `sheinIsQuantityEl()` missed it and the 1-option quantity group won `findOptionContainer('size')` over the real multi-option `مقاس` group.
- Fix, narrow, `sheinBrowserScript.ts` only: (1) `sheinIsQuantityEl()` now also matches a quantity title among the group's DIRECT siblings (immediate parent's children) — never an ancestor, so a neighbouring `مقاس` group is safe. (2) `captureProductPayload()` dedup: on SHEIN, when size.selected === color.selected (same group matched twice — colour label `لون` lives inside the value `لون القرنفل`), blank size + its available/unavailable so the cart shows the colour once, with its swatch image. Side benefit: the spurious `1PC` also drops out of the jewelry tray's available sizes.
- Jewelry tray (`انقر للشراء`/green): live diag shows CORRECT capture `[أخضر داكن|...]` from the drawer `bs-color-square-image__wrapper`; `آخر إضافة` was empty (no completed add). So NO jewelry-tray change was made — the evidence says v86.54 already captures it right. If it still ships red, get the `آخر إضافة` line from a completed add on v86.55 to pin the exact add-time state before touching drawer/color logic.
- No price, payment, wallet, order, region, native lifecycle, or timing changes.
- Validation: `npm run build` OK, freeze guard OK, performance budget OK (SHEIN source `544,753/550,000`, largest JS raw `1,198,488/1,200,000`, JS gzip `356,434/370,000`). Env note: this Windows worktree has `git core.autocrlf=true`, which inflated the local SHEIN-source byte measurement (CRLF) and tripped the budget until the file was normalized to LF (the committed blob is LF, so CI/stored size = `544,753`).
- iOS workflow run `30747252696` succeeded at commit `861a08a`. IPA on Desktop: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-ios-v86.55\otlobli-v86.55-iphone16-unsigned.ipa`; SHA-256 `0774488C0ED7F1DFF0A603A08ED040E49D125F282AEAA725B55793D75A1B8FE5`; size `7,067,897` bytes. Android APK not built this round (user requested IPA only). Real-device acceptance pending; awaiting user retest + jewelry-tray `آخر إضافة`.

## Current candidate (2026-08-02) - v86.54 SHEIN selected color capture

- Marker/version: `2026.08.02-v86.54-shein-selected-color-capture-fix`; Android/iOS `914/86.54`; branch `claude/shein-drawer-open-fix`.
- User provided three cart screenshots: first product selected `لون القرنفل` on a text-button color row but cart showed `أبيض حريري`; second product cart variant joined every color and placed the selected color last; third `انقر للشراء` product kept the earlier red-purple image after the customer changed to green in the opened picker.
- Keep the v86.54 color-capture rules: `getSelectedWithin()` must not return text from a selected wrapper that contains multiple option children; it should use `sheinSelectionLabel()` from a single option and can fall back to `sheinLooksVisuallySelected()` for SHEIN's black selected button. `getColorState()` must prefer direct selected option text over stale page heading text. `getSelectedColorSwatchImage()` must skip multi-option selected wrappers. SHEIN payload image intentionally prefers `colorState.image || getMainImage()` to avoid stale hero thumbnails after a color change.
- Scope stayed narrow: no price, payment, wallet, order, region, native WebView lifecycle, or timing changes. One old shipped comment block was removed only to protect the bundle budget.
- Validation so far: `npm run build` passed, freeze guard OK, performance budget OK (`largest JS raw 1,197,091/1,200,000`, gzip `355,995/370,000`, SHEIN source `543,352/550,000`), extracted `SHEIN_CAPTURE_SCRIPT` `new Function` parse OK, `npx cap sync android`, `npx cap sync ios`, Gradle debug build. APK copied to `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-android-v86.54\otlobli-v86.54-debug.apk`; SHA-256 `366BBDFF77FD5A6535AFDCF1C7B62E40198EA964E4D8CA4AF1CDA3B9326F62D2`, size `11,121,882` bytes. iOS workflow run `30745439884` succeeded at commit `c590373`; CI largest JS raw `1,198,279/1,200,000`; IPA copied to `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-ios-v86.54\otlobli-v86.54-iphone16-unsigned.ipa`; SHA-256 `B04E34DB4A612A7589482B0C7DC7744E77BE707254A0FB85684F9BF0E7562152`, size `7,067,006` bytes; inspection confirmed `86.54/914`, marker/helpers, no app-level signature/provisioning, and native freeze symbols. Real-device acceptance is still pending; `adb devices` was empty.

## Current candidate (2026-08-02) - v86.53 cart gold swatch + Note 8 freeze fixes

- Marker/version: `2026.08.02-v86.53-cart-solid-color-swatch-fix`; Android/iOS `913/86.53`; branch `claude/shein-drawer-open-fix`. Base fix commit `861031f` is pushed; this follow-up trims shipped comments only so the iOS workflow has safe bundle headroom.
- Latest user screenshot showed cart rows saying `ذهبي أصفر` with a tiny color icon from another product. Confirmed in `talabieh.cartsByStore`: several different items had the same stale `colorImage` URL from product `p-424094842`. v86.53 fixes display and future adds by treating `ذهبي/Gold` as a local gold CSS swatch and dropping `colorImage` for new gold items.
- Device check after installing v86.53: existing stale cart rows now render `.cart-item-color-swatch` as `SPAN` with gold gradient, not `IMG`. This preserves the product thumbnail and variant text; only the misleading tiny color icon is replaced.
- Underlying v86.52 fix must stay: `sheinVisibleShippingTabs()` must remain scoped to `.address-header-tab .j-tab-item,.address-header-tab [role="tab"]`. The old generic `[role="tab"]` matched product floor/review tabs and could leave `body{position:fixed}` plus `#otlobli-nav-region-guard`, freezing product pages on Note 8.
- Other included session fixes: warm same-SHEIN-product reopen from cart; `.login-bar.j-login-bar{display:none!important}`; low-end mutation/scan throttles; selected-price tracking for active `.SIZE_ITEM_HOOK` drawer groups; stale body-lock cleanup; challenge-mode lock release.
- Initial manual iOS workflow run `30744352856` failed at `npm run build`: CI largest JS raw `1,201,132/1,200,000` because real `VITE_*` values add bytes. The follow-up removes 48 explanatory comment lines inside `SHEIN_CAPTURE_SCRIPT`; no runtime condition/timer/selector changed.
- Validation performed after the trim: `npm run build` passed, freeze guard OK, performance budget OK (`largest JS raw 1,196,344/1,200,000`, JS gzip `355,943/370,000`, SHEIN source `542,610/550,000`), `npx cap sync android`, `npx cap sync ios`, Gradle debug build. APK SHA-256 `F25829AC663691663F0FBE518C93C0A662FC95021C7186272512A70911BE7A95`, size `11,123,806` bytes.
- iOS workflow run `30744565468` succeeded at commit `96f0beb`; CI largest JS raw `1,197,532/1,200,000`. IPA copied to `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-ios-v86.53\otlobli-v86.53-iphone16-unsigned.ipa`; SHA-256 `A756B746DF0E606530FC8B401ABF4B2CFA2CD7718015793BD08A213AA28B91EE`; size `7,067,379` bytes. Inspection confirmed `com.otlobli.app`, `86.53/913`, no app-level signature/provisioning, v86.53 marker/gold swatch/`.address-header-tab`, and the native freeze symbols.
- Do not add more main-bundle code casually: the budget is safer but still intentionally bounded. If another UI fix needs bytes, remove/split code first. iPhone 16 acceptance was not performed.

## Current candidate (2026-08-01) - v86.47 four device-measured fixes

- Marker/version: `2026.08.01-v86.47-shein-options-clear-of-button`; Android/iOS `907/86.47`; branch `claude/shein-drawer-open-fix`, commit `154338c`.
- PR [#1](https://github.com/m7madv/otlobli/pull/1) open for merge to `main`.
- **Android verified on device**: add-to-cart $21.08, "L / أخضر" on 3-Tier-Lockable. Options visible and clear of floating button.
- **iOS IPA** on Desktop: `otlobli-ios-v86.47/otlobli-v86.47-iphone16-unsigned.ipa`. Build run `30711387365` passed.
- Four bugs fixed (all CDP-measured on Note 8): reversed heading `مقاس/لون`, missing `li` in selectors, toggle re-close, floating button covering options.
- **Diagnose on the Note 8 before writing code.** ADB + CDP: `adb forward tcp:9222 localabstract:webview_devtools_remote_$(adb shell pidof com.otlobli.app)`.
- Do NOT add confirm/retry timers (v86.44 disaster). Do NOT re-tap blind. Read `__otlobliTapTrace` first.
- Real control: `li.j-select-to-buy` > `span.capsule-box`. Toggle behavior — skip press if `sheinLowestOptionGroup()` returns non-null.
- `sheinClearOptionsFromButton` uses `scroll-margin-bottom` from the add button's live position to push options above it.
- Budget: JS raw `1,198,804/1,200,000` locally. CI adds ~1,230 bytes (Vite inlines secrets). Very tight.
- iPhone acceptance still owed.

## Superseded (2026-08-01) - v86.45 SKU drawer, single press

- Marker/version: `2026.08.01-v86.45-shein-sku-drawer-single-press`; Android/iOS `905/86.45`; branch `claude/shein-drawer-open-fix`. v86.44 was device-rejected outright ("خربت الدنيا") and its retry logic is deleted, not disabled.
- **Do not re-add a confirm/retry timer around the drawer.** v86.44's probe assumed an open drawer covers its entry row; SHEIN's drawer is a bottom sheet, the row stays visible and uncovered, so the timer re-tapped and CLOSED drawers that had opened, then refused the add on every product. If one press proves insufficient, read `__otlobliTapTrace` from the diagnostics `=== الدرج ===` section before touching the code.
- What must stay: `sheinTapElement()` (deepest node under the target centre; `pointerdown → touchstart → pointerup → touchend`, mouse/click tail only when the page did not cancel the touch) and `sheinSkuPromptNode()` (aim at the `انقر للشراء` chip, not its label row). `sheinOpenSkuDrawer()` presses once and returns.
- Requirement in the user's own words: on a product whose colour/size sits behind a separate screen, one press on `أضف للسلة` must press `انقر للشراء` for them so SHEIN opens its selection panel.
- `src/` equals v86.43 (`2dccab9`) plus exactly four things: the `sheinSkuTap` interpolation, the shared `OTLOBLI_SKU_PROMPT` constant, the tap replacing `entry.click()`, and the removal of the dead `debugSnapshot`. Keep it that small until the device confirms.
- Budget note stands: CI builds `1,230` bytes larger than a secretless local build (Vite inlines the real `VITE_*` values), NOT `~120`. Current CI-equivalent JS raw is `1,198,715/1,200,000`.

## Superseded (2026-08-01) - v86.44 SKU drawer opened by a real tap

- Marker/version: `2026.08.01-v86.44-shein-sku-drawer-tap`; Android/iOS `904/86.44`; branch `claude/shein-drawer-open-fix` off `claude/ios6-cover-fix` (`2dccab9`). v86.43 is device-rejected with "ما فتح": the drawer never opened and the add button said nothing.
- Superseded guidance: v86.42's "direct `entry.click()` is required for SHEIN's delegated product-drawer row" is wrong. `.click()` only reaches `click` listeners on that node or an ancestor, and the mobile options entry is bound with a touch directive on an inner chip.
- Preserve `src/services/sheinSkuTap.ts` and its `${OTLOBLI_SKU_TAP_JS}` interpolation next to `sheinSkuSelectionEntry`. It must stay outside `sheinBrowserScript.ts` (source budget) and its explanation must stay outside the template literal (everything inside ships verbatim).
- Preserve the tap contract in `sheinTapElement()`: deepest node under the target centre, `pointerdown → touchstart → pointerup → touchend`, and the mouse/click tail ONLY when the page did not cancel the touch. Sending it unconditionally double-activates a dual-bound row and toggles the drawer shut. Preserve `sheinConfirmSkuDrawer()`'s coverage probe (a drawer covers its own row) rather than any `.SIZE_ITEM_HOOK`-style class check, and its single retry plus the `اضغط "لون/مقاس" واختر ثم أضف` message - silence is the defect the user reported.
- Budget reality check before you add anything: CI builds `1,230` bytes larger than a secretless local build (Vite inlines the real `VITE_*` values), NOT `~120` as previously recorded. Measure with LF endings and realistic secret lengths. Current CI-equivalent headroom is `763` bytes on `largest JavaScript raw`.
- Evidence is logic-level only: injected-script syntax check, a four-scenario synthetic-DOM harness (touch-bound chip, ancestor click, no `TouchEvent`, blocked `elementFromPoint`), freeze guard and production build. No APK/IPA and no device acceptance - build them from this branch's workflows.
- If it still does not open, do not guess again: read the diagnostics `=== الدرج ===` section. `لمسة:` gives the tapped tag/class, `touch=0` means the engine refused to construct real touch events (then the touch path is unavailable on that WebView and the listener must be reached another way), and `cancel=1` means the page consumed the tap.

## Current candidate (2026-08-01) - v86.42 image swatches and inline sizes

- Marker/version: `2026.08.01-v86.42-shein-image-swatch-color-inline-size-focus`; Android/iOS `902/86.42`. v86.41 is device-rejected for product `p-453254089`: its active `.bs-color__item` produced an empty color, and an unselected inline `0XL–4XL` group did not receive the user. Preserve correct `$19.18/spa-dom` price.
- Preserve selected-host priority in `findOptionContainer()` and the `j=-1` container-self pass in both `getSelectedWithin()` and `getSelectedColorSwatchImage()`. Image-only active swatches may put the `active` class and image on the container itself, with no descendant selection label.
- Preserve `sheinPageColorHeading()`: at most four exact `.main-sales-attr-container` nodes, exact `لون/اللون/Color/Colour: value`, and only when no active compound drawer state exists. This changing heading supplies names such as `الأسود`/`الأحمر`; the selected swatch supplies the matching image.
- `sheinRevealSizeOptions()` scrolls and focuses the real detected size group but never clicks a size. Call it before both missing-size messages. Direct `entry.click()` is required for SHEIN's delegated product-drawer row. Full-script proof sends `الأحمر | 2XL | red.jpg | $19.18` only after a no-add focus step; prior shipping/drawer/compound regressions pass.
- Freeze/performance build, native syncs, Gradle/APK, and GitHub/Xcode run `30698764256` pass. Code commit `cbeada7`; inspected paths/hashes are in `CURRENT_STATE.md`. IPA confirms `86.42/902`, all new and native freeze markers, and no app-root signature/provisioning.
- Do not claim real-device acceptance. Test multiple image swatches, inline-size focus and two selected sizes, plus `انقر للشراء`, shipping blocking, five resume cycles, and cold launch. Automatic region switching remains separately open.

## Current candidate (2026-08-01) - v86.38 externally-rendered combined size

- Marker/version: `2026.08.01-v86.38-shein-confirmed-external-size`; Android/iOS `898/86.38`. v86.37 is device-rejected: the combined heading/value can live outside the detected drawer container, so a container-scoped query cannot see it.
- Preserve the strict two-signal rule: the external summary supplies order/text, but the second segment is accepted only when `isSelectedSwatchEl()` confirms a matching selected descendant inside the detected options container. If the summary matches the first segment but the second is unconfirmed, return an empty size and block the add.
- Browser proof reproduces the device failure before and passes after with `صينية من الخشب الصلب|رمادي / كبير`, while a stale/unconfirmed external summary is blocked. Normal `L`, `M / 1PC`, and `14.43/selected-mutation` stay unchanged.
- Freeze/performance build, native sync, Gradle, and APK metadata pass. APK: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.38-shein-confirmed-external-size-debug.apk`; SHA-256 `86B530AAAD1C98A680DA5CE644A8BFEAE5E80DDCA28E2C4A294EAE972CE615B1`; `86.38/898`.
- Commit `e3b82b1` is pushed; GitHub/Xcode run `30695599782` passed. Inspected IPA: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.38-iphone16-unsigned.ipa`; SHA-256 `E6423E8070530710A4876E5080D2ECC2CB0A2060A112A57DF346E85A648C7C67`; `86.38/898`, fail-closed confirmation and native recompose markers present, app unsigned/unprovisioned.
- Do not claim success without the exact v86.38 iPhone diagnostic and cart evidence. Preserve price, region signing, nav/drawer behavior, SKU memo, native recompose timing, and the unchanged-store comparison.

## Current candidate (2026-08-01) - v86.37 nested combined-size summary

- Marker/version: `2026.08.01-v86.37-shein-nested-combined-size`; Android/iOS `897/86.37`. v86.36 is device-rejected: its one-level relationship assumption still sent `رمادي`, despite the visible `رمادي / كبير` summary.
- Preserve the bounded ancestor walk in `completeSelectedCompoundSize()`: at most three levels, never beyond the detected container, exact heading, row shorter than 60, and exact equality between the first combined segment and the selected descendant. Do not replace it with page-text inference or option-stock parsing.
- The device-shaped nested fixture fails before and passes after: `صينية من الخشب الصلب|رمادي / كبير` is used by diagnostic, selected-price key, and add payload. Normal `L`, legacy `M / 1PC`, and price `14.43/selected-mutation` pass unchanged.
- Freeze/performance build, native sync, Gradle, and APK metadata pass. APK: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.37-shein-nested-combined-size-debug.apk`; SHA-256 `C0A98346368A80111F69C0C61FE0532530190F9D286C3E7D3CE27E366DD174A1`; `86.37/897`.
- Commit `355f89f` is pushed; GitHub/Xcode run `30695161552` passed. Inspected IPA: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.37-iphone16-unsigned.ipa`; SHA-256 `1E7666B2533859FE8F544BFD2EF65AC62A7A59B640DFFEB658CE786FA3104DF8`; `86.37/897`, nested-size and native-recompose markers present, app unsigned/unprovisioned.
- Real iPhone acceptance remains mandatory; require the full key/selected/last-add/cart evidence and retain five resume cycles plus cold launch. Preserve v86.35 navigation, v86.34 SKU memo, v86.33 price selectors, signed region guard, and all native recompose timing.

## Current candidate (2026-08-01) - v86.36 combined color/size capture

- Marker/version: `2026.08.01-v86.36-shein-combined-color-size`; Android/iOS `896/86.36`. Do not change price capture: the user confirmed it is fixed, and the exact regression still posts `14.43/selected-mutation`.
- Root cause is proven from the device diagnostic and full-script fixture: the detected size container returned its first selected descendant `رمادي`, although the same container's adjacent exact `لون / مقاس` summary said `رمادي / كبير`. Preserve the narrow completion in `completeSelectedCompoundSize()`.
- The completion is valid only for exact combined headings, a summary shorter than 60 characters, and an exact first-segment match with the already-selected descendant. Do not broaden this to nearby page text or infer a size from stock labels. Preserve the normal single-size path and the old `M / 1PC`/`CP1` path.
- Browser proof passes the photographed DOM (`صينية من الخشب الصلب | رمادي / كبير`), normal `L`, and `M / 1PC`. Freeze/performance build, both native syncs, Gradle, and APK metadata pass; paths and hashes are in `CURRENT_STATE.md`.
- Commit `6cc1384` is pushed; GitHub/Xcode run `30694579185` passed. The inspected unsigned IPA is `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.36-iphone16-unsigned.ipa`, SHA-256 `07D48915EAD3B6DA2B7243F9E16FB3058AD2195732C841393998B2270632B251`, with `86.36/896`, the combined-size and native-recompose markers, and no app signature/provisioning.
- Real iPhone acceptance remains unperformed. Verify the exact cart text, five background/resume cycles, and cold launch before calling the issue solved. Preserve v86.35 navigation, v86.34 drawer/SKU memo, v86.33 price selectors, signed-region guard, and all native recompose timing.

## Current candidate (2026-08-01) - v86.35 product-options drawer navigation

- Marker/version: `2026.08.01-v86.35-shein-options-drawer-nav`; Android/iOS `895/86.35`. The user explicitly confirmed the price issue is fixed; do not alter price capture while validating this candidate.
- The remaining defect was deterministic: the v85.8.12 geometry-only drawer guard set the visible `#otlobli-nav` to `pointer-events:none` whenever the full-screen product-options backdrop overlapped its rectangle. Preserve the new `!otlobliNavIsActuallyCovered(nav)` boundary: a backdrop painted behind Otlobli must not disable it, while a real option painted above it may still receive the tap.
- Preserve `OTLOBLI_NAV_TOUCH_BRIDGE_JS`, `data-otlobli-nav-type`, the capture-phase `touchend`, and its `450ms` touch/click dedupe. The bridge is installed at documentStart so SHEIN's later modal listener cannot swallow navigation before the button handler.
- Playwright at `430×932` passes the exact modal-capture regression: old geometry would yield, new hit-test does not, nav remains `auto`, `cart/orders/profile` each fire once, and an SKU option remains clickable. Evidence is untracked under `output/playwright/v86.35-options-nav.png`.
- Freeze guard, production/performance build, Android/iOS sync, Gradle debug, and APK metadata pass. APK: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.35-shein-options-drawer-nav-debug.apk`; SHA-256 `336074AE7BD25DC59079D51ADD177371EBB63EBBF0A850BFB38FF191E2F31D6C`; `86.35/895`. No physical device was present for this batch.
- Code commit `4768893` was pushed to `claude/ios6-cover-fix`; GitHub/Xcode run `30693899285` passed. IPA: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.35-iphone16-unsigned.ipa`; SHA-256 `22B61C8F6204433A5E4F30E8FFABDC43F11D6CC61F83A5C48DAD771387AAF00B`; `86.35/895`. Inspection found the v86.35 nav markers, current price/SKU markers, and native recompose markers, with no app signature or provisioning profile.
- Do not claim iPhone acceptance from Playwright/build. Test the photographed SHEIN options drawer on the real iPhone, including first-tap cart/orders/profile, SKU choice/add, five background/resume cycles, and cold launch. Preserve all v86.34 SKU memo/covered-placeholder and v86.33 price markup logic.

## Current candidate (2026-07-30) - v86.29 selected-price race guard

- Marker/version: `2026.07.30-v86.29-shein-price-race-guard`; Android/iOS `889/86.29`; auth bypass off. The intermittent symptom is now reproduced: add completion could beat SHEIN's delayed option-price mutation.
- Preserve `__otlobliSelectedSkuPriceBefore` and `sheinSelectedSkuPricePending()`. The capture-phase option click stores the old amount; add waits only while the existing bounded observer has not produced a current path/key amount different from that old value. Do not replace this with a permanent observer, global price polling, or a fixed delay on every product.
- `priceWaits` is bounded to 16 × `120ms` and runs only during an active add after an option click. A price mutation releases it immediately. A legitimately same-price option falls through when the existing `1.75s` observer disconnects. Preserve the positive-price completeness/fail-safe and the exact live PDP price preference on the first product as well as SPA routes.
- Browser proof before/after: delayed `$1 -> $9.99` posted wrong `$1/json` in `42ms`; after the guard it posted `$9.99/selected-mutation` in `747ms`. The no-change `$1` case completed in `1,835ms`. Immediate mutation, SPA, compound/no-selection, country-scroll, and signed-region suites also pass.
- Freeze/performance/build, Android/iOS sync, Gradle, APK metadata, GitHub/Xcode run `30547309099`, and IPA inspection pass. APK/IPA paths and hashes are in `CURRENT_STATE.md`. Primary code commit is `216ea26`; iOS code commit is `29e8e08`. The IPA contains the price-pending, country-scroll, and native-recompose markers, excludes the old live-scanner/stable-read markers, and has no app signature or provisioning. Do not claim real iPhone acceptance until the timing, multi-product, region, resume, and cold-launch cases are tested on-device.

## Current candidate (2026-07-30) - v86.28 SPA price and country-list scroll

- Marker/version: `2026.07.30-v86.28-shein-spa-price-country-scroll`; Android/iOS `888/86.28`; auth bypass off. The user proved the price defect is session-scoped: several products reused one amount, then a full app restart made prices change correctly.
- Preserve the SPA boundary. `__otlobliInitialCapturePath` identifies a later `history.pushState` product route; on that later route `getTitle()`, `getMainImage()`, and `sheinSpaRoutePrice()` prefer exact live PDP state instead of document-static JSON/meta from the first product. The selected-mutation value remains first priority and must keep exact selection-key/path validation. Never restore a whole-page price scan or cache a price without the current route/selection boundary.
- Preserve `sheinCountryRowsInRoot()` as a fallback only inside `sheinResolvedShippingUiRoot()`, with exact known-country matching and bounded descendants. `sheinAddressListScroller()` must compare ancestors of all visible rows and pick the smallest true scroller; inspecting only the first row can select a drawer/tab ancestor and leave the inner virtual list unchanged. Keep `country-row-fallback` and `country-list-scroll` bounded diagnostics.
- Browser proof: a same-document SPA transition with stale `$4.50` JSON/meta and visible `$8.25` changed from wrong `$4.50`/first title to `$8.25`/second title/source `spa-dom`. A generic-row drawer started with `visibleOptions:0`; after the fix the inner list scrolled `0 -> 180`, Saudi rendered and was clicked, and the signed cookie became Saudi. Selected mutation, compound selection, no-selection, and already-signed fast-path suites also pass.
- Freeze/performance/build, Android/iOS sync, Gradle, APK metadata, GitHub/Xcode run `30540335090`, and IPA inspection pass. APK/IPA paths and hashes are in `CURRENT_STATE.md`. Primary code commit is `25e2b4d`; iOS code commit is `39ba8ef`. The IPA contains the SPA-price/country-scroll and native-recompose markers, excludes the old live-scanner/stable-read markers, and has no app signature or provisioning. Do not claim real iPhone acceptance until the user tests the exact session, region, resume, and cold-launch cases.

## Current candidate (2026-07-30) - v86.27 selected-SKU mutation price

- Marker/version: `2026.07.30-v86.27-shein-selected-sku-mutation-price`; Android/iOS `887/86.27`; auth bypass off. The user rejected v86.26 on the real iPhone because changing to a higher-priced color/size still posted the entry price.
- Preserve the causal selection tracker: `sheinTrackSelectedSkuPrice()` starts only from a click inside the detected color/size containers, watches only changed PDP price roots for at most `1.75s`, and caches the non-crossed USD amount with the exact `color|size` key plus pathname. It commits from the price mutation immediately so a fast add does not fall back to static JSON.
- Preserve the key/path validation in `getPrice()`. A selected-mutation price must never be reused for another option or product. When no matching mutation exists, keep the exact v85.8.55 fallback order: JSON-LD, meta, legacy DOM. Do not restore `sheinLiveSkuPrice()`, stable-read waiting, whole-page scanning, or the old `price-capture` diagnostic.
- Preserve `selected-sku-price-capture` through the existing diagnostic bridge. It is event-driven and bounded; do not turn it into polling or a permanent observer. Keep the source budget and do not raise performance limits.
- Playwright proves static JSON/meta `$1` plus immediate live mutations: `S=$1` source `json`, `M=$2` and `L=$9.99` source `selected-mutation`. The no-selection and compound suite still passes `L`, `M / CP1`, `M / 1PC`, and `L / 1PC`.
- Freeze/performance/build, Android/iOS sync, Gradle, APK metadata, GitHub/Xcode run `30538230343`, and IPA inspection pass. APK/IPA paths and hashes are in `CURRENT_STATE.md`. Primary code commit is `4b0b99d`; iOS code commit is `237db18`. The IPA contains the selected-mutation and native-recompose markers, excludes the old scanner/stable-read markers, and has no app signature or provisioning. The connected iPhone cannot receive an unsigned IPA from this Windows host, so do not claim device acceptance before the user tests the exact product and resume/cold-launch cases.

## Current candidate (2026-07-30) - v86.26 v85.8.55 capture baseline

- Marker/version: `2026.07.30-v86.26-shein-v855-capture-baseline`; Android/iOS `886/86.26`; auth bypass off.
- The user rejected v86.25 on the real iPhone. The requested known-good baseline is not a guessed tag: GitHub run `29657616560`, commit `eb7b0ca`, and downloaded v85.8.55 IPA SHA-256 `52ED888B77AF294970B6CC7E19557131CDC848B3A29D79E4C40B3D3E93FF1F16`. Its built production script was inspected directly.
- Preserve the restored v85.8.55 capture order: JSON-LD offer, `product:price:amount`, then `.product-price .price-content, .product-intro__head-price, [class*="price" i]`. Do not reintroduce `sheinLiveSkuPrice()`, `stableSheinPriceReads`, or the `price-capture` diagnostic without new real-device evidence; the guard now forbids them.
- Preserve v85.8.55's immediate SHEIN add completion once title/image/color are ready. This removes the newer repeated price waiting that made “جاري التجهيز” slower. Keep the signed `addressCookie`/region guard and `sheinSkuSelectionPending()` protection.
- The sole intentional post-v85.8.55 capture delta is the narrow `completeSelectedCompoundSize()` helper, retained for the user's original `M / CP1` case. Do not replace it with broad summary or quantity inference.
- Playwright passed `$11.15 -> $17.19` at `$17.19` in `314ms`, plus no-selection, `L`, `M / CP1`, `M / 1PC`, and `L / 1PC`. Freeze/performance/build, native sync, Gradle, APK metadata, GitHub/Xcode run `30536477640`, and IPA inspection pass. Paths/hashes are in `CURRENT_STATE.md`.
- Primary code commit: `08bc726`; iOS code commit: `7196f98`. The connected iPhone was detected by Windows but the unsigned IPA could not be installed from this host. Do not claim real iPhone acceptance until the user tests the exact product, rapid variant changes, region setup, resume cycles, and cold launch.

## Current candidate (2026-07-30) - v86.25 priority SHEIN PDP title

- Marker/version: `2026.07.30-v86.25-shein-priority-pdp-title-price`; Android/iOS `885/86.25`; auth bypass off.
- Preserve `sheinPdpTitleElement()` priority: exact `.product-intro__head-name`, then `h1`, then legacy broad fallbacks. A comma-separated `querySelector('h1, ... [class*="product-name"] ...')` is forbidden here because selector order does not create priority; a recommendation name earlier in DOM can become the boundary and reject the real PDP price.
- Preserve v86.24's bounded price roots before the authoritative PDP title, v86.23's later equal-score active root, live-before-meta/JSON fallback, two stable reads, and the incomplete-payload block. Do not restore whole-page price scanning or variant inference.
- `price-capture` deliberately runs before the fail-safe and records `title`/`image` booleans. Keep it bounded to the existing add flow; do not add polling or a new observer.
- Full-script Playwright passes the exact drawer-before-PDP regression: stale `$11.15`, active `$14.26`, later recommendation `$2.23` posts `$14.26` with roots `11.15@40,14.26@40`. A no-price run posts nothing and diagnoses `captured:0/source:missing/title:true/image:true`.
- Build/freeze/performance, native sync, Gradle, Android install, GitHub/Xcode run `30533726236`, and IPA inspection pass. APK/IPA paths and hashes are in `CURRENT_STATE.md`. The connected Note8 had no usable SHEIN/VPN route, and no real iPhone acceptance was performed; do not claim the photographed product is device-accepted until the user tests it.
- Primary code commit: `46e4dae`; iOS code commit: `7adff45`. Preserve the signed-address region fast path, bottom bar, unchanged-region comparison, and all native recompose timing.

## Current candidate (2026-07-30) - v86.24 PDP-only price and signed-region fast path

- Marker/version: `2026.07.30-v86.24-shein-pdp-price-signed-fast-path`; Android/iOS `884/86.24`; auth bypass off.
- Preserve the diagnosed price boundary: only painted PDP price roots before the real product title are eligible. Do not restore generic `[data-testid*="price"]`, whole-page price scanning, or recommendation roots after the title. Keep the later equal-score PDP root rule so a newly selected SPA SKU beats a stale entry root.
- Preserve the region condition `!sheinSignedSaudiAddressReady() && sheinProductUrlNeedsRegionBootstrap(normalized)`. Real-device v86.23 proved that omitting the signed check caused a false veil/repair/reload on every signed SPA product. The signed `addressCookie` remains the add-to-cart authority.
- Preserve readiness dedupe by `type + pathname`. It posts one state per route but still permits a new route and an `interactive -> signed-ready` transition. The key is set only when the bridge exists.
- Real Note8 final evidence: `86.24/884`, signed Saudi cookie with signature length 192, `prime-already-ready`, one `sheinSaudiReady`, no veil, and zero `product-bootstrap-reload`. The pictured product `418157946` visibly mounted recommendation prices `$2.66/$2.40`; its active SKU was sold out, so the incomplete add was blocked. A Chrome renderer crash occurred only during the Android 9 DevTools stress session; do not present it as an app-JS fix or iPhone result.
- Playwright exact regression captures `$14.26` from stale `$11.15` + active `$14.26` PDP roots while excluding later `$2.23`; all repeated/delayed/compound/no-selection suites pass. Build/freeze/performance, native sync, and Gradle pass. APK path/hash are in `CURRENT_STATE.md`.
- Primary commits: `608842d` + `f4ce902`; iOS commits: `9597fc9` + `0cbf6dc`; GitHub run `30530246600` passed. The unsigned IPA path/hash and inspection are in `CURRENT_STATE.md`. Real iPhone acceptance is still mandatory; do not infer it from Android, Playwright, or CI.

## Current candidate (2026-07-30) - v86.23 active SHEIN SKU price root

- Marker/version: `2026.07.30-v86.23-shein-active-sku-price-root`; Android/iOS `883/86.23`; auth bypass off.
- The user's known-good GitHub reference is workflow run `#427`, resolved to run id `30085191333`, commit `b22f5d1`, and built marker `v85.8.91`. The actual IPA was downloaded and inspected. That script used JSON-LD first and did not contain `sheinLiveSkuPrice()`.
- The new regression was inside v86.21's live scanner: `if (best > 0) return best` ran inside the root loop, so a still-mounted entry-price root could win before the selected SKU root. v86.22 was not handed off; it still returned static meta before the live price. Do not restore either order.
- Preserve the v86.23 rule: scan only the bounded product-price roots during existing add retries, reject hidden ancestor branches/old prices, compare all roots, prefer the later equal-score active root, then fall back to meta/JSON. Preserve the bounded `roots` diagnostic; it is the next device-proof signal if the page still differs.
- No variant inference changed. Keep v86.20's narrow `completeSelectedCompoundSize()` and the ban on `sheinQuantitySizeSummary()`. Keep signed `addressCookie`, region repair, bottom nav, WebView lifecycle, and native recompose invariants unchanged.
- Playwright passes repeated two-root prices (`1 -> 2 -> 9.99`) with exact root traces, the screenshot and delayed-price fixtures, JSON fallback, and all no-selection/normal/compound variant regressions. Build/freeze/performance, native sync, and Android Gradle pass. APK and hashes are in `CURRENT_STATE.md`.
- Primary commits: `80d9d1a` + `a390f5e`; iOS commits: `1c960e1` + `328a563`. Final iOS run `30522960782` passed. The unsigned IPA path/hash and clean inspection are recorded in `CURRENT_STATE.md`. No real-device acceptance has been performed.

## Current candidate (2026-07-30) - v86.21 SHEIN live selected-SKU price

- Marker/version: `2026.07.30-v86.21-shein-live-sku-price-fix`; Android/iOS `881/86.21`; auth bypass off.
- Confirmed root cause: `getPrice()` returned JSON-LD's default offer `$11.15` before the selected color's live DOM price `$17.19`. Do not restore JSON-LD-first pricing or generic page-wide `[class*="price"]` scraping.
- `sheinLiveSkuPrice()` scans at most four primary PDP price roots and 60 descendants per root, excludes percent/old/crossed prices, and runs only during the existing add retries. Capture requires two stable price reads after interaction settles; there is no permanent timer, cache, React state, or new polling.
- Do not mix this price fix with option inference. v86.20's no-cache `completeSelectedCompoundSize()` remains the only narrow compound exception, and `sheinQuantitySizeSummary()` remains forbidden. Signed `addressCookie`, region repair/diagnostics, bottom nav, and all iPhone/Android recompose guards are unchanged.
- Playwright passes the exact `$11.15 JSON → $17.19 live` case, delayed price update, JSON fallback, compound size, and the complete v86.20 selection suite. Local build/sync/Gradle and GitHub/Xcode run `30519999113` pass. APK/IPA paths and hashes are in `CURRENT_STATE.md`.
- Primary code commit `9efab6b`; iOS code commit `cf7a442`. IPA inspection is clean and unsigned. No Android device was connected and no real iPhone acceptance was performed; require the photographed premium color/size, rapid variant changes, five background/resume cycles, and cold launch before claiming device resolution.

## Current candidate (2026-07-30) - v86.20 SHEIN variant regression fix

- Marker/version: `2026.07.30-v86.20-shein-variant-regression-fix`; Android/iOS `880/86.20`; auth bypass off.
- v86.19's `sheinQuantitySizeSummary()` is rejected by real-device feedback. It scanned controls near `الكمية / مقاس` and could mistake an unselected/default/stale value for the customer's choice. Do not restore that function, its 1.2s value cache, its click invalidation, or the extra broad size heading labels.
- Ordinary product capture and price logic are exactly the v86.18 baseline again. `completeSelectedCompoundSize()` is deliberately narrow: it activates only when the old selected value is an exact piece count (`1PC`/`CP1`) and completes it from a size that is also explicitly selected inside the same container, preserving `M / CP1` when that is the selected control text.
- Playwright passes five cases: unselected blocked, normal `L`, nested `M / CP1`, separate `M / 1PC`, and changed `L / 1PC`. Local build/freeze/performance, Android/iOS sync, Android Gradle, and GitHub/Xcode run `30497128620` pass. APK/IPA paths and hashes are recorded in `CURRENT_STATE.md`; all real-device acceptance remains pending.

## Current candidate (2026-07-30) - v86.19 auth, compound variant, tracking

- Marker/version: `2026.07.30-v86.19-auth-variant-tracking-fix`; Android/iOS `879/86.19`; auth bypass off.
- Production auth root cause is confirmed and fixed live: `public.ensure_customer` called `public.validate_customer_full_name`, but no migration had ever created the validator. Migration `20260730120000_fix_new_phone_customer_session.sql` is applied; `validator_exists=true`, `validate_customer_full_name('عميل طلبية')` passes, and a new-customer `ensure_customer` path passed inside `BEGIN/ROLLBACK`. Ask the user to request a fresh OTP when retesting.
- The server source also reopens the same correct OTP when session persistence throws. That defense is not deployed to the Oracle WhatsApp host because this workspace has no accepted SSH/deploy credential; do not claim it live. The database change that caused the user-visible failure is deployed.
- SHEIN size capture must preserve the complete visible combined selector. `sheinQuantitySizeSummary()` scores `M / CP1` above a nested partial `1PC`, caches the bounded scan for 1.2s during retries, and invalidates it after a real SHEIN tap. The Playwright fixture proved the posted cart value is exactly `M / CP1` while signed-region readiness remains true.
- Do not weaken `sheinSignedSaudiAddressReady()`, region diagnostics, one-reload guard, veil, or native freeze lifecycle. This release did not change region switching or native recompose timing.
- Tracking now uses `mobile-content--tracking` max-content rows and two-column cards. At 320/430px: header/product overlap false, card overlap false, horizontal overflow false. Visual artifacts are under `output/playwright/v86.19/`.
- Validation/build budgets and artifact hashes are recorded in `CURRENT_STATE.md`. APK is `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.19-auth-variant-tracking-fix-debug.apk`; IPA is `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.19-iphone16-unsigned.ipa`. GitHub run `30493537125` passed from iOS commit `0400ffb`; IPA is unsigned and real-device acceptance is pending.

## Current diagnostic candidate (2026-07-29) - v86.18 region injection trace

- Marker/version: `2026.07.29-v86.18-shein-region-injection-diagnostics`; Android/iOS `878/86.18`; auth bypass off. v86.17 was rejected on the real iPhone 16 because first-product region switching still did not start visibly.
- Do not guess at iPhone DOM yet. The confirmed architecture gap is earlier: `OTLOBLI_NAV_BOOTSTRAP_SCRIPT` can make the nav visible without proving the full `SHEIN_CAPTURE_SCRIPT` ran. The `browserPageLoaded` handler used to reject a non-empty event id when `webviewIdRef.current` was still empty; it now adopts that first singleton id and injects against it.
- WebView → React telemetry type is `sheinRegionDiagnostic`. Expected first-product chain: `capture-evaluation-start` → `capture-script-injected` → `tick-product-route` → `prime-called` → `repair-started` → `region-veil-state` → `shipping-scan`/`shipping-entry-control`/`shipping-control-click` → `repair-signed-ready` or `repair-timeout`.
- React keeps the last 80 entries in `window.__OTLOBLI_SHEIN_REGION_DIAGNOSTICS__` and logs them under `[otlobli][shein-region]`; no state update/render occurs. The WebView queue is capped at 32 and retries for at most 20 × 250ms.
- Add-to-cart still requires `sheinSignedSaudiAddressReady()`. The one product bootstrap reload, native recompose patch/burst, Android resume defense, and unchanged-region `JSON.stringify` guard remain intact. No device-acceptance claim is allowed until a real iPhone captures the diagnostic chain plus the five resume cycles and cold launch.
- Local validation passed: TypeScript, production build, freeze guard, performance budget, Android/iOS Capacitor sync, and Android Gradle debug build. APK: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.18-shein-region-injection-diagnostics-debug.apk`, SHA-256 `5A143E2038E61508FD4E6D15A6B3E105AB04557572CE8DCF08303C5BB9CF6070`, size `11,528,789` bytes. No ADB device was connected.
- Code/source commit `5e68790` is pushed on the primary and `codex/ios-v86-4` branches. GitHub/Xcode run `30489996516` passed. Unsigned IPA: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.18-iphone16-unsigned.ipa`, SHA-256 `99BA19D125568162F8AB4601148375080FCBB8825755F724332EEC1CD7AEC41F`, size `7,064,608` bytes. Inspection confirms `com.otlobli.app`, `86.18/878`, diagnostic/injection/recompose markers, no provisioning profile/signature, and only the `otlobli` URL scheme.

## Current candidate (2026-07-29) - v86.17 first-product region bootstrap + hidden switch veil

- Marker/version: `2026.07.29-v86.17-shein-first-product-region-veil`; Android/iOS `877/86.17`; auth bypass off. Primary branch remains `claude/ios6-cover-fix`; matching iOS source is pushed on `codex/ios-v86-4` at `ad8b93d`.
- Root cause addressed after v86.16: iPhone 16 fresh install/first product could show no region action because repair was effectively waiting on shipping DOM/readiness. `sheinLooksLikeProductRouteForShipping()` now treats product URL/queries as enough to prime repair, and `tick()` calls `sheinPrimeRegionRepairFromRoute()` before the touch/scroll early-return.
- Product URLs missing/stale region params get one bounded bootstrap reload through `__otlobliRegionBootstrapReload:<country>:<path>`; this is allowed only on product routes and skipped on SHEIN challenge routes. Do not turn it into a repeated reload/setUrl loop.
- The switch is hidden by the in-page `#otlobli-region-switching` veil, not the old native `sheinSaudiRepairStart` cover. The bottom nav remains above it; add/back are hidden while the veil is active; add-to-cart must still require `sheinSignedSaudiAddressReady()`.
- Preserve the new freeze-guard markers in `scripts/verify-shein-freeze-guard.mjs`: first-product route detection, region veil, prime repair, bootstrap reload key, and the tick call. Old `OTLOBLI_DBG` console scanning was intentionally reduced to a no-op to stay under the SHEIN source budget.
- Validation passed: production build, freeze guard, performance budget, Android sync, iOS sync, Android Gradle debug build, GitHub/Xcode run `30487346505`, and IPA inspection. Budgets: JS raw `1,180,135`, JS gzip `355,127`, CSS `62,602`, fonts `81,364`, SHEIN source `549,688/550,000`.
- APK/SHA: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.17-shein-first-product-region-veil-debug.apk`, `036333156DFA7A9C37123E1CAFD1057391596304EC118066E0F0A9243583A91D`. No Android device was connected for install.
- IPA/SHA: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.17-iphone16-unsigned.ipa`, `56A70B26090D484045A09654077D48D5B5B7108F67B31D792B8B82018F746A3A`. Unsigned/unprovisioned; Info.plist is `com.otlobli.app`, `86.17/877`, URL schemes only `otlobli`. Real iPhone acceptance remains required.

## Current candidate (2026-07-29) - v86.16 background region repair + payment normalizer

- Marker/version: `2026.07.29-v86.16-region-background-payment-status-normalizer`; Android/iOS `876/86.16`; auth bypass off. Primary branch remains `claude/ios6-cover-fix`; matching iOS source is pushed on `codex/ios-v86-4` at `225cdb2`.
- Payment screenshot root cause was production `orders_payment_status_check`. Remote Supabase has migration `20260729223000_normalize_order_payment_status_before_check.sql` applied and listed. It adds `normalize_order_payment_status_before_write()` plus trigger `orders_aa_normalize_payment_status` before insert/update so legacy/mojibake/mobile statuses normalize to canonical Arabic before constraints and exact-payment trigger logic. Keep `supabase/schema.sql` aligned.
- SHEIN region repair changed intentionally: do not restore the old native `sheinSaudiRepairStart` cover. Repair now starts in the background, returns immediately, and uses a fast bounded progress timer. It applies the signed `addressCookie` requirement to every configured supported country, not Saudi only. Add-to-cart must remain blocked until `sheinSignedSaudiAddressReady()` passes.
- Region switching performance guard: heavy `tick()` backs off during touch/scroll even while repair is active; only `scheduleSheinShippingProgress(...)` continues. If the shipping drawer is visible, `stabilizeSheinShippingDrawerInteraction()` must keep touches inside the drawer and keep Otlobli nav visible.
- Lightweight Arabic labels are visual-only (`data-otlobli-ar-label`/CSS) and must not replace SHEIN option `textContent`, because automation depends on original English/Arabic labels.
- Validation passed: production build, freeze guard, performance budget, Android sync, iOS sync, Android Gradle debug build, Supabase migration push/list, GitHub/Xcode run `30455469510`, and IPA inspection. Budgets: JS raw `1,178,885`, JS gzip `355,134`, CSS `62,602`, fonts `81,364`, SHEIN source `548,516/550,000`.
- APK/SHA: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.16-region-background-payment-status-debug.apk`, `6A6E250025BC9A8D9D4C1D3615E8C16DB8FFE9F64D90086E4BB3F6334AC6CEFB`. No Android device was connected for install.
- IPA/SHA: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.16-iphone16-unsigned.ipa`, `B306938FC6AEAEB2189026AF9D4966C05658F0F8CC05C2DBE79677FAA816E5D9`. Unsigned/unprovisioned; Info.plist is `com.otlobli.app`, `86.16/876`, URL schemes only `otlobli`. Real iPhone acceptance remains required.

## Current candidate (2026-07-29) - v86.15 iOS safe top + Saudi region repair

- Marker/version: `2026.07.29-v86.15-ios-safe-top-saudi-region-repair`; Android/iOS `875/86.15`; auth bypass off. Preserve the dirty primary worktree. Matching iOS source is pushed on `codex/ios-v86-4` at `36d0486`.
- The live Admin app setting was verified as SHEIN `SA`, path `Riyadh Province -> Riyadh -> Al Olaya`; do not chase Admin first if the user still sees Qatar. The bug was the iPhone/SHEIN automation path.
- Keep `enabledSafeTopMargin:true` for all platforms and keep `useTopInset: !isIosNative`. This fixes iPhone status-bar overlap while preserving the existing iOS bottom-nav strategy (`enabledSafeBottomMargin: !isIosNative`).
- Region automation changes to preserve: product readiness for SA now requires signed `addressCookie`; country lists move toward the configured country when the target row is off-screen; bilingual address rows match any `/` side, so `العليا/Al Olaya` can match the configured `Al Olaya`.
- No new permanent polling was added. The repair still runs inside the existing bounded native-cover cadence and must stay under the SHEIN source budget.
- Validation passed: production build, `verify:shein-freeze-guard`, `verify:performance-budget`, Android/iOS sync, Android Gradle, isolated iOS build, GitHub/Xcode run `30445161898`, and IPA inspection. Budgets in primary build: JS raw `1,179,804`, JS gzip `355,415`, SHEIN source `549,631/550,000`.
- APK/SHA: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.15-ios-safe-top-saudi-region-repair-debug.apk`, `FA406DAFD77CD390023E2686E41EF9786B65CA208E2BA758456ED35F1B410DC2`.
- IPA/SHA: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.15-iphone16-unsigned.ipa`, `64C3DCFAEBE2FD27225D266305819B58EA167CCD744697AFB128DA0135ED8125`. Unsigned/unprovisioned; real iPhone acceptance remains required before claiming final device success.

## Current candidate (2026-07-29) - v86.14 checkout/cart iOS layout + payment status

- Marker/version: `2026.07.29-v86.14-checkout-cart-ios-layout-payment-status-fix`; Android/iOS `874/86.14`; auth bypass off. Preserve the dirty primary worktree. Matching iOS source is pushed on `codex/ios-v86-4` at `db6e73c`.
- The user-reported iPhone distortion was not a global iOS scale problem. It was checkout/card content being clipped by implicit CSS Grid row sizing plus oversized long cart text. Preserve `.mobile-content--checkout { grid-auto-rows:max-content; }`, compact checkout spacing, the separated primary action, and the three-line `.cart-item-title` clamp.
- Do not reintroduce `backdrop-filter` on `.sticky-pay-bar`; it was removed to keep weak-phone rendering lighter. Avoid global zoom, page scale, or iOS top inset tweaks unless a real device proves a separate problem.
- New order payloads must use normalized `payment_status`. Production Supabase already received `20260729210000_fix_order_payment_status_constraint.sql` via `supabase db push --linked`; do not create another conflicting payment-status check migration unless comparing the live schema first.
- Validation passed: production build, `verify:shein-freeze-guard`, `verify:performance-budget`, Android/iOS sync, Android Gradle, isolated iOS build, and GitHub/Xcode run `30441863134`. Visual fixtures are in `output/playwright/v8614-*.png` and `output/playwright/v8614-layout-report.json`.
- APK/SHA: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.14-checkout-cart-ios-layout-payment-status-fix-debug.apk`, `7538734E1C5DF5F8D6ED7D7517A693FF3BF12CBFEC250E62E611D7B8212001BD`.
- IPA/SHA: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.14-iphone16-unsigned.ipa`, `E64F0A488ABC5BB241E972BD67E3A95DAF15B61ACA7F3F39988446C4C9F922A9`. It remains unsigned/unprovisioned. Required real iPhone acceptance: checkout/cart/payment, nav taps, five background/resume cycles, and cold launch.

## Current candidate (2026-07-29) - v86.13 responsive cart, native navigation, Android top inset

- Marker/version: `2026.07.29-v86.13-responsive-cart-instant-native-nav`; Android/iOS `873/86.13`; auth bypass off. Preserve the dirty primary worktree. The isolated iOS source branch is `codex/ios-v86-4`.
- Cart overlap was Grid track shrinkage, not a typography or global scale issue. Preserve `.mobile-content--cart { grid-auto-rows: max-content; }`, the flex-based `.cart-item`, bounded image/swatch dimensions, semantic title button, and narrow breakpoint. Do not restore generic `.cart-item { overflow:hidden }`.
- Android top clipping is fixed only through `enabledSafeTopMargin/useTopInset: !isIosNative`. Do not add a page-wide zoom or change iOS top sizing; the user explicitly said iPhone 16 is already correct.
- Store nav uses the native `mobileApp.navigate()` bridge and host `otlobli:nativeNavigate` + `flushSync`, with post-message/hide retained as an older-script fallback. It is one-shot and event-driven. Do not replace it with polling or repeated host evaluation.
- Mount `#otlobli-nav` on `document.documentElement`, because current SHEIN replaces body during product/ranking updates and can otherwise remove the visible/clickable bar. The freeze verifier protects `stableNavHost`.
- Real Note 8 v86.13/873 acceptance preserved installed data: top WebView begins at y=63 below the status bar; full SHEIN header/search is visible; product/search pages retained the bar; Orders was visible in the first capture at 1.17s including 0.58s ADB input overhead. Existing user cart entries were not modified.
- Validation passed locally: production/freeze/performance, `390/320` cart geometry/visual fixtures, Android/iOS sync, Android Gradle/install. APK/SHA: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.13-responsive-cart-fast-nav-debug.apk`, `D74996688545B1FA884F6883ED4741ECF948E404FC6C6B8B0B9089831AD9D9E4`.
- iOS source is pushed at `011b4a1`; GitHub/Xcode run `30437092864` passed. IPA/SHA: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.13-iPhone16-unsigned.ipa`, `B9ECA22B8457625645FE8D2355AF44B2A0CE3725EDBC8FFB325424719F063019`. Inspection confirms `com.otlobli.app`, `86.13/873`, required markers, no provisioning profile/top-level signature, and only the `otlobli` URL scheme.
- Real iPhone acceptance is not complete. Required test: cart with long titles, rapid product scroll then Orders/Cart/Profile, five resume cycles, and cold launch. Never claim iPhone acceptance from CI.

## Current candidate (2026-07-29) - v86.12 native offline recovery

- Marker/version: `2026.07.28-v86.12-native-offline-recovery`; Android/iOS `872/86.12`; auth bypass off. Preserve the dirty primary worktree. Matching iOS source is pushed on `codex/ios-v86-4` at `5ab5639`.
- The raw `net::ERR_INTERNET_DISCONNECTED` screen is a native Chromium/WebKit main-frame failure, not injected SHEIN DOM. The plugin patch now owns a lightweight Arabic offline cover on Android and iOS, retains the failing product URL, and retries it manually or once a validated network path returns. Never replace this with a hot JavaScript poll or a WebView rebuild.
- The network observer is registered only while the offline cover exists and is cancelled on success/dismissal. The cover remains above the failed page until `onPageFinished`/`didFinish` succeeds; failed retries restore the waiting state. iOS `-1009` is deliberately excluded from fatal WebKit teardown.
- Preserve the accessibility invariant: one modal cover, a native button, a polite/live status, and no loading cover behind it. Preserve the existing `otlobliForceRecompose`, resume burst, Android resume defense, and unchanged-region comparison exactly.
- Real Note 8 acceptance passed with data preserved: forced offline main-frame load through the real Capacitor plugin showed the Otlobli cover, no raw Chromium text, no duplicate loading cover, and retry while offline safely returned to waiting. Live network-return auto-retry was not device-tested because the phone had no usable route.
- Validation passed: production/freeze/performance guards, Android/iOS sync, Android Gradle/install, Note 8 visual/accessibility checks, and GitHub/Xcode run `30390632982`.
- APK: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.12-offline-recovery-debug.apk`, SHA `79E8EFBA569381E3AB62B9121DE79ECF57F2C64077814F56839CD3728301EED6`.
- IPA: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.12-iPhone16-unsigned.ipa`, SHA `EF7E0175AEAB4091B647E8FD7C05D924029848C1436105CC734301BAED0850DE`; `com.otlobli.app`, `86.12/872`, unsigned/unprovisioned. Required iPhone acceptance: offline/reconnect on a product, manual retry, five background/resume cycles, and a separate cold launch.

## Current candidate (2026-07-28) - v86.11 scroll-safe SHEIN navigation

- Marker/version: `2026.07.28-v86.11-scroll-safe-nav-input`; Android `871/86.11`; iOS `871/86.11`; auth bypass off. Preserve the dirty primary worktree. Matching iOS source is pushed on `codex/ios-v86-4` at `ab5dda3`.
- Root cause is measured, not inferred: installed v86.9 on Note 8 left the visible injected nav at computed `pointer-events:none` with no yield attribute after region setup. Drawer-style restoration had captured the temporary nav-yield value and restored it after the drawer closed.
- Never put nav display/opacity/pointer state back into `sheinShippingInteractionStyles`. `sheinRestoreNavAfterShipping()` owns the nav invariant; `#otlobli-nav-region-guard` blocks conversion taps, and `otlobliApplyNavYield()` handles only real non-region overlays after cleanup.
- `otlobliInteractionActive()` defers mutation-driven and interval-driven text/DOM/layout scans for 320 ms after active input, before the human-challenge `body.innerText` read. Do not move that guard back below the challenge detector. Native region repair remains exempt, and resolved shipping roots have a short active/inactive cache.
- Static protection was added to `verify:shein-freeze-guard`. Production/freeze/performance guards, Android build/install, iOS sync, and GitHub/Xcode run `30361886400` passed.
- Note 8 acceptance passed with data preserved: repeated fast swipes followed by first-tap Orders, Cart, and Profile navigation; no crash/ANR/render loss. p99 dropped from v86.9 `38ms` to `28-29ms`, and missed deadlines from `22` to `4-7`; jank percentage varied across runs.
- APK: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.11-scroll-safe-nav-debug.apk`, SHA `1E930ADF3C6FB5ABB2B3D1F1DD3A32DC3E2593AA684820F22B5AD56390AAF1E5`.
- IPA: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.11-iPhone16-unsigned.ipa`, SHA `E8CF4581911EB0B2B45E1C5B87575224F26960023529C67F58EA233AC06B8814`; `com.otlobli.app`, `86.11/871`, unsigned/unprovisioned. Google iOS is still hidden. Real iPhone acceptance is mandatory before claiming the iOS symptom is fully closed.

## Current candidate (2026-07-28) - v86.10 persistent iOS region nav

- Marker/version: `2026.07.28-v86.10-ios-persistent-nav-region-cover`; Android `870/86.10`; iOS `870/86.10`; auth bypass off. Preserve the dirty primary worktree. Matching iOS source is pushed on `codex/ios-v86-4` at `88a9765`.
- v86.9 hid `otlobli-nav` whenever the verified SHEIN shipping drawer was open. Because the iOS native cover deliberately reserves the bottom-nav band, that exposed region rows under a missing bar during store/region conversion.
- `stabilizeSheinShippingDrawerInteraction()` now keeps the nav mounted, opaque, and visible. Its child `#otlobli-nav-region-guard` temporarily owns bottom-band touches during the cascade, while Add/Back remain hidden until the drawer closes. Never restore nav hiding here; never extend the native cover through the bottom safe-area/nav band.
- The fix adds no timer or polling and does not touch the permanent WKWebView detach/reattach freeze guard. Visual fixture acceptance passed at `390x844`; the bar was visible and the bottom hit target was the transparent guard.
- Validation passed: production/freeze/performance guards, Android sync/Gradle, iOS sync, and GitHub/Xcode run `30357835150`. Android was not installed because Note 8 was disconnected.
- APK: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.10-persistent-nav-region-cover-debug.apk`, SHA `904B81F6BC1FF6A72C2AC738B2CDF1EB780387E08ADBFFC4CD54AF6FF957B6F1`.
- IPA: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.10-iPhone16-unsigned.ipa`, SHA `F38D74471E35A3AE6F3C8991C66A180822C1040AB3E78DCF9EE1302CB6045DE0`; `com.otlobli.app`, `86.10/870`, unsigned/unprovisioned. Google iOS is still hidden. Required next acceptance: sign/install, change store/region and confirm the bar never disappears or exposes region rows, then run five background/resume cycles.

## Current candidate (2026-07-28) - v86.9 iOS country drawer repair

- Marker/version: `2026.07.28-v86.9-ios-country-first-drawer-touch-lock`; Android `869/86.9`; iOS `869/86.9`; auth bypass off. Preserve the dirty primary worktree. Matching iOS source is pushed on `codex/ios-v86-4` at `4fe7f5b`.
- iOS kept the old `Qatar` tab label after opening the country list. `sheinNativeSaudiAddressStep()` now recognizes a live list containing multiple country-coded rows and selects the configured country before it ever considers the stale tab.
- `sheinElementIsPainted()` lets automation/root discovery see the transition drawer even when iOS temporarily applies `pointer-events:none`. The verified drawer gets pointer/touch restoration, internal momentum scrolling, fixed-body background lock with scroll restoration, and temporary hiding of overlapping Otlobli chrome.
- Do not replace this with `overflow:hidden` alone; WebKit has documented iOS cases where body scrolling continues. Do not add another polling interval: this stabilization deliberately runs at the end of the existing SHEIN tick.
- Validation: production/freeze/performance guards passed; Android Gradle passed but v86.9 was not installed because Note 8 was disconnected. GitHub/Xcode run `30356842504` passed and produced the inspected unsigned IPA.
- APK: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.9-ios-country-drawer-fix-debug.apk`, SHA `3202CC4930233F336851492134D69A9486D21ED3CC6D72A4A432B4351C052276`.
- IPA: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.9-iPhone16-unsigned.ipa`, SHA `5A8A39E38CC59D88EA598F3F87427F2A837C85A7E7B9C2C789E28E4C4D86A20B`; `com.otlobli.app`, `86.9/869`, unsigned/unprovisioned. Google iOS is still hidden. Required next acceptance: sign/install, switch a stale Qatar product to Saudi, confirm the drawer closes onto the product, then perform the permanent five-resume freeze test.

## Current candidate (2026-07-28) - v86.8 smart region lifecycle

- Marker/version: `2026.07.28-v86.8-smart-fast-region-close-single-webview`; Android `868/86.8`; iOS `868/86.8`; auth bypass off. Preserve the dirty primary worktree and use the pushed isolated iOS branch `codex/ios-v86-4` at `3b371a4`.
- Root cause was measured on Note 8: region settings and the home effect could open two SHEIN WebViews; the untracked one could cover the injected one. Startup now waits for the tiny no-cache two-key region read (4s offline ceiling), stores a verified cache, enforces one open/close operation, closes stale native results, and filters native events by WebView ID.
- Current SHEIN address markup uses focusable `.j-tab-item` spans and `span.header-close`. The cascade now handles placeholder country lists, ignores the stale previous-country cookie after the requested country tab is selected, follows configured lower levels, closes the resolved drawer before removing the native cover, and has a 25s force-close fallback.
- Note 8 acceptance: KW drawer `4.926s` to signed `Abu Halifa`; live Admin KW->SA drawer `6.666s` through `Riyadh Province/Riyadh/Al Olaya`; drawer closed, signed cookie correct, Otlobli Add/nav present. One SHEIN target remains; current live Admin setting is SA.
- Admin production is deployed with the matching 20-second live-update badge. Android artifact/hash: `otlobli-v86.8-smart-fast-region-debug.apk`, `5EDB396603F94337E151AA9C8117D63C16C7784C729966D3DD55D3F72A712F78`.
- Final unsigned iOS run `30354782068` passed at `3b371a4`. IPA/hash: `otlobli-v86.8-iPhone16-unsigned.ipa`, `F36A6F6A90542808E7353038CD2E72326069C482F34540EB547AF7C990EC1C73`. Artifact inspection confirms `86.8/868`, singleton/close/placeholder markers, native visibility control, and the iPhone freeze symbols.
- Do not claim iPhone acceptance yet. Google remains hidden because `VITE_GOOGLE_IOS_CLIENT_ID` is absent; the IPA is unsigned/no provisioning profile. The user must test the Saudi product flow and the mandatory five resume cycles plus cold launch on the real iPhone.

## Permanent same-task synchronization rule (2026-07-28)

- After every completed modification batch, update `CURRENT_STATE.md`, `AI-HANDOFF.md`, and `SESSION_SUMMARY.md` before handoff; do not wait for a "major" release.
- Synchronize and build every affected customer web/Android/iOS/Admin target. Keep migrations, `supabase/schema.sql`, and deployed backend code aligned, and record local-versus-production status explicitly.
- Documentation-only changes need no native rebuild. Full mandatory details are in `AGENTS.md → Mandatory Immediate Project Sync`; `CLAUDE.md` and `AI_QUICK_HANDOFF.md` mirror the rule.

## Permanent SHEIN iPhone freeze invariant (2026-07-28)

- Read `docs/SHEIN_IOS_FREEZE_GUARD.md` before any SHEIN/InAppBrowser/native WebView/lifecycle/injection/store-region change.
- `npm run build` now pre-runs `scripts/verify-shein-freeze-guard.mjs`, which fails if the patch or applied native detach/reattach, scroll restoration, `appDidBecomeActive` invocation, Android resume wake, or unchanged-region comparison disappears.
- The current persistent patch observes both `appDidBecomeActive` and `appWillEnterForeground`, calls `otlobliRecomposeAllWebViews()`, and runs the bounded `0.12/0.5/1.2/2.2s` forced detach/reattach burst. The build guard requires these markers; do not delete or weaken them.
- Acceptance for any affected release is five background/resume cycles without killing the process, plus a separate App Switcher force-quit/cold-launch run. Build/simulator checks alone are insufficient.
- This guard-only batch passed the verifier, production web build, Android sync, and iOS sync. It did not change runtime/version or produce new artifacts, so no device-acceptance claim was added.

## Weak-device and iOS credential invariant (2026-07-28)

- Read `docs/LOW_END_DEVICE_PERFORMANCE_GUARD.md`; preserve all features. `npm run build` now post-runs `verify:performance-budget` with frozen baseline ceilings. The 1.15MB entry bundle remains known code-splitting debt, not an ideal target.
- Read `docs/IOS_GOOGLE_PUSH_REQUIREMENTS.md` before iOS Google/Push work. Google requires Google Cloud iOS OAuth for `com.otlobli.app`; the missing `VITE_GOOGLE_IOS_CLIENT_ID` keeps the action hidden.
- An iOS notification permission grant is only UI authorization. Current remote push is blocked by unsigned/no-entitlement provisioning and absent Supabase APNs secrets. Apple Developer Program signing, Push capability/profile, p8 key/IDs, and matching sandbox/production environment are required.
- Never request or store the user's Apple password/2FA in chat. Use their local authenticated session/team access and secure CI/Supabase secrets.
- This batch passed freeze guard, production build, performance budget (`1,151,303` largest JS raw; `348,843` total JS gzip), Android sync, and iOS sync. No runtime/version/artifact change or device-acceptance claim.

## Current Candidate (2026-07-28) — v86.7 instant store navigation

- Primary dirty worktree remains `claude/ios6-cover-fix`; preserve all unrelated changes. Marker/version: `2026.07.28-v86.7-instant-store-nav-iphone16-candidate`, Android `867/86.7`, iOS `867/86.7`, auth bypass off.
- Root cause of the slow store bar was measured, not guessed: SHEIN → Orders took `5–6s` on Note 8 because the foreground native WebView remained visible until a background React state change and later effect called `hide()`.
- `CapgoInAppBrowser.allowWebViewJsVisibilityControl=true` plus an immediate `window.mobileApp.hide()` in every injected navigation path makes Orders/Cart/Profile leave the store at tap time. React also starts the same idempotent hide before `setScreen` as a cached-script fallback.
- Note 8 recordings show all three destinations in `0.5–0.75s`; Home restores the prepared store without reload. No crash, ANR, blocked hide, or renderer loss appeared.
- Android APK is installed with `adb install -r` and data preserved: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.7-instant-store-nav-debug.apk`; SHA-256 `0CD3A847436F44B0FED48426692498B87E4E6CA8B17509C67DD123315F90D026`.
- Matching iOS commit is `7b32f28` on `codex/ios-v86-4`; Xcode run `30350677536` passed. IPA: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.7-iPhone16-unsigned.ipa`; SHA-256 `FBD006DE08A2CFEBA49F161B5A8E908E918191405B136A48018646645651CF57`. Embedded bundle/version/marker/visibility/plugin/no-placeholder/no-signature checks passed. Ignore the older successful run `30349879711`/86.6.
- iOS Google is still hidden because `VITE_GOOGLE_IOS_CLIENT_ID` is absent; the IPA is unsigned and cannot prove Google/APNs. Real iPhone 16 five-cycle resume plus cold launch and store-bar timing remain device acceptance.
- Security: current tracked relay placeholders are clean, but the earlier isolated commit `661dded` contained an embedded relay credential. It was removed from current source at `aa11fab`; rotate the external credential before production because git history persists.

## Current Candidate (2026-07-26) — v86.5 account recovery + responsive shell

- Primary dirty worktree remains `claude/ios6-cover-fix`; preserve existing changes. Current versions are app marker `2026.07.26-v86.5-account-recovery-responsive-shell`, Android `865/86.5`, iOS `865/86.5`, with auth bypass off.
- `useStoredState` now persists synchronously. Do not revert this to effect-only storage: Google/OTP success immediately calls authenticated RPCs, and the old effect delay let them read a stale token.
- Startup account hydration restores profile, historical orders, both wallet balances, and wallet transactions. `getAccount` now throws on backend/session failure so a transient failure cannot authoritatively erase local orders or zero the wallet.
- Live migrations through `20260726234500_session_account_hydration.sql` are applied and `google-auth` is deployed. The account RPC trusts the authenticated session phone and legacy order matching tolerates `09…` versus `9639…`.
- Android Google now uses `style=standard`, `filterByAuthorizedAccounts=false`, `autoSelectEnabled=false`, and `forcePrompt=true`, giving the explicit account chooser/add-account path.
- Mobile shell: only `.mobile-content` scrolls; header and bottom nav are stable flex siblings with opaque backgrounds. The profile login-method label wraps, and 320/360/412 px checks showed no truncation or header drift.
- Android APK: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.5-account-recovery-responsive-debug.apk`; SHA-256 `A5D5BFDFE7E251C6CE114AF9FF049B6082163898BD2D633D61B45B4EFFBBEE05`. It is built but not installed because `adb devices -l` was empty. Install with `adb install -r` after reconnecting; do not clear app data.
- iOS work is isolated on `codex/ios-v86-4`, commit `e9662da`, pushed. Xcode run `30216693369` passed. IPA: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.5-iPhone-unsigned.ipa`; SHA-256 `0E241E31DD9316EA67AD0F2F54040D4A924ABD364F6E17A780869FCA5356C5CC`.
- iOS Google is intentionally unavailable in that IPA: repository secret `VITE_GOOGLE_IOS_CLIENT_ID` is absent and embedded `Info.plist` has no `GIDClientID`. Do not claim it works until the iOS OAuth client/reversed callback secret is added and the IPA rebuilt. The Chrome control extension is not installed and the available Google/Firebase CLI session needs reauthentication.

## Current Candidate (2026-07-26) — v86.4 complete region routing

- Primary worktree stays on dirty branch `claude/ios6-cover-fix`; preserve all existing changes. `APP_VERSION=2026.07.26-v86.4-complete-store-region-routing`, Android `864`, iOS marketing/build `86.4/864`.
- SHEIN readiness is now based on a complete signed `addressCookie`, not country text. On a product with no address it keeps the native cover, opens the live shipping selector, selects country/province/city/district, waits for `xAdFlag`, closes the drawer, then reveals the product.
- Real Note 8 acceptance passed from an intentionally removed `addressCookie`: `Saudi Arabia → Riyadh Province → Riyadh → Al Olaya`, `xAdFlag` length 216, drawer closed, nav present, product visible. Do not clear broader WebView data or login.
- Admin production is deployed at `https://talabieh-admin.vercel.app`. SHEIN has its exact 7 live PWA countries; Temu has the official 80+ global list. Live settings currently resolve SHEIN to `SA/Riyadh Province/Riyadh/Al Olaya` and Temu to SA.
- Android APK: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.4-complete-region-routing-debug.apk`; SHA-256 `BAF091D2C1C940C80B71982E3999325303C6AC77E3C9598A2FB0694CB00320DA`.
- Matching iOS work is isolated on `codex/ios-v86-4`; commits `3529bfb`, `7a5b69d`; Xcode run `30196655282` passed. IPA: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.4-iPhone-unsigned.ipa`; SHA-256 `2A004AC399C033B70F978B3BFC2385BAEBA128FB956A08E0680F46F4ECC4FA17`. Embedded bundle/version/path/plugin checks passed. Keep iPhone acceptance claims limited until the unsigned IPA is installed on a real device.
- Validation passed: customer/admin builds, injected-script parse, targeted lint, live admin asset verification, live settings readback, Gradle build/install, Note 8 version check, first-run cascade, drawer-close/nav/product verification. No payment, wallet, completed-order, or login semantics changed.

## Current Candidate (2026-07-26) — v86.3 Android + iPhone

- Branch is `claude/ios6-cover-fix`, with uncommitted v86.2/v86.3 task work. Preserve all unrelated existing modifications and `output/`.
- `APP_VERSION=2026.07.26-v86.3-unified-google-phone-auth`; Android `versionCode=863`; auth bypass is off.
- Google and phone are independent verified login methods on one customer account. The customer phone remains delivery contact data for compatibility with order/wallet code; `phone_login_enabled=false` only for new Google-first accounts until successful OTP.
- New Google user flow: choose Google → enter delivery profile → `google-auth action=register` → immediate session, no OTP. Existing Google identity remains immediate login.
- `حسابي → طرق تسجيل الدخول` reads `get_customer_auth_methods`, links Google to the active phone session, and verifies the saved delivery number via the existing WhatsApp OTP flow. Cross-account identity conflicts fail closed.
- Live migration `20260726223000_unified_customer_auth.sql` is applied; `google-auth` is deployed with `verify_jwt=false`. SQL rollback assertions proved `phoneLinked=false` before OTP and `true` after OTP. All 27 old customers remain phone-enabled.
- Real Note 8 acceptance passed: native Google returned an online ID token; live exchange returned `mode=existing` and a valid session. The current live account has Google and phone linked. Do not ask the user for account credentials.
- Push is accepted end-to-end: device token enabled, admin `sent=1`, channel `otlobli_general` importance 5, visible notification, and user confirmation. `send-push` and admin production are deployed.
- Admin production: `https://talabieh-admin.vercel.app`.
- Android artifact: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.3-unified-google-phone-auth-debug.apk`; SHA-256 `DAB16D357518A27AB2732EEFB2EAF0DC358A3847D4772A074FC4E4BCD8FF859B`.
- Matching iPhone source is committed only on isolated branch `codex/ios-v86-3` (`facff16`, `e808fd0`); the primary dirty worktree was not committed or overwritten.
- Xcode run `30194500640` succeeded. Unsigned IPA: `C:\Users\MOHAMMAD\OneDrive\Desktop\otlobli-v86.3-iPhone-unsigned.ipa`; SHA-256 `B4274F8CB1AA3BA5875A2EE10CA75B05FCE82E0723BCBF196700DC7BA3AEDE88`.
- Embedded iOS checks: `com.otlobli.app`, version `86.3`/build `863`, v86.3 marker, native Google/Push/InAppBrowser plugin strings, and no relay placeholder.
- iOS Google code/workflow now expects `VITE_GOOGLE_IOS_CLIENT_ID` and adds its reversed callback scheme. Until that secret exists, the Google action is intentionally hidden on iOS. The likely project-owner Google account currently stops at identity re-verification.
- The IPA is unsigned and not real-device accepted. APNs also remains pending Apple signing/capability/credentials; do not claim iPhone Google or push end-to-end yet.
- Validation: production build, live SQL/edge contracts, Playwright mobile screenshot review, Capacitor sync, Gradle assemble, APK install/version inspection, live account-method UI, native Google token, backend exchange, and push receipt.
- Remaining device acceptance: non-SA SHEIN/Temu pages, iPhone install/store-flow acceptance, iOS OAuth, and signed APNs. Payment, wallet, and completed-order logic were not changed.

## Current Candidate (2026-07-26) — v86

الفرع: `claude/otlobli-v86-push-google-telegram`. أُضيفت ٣ ميزات إضافية خاملة آمنة:
دخول جوجل (ربط هوية مرتكز على الهاتف)، إشعارات Push (FCM/APNs)، تنبيه تيليغرام لحظر واتساب.
كل الطبقة الخلفية منشورة وحيّة لكنها تفشل مغلقة/خاملة حتى يُدخل المستخدم مفاتيحه.
**اقرأ `SESSION_SUMMARY.md` + `docs/CREDENTIALS_SETUP.md` قبل أي عمل على هذه الميزات.**
لا تحوّل الاستيراد الديناميكي المحروس في `googleAuthApi.ts`/`pushNotifications.ts` إلى استيراد ثابت (يكسر البناء).
عند إعادة نشر أي دالة حافة: حافظ على `verify_jwt` نفسه (`admin-orders`=true, `google-auth`/`send-push`=false).

## Current Candidate (2026-07-25) — v85.8.92

- Branch `claude/ios6-cover-fix`, base re-set to clean v85.8.77 source + layered fixes. `APP_VERSION = 2026.07.25-v85.8.92-freeze-fix-plus-payment-claim-5min-no-otp-test`.
- **SHEIN iPhone-16 freeze FIXED (user-confirmed):** native detach+reattach WKWebView on `appDidBecomeActive` (patch-package `otlobliForceRecompose`) + Android `handleOnResume`. iOS run `30144837725`; Android APK launches clean on Note 8.
- **ShamCash payment auto-match FIXED:** Note 8 upgraded to listener v2 (HMAC) via adb + `PAYMENT_WEBHOOK_SECRET` rotated via Supabase CLI (both sides match; signed test → 200).
- Live DB/edge/admin changes this session (all deployed via CLI): coupon `per_user_max_uses`, 5-min `order_payment_window_minutes`, `claim_order_payment` + `orders.paid_claim_at`, revoked anon on leaky legacy `get_customer_account(text)`/`get_wallet(text)`, admin-orders + admin frontend redeployed.
- **WhatsApp anti-ban** added to the ACTIVE `server/` (warmup, per-number cap, risk auto-pause, 429/463 handling, onWhatsApp check, Telegram alerts). Deploy on Oracle via `git pull && cd server && npm install && pm2 restart`.
- **CRITICAL gotchas:** (1) `schema.sql` ≠ live DB — audit live via `supabase db query --linked`. (2) TWO whatsapp dirs: `server/` is active, `server-whatsapp/` is a DEAD duplicate — never edit it. (3) harness may start on a stale branch — verify branch + APP_VERSION first.
- Access available: Supabase CLI (linked `dcicqdprtyhwmhegabay`), Vercel CLI (`talabieh-admin`), adb (Note 8 serial `988e16384e4f51395230`), GitHub Actions (iOS).
- **Pending next (user-requested):** push notifications (FCM/APNs — needs Firebase + Apple APNs key), Google sign-in + account linking (needs Google OAuth client), cart-group session hardening.

## Current Candidate

- Branch: `claude/ios6-cover-fix`.
- Current candidate: v85.8.89 / `APP_VERSION = 2026.07.23-v85.8.89-shein-ios-modal-lifecycle-no-otp-test`.
- iPhone 16 Pro Max evidence: the failed reopen used new app/WebContent processes, then stopped after one 705-byte HTTP 200 response without normal resource fan-out, challenge, 429, renderer termination, or jetsam. Two older crash reports independently show `didFinish -> presentView -> UIViewController.present -> SIGABRT`.
- Root native defect: Capgo InAppBrowser 8.6.25 predates its official safe-presentation, touch-blocking `UITransitionView`, and double-resolve fixes. The old hide path left modal transition layers above the app, matching the image-like untappable UI.
- Fix: SHEIN-only opt-in dismisses the modal while preserving the same sized `WKWebView`; a transient flag prevents `viewDidDisappear` cleanup during visibility hide; React serializes SHEIN `hide/show`; presentation is guarded; and SHEIN `openWebView` resolves once. Temu remains on its old path.
- Scope protected: no Saudi/passive handling, product capture, add-to-cart payload, color/size parsing, cart math, payment, wallet, completed orders, or Temu behavior changed.
- Code commit: `35913c1`, pushed to `origin/claude/ios6-cover-fix`. GitHub iOS run `30012069056` passed.
- IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.89-shein-ios-modal-lifecycle.ipa`; SHA-256 `38568CD56DDAB5E042443A60E8EBA7F5BE9C68A139FE8D4BE12BF70A8330664C`.
- Validation: clean patch apply, web build, targeted lint, independent native review, Xcode build, and embedded version/native-guard marker checks passed. App-wide lint still has old unrelated errors.
- Device acceptance remains mandatory on iPhone 16 and iPhone 6: repeated Home ↔ Cart, rapid transition during first load, background/resume, then cold reopen. Do not claim the separate 705-byte cold-load path fixed solely from this native build.
- Old IPAs installed over the same bundle ID preserved `Library/WebKit/WebsiteData`; they were not clean tests. If cold reopen still fails, reconnect/unlock the iPhone 16 and pull `Library/WebKit` plus `Library/Caches/WebKit` read-only after force-closing Otlobli, or perform one Delete App + reboot + reinstall test with fixed VPN/IP.

## Previous Candidate

- Previous candidate: v85.8.88 / `APP_VERSION = 2026.07.23-v85.8.88-shein-passive-saudi-no-otp-test`.
- v85.8.88 made SHEIN Saudi handling passive and remains the code baseline beneath the native v85.8.89 lifecycle fix.
- User result: it opened once on iPhone 16 Pro Max, then failed after leaving/reopening. iPhone 6 continued to work better.

## Previous Candidate

- Branch: `claude/ios6-cover-fix`.
- Previous local code candidate: v85.8.87 / `APP_VERSION = 2026.07.23-v85.8.87-shein-cookie-reset-no-otp-test`.
- User rejected v85.8.86 on iPhone 16 Pro Max: SHEIN still showed the blocked/frozen behavior even after removing SHEIN document-start injection and avoiding challenge-page writes.
- Fix attempted: bounded SHEIN-only cookie/cache reset for `m.shein.com`, `www.shein.com`, and `shein.com` before first SHEIN open and after confirmed stuck/blocked paths.
- User rejected v85.8.87 too, so cookie-only cleanup is not the root fix for the current iPhone 16 case.

## Previous Candidate

- Branch: `claude/ios6-cover-fix`.
- Current local code candidate: v85.8.86 / `APP_VERSION = 2026.07.23-v85.8.86-shein-no-docstart-challenge-no-otp-test`.
- User rejected v85.8.85 on iPhone 16 Pro Max: SHEIN was still blocked.
- Change: removed SHEIN's `otlobliDocumentStartScript` bootstrap entirely. SHEIN now gets no Otlobli DOM/nav injection at document start; the full script is injected only after page load.
- Change: added early loaded-document challenge detection before any Saudi cookie/storage write. This catches same-URL challenge pages, removes all Otlobli nodes, posts `humanCheck`, and returns without touching the challenge.
- Scope protected: no product capture, add-to-cart, color/size parsing, product URL normalization, cart math, payment, wallet, completed-order, or Temu logic changed.
- GitHub iOS build `29970160713` succeeded from code commit `d92b777`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.86-shein-no-docstart-challenge.ipa`; SHA-256 `4BE352FDDCC5FFBAB5EE4707D210E204FC75CB4AFA48B3A3A7DB85B7702FC9FA`.
- Validation: `npm run build` clean; injected scripts parse with `new Function`; `npx eslint src/services/sheinBrowserScript.ts src/config.ts` clean; GitHub iOS build passed; embedded IPA marker check found v85.8.86 and no `otlobliDocumentStartScript` marker. Targeted `src/App.tsx` lint still reports pre-existing unrelated App errors; full build passes.

## Previous Candidate

- Branch: `claude/ios6-cover-fix`.
- Current local code candidate: v85.8.85 / `APP_VERSION = 2026.07.23-v85.8.85-shein-ios-gentle-challenge-no-otp-test`.
- New user evidence: SHEIN works normally on iPhone 6, but iPhone 16 Pro Max is challenged/blocked after first entry even after reinstall. The issue is device/session/anti-bot sensitive, not a universal SHEIN break.
- Change: when a SHEIN human/security challenge is detected, the full injected script no longer writes Saudi cookies/storage and no longer mounts the Otlobli nav inside the challenge document. It only removes Otlobli nodes, releases scroll lock, posts `humanCheck`, and leaves the challenge untouched.
- Change: all iOS SHEIN WebViews now use the gentler low-end polling cadence, reducing script pressure on modern iPhones while preserving the existing iPhone 6 behavior.
- Scope protected: no product capture, add-to-cart, color/size parsing, product URL normalization, cart math, payment, wallet, completed-order, or Temu logic changed.
- GitHub iOS build `29969344175` succeeded from code commit `e363db1`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.85-shein-ios-gentle-challenge.ipa`; SHA-256 `0DB95F793C7E74108595C0E16708303B99512B3388305B2C69C235B545FAAF0A`.
- Validation: `npm run build` clean; injected scripts parse with `new Function`; `npx eslint src/services/sheinBrowserScript.ts src/config.ts` clean; GitHub iOS build passed; embedded IPA marker check found v85.8.85 and `OTLOBLI_SHEIN_GENTLE_TIMERS`.

## Previous Candidate

- Branch: `claude/ios6-cover-fix`.
- Current local code candidate: v85.8.84 / `APP_VERSION = 2026.07.22-v85.8.84-rollback-v83-shein-stable-saudi-no-otp-test`.
- User rejected v85.8.83 on real iPhone: Saudi locking broke, first open worked only once, then returning to the app left SHEIN as a frozen image. Treat v85.8.83 as failed.
- What v85.8.83 changed and why it failed: it closed SHEIN on leaving home/background/resume, reset volatile WebView state, and forced a fresh VPN/Saudi check. On the real device that made lifecycle timing worse and destabilized the Saudi setup instead of fixing the freeze.
- Response: revert the v85.8.83 fresh-session policy and restore the v85.8.82/v85.8.79 behavior: preserved SHEIN WebView, old page heartbeat, and old post-ready recovery path. Keep v85.8.82's narrow Saudi `addressCookie` recovery and cart back-target behavior.
- Scope protected: no color/size, product capture, add-to-cart, product link normalization, nav/icon sizing, payment, wallet, completed-order, or Temu capture logic changes.
- GitHub iOS build `29957413860` succeeded from code commit `81ac13c`; IPA is `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.84-rollback-v83-shein-stable-saudi.ipa`; SHA-256 `36C2A08AFB95DAA88D97916DCFB1B6E595664111E59BEEBC7F6D3341E803CB10`.
- Validation: `npm run build` clean; injected scripts parse with `new Function`; `npx eslint src/services/sheinBrowserScript.ts src/config.ts` clean; `git diff --check` only reports Windows LF/CRLF warnings; GitHub iOS build passed; embedded IPA marker check found v85.8.84.

## Previous Candidate

- Branch: `claude/ios6-cover-fix`.
- Previous local code candidate: v85.8.83 / `APP_VERSION = 2026.07.22-v85.8.83-shein-fresh-session-no-heartbeat-no-otp-test`.
- Rejected on real iPhone: Saudi locking broke and SHEIN froze after app background/resume. Do not reuse the close-on-resume fresh-session policy.

## Previous Candidate

- Branch: `claude/ios6-cover-fix`.
- Previous local code candidate: v85.8.82 / `APP_VERSION = 2026.07.22-v85.8.82-shein-stable-saudi-back-no-otp-test`.
- User rejected v85.8.81 as worse: first entry could show SHEIN on Bahrain and fail Saudi locking, so capture/add was blocked; after leaving/re-entering the app, SHEIN could freeze without cart/product.
- Response: v85.8.82 rolls back the failed v85.8.80/81 SHEIN experiment. SHEIN cart products again use the v85.8.79 native `InAppBrowser.setUrl()` path; in-page cart navigation remains Temu-only. Restored the old SHEIN hot interval timings and the SHEIN heartbeat/recovery path from v85.8.79.
- Kept only the useful back-target fix: repeated `sheinPageInteractive` no longer resets a cart-opened product back button from `cart` to `home`; reset happens only when the user actually leaves through Otlobli cart/orders/profile.
- Added narrow Saudi recovery: if SHEIN has `addressCookie` saved with an explicit non-Saudi country such as Bahrain, remove only that one key before seeding Saudi/USD. Signed Saudi addresses are preserved.
- Scope protected: no color/size, product capture, add-to-cart, product link normalization, nav/icon sizing, payment, wallet, or order logic changes.
- GitHub iOS build `29952878400` succeeded from code commit `394bcae`; IPA is `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.82-shein-stable-saudi-back.ipa`; SHA-256 `20763A568A3E399CA59C98A4AF622C2059A62469F8D14893E77A51F1736297E3`.
- Validation: `npm run build` clean; injected scripts parse with `new Function`; `npx eslint src/services/sheinBrowserScript.ts src/config.ts` clean; `git diff --check` only reports Windows LF/CRLF warnings; GitHub iOS build passed; embedded IPA marker check found v85.8.82. User reported freeze still remained, but Saudi was not broken like v85.8.83.

## Previous Candidate

- Branch: `claude/ios6-cover-fix`.
- Previous local code candidate: v85.8.81 / `APP_VERSION = 2026.07.22-v85.8.81-shein-cart-back-target-no-otp-test`.
- User tested v85.8.80 and the same issue remained: SHEIN cart product opens correctly, but Otlobli back returns inside SHEIN to a home/categories page with no product grid below it and the page becomes stuck.
- Corrected root cause: repeated `sheinPageInteractive` messages were overwriting the cart-product back target. After reveal, React initially sent `__backTarget = cart`, then a later readiness message called `markStoreWebviewReady()` again, reset/sent `__backTarget = home`, and the back button used SHEIN `history.back()` instead of returning to Otlobli cart.
- Change: `markStoreWebviewReady()` and the home-show effect no longer reset `pendingBackTargetRef` after posting it. The target resets to `home` only when the customer actually leaves the WebView through Otlobli cart/orders/profile messages. This keeps cart-opened SHEIN products bound to Otlobli cart and avoids SHEIN's broken in-page back state.
- Scope protected: no color/size detection, capture, add-to-cart, deep-link, product opening, nav/icon sizing, payment, wallet, or order changes beyond the back-target fix.
- GitHub iOS build `29946868465` succeeded from code commit `505db9d`; IPA is `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.81-shein-cart-back-target.ipa`; SHA-256 `3A418030C59499B76611B59E0102C72909686954879185E7A9258CCF5E3B7A84`.
- Validation: `npm run build` clean; injected scripts parse with `new Function`; `npx eslint src/services/sheinBrowserScript.ts src/config.ts` clean; GitHub iOS build passed; embedded IPA marker check found v85.8.81. Needs real-device check.

## Previous Candidate

- Branch: `claude/ios6-cover-fix`.
- Previous local code candidate: v85.8.80 / `APP_VERSION = 2026.07.22-v85.8.80-shein-cart-light-nav-no-otp-test`.
- User rejected v85.8.79 because it was a recovery-after-freeze approach and the SHEIN cart-product freeze still reproduced. Do not continue with heartbeat/rebuild-after-freeze workarounds unless the user explicitly asks.
- Root-cause direction for v85.8.80: SHEIN cart products were still using native `InAppBrowser.setUrl()` deep product loads from the cart/hidden preserved WebView. Switching Temu -> SHEIN recovered because it rebuilt the WebView, which points to the cart-origin native deep load poisoning the preserved SHEIN iOS WebView session.
- Change: SHEIN cart products now open through the live store document, like the confirmed Temu cart fix. Cold cart open loads SHEIN home first, keeps the pending URL queued, then `markStoreWebviewReady()` runs in-page navigation with `window.location.assign()` through `executeScript`. Warm SHEIN cart open shows the WebView before running the same in-page navigation. The pending URL is not cleared before the home-ready handoff.
- Removed the v85.8.79 SHEIN heartbeat/page heartbeat watchdog. `restartStuckSheinWebview()` is back to the conservative pre-ready-only recovery guard.
- Low-end change: widened `OTLOBLI_LOW_END` to include small iPhone-6-sized viewports, low CPU, and low memory, then relaxed SHEIN hot scan intervals on those devices. Modern phones keep fast timings.
- Scope protected: no changes to color/size detection, product payload capture, add-to-cart flow, deep-link building, add validation, or nav/icon sizing.
- Added visible browser harness `scripts/shein-cart-browser-harness.mjs`. It injects the real SHEIN script and compares full load vs in-page navigation. It has `--keep-open=1` for manual CAPTCHA, but Playwright Chromium is bot-flagged by SHEIN, so a failed CAPTCHA answer there is not evidence the user selected wrong images.
- Browser evidence with the user's product URL: SHEIN home became interactive and the long URL was preserved; both desktop automation paths reached SHEIN `/risk/challenge` with `humanCheck`. This proves URL shape is valid and desktop automation cannot be trusted for CAPTCHA completion.
- GitHub iOS build `29944509509` succeeded from code commit `71a3f13`; IPA is `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.80-shein-cart-light-nav.ipa`; SHA-256 `67D53FD87BCFECF606DAFD641CB2AAB657C2EB1084C8401C248432BF150C8AAD`.
- Validation: `npm run build` clean; injected scripts parse with `new Function`; `npx eslint src/services/sheinBrowserScript.ts src/config.ts` clean; `git diff --check` only reports Windows LF/CRLF warnings; GitHub iOS build passed; embedded IPA marker check found v85.8.80 and no old SHEIN heartbeat markers. `npx eslint src/App.tsx ...` still reports pre-existing unrelated App lint errors.
- Next real-device check for v85.8.80 was failed by user; use v85.8.81 instead.

## Previous Candidate

- Branch: `claude/ios6-cover-fix`.
- Previous local code candidate: v85.8.79 / `APP_VERSION = 2026.07.22-v85.8.79-shein-ready-freeze-recovery-no-otp-test`.
- User report: SHEIN freezes after opening a product from Otlobli cart and backing out to SHEIN home; category taps stop working. Switching to Temu and back recovers because it rebuilds the WebView; killing/reopening the app does not reliably recover.
- Root cause in v85.8.78: heartbeat recovery was logically blocked. The watchdog required `sheinReadyRef.current === true`, then called `restartStuckSheinWebview()`, whose guard returned immediately when `sheinReadyRef.current` was true. Result: no rebuild ever happened for the exact post-ready freeze case.
- Change: `restartStuckSheinWebview(sessionId, allowReadyRecovery = false)` keeps the old pre-ready behavior by default, but the SHEIN heartbeat watchdog calls it with `true`, allowing the proven WebView rebuild recovery after an already-ready SHEIN page stops heartbeating for >15s. Also added a narrow fallback in `dismissSheinProductLoginPrompt()` to hide an unsolicited product-page auth dialog when SHEIN provides no reliable close button, and release scroll lock. Real login routes are still skipped.
- Scope: SHEIN post-ready freeze recovery + first-product auth prompt hiding only. No Temu, payment, wallet, completed orders, SKU capture, cart pricing, or order logic changed.
- GitHub iOS build `29928244012` succeeded from code commit `377f6d5`; IPA is `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.79-shein-ready-freeze-recovery.ipa`; SHA-256 `89677EFA17882DFB02C893FF16447323829A074141DC0C5E937A68771F2A120A`.
- Validation: `npm run build` clean; injected bootstrap/capture scripts parse with `new Function`; `npx eslint src/services/sheinBrowserScript.ts src/config.ts` clean; `git diff --check` only reports Windows LF/CRLF warnings; GitHub iOS build passed; embedded IPA marker checks found v85.8.79 and the SHEIN login-prompt fallback marker. `npx eslint src/App.tsx ...` still fails on pre-existing unrelated App lint errors.
- Next real-device check: install v85.8.79 on iPhone 6 and iPhone 16 Pro Max. Reproduce: SHEIN cart item -> product -> back to SHEIN home -> tap categories/search/products. If SHEIN freezes, expect automatic WebView rebuild after about 15-19s instead of permanent freeze. Also verify first product for a fresh user never leaves a SHEIN login dialog visible.

- Branch: `claude/ios6-cover-fix`.
- Current local code candidate: v85.8.74 / `APP_VERSION = 2026.07.21-v85.8.74-temu-cart-inpage-nav-no-otp-test`.
- Change (v85.8.74): open Temu cart products via an IN-PAGE navigation (`navigateStoreWebviewInPage` → `window.location.assign` through `executeScript`) inside the warm Temu page, so the request carries a temu.com referrer like a real card tap — instead of a refererless `InAppBrowser.setUrl` that Temu 302s to `/login.html`. Applied in `openStoreProductFromCart` (warm) and `markStoreWebviewReady` (queued). Cold open loads Temu HOME first then in-page-navigates to the queued product. SHEIN unchanged. Keeps v85.8.73 login recovery + `temuLoginBlocked` graceful fallback + probe. Built clean (tsc+vite); referrer hypothesis NOT device-verified (test browser is bot-flagged). If device still shows /login.html, next step is driving Temu's SPA router.
- Previous candidate below (v85.8.73):
- Current local code candidate: v85.8.73 / `APP_VERSION = 2026.07.21-v85.8.73-temu-login-redirect-recover-no-otp-test`.
- ROOT CAUSE (v85.8.72 URL probe, real device): Temu cart-product white screen IS Temu's own `/login.html?from=<product>`. Cold full-navigation to a deep Temu PDP for a logged-out user gets 302'd to login; SPA in-app browsing does not. Not our blocking (img=0/0).
- Change (v85.8.73): `otlobliTemuRecoverFromLoginRedirect()` navigates once to the `from` product URL (guest cookie now set) guarded by sessionStorage (one retry per target, no loop). On failure the script posts `temuLoginBlocked`; App.tsx aborts the cart-product prep, returns to cart, shows a Temu-login notice — never reveals the white login page. Keeps v85.8.71 900ms stable gate + v85.8.72 top URL probe. Built clean; NOT real-device tested.
- Previous candidate below (v85.8.71):
- Current local code candidate: v85.8.71 / `APP_VERSION = 2026.07.21-v85.8.71-temu-cart-stable-gate-urlprobe-no-otp-test`.
- Change (v85.8.71): confirmed via capgo InAppBrowser Swift source that `preShowScript`+`documentStart` is a persistent WKUserScript, so the script runs on every setUrl navigation — the cart-open white screen is NOT a missing-script problem. Real cause: reveal gate posted `temuProductVisible` on the first transient PDP paint, then Temu bounced the cart-origin direct load to login → blank. Fix: reveal now requires product content continuously visible for `OTLOBLI_TEMU_STABLE_MS=900`ms (timer resets on any non-PDP/login/no-content tick). Added `otlobliTemuUrlProbe()`, a permanent bottom diagnostic bar (test build) that stays on the white screen showing PDP/ACCT/LOGIN flags + img counts + URL path — READ IT if white persists. Built clean; NOT real-device tested.
- Previous candidate below (v85.8.70):
- Current local code candidate: v85.8.70 / `APP_VERSION = 2026.07.21-v85.8.70-temu-cart-login-sheet-gate-no-otp-test`.
- Change (v85.8.70): the Temu cart-product reveal gate now also blocks reveal while a login sheet is visible. New `otlobliTemuLoginSheetVisible()` flags a large visible centered surface with a sign-in/continue phrase + a phone/email/password input or social button; `otlobliPostTemuProductVisibleIfReady` returns early on it. Reveal gate only — hides nothing. Fixes: cart product → brief Temu login → white screen. Built clean; NOT yet real-device tested.
- Previous candidate below (v85.8.69):
- Current local code candidate: v85.8.69 / `APP_VERSION = 2026.07.20-v85.8.69-temu-cart-product-visible-gate-no-otp-test`.
- Code commit: `b9d6d14` (`fix: v85.8.69 gate Temu cart product reveal`).
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.69-temu-cart-product-visible-gate.ipa`.
- GitHub iOS build `29735372870` succeeded from code commit `b9d6d14`.
- v85.8.69 IPA SHA-256: `C66EF04310F50891BA1D1A127E587DBC9A1FF94153CAA5C6E85307F890FCBF4F`.
- Latest user report after v85.8.68: ordinary Temu product opens work again, but tapping a product from Otlobli cart briefly shows Temu login/account UI and then a white product screen.
- Change: Temu pending cart-product reveal no longer trusts native `browserPageLoaded` alone. The injected page script posts `temuProductVisible` only after visible product content exists (large product image or visible price) and no visible account/login surface remains. React verifies the visible URL against the pending cart URL before switching from cart to home.
- Includes v85.8.68 underneath: no opaque Temu product-entry cover and large product-flow containers protected from account/promo hiding.
- Scope: Temu cart-product reveal timing only. No SKU capture, add-to-cart logic, header, bottom nav placement, payment, wallet, orders logic, or real account route changes.
- Validation: targeted ESLint for script/config, `npm run build`, `git diff --check`, injected-script parse, GitHub build, and embedded IPA marker checks passed (`v85.8.69`, `temuProductVisible`, and `otlobliPostTemuProductVisibleIfReady` present).
- Do not reapply the v85.8.47 visible-SKU/group-dims approach until the white-page regression is understood from real-device evidence or a DOM fixture that reproduces it.
- Next real-device checks: install v85.8.69, add a Temu item to cart, open it from Otlobli cart, and confirm the cart remains visible until the actual Temu product content appears with no login flash -> white page.

## Previous Candidate (v85.8.68)

- v85.8.68 / commit `091a35f` removed the full-page white Temu product-entry cover and protected large non-floating product-flow containers from account/promo hiding on product URLs.
- GitHub iOS build `29733534914` produced `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.68-temu-product-white-screen-guard.ipa` with SHA-256 `C26CC0F9EB31B01D105F1F004305E2F16B7F8F47DABF6C89DF5F0B499613337B`.

## Previous Candidate (v85.8.67)

- v85.8.67 / commit `3a4e2dc` fixed Temu bottom-nav placement for modern iPhones when `env(safe-area-inset-bottom)` reports zero, while keeping legacy iPhone 6 on the `0px` path.
- GitHub iOS build `29704696750` produced `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.67-temu-modern-iphone-nav-offset.ipa` with SHA-256 `1A9CF7A06D25ADF48A91EF71C0F037A09187AA49511348F41ACBCCD1C7E16451`.

## Previous Candidate (v85.8.66)

- v85.8.66 / commit `3648898` fixed opening Temu products from the cart and polished notice surfaces.
- GitHub iOS build `29700181145` produced `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.66-cart-product-open-notice-polish.ipa` with SHA-256 `943C7862779CA9284855C3DD717CC93BA9B1229C87D8D799CC768CF3F435953D`.

## Previous Candidate (v85.8.65)

- v85.8.65 / commit `d3b2be2` fixed Temu bottom-nav vertical alignment on legacy iPhones by reading real `env(safe-area-inset-bottom)`: no-safe-area iPhones use `bottom:0px`, home-indicator iPhones keep `bottom:-18px`, Android unchanged.
- GitHub iOS build `29697979381` produced `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.65-temu-legacy-safe-area-nav.ipa` with SHA-256 `FDBA2940D03E7962193C416CCB11F93B7838D5F157DBC3BDBE78BAEE3F21CECF`.

## Previous Candidate (v85.8.64)

- Branch: `claude/ios6-cover-fix`.
- Previous local code candidate: v85.8.64 / `APP_VERSION = 2026.07.19-v85.8.64-temu-items-row-cart-open-no-otp-test`.
- Code commit: `d7cd70f` (`fix: v85.8.64 detect Temu items selector row`).
- Previous iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.64-temu-items-row-cart-open.ipa`.
- GitHub iOS build `29672118803` succeeded from code commit `d7cd70f`.
- v85.8.64 IPA SHA-256: `81C48D748AB0A5C219BA585FF84A46E1219AAAB6C349EA3BF53BBF340C0882C7`.
- Latest user DOM/screenshot: Temu smart-watch product has structural row `skuSelector-* role="button" aria-label="7 أغراض:حدد"`. The old structural parser detected the selector shell but did not count `أغراض`, so Otlobli could treat the product as if it had no required options.
- Change: centralized Temu counted-variant label detection and reused it across `temuVariantCounts()`, `temuVariantSummaryEl()`, `otlobliTemuCollapsedVariantRow()`, and the structural `skuSelector-*` parser. The second-option family now includes size/model/style/type/RAM/storage plus `أغراض/اغراض/غرض/عناصر/عنصر/قطع/قطعة/items/pieces/pcs`.
- Includes v85.8.63 underneath: opening Temu products from Otlobli cart now reveals the prepared product after WebView page load instead of leaving a white screen.
- Scope: Temu SKU/variant detection and Temu cart-product reveal only. No header, bottom nav, blocker, payment, wallet, orders logic, or account route changes.
- Validation: pasted-DOM check extracts `7 أغراض` as `secondCount=7`, targeted ESLint for script/config, `npm run build`, injected-script parse, `git diff --check`, GitHub build, and embedded IPA marker checks passed. Real-device acceptance is still pending.
- Do not reapply the v85.8.47 visible-SKU/group-dims approach until the white-page regression is understood from real-device evidence or a DOM fixture that reproduces it.
- Next real-device checks: install v85.8.64, open a Temu product from Otlobli cart and confirm no white screen; on the smart-watch product, pressing Otlobli add should open the `7 أغراض` options sheet and capture after selecting one item. Recheck older `4 الموديل`, unavailable option, and normal color/size products.

## Previous Candidate (v85.8.62)

- Branch: `claude/ios6-cover-fix`.
- Current local code candidate: v85.8.62 / `APP_VERSION = 2026.07.19-v85.8.62-temu-single-model-row-no-otp-test`.
- Latest user screenshot: Temu product with collapsed row `4 الموديل: ...` and `حدد`, while diagnostic overlay reads `sku: لا خيارات`. The row is model-only, so old summary detection missed it.
- Scope: Temu SKU/variant detection only. No bottom nav placement, header forcing, blockers, payment, wallet, orders logic, or account route changes.
- Change: added `otlobliTemuCollapsedVariantRow()` to detect visible `حدد/select/choose` rows with counted variant labels (`4 الموديل`, color/model/size/style/type/RAM/storage). It sets `collapsedEl` so add opens the sheet and waits for the customer selection.
- v85.8.61 remains the unavailable-option fix and is included underneath this change.
- GitHub iOS build `29670967272` succeeded from code commit `0e7882c`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.62-temu-single-model-row.ipa`.
- v85.8.62 IPA SHA-256: `5A23674D464277D424C6D961A3190179638FF86D4B22A45804B8A6939B3D4B5B`.
- Validation: targeted ESLint for script/config, `npm run build`, regex check for `4 الموديل`, injected-script parse, `git diff --check`, GitHub build, and embedded bundle marker check passed. Real-device acceptance is still pending.
- Do not reapply the v85.8.47 visible-SKU/group-dims approach until the white-page regression is understood from real-device evidence or a DOM fixture that reproduces it.
- Next step: install v85.8.62 on the real iPhone. On the WEEME product, pressing Otlobli add should open the `4 الموديل` options sheet instead of treating the product as `لا خيارات`; after selecting a model, it should capture/add normally.

<!-- Older handoff content below may be stale. -->

## Current Candidate

- Branch: `claude/ios6-cover-fix`.
- Last tested IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.30-temu-no-false-size-gate.ipa`.
- Last tested code: `dcc2bb5` (`fix: v85.8.30 avoid false Temu size gate`) - user reported occasional blank white product pages and a text-only color product still blocked by "select color".
- Current local code candidate: v85.8.31 / `APP_VERSION = 2026.07.17-v85.8.31-temu-product-panel-color-no-otp-test`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.31-temu-product-panel-color.ipa`.
- Build run: `29589915204` (success), built from code commit `81426c7`.
- IPA SHA-256: `C6E8DA038BC4CB9E7363222E17452F24678B169B6FB729675C5CACFBD937CBCC`.
- Previous iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.30-temu-no-false-size-gate.ipa`.
- Previous build run: `29587915183` (success), built from code commit `dcc2bb5`.
- Previous IPA SHA-256: `4804EB86912DAD859BC389819C351ABD74A58795E957286BE36E6FAD4C6DF747`.
- Older iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.29-temu-ram-variant-gate.ipa`.
- Older build run: `29586606771` (success), built from code commit `74e2c0f`.
- Older IPA SHA-256: `6EB037D772BD6FBF6BB0E2264A61AA323A13E6177FA431EE238CD73A548847C5`.
- Older iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.28-temu-search-preserve-query.ipa`.
- Older build run: `29584752961` (success), built from code commit `c7c49d5`.
- Older IPA SHA-256: `2AFC1C27164E1023493632323B0F1F7992ACC16B3C6294BB9E7CFE54B97C8BCB`.
- Older iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.27-temu-search-light-blockers.ipa`.
- Older build run: `29583256531` (success), built from code commit `d9368b4`.
- Older IPA SHA-256: `9B706F650718BA25A7D3E9B61CACB54AAAC873DA492FD5F11CA81866EE2A3826`.
- Older iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.26-temu-clean-blockers.ipa`.
- v85.8.26 build run: `29581021125` (success), built from code commit `e3984fd`.
- v85.8.26 IPA SHA-256: `DD22DFD3CE658E056F652F140B6AEA5FEAC8A5CA1193DDAEEEDE557BA0864C2B`.
- Rollback/reference: v85.8.5 / `a914d81` and the user-provided v85.8.5 IPA.
- v85.8.19 did not fix Temu. Current focus is Temu only; do not touch payment, wallet, completed orders, or account routes unless explicitly requested.
- v85.8.10's ordinary iPhone 16 SHEIN nav behavior was accepted. Do not call any new Temu change proven until tested on the real iPhone device; do not rely on the simulator.

## Confirmed Diagnosis

- iPhone 6 needed about 14 seconds, but the v85.8.5 readiness watchdog killed the valid WebView at 13 seconds and then showed a false VPN-server error.
- Cairo was fetched independently from Google in React and SHEIN, causing delayed nav appearance and font/size shifts.
- The full script hid generic fixed/sticky bottom elements, which could affect cookie/action UI.
- Swatches can store the real color in a nested CSS background while HOT is a smaller overlay image.

## Implementation Notes

- First iOS presentation uses `isPresentAfterPageLoad`; no hidden/`FAKE_VISIBLE` path.
- The native cover reappears at every `didStartProvisionalNavigation` and stops above the exact nav height.
- Interactive security verification is revealed after six seconds; it is not bypassed.
- Readiness is 35 seconds; preparation failure is distinct from network/VPN failure.
- Bottom-tab hiding requires verified tab semantics. Cookie adjustment and feed retry are exact and bounded.
- Cairo is self-hosted through `@fontsource-variable/cairo` and embedded into the document-start script.
- Product navigation keeps the same WebView and now gets a native loading cover.
- OTP bypass is test-only.
- v85.8.7 adds semantic visual-stack detection for SHEIN's obfuscated early five-tab div, exact success-toast suppression, warm-cache fast path with bounded clean recovery, and full-bottom iOS WebView layout.
- v85.8.8 makes the injected nav DOM/grid match React, recognizes only exact five-control fixed tab geometry before labels appear, and keeps cart products hidden until both page-load and post-blocker readiness arrive.
- v85.8.9 replaces the incompatible injected Grid with four explicit Flex cells and removes the new first-session geometry scan. The v85.8.7 semantic detector and v85.8.8 product readiness gate remain.
- v85.8.10 gives all injected nav phases one CSS source and only reclaims the DOM node after actual occlusion hit-tests.
- v85.8.11 hides only the confirmed 15%-signup strip or the email-newsletter panel, with explicit real-auth exclusion.
- A SHEIN photo viewer must be fixed, near-full-screen, contain a large image, and expose a numeric image counter before viewer handling activates. Its add button is suppressed, its lower black band is guarded, and nav/back reclaim paint order only on viewer transition.
- v85.8.12 detects nested fixed viewers from targeted painted points, blocks gallery click-through at the event boundary, raises the full cookie action row without auto-consent, closes only a signed-Saudi address surface, and throttles signup/cookie scans. MutationObserver now schedules the normal coalesced tick only.
- v85.8.20 local Temu candidate broadens top search-field detection, caches search-mode probing briefly to reduce typing lag, prevents search chrome restoration from re-showing account/login panel ancestors, reapplies search-only login panel hiding if Temu redraws it, and stops home-header forcing from scrolling to top or raising the category strip with forced transform/background/z-index.
- v85.8.21 fixes a WebKit document-start abort in Cairo font injection and defers the MutationObserver until a root node exists. It nudges Temu's first-entry home header only when the category strip is missing, then returns to top. It hides the live Temu account/login surfaces by observed classes on non-account routes, including search redraws, without the previous heavy 90ms full-page text scan.
- v85.8.22 marks verified Temu category strips and forces only those strips to `display:flex`, detects focused searchboxes as search mode, lowers the active search shell by 18px, hides Temu's native search back control, and cleans login/offer sheets on non-account routes while preserving real account routes. The iOS splash PNGs are now blank white to avoid the blue logo in app switcher previews.
- v85.8.23 fixes home layout breaking after entering Temu search and backing out. Otlobli search-back now remembers/clears the search input, dispatches input/search/change, suppresses stale search-mode briefly, hides only search suggestion overlays, and prevents those overlays from being restored as category strips.
- v85.8.24 is rejected on real device. It used active search shell/frame marking plus transform/min-height CSS and caused multiple-tap search entry, moving search bar while typing, half-hidden category strip, and broken home size after exit.
- v85.8.25 removes the v85.8.24 motion/frame path. During search, Otlobli no longer restores/forces the category strip and no longer applies search-mode transform/min-height/margin CSS. Otlobli back uses a short focus-loss grace window so tapping the back button still exits search even if focus leaves the input first.
- v85.8.26 resets the active Temu blocker path: one lightweight cleaner hides only account/login, cart/basket, app-download/open-app, and promo/offer/coupon sheets. The active Temu tick no longer calls the old header/search/category forcing stack. The cleaner protects search inputs/triggers, category rows, product grids, prices, and image-heavy content; it also fixes the old broad `near search input` guard and removes generic `category/nav/menu` distraction matching from promo detection.
- v85.8.27 lightens blockers during active Temu search: it no longer hides Temu's native search back button, and the JS text/geometry cleaner returns immediately while search is active so suggestion words/letters are preserved. Static CSS blockers still apply.
- v85.8.28 adds a narrow search-only cleanup that hides compact top account/cart/menu controls and the fixed Temu bottom nav during search/results without touching suggestion text or Temu's native search back. Otlobli search exit now preserves a focused/populated query instead of clearing it.
- v85.8.29 fixes Temu product option gating for summaries that include RAM/memory/storage, including Arabic `ذاكرة الوصول العشوائي`. Otlobli add now opens the `حدد` variant row instead of adding directly when color plus memory/storage options are present.
- v85.8.30 fixes false Temu size/color gates: products with no size/RAM/model options no longer show "select size"; text-only single-color products such as `اللون: لون فضي` can add and capture the color text. v80 (`db7dfb8`) was checked and not reused because it lacks RAM/memory support and still uses the broad size-section block.

- v85.8.31 fixes two Temu product-page regressions after v85.8.30: removes early static hiding of live `panel/adaptPad` account classes so product templates cannot be blanked, adds a product-content guard to the dynamic account cleaner, and allows a selected text-only color like `اللون: اسود و ابيض` to add without a swatch image.

## Next Step

Install v85.8.31 on the real iPhone. Verify the previously white product pages first, then verify the GENBOLT text-only color product adds with `اسود و ابيض` and empty size. Also recheck that a color+RAM summary product still opens `حدد` before adding. Temu search behavior should remain like accepted v85.8.28.
# Current candidate — v86.99 persistent startup navigation (2026-08-09)

- The Note 8 “tabs disappear for 1–2 seconds” problem was not the SHEIN WebView or React: it was Android's pre-Java activity preview. The previous `Theme.SplashScreen` painted a bare white window before either existing loading/navigation layer could run.
- Keep the v86.99 handoff in this order: `otlobli_starting_window.xml` draws one static-vector four-icon strip in the pre-Android-12 activity preview; `MainActivity.load()` adds the full native Otlobli surface before `BridgeActivity` creates/parses the WebView; the patched SHEIN cover keeps its 120dp bottom navigation area; React calls `OtlobliLaunchSurface.ready()` only after two animation frames. The plugin call is Android-only.
- The static preview is deliberately icon-only and non-interactive: system drawables cannot provide an adaptive text layout, and it lasts only before Java runs. Do not remove it, restore a white `Theme.SplashScreen` on legacy Android, or replace it with a timer/animation/WebView rebuild. Do not revert the single-vector drawable to independently positioned layer-list icons; legacy Android collapsed those layers onto one position in the recording.
- v86.99/959 has passed production build, low-end budget, iPhone-freeze guard, Android/iOS sync, Android debug build, Note 8 install, and a 5-fps frame-by-frame cold-start recording. Final APK: `android/app/build/outputs/apk/debug/app-debug.apk`, 12,574,241 bytes, SHA-256 `89680514B56FE6FD14992079A2B66D85BFA84CABD9E6BC8B99D7EA050E9D0BA9`. iOS source is synchronized, but real iPhone 16 cold launch plus five resume cycles remain mandatory and unperformed.
