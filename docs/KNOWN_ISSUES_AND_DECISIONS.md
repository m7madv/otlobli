# Otlobli — سجل المشاكل والقرارات الدائم

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
  from the first frame. Real iPhone product-open and lifecycle acceptance is
  still required; no simulator/browser result can claim it.

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
