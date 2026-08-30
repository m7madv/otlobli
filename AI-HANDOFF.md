# Active handoff — v86.244/1112 App Review rejection repair (2026-08-30)

Work only in `C:\Users\MOHAMMAD\Projects\otlobli-v86-212-testflight-auth` on
`codex/otlobli-v86-212-testflight-auth`. Marketing remains `86.244`; native
build is `1112` because Apple already has immutable build `1111`.

Apple rejected only the old public `86.230 (1095)` record. The exact 2.3.3
cause was the repository's two login-only screenshots. They are deleted and
replaced by six sanitized product-flow screenshots: store, cart, checkout for
`APP_IPHONE_65` at 1242x2688 and `APP_IPAD_PRO_3GEN_129` at 2048x2732.
`verify:app-store-assets` validates dimensions, count, names, old rejected
hashes, unlisted PNGs, and the mandatory `PREPARE_ONLY` marker. The submission
script uploads all replacements to COMPLETE before deleting stale screenshots.

The plausible 2.1(a) dead end is now explicit and enforced. Pure
`evaluateCheckoutEligibility` returns ordered empty/customization/availability/
minimum blockers. Cart UI shows the exact first Arabic reason and remaining
amount in a live status; its action remains tappable to repeat that feedback.
`confirmOrder` revalidates the same result before any order call. Group checkout
uses its own displayed group total and minimum. Isolated browser tests proved a
4300 SYP cart stays blocked with an exact 700 SYP remainder and a 6400 SYP cart
reaches checkout with the ShamCash action. No production order/payment was
created. Normal pending orders use the server's two-hour deadline; top-up and
issue-payment flows retain their separate five-minute deadline.

App Store version reuse now accepts exactly one `REJECTED` or
`PREPARE_FOR_SUBMISSION` record, preserves metadata, and safely reassigns the
build. The owner explicitly confirmed the complete physical iPhone 16
SHEIN/lifecycle matrix and clean iPhone+iPad checkout through the ShamCash code
screen without pressing paid confirmation. `PREPARE_ONLY` was therefore
replaced by exact-build `SUBMISSION_AUTHORIZED.json` for `86.244 (1112)`.
Asset verification enforces exactly one gate, the complete acceptance fields,
and five resume cycles; the submission script refuses any version/build other
than the authorized pair. App Review submission is now authorized and pending.

First App Review attempt `33304324644` passed build/signing and reused TestFlight
without upload. It uploaded all six replacement screenshots to COMPLETE,
deleted the two stale login screenshots, and linked build 1112. Apple then
returned `ITEM_PART_OF_ANOTHER_SUBMISSION`: version resource `890129230` remains
inside prior submission `e5e27b8a-b628-4116-b135-361b91266929` from the old
rejection. The script now searches editable `READY_FOR_REVIEW` and
`UNRESOLVED_ISSUES` submissions for the version, PATCHes a rejected item with
`resolved=true`, and resubmits that same submission instead of creating a new
one. Retry `33304628281` proved the old submission is not returned by an `IOS`
platform filter; Apple's current review-submission platform is optional. The
search is now unfiltered and the 409 ownership response has a constrained
single-ID recovery path that rereads the submission and verifies the exact
version item before PATCH. Do not delete the old version or detach it manually
while the retry runs.

Full production build, all release/auth/security/SHEIN/Temu guards, Android/iOS
sync, performance budgets, signed Android R8 APK/AAB, APK v2/v3 signature and
AAB JAR verification pass. Final budgets: startup 674276, JS gzip 301491, CSS
69989, shipped store scripts 320230, Temu Gecko 172513, store source 582416.
Artifacts:

- APK `artifacts/release-86.244/Otlobli-86.244-1112-release.apk`, 4,113,735
  bytes, SHA-256 `B8FD9B8BA63D5F074DAC52EC3437587EC67D75AD31B692FDF22964CBFB9AC00D`.
- AAB `artifacts/release-86.244/Otlobli-86.244-1112-release.aab`, 5,775,124
  bytes, SHA-256 `CCFC71D2EE3A4E40C86DEF9E102C4C5846ED5F0D9E68DEEB4D67CCC1742BBBE6`.

No Android device was connected, so no weak-device acceptance is claimed.
GitHub Actions run `33303524932` succeeded from exact head
`f3327247bde550e4e7c426774bd2b2a44030dbee`. Apple validation and upload both
completed without errors; Delivery UUID is
`e4afe608-6bc5-4753-a123-c39b8d66d973`. App Store Connect verified
`86.244 (1112)` as `VALID` and `IN_BETA_TESTING` in all-builds group
`Otlobli Internal`, with expected tester state `INSTALLED`. The App Review step
was explicitly skipped and `PREPARE_ONLY` remains in place.

The signed GitHub artifact is
`otlobli-ios-v86.244-build-1112-testflight`, artifact ID `9729795372`, size
`25,409,917` bytes, GitHub archive SHA-256
`094339D4223FCE87EC8C2F5CB6E73DB11FFCD31745CF88E116DD1B2F06CADFBA`, expiring
`2026-09-29T09:20:48Z`; Apple transferred IPA size `10,601,779` bytes.

The production WhatsApp number/session is intentionally shared by two apps.
After one graceful Oracle instance reboot, the owner requested a real OTP from
one app and confirmed receipt. Release preflight then reported
`whatsappConnected=true`, `whatsappSenderReady=true`, credentials present,
session store ready, `customer-session-v1`, and OTP security ready. Oracle Run
Command stayed `Accepted` without execution, and Cloud Shell had no SSH private
key. No session deletion, number/config change, QR replacement, or tool-originated
test OTP occurred.

Physical acceptance is recorded from the owner's explicit report, not inferred
from CI: iPhone 16 Pro Max guest SHEIN to first product, login-page dismissal,
Google/Facebook contained from Safari, five background/resume cycles, separate
force-quit/cold-launch, plus iPhone and iPad checkout to the ShamCash code screen
without pressing paid confirmation. Weak-Android acceptance for 1112 remains
unperformed and does not block the authorized iOS review submission.

# Active handoff — v86.244/1111 SHEIN verification commit barrier (2026-08-27)

Work only in `C:\Users\MOHAMMAD\Projects\otlobli-v86-212-testflight-auth` on
`codex/otlobli-v86-212-testflight-auth`. Marketing version remains `86.244`;
native build is `1111` because uploaded build `1110` is immutable.

Live official SHEIN assets prove that successful one-pass UI removal precedes
the actual session commit: validation check succeeds, the dialog is removed
after 1000ms, then `/api/risk/flow_check` is awaited, `_f_c_llbs_` is written,
and only then `/risk/challenge` replaces the document with its redirection.
The prior same-document `1200ms` absence plus `600ms` settlement could resume
region/policy work during that gap, explaining intermittent access-timeout and
blank/unavailable-product outcomes. Cookie storage itself was not cleared.

The full `/risk/challenge` document can no longer resolve by elapsed time; the
existing fresh-document coordinator handoff owns success. An embedded
same-document challenge resolves quickly only when the exact `_f_c_llbs_`
value appears/changes, with a 5000ms stable-absence fallback for a same-value
rewrite. Arabic/English access-timeout dialogs remain challenge-owned. Every
same-document resolution resets the three readiness dedupe keys so the same
PDP emits one new trusted snapshot. This adds no WebView, reload, observer,
interval, broad scan, or cookie mutation/clear.

Native iOS and Android blocked-route recovery, delayed goBack/Home, and popup
source recovery all wait while the human-challenge lock is active. Internal
`*.shein.com` top-level/popup navigation remains in the same WebView; external
navigation stays closed. Trusted unlock performs the existing blocked-route
recovery once if necessary. Recoverable WebKit network codes do not tear down
the challenge WebView; real WebContent termination remains fatal. Preserve
`otlobliForceRecompose()`, exact `0.25s` app-active delay, scroll/constraint
restoration, Android `otlobliOnHostResume()`, `WKWebsiteDataStore.default()`,
and `JSON.stringify` region comparison.

Full build/guards, Android/iOS sync, native Java compilation, and signed Android
R8 APK/AAB pass without budget changes. Final budgets are startup 673,259,
total JS gzip 301,034, CSS 69,989, shipped store scripts 320,230, Temu Gecko
172,513, and store source 582,416 bytes, all below their existing ceilings.
Standalone `npm run lint` still exits nonzero on three pre-existing
`no-useless-escape` errors in unchanged `src/services/sheinNavigationScript.ts`
plus 20 established hook warnings; this batch did not widen scope to fix them.
Artifacts:

- APK `artifacts/release-86.244/Otlobli-86.244-1111-release.apk`, 4,113,286
  bytes, SHA-256 `228AA73C6B495C4B4997F131CAF435104B4E55184209C76EC06C375774D17336`.
- AAB `artifacts/release-86.244/Otlobli-86.244-1111-release.aab`, 5,774,680
  bytes, SHA-256 `0D12CA3391DE720715EA8F8F6D970196FD4F7F8252A54EEF76CA9EE7138D5A19`.

Note 8 was offline/disconnected, so no install or physical challenge acceptance
was claimed. Real iPhone 16 acceptance still requires a genuine challenge,
five background/resume cycles, and a separate force-quit/cold launch. TestFlight
upload for 1111 is pending; App Review submission must remain disabled.

# Active handoff — v86.244/1110 event-driven SHEIN login-later (2026-08-27)

Work only in `C:\Users\MOHAMMAD\Projects\otlobli-v86-212-testflight-auth` on
`codex/otlobli-v86-212-testflight-auth`. Marketing version remains `86.244`;
the new build is `1110` because uploaded build `1109` is immutable.

Keep the two SHEIN auth surfaces separate. Full `/ar/user/login` has no later
button and still exits through the v86.244 native URL-event Back/Home recovery.
The optional product interstitial does have an exact Login Later action. Its
document-start policy used to discover it immediately only under
`.s_auth__block-login-tip`, so a SHEIN wrapper rename could miss the action.

The policy's single existing MutationObserver now reuses the existing
`candidateSelector` NodeList from `scan()`: it checks the added root and the
last 16 candidates for an exact Arabic/English Login Later label. It adds no
document-wide selector, observer, interval, timer, or WebView. The known scope
remains as a bounded fallback. Challenge detection exits first; generic login,
inexact labels, fields, and deliberate authentication are untouched. The old
coordinator fallback only gained the same exact Arabic label variants. Both
paths now set/read the shared `data-otlobli-login-later-action/fired` markers
before clicking, so policy→fallback and fallback→policy each click once.

The executable freeze fixture proves unscoped wrapper matching, post-mutation
one-shot clicking, pre-runtime defer/resume, no inexact or challenge click,
exactly one observer, and zero generic control queries on document root.
Preserve `otlobliForceRecompose()`, the exact `0.25s` app-active delay,
scroll/constraint restoration, Android `otlobliOnHostResume()`, and the
`JSON.stringify` region comparison. Do not change region, cookies/session,
human verification, Temu, payment, wallet, completed orders, or lifecycle.

Full build, freeze/store/release/security guards, performance budgets, and both
native syncs pass. Budgets are startup `673,159/720,000`, total JS gzip
`300,476/370,000`, CSS `69,989/70,000`, shipped store scripts
`318,372/470,000`, Temu Gecko `172,513/180,000`, and store source
`582,181/600,000`; no limit changed.

Signed Android artifacts are under `artifacts/release-86.244/`: APK build 1110
is `4,112,739` bytes, SHA-256
`DAF3A6D0BD3ADAE41873CCD4D425D9134F265BA68018CFCFCC1B32A1FA8956BC`;
AAB is `5,773,866` bytes, SHA-256
`6BBF28ACFC24D96D491160719E0D392EB388BD5B20BE14C872E178EB4E322C95`.
Note 8 was updated in place, confirms `86.244 (1110)` and `120000ms`, and
opened SHEIN Home → listing → PDP without matching fatal/ANR/OOM. Its retained
session did not show the optional auth prompt, so this is not prompt acceptance.

Live App Store Connect GET shows public `86.230 (1095)` is `REJECTED`, with its
review submission `UNRESOLVED_ISSUES`. `86.244 (1109)` is `VALID`,
`APP_STORE_ELIGIBLE`, and `IN_BETA_TESTING`, but has no appStoreVersion relation
and was never submitted for review. The rejection text is available only in
App Review Issues & Messages after account login. Do not run the current
submission script blindly: it only reuses `PREPARE_FOR_SUBMISSION`, not
`REJECTED`, and may hit a 409 trying to create 86.244. Read the message first,
then either rename/reuse the rejected record if Apple permits it, or choose a
non-destructive compatible build path.

Immediately before the planned 1110 upload, WhatsApp session `0` was in an
in-memory `error` state with persisted credentials, zero risk, and no actual
QR. Restarting only `otlobli-wa` restored `idle`; one protected reconnect POST
reused those credentials. Final health has WhatsApp connected/sender ready and
session store/OTP ready. No session was deleted, no QR was scanned, and no
message or test OTP was sent.

Release commit `0a78e5764f39cbc30241c2bfd622d0d39cd022a7` is pushed. GitHub
run [33075528666](https://github.com/m7madv/otlobli/actions/runs/33075528666)
succeeded in `8m57s` and uploaded build `86.244 (1110)` with delivery UUID
`bd950715-b83a-49c6-966b-ec0cf04cdf28`. App Store Connect reports `VALID` and
`IN_BETA_TESTING`; `Otlobli Internal` has all-build access and the expected
tester is `INSTALLED`. The IPA is `10,551,551` bytes, SHA-256
`8FAB591376D0A6DAD28141BF6480664744B9C693B7F6F65315B64928AE7340BD`.
Artifact `9647984843` is `25,260,454` bytes with ZIP digest
`91E053F44FB846F319DCD2F731911A7A8FE2CE61A95FD4EA388E2BCCB8BC8796`.
The App Review step was explicitly skipped.

The authenticated App Store Connect UI exposed the exact rejection for old
`86.230 (1095)`, submission `e5e27b8a-b628-4116-b135-361b91266929`.
Guideline 2.3.3 says both the 6.5-inch iPhone and 13-inch iPad product-page
screenshots show only Login. Guideline 2.1(a) says review could not continue
payment after adding cart items on iPhone 17 Pro Max and iPad Air 11-inch M3,
iOS/iPadOS 26.6. The rejected record's Version textbox is enabled. Prefer
reusing it: rename 86.230→86.244, detach build 1095, attach 1110, replace Login
screenshots with real feature screenshots, then resubmit only after clean
iPhone/iPad checkout acceptance. No field, message, record, or review status
was mutated during inspection.

Do not claim build 1110 fixes Guideline 2.1(a). History review found that
`a53fbf9` corrects Temu/SHEIN cart ownership and later UI makes the cart clearer,
but the core continue-button predicates and `setScreen('checkout')` flow are
materially the same as build 1095. Apple may have hit the 5000 SYP / $40
minimum, an unavailable/incompletely customized item, or the old cross-store
cart bug; none is proven without the reviewer capture/logs. Before attaching
1110, clean-install on iPhone and iPad with a complete review account, test one
ordinary available item per store above both minimum interpretations, verify
the correct cart and enabled continue button, create exactly one pending order,
and stop after a non-empty ShamCash code/amount/future expiry appears. Do not
transfer money or press the paid button. Resolve the repository's two-hour
expiry versus the UI/docs' five-minute statement before App Review.

# Active handoff — v86.244/1109 full SHEIN auth-route exit (2026-08-26)

Work only in `C:\Users\MOHAMMAD\Projects\otlobli-v86-212-testflight-auth` on
`codex/otlobli-v86-212-testflight-auth`. Standard Android/iOS are
`86.244 (1109)`. This batch is intended for internal TestFlight only; App Store
Review must remain disabled.

The user's screenshot is the live full SHEIN route `/ar/user/login`, not the
optional `.s_auth__block-login-tip` interstitial. The existing route classifier
already returns `blocked-login`, but SHEIN's same-document History API routing
bypassed iOS `decidePolicy` and Android `shouldOverrideUrlLoading`. iOS KVO and
Android `doUpdateVisitedHistory` observed the new URL without leaving it, while
the full page could open Facebook externally.

v86.244 reuses those existing native URL events. A blocked History route gets
one native Back; a single bounded `200ms` check falls back to
`https://m.shein.com/ar/` only if Back did not leave the blocked route, while
missing Back history uses Home immediately. Every popup from that blocked page
is canceled before internal popup handling or an external intent, so Google or
Facebook cannot escape to another app. No DOM selectors, extra observer,
persistent interval, reload, WebView recreation, or social-OAuth implementation
was added. The clean Capgo `8.6.25` install accepts the persistent patch.

Preserve `otlobliForceRecompose()`, exact `0.25s` app-active delay, scroll and
constraint restoration, Android `otlobliOnHostResume()`, and the
`JSON.stringify` region comparison. Region, cookies/session, human verification,
payment, wallet, completed orders, and Temu are untouched. The exact
login-later and privacy behavior from v86.243 remains separate and unchanged.

`npm ci`, all release/service/store/freeze/security guards, full build,
performance budgets, Android/iOS sync, Android debug/release Java compilation,
R8 APK/AAB build, signatures, package identity, and artifact guards pass.
Budgets are startup `673,159/720,000`, total JS gzip `300,219/370,000`, CSS
`69,989/70,000`, shipped store scripts `318,044/470,000`, Temu Gecko
`172,513/180,000`, and store source `581,616/600,000`; no limit changed.

Note 8 was updated in place to `86.244 (1109)`, retains the `120000ms` screen
timeout, and cold-launched without a matching fatal/ANR/OOM. This is packaging
and weak-device smoke evidence, not acceptance of the reported iPhone route.

The TestFlight phone-auth preflight initially found session `0` in an in-memory
`error` state after an old connection termination, with zero risk, no pause,
and no QR. No reconnect POST was sent in that state. Restarting only the
`otlobli-wa` PM2 process restored the persisted session to exact safe `idle`;
one protected reconnect POST then returned connected. Final health is
`whatsappConnected=true`, `whatsappSenderReady=true`, session store/OTP ready,
with no session deletion, QR, or customer OTP sent.

- APK: `artifacts/release-86.244/Otlobli-86.244-1109-release.apk`,
  `4,112,470` bytes, SHA-256
  `917605B307DC5A32FF10430181965EE686FEDBEBB36F0EF7B817F0EAAE1820CB`.
- AAB: `artifacts/release-86.244/Otlobli-86.244-1109-release.aab`,
  `5,773,596` bytes, SHA-256
  `15D0DE97BA2F75E319188BB2412B550178EB61756995432377C25FC270DFDE89`.

Release commit `28ea4518d6bd47575fd594d4020c460649876b31` is pushed. GitHub
run [32988536909](https://github.com/m7madv/otlobli/actions/runs/32988536909)
succeeded and uploaded `otlobli-v86.244-build-1109-testflight.ipa`: `10,551,296`
bytes, SHA-256
`E40902F61230CDE3D279C9A1281AF56DB5445D705513F4CB4B157C05D0382ED1`,
delivery UUID `25645ee5-2f2e-4e68-8f09-d6161e4fc7de`. App Store Connect
reports `VALID` and `IN_BETA_TESTING`; `Otlobli Internal` has access and the
expected tester is `INSTALLED`. GitHub artifact `9614099128` is `25,260,142`
bytes with ZIP digest
`A3178BA4B5076A691DE9CBBA5084D1B915A20F15D6586693460BB92579442E19`.
App Review submission was skipped as required.

The user must now test first-product guest entry on iPhone 16 Pro Max, confirm
the full auth page never remains and no external browser opens, then run five
background/resume cycles plus a separate force-quit/cold-launch. Do not claim
device acceptance from CI.

# Active handoff — v86.243/1108 post-challenge SHEIN resume and verified group links (2026-08-26)

Work only in `C:\Users\MOHAMMAD\Projects\otlobli-v86-212-testflight-auth` on
`codex/otlobli-v86-212-testflight-auth`. Standard Android/iOS are
`86.243 (1108)`. Functional app commit
`a962b0d2553925f0ae6a1fb38883a4e204a2a174` and TestFlight workflow fixes
through `142eacd1ddf9cfe27c221110274cd961c3b3b80c` are pushed.

The user's exact observation confirms the SHEIN failure mode: after manually
completing the first human challenge, the page could retain stale policy/privacy
state and stop scrolling; entering Temu and then returning to SHEIN made it work
fully. v86.243 resumes policy once and privacy once only after the existing
`1200ms` challenge-absence proof plus `600ms` settlement. Login-later is exact
text inside `.s_auth__block-login-tip`; Accept All is exact text inside the
confirmed privacy wrapper, bounded to 160 candidates. Privacy adds no observer
or interval. Never automate the challenge, add reload/recreate, broaden the
scans, or change region/cookies/session behavior.

Preserve `otlobliForceRecompose()`, exact `0.25s` app-active delay, scroll and
constraint restoration, Android `otlobliOnHostResume()`, and the
`JSON.stringify` region comparison. Payment, wallet, completed orders, human
verification, and Temu DOM/layout are untouched in v86.243. The v86.242 native
blank-navigation fix remains the only fix for the prior iPhone Temu PDP gap.

Group invites now have verified platform associations at
`https://talabieh.vercel.app`: Android `assetlinks.json`, Apple AASA, exact JSON
headers, Android domain status `always : 200000000`, and Apple CDN `200` for
`36D743K87T.com.otlobli.app` with `/group` and `/group/*`. The fallback never
auto-runs the custom scheme; joining remains explicit and limited to one friend.
TestFlight's signed app entitlement is exactly
`["applinks:talabieh.vercel.app"]`. No real iPhone WhatsApp-link tap was
performed, so do not claim physical Universal Link acceptance yet.

Vercel production deployment is `dpl_4iZnSZqiDgMN3EtVQkzpSoYoRGND`, aliased
to `https://talabieh.vercel.app`. The first cached dependency deployment failed
safely at `patch-package`; the forced clean production deployment passed all
guards. Origin and Apple CDN are both valid now.

All build/freeze/store/group/security guards and Android/iOS sync pass. Local
budgets: startup `673,159/720,000`, total JS gzip `300,217/370,000`, CSS
`69,989/70,000`, shipped store scripts `318,044/470,000`, Temu Gecko
`172,513/180,000`, store source `581,616/600,000`. CI startup/gzip are
`673,350` and `300,262`. No budget was raised.

Note 8 has `86.243 (1108)` installed in place with data preserved. SHEIN
rendered after about 25 seconds and scrolled; no matching fatal/ANR/OOM was
found. Evidence is under `artifacts/device-captures/v86.243-note8/`. Existing
cookies mean this is not clean-install acceptance of Accept All/Login Later.

- APK: `artifacts/release-86.243/Otlobli-86.243-1108-release.apk`,
  `4,112,457` bytes, SHA-256
  `D8AC90063B7CD15C95A0278BA9369A160BC9ADA5DF316356C74F9450E164AFF3`.
- AAB: `artifacts/release-86.243/Otlobli-86.243-1108-release.aab`,
  `5,772,733` bytes, SHA-256
  `CD7AB051E00C2535BBF8A4763A237ACC262C1FFEA8992D8C831D323D14AB4B13`.

TestFlight run `32952198744` succeeded in `7m56s`; Delivery UUID
`4ea11eda-a514-4c24-a05a-8b39d04c646c`. Build `86.243 (1108)` is `VALID` and
`IN_BETA_TESTING` in all-builds group `Otlobli Internal`, expected tester state
`INSTALLED`, with App Review disabled. Signed IPA is `10,546,318` bytes,
SHA-256 `5637399386858365D318C40FFE6F4000815553556BB093CB884E67A38CDB11A5`.
Artifact `9600827192`, `otlobli-ios-v86.243-build-1108-testflight`, is
`25,253,256` bytes with digest
`sha256:a509dd9fa5fef6be5ad1ae2dd1a0e6a7de0965671853799d5581e3cbe493183a`.

The persisted Oracle WhatsApp session `0` was reconnected once from stored
credentials after the first run stopped before signing; no QR, new session, or
message was generated. Final health reports connected/ready sender, credentials,
`customer-session-v1`, session store, and OTP security ready. Apple capability
`ASSOCIATED_DOMAINS` is enabled. Profile
`053cb721-6618-48ae-8d16-1c6ba86feed5` uses Apple's authorization wildcard
`*`; this is intentionally distinct from the app's exact array entitlement.
Never weaken the exact IPA check or delete/revoke signing assets to refresh it.

Remaining physical acceptance: update TestFlight on iPhone 16 Pro Max; test the
first SHEIN challenge/privacy/login-later sequence and scroll; tap a real group
link from WhatsApp; run five background/resume cycles and one separate
force-quit/cold-launch. No physical iPhone acceptance is claimed from CI.

# Active handoff — v86.242/1107 iOS blank-navigation fix (2026-08-26)

Work only in `C:\Users\MOHAMMAD\Projects\otlobli-v86-212-testflight-auth` on
`codex/otlobli-v86-212-testflight-auth`. Standard Android and iOS are
`86.242 (1107)`. Source commit
`e46dbf9ab01dc594942501f0ba3ac223c3a9c373` is pushed. TestFlight run
`32923259010` succeeded in `8m6s` with internal distribution and
`app_store_submission=false`.

The iPhone 16 Pro Max screenshot proves the PDP gap is a native blank
`UINavigationBar`, not Temu DOM or safe-area geometry: the status surface ends
at downscaled `y=132`, pure white spans `y=136..295`, and a native separator is
at `y=296..298`, matching about `75pt`. Capgo initially hides the bar for
`ToolBarType.BLANK`, but its old `setUpState()` unconditionally showed it with
animation during `viewWillAppear`. The persistent patch now uses
`setNavigationBarHidden(blankNavigationTab, animated: !blankNavigationTab)`.
Do not replace this with DOM/CSS, inset compensation, another layer, a timer,
observer, or scan. The WebView remains anchored to the safe-area top.

The dedicated iOS SHEIN browser is untouched. Preserve exact
`otlobliForceRecompose()`, the `0.25s` app-active delay, Android resume defense,
and `JSON.stringify` region equality. Store region, sessions, human
verification, payment, completed orders, and wallet remain out of scope.

All release/build/performance/freeze/store guards pass. Local startup/total-gzip
budgets are `673,159/720,000` and `299,506/370,000`; CI records
`673,350/720,000` and `299,553/370,000`. CSS is `69,989/70,000`. Standard iOS
and Android sync pass. The clean upstream Capgo package accepts the persistent
patch, and the new guard rejects the legacy unconditional navigation-bar line.

Release APK/AAB are under `artifacts/release-86.242/`. APK SHA-256 is
`208FFB9B5B333C7731FB816ECDDA33BE95B06BA9721B167C79D41F3704594A78`; AAB
SHA-256 is `C42AE0279ACF5FAEDCA23E9FFDC43584FB4913FC741DF386DB4F420C1B648557`.
The APK is installed in place on Note 8 as `86.242 (1107)`; live Temu remains
correct and logs contain no fatal/ANR/OOM match. Evidence is under
`artifacts/device-captures/v86.242-note8/`.

Apple delivery UUID is `e7ab793a-ba55-49c0-b03b-ca25cb7f3a04`. Build
`86.242 (1107)` is `VALID` and `IN_BETA_TESTING` in the all-builds group
`Otlobli Internal`; expected tester state is `INSTALLED`. Signed IPA is
`10,544,361` bytes with SHA-256
`F814CD76FB3D9F82D9F7FCF98D7BB45BD66C48BC3178616509E6B36A357D92A3`.
GitHub artifact `9590730095`,
`otlobli-ios-v86.242-build-1107-testflight`, is `25,251,919` bytes with digest
`sha256:2a6a8ce5795e900e74de760bd22651978fa0c6ad3a7f5765d1a68653688c9a54`.
WhatsApp/authentication preflight passed without sending a test OTP.

Do not claim real iPhone acceptance from CI. Verify the PDP gap on iPhone 16
Pro Max, then perform five background/resume cycles and one separate
force-quit/cold-launch test.

# Active handoff — v86.241/1106 Temu/SHEIN/group-order release (2026-08-26)

Work only in `C:\Users\MOHAMMAD\Projects\otlobli-v86-212-testflight-auth` on
`codex/otlobli-v86-212-testflight-auth`. Android and iOS are `86.241 (1106)`.
The production web alias is `https://talabieh.vercel.app`; Supabase migration
`20260826123000_group_order_single_friend.sql` and the `cart-groups` Edge
Function are live in project `dcicqdprtyhwmhegabay`. Source commit
`33da0d8505f4979115b2659a04e711ec05b076fa` is pushed. TestFlight run
`32918348290` succeeded on attempt 2 with internal distribution and
`app_store_submission=false`.

Preserve the narrow Temu fix. The iPhone video proved that Otlobli's native bar
stayed fixed while Temu's own search/logo header moved about `70px`. iOS now
gets the same semantic sticky-marker Y correction as Android, only when the
bounded download-shell detector has marked Temu Home as collapsed. Do not add
`top`, scroll work, a timer, observer, broad scan, or an in-page bar.

Preserve the SHEIN behavior: the existing policy cadence may activate only the
exact site-owned «تسجيل الدخول لاحقًا» action on the optional first-product
interstitial. Human verification exits first. Never fill an account form,
hide deliberate login, or add another cadence/observer.

Group orders are intentionally exactly two people. Invite URLs carry only
`code`, `group`, and `store`; joining is explicit. Keep session-authenticated
atomic RPCs, the one-host/one-friend partial indexes, `200`-item cap, UUID
validation, per-operation epoch, and matching-group/item cleanup. Never restore
the old anonymous RPCs or globally deduplicate historical customers: nine
expired legacy groups have duplicates and one is linked to an order. The live
transactional test rolled back and left `30` groups and `44` memberships.

The full production build, TypeScript, Deno, group guard, store/freeze guards,
release hardening, and performance budgets pass. Final budgets are startup JS
`673,159/720,000`, total JS gzip `299,501/370,000`, and CSS
`69,989/70,000`. Android/iOS sync passed. Repository lint still has only the
pre-existing out-of-scope escapes at `src/services/sheinNavigationScript.ts:44`
plus known warnings.

Physical Note 8 has `86.241 (1106)` installed in place with data preserved.
Temu's header stayed fixed at open and after deep scroll. A native Temu security
challenge appeared on Back, so testing stopped without interaction or bypass.
No fatal/ANR/OOM match was found. Evidence is in
`artifacts/device-captures/v86.241-note8/`.

- APK: `artifacts/release-86.241/Otlobli-86.241-1106-release.apk`,
  `4,111,877` bytes, SHA-256
  `122BF44912874CC78F9D3D2D29C4D3A2DAE1B27DBC3957A160AE53232AB47D8F`.
- AAB: `artifacts/release-86.241/Otlobli-86.241-1106-release.aab`,
  `5,772,199` bytes, SHA-256
  `F931E6262CC113325DA770C192C18734E47F1708456E6340290F0933F49A13B3`.

Attempt 1 stopped safely before signing because the persisted WhatsApp sender
was idle. Session `0` had credentials, no QR, no pause, and zero risk. It was
reconnected exactly once through the protected Oracle loopback admin endpoint;
no session was deleted/created and no message was sent. Live health after the
workflow still reports connected/ready sender, stored credentials,
`customer-session-v1`, and hardened OTP storage.

Attempt 2 completed in `8m37s`. Apple delivery UUID is
`62c29df1-3eb2-4578-8855-68d79716acd6`; build `86.241 (1106)` is `VALID` and
`IN_BETA_TESTING` in all-builds group `Otlobli Internal`, with expected tester
membership `INSTALLED`. The signed IPA is `10,544,380` bytes with SHA-256
`23DEACC520F414E01919BA15AAF2AEB25160F3A20D4FB5706B993467C7472425`.
GitHub artifact `9589184204`,
`otlobli-ios-v86.241-build-1106-testflight`, is `25,251,950` bytes with digest
`sha256:826a0531247e67cf8ddb72b86d9beea08b6d23ac43f09fef78f17a4cdc778678`.
App Review was disabled and skipped.

Preserve `otlobliForceRecompose()`, exact `0.25s` app-active delay, Android
resume defense, and `JSON.stringify` region equality. SHEIN region, sessions,
human verification, payment, completed orders, and wallet were not changed.
Five real iPhone 16 resume cycles plus a separate force-quit/cold launch remain
mandatory even after a successful TestFlight upload.

# Active handoff — local v86.237/1102 store-identity candidate (2026-08-25)

Work only in `C:\Users\MOHAMMAD\Projects\otlobli-v86-212-testflight-auth` on
`codex/otlobli-v86-212-testflight-auth`. Preserve the dirty worktree. This
candidate is local, uncommitted/unpushed, and not uploaded or submitted.
Standard Android/iOS are `86.237 (1102)`; isolated Android is
`86.237-personal (1102)` with Gecko manifest `1.3.21`.

The reproduced fault was identity aliasing, not a Temu layout failure.
`selectedStoreRef` represented both the visible Cart tab and the store that
actually owned the singleton native WebView. Thus Temu → Cart → SHEIN tab →
Home → chooser → SHEIN could expose the parked Temu session, and a late capture
could land in the selected tab's cart. Preserve the explicit standard owner
`{store, sessionId, id}` and the rule that switching only the Cart tab never
changes, closes, or reuses the native owner.

Standard events must match the current session and WebView id. The bounded
opening-id adoption is allowed only for the same store/session while opening,
never while closing, never for a remembered old id; strict matching resumes
immediately. Keep store hosts exact (`temu.com`/`shein.com` and subdomains),
route product links by their proven host, send ACK to `event.id`, and retain
Gecko's explicit `sourceStore:'temu'`. The mount repair moves only cart rows
whose source URL proves the opposite store; unknown links remain untouched.

The Temu add button alone uses static `bottom:24px`; SHEIN remains `16px`.
Button size/right stay `128×48px` and `14px`. Do not replace this with dynamic
inset work, `visualViewport`, a timer, observer, broad DOM scan, or another bar.
The native Otlobli bar remains outside WebView. Note 8 measured
`[706,1666][1044,1795]` with a `63` physical-pixel (`24 CSS px`) clearance to
the WebView ending at `1858`.

Physical Note 8 has the final standard APK installed in place with data
preserved. Both store-switch directions passed, including the user's exact
Temu/SHEIN Cart-tab sequence. Cart counts are `Temu=2`, `SHEIN=0` after the
safe migration. A reverse Temu loading screenshot was a timing boundary, not a
hang: native attachment occurred `19ms` later. Do not change
`isPresentAfterPageLoad`, `preShowScript`, or add a timer/cover from that
evidence. Acceptance files are under
`artifacts/device-captures/v86.237-note8/`; the process log has no fatal, ANR,
OOM, or native-crash match. Cold launch was `755ms`.

The width gate passes `320/360/393/412/430 CSS px`. The A52-like emulator is
`1080×2400 @420dpi` and accepted Debug `86.237/1102` without data deletion,
but it is logged out; no auth bypass or live Temu claim was made. A real A52
remains untested.

All release-service, TypeScript, scoped ESLint, Temu-size, store-surface,
hardening, freeze, full standard/personal build, and performance checks pass.
Android and iOS are synchronized from final standard `dist`. Budgets are
startup JS `669,726/720,000`, JS gzip `295,014/370,000`, CSS
`69,932/70,000`, fonts `81,364/100,000`, shipped store scripts
`315,090/470,000`, Gecko `170,458/180,000`, and store source
`564,829/600,000`.

- Standard APK: `artifacts/release-86.237/Otlobli-86.237-1102-release.apk`,
  `4,107,374` bytes, SHA-256
  `C05C949846881FDBB6E82B286CAEE487AE38CBF6A1DF30A65FA4B24B8A6552A8`.
- Personal arm64 APK:
  `artifacts/release-86.237/Otlobli-86.237-1102-temu-personal-arm64.apk`,
  `195,389,315` bytes, SHA-256
  `8B4009316E168DEA720ACE20186F6629625EDA002A5D927625676DC1CFB80AD9`.

Both verify with the expected Otlobli certificate and APK v2/v3. SHEIN region,
human verification, payments, orders, wallet, and lifecycle were not changed.
Preserve `otlobliForceRecompose()`, the `0.25s` foreground delay, Android
resume defense, and `JSON.stringify` region comparison. iOS is synchronized
but has no IPA/device acceptance; five iPhone 16 resume cycles plus a separate
cold launch remain mandatory.

# Active handoff — local v86.236/1101 Temu sticky-offset candidate (2026-08-25)

Work only in `C:\Users\MOHAMMAD\Projects\otlobli-v86-212-testflight-auth` on
`codex/otlobli-v86-212-testflight-auth`. Preserve the dirty worktree; this
candidate is uncommitted/unpushed and was not uploaded or submitted. Standard
Android/iOS are `86.236 (1101)`, isolated Android is `86.236-personal (1101)`,
and Gecko manifest is `1.3.20`. External `86.230/1095` review and
`86.231/1096` TestFlight states were not changed.

The fixed fault is not Temu's ordinary dense Home layout. On v86.235 Note 8,
after scrolling down and returning to zero, Temu's Search/logo row moved down
`173` physical px = `65.9 CSS px`. The bounded Otlobli download-shell collapse
removed Temu's `0.66rem` shell while Temu retained the same `0.66rem` Y
transform on `[js-selector="bg-cui-top-sticky"]`. Live DOM showed
`font-size:100px`, so the causal values match exactly.

Keep the correction narrow: the CSS selector requires Android, Temu Home, and
`data-otlobli-temu-download-collapsed="1"`, which is set only after the existing
bounded shell guards succeed. Reset only `transform: translate(-50%, 0)` on the
semantic presentation marker. Do not add `top`, target Search/top tabs, widen
the selector, add scroll work, or make the success marker churn every `650ms`.
The marker synchronizer mutates only when collapsed state actually changes.
Product/account/challenge routes, iOS, and Gecko web remain excluded.

Preserve the native bar outside `WebView`, its exact Temu chooser wording, all
human-verification ownership rules, persistent sessions, and the protected
iPhone/Android lifecycle invariants. In particular retain
`otlobliForceRecompose()`, the `0.25s` `appDidBecomeActive` delay, Android
`otlobliOnHostResume()`, and `JSON.stringify` active-region comparison. SHEIN,
region, payment, orders, wallet, and authentication were not changed.

Physical Note 8 `SM-N950F` now has standard `86.236 (1101)` installed in place.
The Home header/logo stayed at `y=95..138` initially and after 5/10 varied-
speed scroll cycles; the cycle-10 header crop equals the initial crop pixel for
pixel. v86.235's broken post-scroll capture was `y=268..311`. Search accepted
English input/suggestions and Arabic keyboard input; two products opened and
returned; another scroll and background/resume remained correct. Chrome was
blocked by Temu's own `bgn_verification` and was not bypassed. The current app
process has no fatal/ANR/OOM/native-crash line. Synthetic ADB taps did not meet
the native chooser cadence in this rerun; v86.235's accepted chooser code is
unchanged.

The 80-swipe stress trace is `5,214` frames, `28.63%` jank,
`p50/p90/p95/p99=10/21/24/32ms`, 12 missed vsyncs, and PSS
`194,091 -> 203,757 KB`; graphics stayed `56,736 KB`. Temu remains the heavier
third-party renderer. Final budgets pass without raising a cap: startup/largest
JS `665,888/720,000` and `/1,200,000`, JS gzip `293,819/370,000`, CSS
`69,932/70,000`, fonts `81,364/100,000`, shipped store scripts
`315,089/470,000`, Gecko `170,453/180,000`, source `564,718/600,000`.

Both builds, protected guards, production artifact check, and scoped ESLint
pass; standard `dist` is synchronized to Android and iOS. Full repository
ESLint remains blocked only by two pre-existing out-of-scope errors at
`src/services/sheinNavigationScript.ts:44` and 18 existing warnings. Artifacts
use the expected Otlobli certificate and APK v2/v3:

- `artifacts/release-86.236/Otlobli-86.236-1101-release.apk` — `4,106,166`
  bytes; SHA-256
  `05AF2BBFC825235328DFA72E59EB7AD0F7E7047307ABFEDB0217EABE1E3BD32F`.
- `artifacts/release-86.236/Otlobli-86.236-1101-temu-personal-arm64.apk` —
  `195,388,096` bytes; SHA-256
  `D675BC71234069569451717F09AC7B4885543682BF048A9B56F9DD892CCC2E5F`.

iOS was synchronized but no IPA/iPhone test was possible on Windows. Five real
iPhone 16 resume cycles and a separate force-quit/cold launch remain required;
do not infer that acceptance from the passing freeze guard or Android result.

# Active handoff — v86.231/1096 internal TestFlight performance maintenance (2026-08-24)

Continue only in `C:\Users\MOHAMMAD\Projects\otlobli-v86-212-testflight-auth`
on `codex/otlobli-v86-212-testflight-auth`. Exact source is
`44a5200a127f0e3689373c5b756486fef510dd4f`; do not replace it with an older
branch. Signed workflow
[32760648713](https://github.com/m7madv/otlobli/actions/runs/32760648713)
uploaded exact `86.231 (1096)` with delivery UUID
`05c2aefa-05ec-4ec1-994a-c3e24bcb6d65`. Apple reports it `VALID` and
`IN_BETA_TESTING` in the `Otlobli Internal` all-builds group; expected tester
state is `INSTALLED`. Public App Review submission was false and its step was
skipped. The separate `86.230 (1095)` remains in its last confirmed
`WAITING_FOR_REVIEW` state with automatic release after approval; do not submit
or attach `86.231` to public review without a new explicit owner instruction.

Run `32759501489` stopped at `npm ci` before signing/Apple because patch-package
rejected manually edited hunk offsets. Commit `44a5200` mechanically regenerated
the Capgo patch and clean reverse/apply checks pass. Run `32760002781` then
stopped before signing because the Oracle WhatsApp sender was disconnected.
Session `0` had stored credentials and was reconnected exactly once through the
protected localhost endpoint, without sending a message or generating QR. All
required health fields passed before the successful run. Railway was inspected
with the installed `use-railway` operating guidance and proved inactive/removed;
do not redeploy it for this service because Oracle/pm2 is authoritative.

The store runtime is compiled per store and protected by an exact host guard.
Minified captures are SHEIN `138,492` bytes and Temu `150,400` bytes. Temu's
personal-Gecko capture is `138,945` bytes (`139,825` with wrapper), down from
`416,137`. Preserve the one-snapshot SHEIN region check, filtered policy
mutations, already-blocked header fast path, current-route Temu readiness, and
post-confirmation watchdog shutdown/re-arm logic. Do not lengthen blocking
intervals or remove a feature to pass a budget.

The Capgo patch removes three production logging hot paths: the entire injected
pre-show source, complete WebView callback messages/product URLs, and routine
postMessage event payloads. The patch passes both reverse-check against current
`node_modules` and clean apply-check against a fresh upstream `8.6.25` package.
`verify:shein-freeze-guard` asserts those logs remain absent. Preserve the iOS
`appDidBecomeActive` 0.25-second single recompose, Android host-resume defense,
one persistent WebView, and JSON-stringified active-region equality.

Full production web build and all release/freeze/Temu/store/performance checks
pass, followed by `cap sync android` and `cap sync ios`. The customer Android
release task passes; the unrelated repository-root task still needs the four
listener signing values. Final signed APK:

- `output/Otlobli-v86.231-Android-Performance-Maintenance.apk`, `4,098,272`
  bytes, SHA-256
  `4EDEE16ACB3C8E1B473E0601D7CF42ECCA1ED6CFDC36EB7C60F7942185B6C4F5`.

It is installed on physical Note 8 `SM-N950F` as `86.231/1096`. Fresh launch
was `812ms`. Temu Home → PDP → Home passed and Back remained visible; SHEIN
Home loaded. There were no app crashes/ANRs and no heavy native bridge logs.
Steady four-swipe SHEIN p50/p90/p95/p99 was `11/16/18/24ms` at `181,936 KB`
PSS. Temu was `17/24/27/36ms`, so the third-party Temu renderer is still the
heavier boundary on the old phone. Do not present this as iPhone acceptance or
complete checkout/auth acceptance. The signed IPA is
`output/testflight-v86.231-build-1096-run-32760648713/otlobli-v86.231-build-1096-testflight.ipa`,
`10,488,204` bytes, SHA-256
`D9B1F22FE42FFC16AFC819ECA81E70E54D49F22688FC5DC6EF91A34F3A6D2A77`.
The dSYMs archive is `14,858,853` bytes, SHA-256
`A8EADD8426A0B0B4DF6FF84449DA67748E656F445D35EDEAB9F80DF83D384F18`.
Portal/build success is not physical iPhone acceptance: five real iPhone 16
resume cycles plus a separate force-quit/cold-launch test remain required.

# Active handoff — v86.230/1095 is waiting for Apple Review (2026-08-24)

The owner explicitly confirmed final submission and automatic release after
approval. Workflow
[32703091122](https://github.com/m7madv/otlobli/actions/runs/32703091122)
passed from `c45ea0114323cc71aff16f1e2e337616115085c2`. It verified and reused
the existing build `86.230 (1095)`, confirmed `APP_IPHONE_65` and
`APP_IPAD_PRO_3GEN_129` screenshots as COMPLETE, added the version to review
submission `e5e27b8a-b628-4116-b135-361b91266929`, and Apple returned
`WAITING_FOR_REVIEW`.

Portal state: Arabic listing metadata is saved; category is Shopping; price is
free; availability is all 175 territories; rating is calculated 13+; untested
Mac/Vision distribution is off. The live privacy and support URLs are from
READY deployment `dpl_2EU6QQoxjhA7xFuFsrARAUB3SS69`. Thirteen actual privacy
data types are fully configured as App Functionality, identity-linked, and not
used for tracking. The owner approved the declaration and publication: the
third-party content-rights answer is saved as having the necessary rights, and
the privacy label is published.

Reviewer first/last name, phone, email, and the Sign in with Apple workflow are
saved in App Store Connect; personal contact values are intentionally omitted
from repository documentation. `PREPARE_ONLY` was removed for the authorized
submission. Do not claim approval or public availability: the confirmed state
is only `WAITING_FOR_REVIEW`. Apple will release automatically if it approves.

# Active handoff — v86.230/1095 is live in internal TestFlight (2026-08-24)

Signed run
[32673961608](https://github.com/m7madv/otlobli/actions/runs/32673961608)
passed from `b8f05e13d6f68e9a170fc5e419209ec7e6911f64`. Apple delivery UUID is
`39aa64a7-dc63-4895-9fe9-81a9f3ef8838`. Exact `86.230 (1095)` is `VALID` and
`IN_BETA_TESTING` in the internal all-builds group; expected tester state is
`INSTALLED`. App Review submission was false and the public-review step was
skipped. Do not submit publicly until the owner completes physical acceptance
and explicitly asks.

Local artifacts are under
`output/testflight-v86.230-build-1095-run-32673961608`. IPA is `10,460,853`
bytes/SHA-256
`5F886B0D053A076AD85073079CF0152AC9709388DD04D1D575890791788FE049`;
dSYMs are `14,858,947` bytes/SHA-256
`F9E770FA70E87016B652ED3BE34AA1DC38B76DC283D982728BCBFC0F26E58C4D`.

Deployment target remains iOS 15.0. iPhone 6 (not 6s) is incompatible because
it belongs to the iOS 12 device set; iPhone 6s or later is required for this
build. Ask the owner to confirm the exact model and test v86.230 on a compatible
iPhone. No physical acceptance of this new auth/design build is recorded yet.

# Active handoff — v86.230/1095 unified auth and signed Android release (2026-08-24)

Continue only in `C:\Users\MOHAMMAD\Projects\otlobli-v86-212-testflight-auth`
on `codex/otlobli-v86-212-testflight-auth`. Marketing and both native build
numbers are `86.230 (1095)`. Nothing from this batch was published to Apple or
Google stores.

The public identity and auth UI now treat SHEIN and Temu as equal stores. Keep
the Arabic-first two-store route, full-width Google/Apple controls,
WhatsApp-phone alternative, and inline Apple SVG (the old glyph rendered as a
square on Android). Metadata, manifest, onboarding, product fallback, and
order-success copy were also generalized. Visual QA passed at 320, 360, and
430 px widths without horizontal overflow; low-end budgets pass. No store
runtime, WebView lifecycle, SHEIN freeze fix, Temu Back fix, payment, wallet, or
completed-order behavior was intentionally changed.

Android production signing is configured with the dedicated outside-repo key at
`C:\Users\MOHAMMAD\.android\otlobli-main-upload.jks` and matching protected
GitHub secrets. Never print or commit the key/passwords. Public certificate
SHA-256 is
`E0:B0:F4:4C:C6:77:88:8F:95:35:C0:1C:91:25:07:7E:09:B0:14:BD:B9:09:6D:C2:81:3E:3B:D0:6F:17:F7:84`.
Firebase project `otlobli-1ccf5` has this SHA-1/SHA-256 registered for
`com.otlobli.app`, and `android/app/google-services.json` contains the new
Android OAuth client. The existing Android workflow now emits a signed,
optimized production APK/AAB after live auth preflight and artifact checks.

Exact production assets are copied into Android and iOS. Full build and all
release/security/freeze/Temu/store/performance guards pass; CSS is
`69,932/70,000`. Full ESLint exits zero with existing warnings only. Local
signed artifacts are:

- `output/Otlobli-v86.230-Android-Production.apk`, `4,070,937` bytes,
  SHA-256 `544A405F7586B69EFD0882BACC3FB9641CB75658AAC3F930B082800C55294373`.
- `output/Otlobli-v86.230-Android-Play.aab`, `5,720,927` bytes,
  SHA-256 `6D1FC53520684CD1761FC7CD921A1FE78981EA6CFC647D72E2951C56A558A2BD`.

APK package/version/signature, non-debuggable state, production phone/Google/
Apple markers, and absence of web source maps are verified; AAB signature and
content markers verify too. Do not claim physical Android acceptance yet. The
owner must install the APK and test phone OTP, Google, Apple, both stores, and
push; a weak/old Android device performance run also remains. iOS was synced
only—no new iOS archive, TestFlight build, or App Store submission exists.

# Active handoff — APNs real-device send accepted; visual confirmation remains (2026-08-24)

Continue only in `C:\Users\MOHAMMAD\Projects\otlobli-v86-212-testflight-auth`
on `codex/otlobli-v86-212-testflight-auth`. Production now has the dedicated
topic-specific production APNs key `4GGVNXQ9UT` for `com.otlobli.app` plus all
four Supabase secrets. The retained one-time `.p8` is
`C:\Users\MOHAMMAD\Downloads\AuthKey_4GGVNXQ9UT.p8`; never print, commit,
move, overwrite, or delete it. Its SHA-256 is
`82D90432FE29D0C74313AFDFE1D57768C0FEFCA71529DA1394A7CB110357E0BE`.

The initial multiline secret was not usable in the hosted runtime: every user
retry logged `APNs JWT sign failed expected valid PKCS#8 data`. The sender now
normalizes PEM, escaped newlines, and single-line base64; production `APNS_KEY`
is stored as base64 so environment transport cannot corrupt it. The authenticated
probe executed inside Supabase and received the expected `400 BadDeviceToken`
for its fake token. Then one real test targeted only the newest active `86.229`,
iOS 27, production installation and returned APNs `sent=1/1`, zero invalid,
retryable, or failed tokens, with APNs configured. Apple accepted the device
message; wait only for the owner's visual/tap confirmation.

Live functions: `send-push` v19 with `verify_jwt=false`; `admin-orders` v46 with
`verify_jwt=true`. The shared trigger secret was rotated. Full build and all
release/security/freeze/performance guards pass. Preserve strict provider mapping
in `supabase/functions/send-push/routing.ts`; never send iOS tokens to FCM. No
TestFlight rebuild or native sync is needed for this server-only correction.

# Active handoff — production Admin push contract repaired (2026-08-24)

Continue only in `C:\Users\MOHAMMAD\Projects\otlobli-v86-212-testflight-auth`
on `codex/otlobli-v86-212-testflight-auth`. The user physically accepted the
complete `86.229 (1094)` Temu result on iPhone. Do not reopen Temu unless a new
device report appears.

The remaining `invalid_payload` screenshot was caused by Admin's legacy manual
sender omitting the safe push `data` contract introduced by the hardened live
`send-push` function. Both broadcast and phone-targeted Admin messages now send
`version=1`, `type=system`, and `route=notifications`; tapping the notification
therefore opens the safe in-app Notifications screen. Known server errors are
localized. The automatic `admin-orders` sender was also corrected from invalid
`order_status` metadata to `order_update` + `orders/details` + `entityId`.

Admin build and release-service tests pass. Production is live at
`https://talabieh-admin.vercel.app`, deployment
`dpl_Ffk4BRxnC18dNNAGWUY6KjB9ZtBW`, asset `/assets/index-DsatHAQz.js`.
The `274,485`-byte live asset has SHA-256
`D04A7D66F3163532F1A74DF0BAE1EDA6F4F0558CBEF6AF64939EA362BD862749`.
`admin-orders` is deployed as Supabase function version `41` and retains
`verify_jwt=true`. No real push was sent during validation; ask the user to
refresh Admin once and retry the intended message. This was Admin/Edge only, so
no customer version bump or native sync was needed.

# Active handoff — v86.229/1094 Temu Back follows SPA URL changes (2026-08-24)

Continue only in `C:\Users\MOHAMMAD\Projects\otlobli-v86-212-testflight-auth`
on `codex/otlobli-v86-212-testflight-auth`. Marketing is `86.229`; iOS is `1094`
and Android is `1093`. The user physically confirmed the v86.228 SHEIN Qatar
region issue is solved. Do not disturb that three-part policy/region correction.

The remaining recording proves Temu's green native Back appears on first entry,
is correctly absent on a product, then stays absent after returning to the
listing/Home surface. v86.224 hid it in native `didStart` and re-published only
from `didFinish`/`pageshow`. Temu performs this product/Home transition as SPA
history: `WKWebView.url` changes, while those completion/wake callbacks are not
guaranteed. The already-installed URL KVO observer is the exact missing event.

Preserve the v86.229 correction in the Capgo 8.6.25 patch: the `case "URL"`
branch binds the live WebView, emits the existing URL event/interface, and calls
`republishOtlobliNativeBackState(in: webView)`. This is event-driven and adds no
timer, retry, scan, reload, or lifecycle work. The structural store guard requires
the call inside that observer. The patch applies strictly to a fresh dependency;
all production guards/build/budgets, native syncs, Android assembly, and artifact
scan pass. Android artifact/hash and exact budgets are at the top of
`CURRENT_STATE.md`. Signed run
[32667383788](https://github.com/m7madv/otlobli/actions/runs/32667383788)
passed from `de3ae2593ffc5abec0eea6b241153fe780cf2c5f`; Apple delivery UUID is
`02801af5-7936-43de-870f-af8c234194a6`. Exact `86.229 (1094)` is
`VALID`/`IN_BETA_TESTING` in the internal all-builds group, expected tester state
is `INSTALLED`, and public review was skipped. Local IPA is `10,460,323`
bytes/SHA-256 `49DABD543789E8D9DBB21D06FC04F86E8ACC114557D1972AA2B3E5FE24A6ACAE`;
dSYMs are `14,858,947` bytes/SHA-256
`EF7CB71DB6B75FDC2FA484B88FD75D71DCB732955AB22A31D771D404DDCC0C7D`, under
`output/testflight-v86.229-build-1094-run-32667383788`. The user subsequently
physically accepted the complete Temu result on the iPhone, including product →
Back → Home and the returning native Back control.

# Active handoff — v86.228/1093 TestFlight Qatar region/policy repair (2026-08-24)

Continue only in `C:\Users\MOHAMMAD\Projects\otlobli-v86-212-testflight-auth`
on `codex/otlobli-v86-212-testflight-auth`. Marketing is `86.228`; iOS is
`1093` and Android is `1092`. Signed run
[32665947122](https://github.com/m7madv/otlobli/actions/runs/32665947122)
passed from `7dacf04ae6c606f24a222adb91aad2f9ab3b046f`; Apple delivery UUID is
`0de5dbb3-1704-4b9c-bc17-dfa1e1bb9ff5`. Exact `86.228 (1093)` is
`VALID`/`IN_BETA_TESTING` in the `Otlobli Internal` all-builds group, expected
tester state is `INSTALLED`, and public App Store review was skipped.

The exact Desktop Pixel 7/API35 launcher reproduced the problem. Live Admin and
host cache were QA/USD/ar. The old fixed 12s timeout raced the Qatar cascade,
which took 11.8–15.3s to produce a signed Al Daayen/Zone 70 address. Android's
final SHEIN document also lost the document-start policy, so visual readiness
remained `unknown`; simply reinstalling policy then hid the internal cascade
that capture needed. Preserve all three v86.228 corrections together:

- post-load capture bundle idempotently restores the policy engine;
- policy exempts only `.sui-drawer.cascade` while
  `#otlobli-region-switching` exists;
- region repair uses stalled-progress and absolute bounds, not a fixed 12s.

Do not broaden that policy exemption or weaken signed Add/capture readiness.
On the emulator policy stayed at one install/observer, the signed QA address
included `xAdFlag`, a real PDP opened, and `addToCart` captured `iPhone 17` at
`$1.60` without a region error. Interactive browse arrived at 6.6–8.1s while
signed preparation continued. Real SHEIN human verification appeared during
rapid repeated clean opens and was deliberately left untouched.

Full build/guards/budgets, both native syncs, Android assembly, and the
three-root artifact scan pass. Bundle and Android artifact hashes are at the
top of `CURRENT_STATE.md`. `TEST_ONLY_AUTH_BYPASS` is false and temporary CDP
files are deleted. Downloaded iOS artifacts are under
`output/testflight-v86.228-build-1093-run-32665947122`: the IPA is
`10,460,344` bytes/SHA-256
`68F47AA61E8B859D2D7EA8EDA1B1D2394BCD9AA21B0D69F2FD541CA2A9A9F1AA`; dSYMs
are `14,858,923` bytes/SHA-256
`53C81F41932A2F81E200582C0B722AC84CE496756CB7F2A00A4E81C8465DCC30`.
Physical iPhone acceptance has not occurred. Retain the freeze invariant and
perform five real iPhone 16 background/resume cycles plus one
force-quit/cold-launch test before declaring device acceptance.

# Active handoff — v86.227/1092 exact v86.216 region regression boundary (2026-08-23)

Continue only in `C:\Users\MOHAMMAD\Projects\otlobli-v86-212-testflight-auth`
on `codex/otlobli-v86-212-testflight-auth`. Marketing is `86.227`; iOS is
`1092` and Android is `1091`.

The user physically established that v86.216 changes SHEIN region correctly and
v86.217 first broke it; the failure remains in v86.226. Commit `233bc46` removed
the v86.216 short browse-ready continuation during signed-address repair and
added Home-unknown cancellation. The cancellation had already been removed, but
the continuation had not. v86.227 restores the exact `1.8s`/low-end `2.8s`
head-start plus per-path visual/signed readiness, while Add/capture still require
full signed READY. Preserve the guard that forbids
`home-unknown-repair-cancelled` and the explicit-mismatch-only Home rule.

Full build, release/SHEIN guards, unchanged performance budgets, both native
syncs, and Android `assembleDebug` pass. Store bundle is `250,063` bytes/SHA-256
`102B4C016C49E6D6F36EA2AD04D0521048B8DB5C5FA4886325614CFB278B8F0B`.
Android artifact is `output/Otlobli-v86.227-build-1091-Android-debug.apk`,
`11,113,604` bytes/SHA-256
`0DCBC2601DEE34D01F288A4A5D48A72E65EB1AB14256CFE977F2ACEFB3B37528`.
Signed run `32662460797` from `8ce2cce` passed with delivery UUID
`616777a5-f4c9-4b08-a21a-b0f226222d09`; `86.227 (1092)` is
`VALID`/`IN_BETA_TESTING`, all-builds in `Otlobli Internal`, expected tester
state `INSTALLED`, and public review was skipped. IPA is `10,460,026`
bytes/SHA-256 `4484FD3B0313D0885DC5832D581BFE13203F9CB67BB206077B1D11BAACA12960`;
dSYMs are `14,858,923` bytes/SHA-256
`885EE512576461BFDAC3E34009F8066E74FEA4C065B3ADDC1FAEEA2B347E3F42`,
under `output/testflight-v86.227-build-1092-run-32662460797`. Physical acceptance
remains pending. Preserve all lifecycle, navigation, orders, auth, Temu, and
`JSON.stringify` region invariants.

# Active handoff — v86.226/1091 release v86.71 interactive readiness (2026-08-23)

Continue only in `C:\Users\MOHAMMAD\Projects\otlobli-v86-212-testflight-auth`
on `codex/otlobli-v86-212-testflight-auth`. Marketing is `86.226`; iOS is
`1091` and Android is `1090`.

The user physically rejected `86.225 (1090)` because SHEIN remained forever on
«جاري تجهيز المتجر». USB detection confirmed iPhone 16 Pro Max/iOS 27, but
3uTools timed out before syslog. The code cause is proven independently against
accepted `56d1c56`: `sheinPageInteractive` after the bounded repair timeout was
rejected by both React and Swift unless country+signed region were fully
matching. That is stricter than v86.71 and creates an infinite cover.

Preserve the v86.226 correction: visual readiness accepts `unknown` country or
region but rejects explicit mismatch; policy/currency/language/capture/login and
interactive checks remain. Full READY and signed-address checks still gate Add.
No new periodic work or diagnostic UI exists. Complete full build, both native
syncs, Android `assembleDebug`, all release guards, and performance budgets pass.
The synchronized store bundle remains `249,770` bytes/SHA-256
`1EBA8CD8D892D558E1AD4E277B97777E1C8478180C6580D59E235FBF9F38179A`;
the Android artifact is `output/Otlobli-v86.226-build-1090-Android-debug.apk`,
`11,113,448` bytes/SHA-256
`54BF073B97C750EEC7A3C5B28844CCE7CB54226D8EE2A01B802B7AEE86A95055`.
Signed run `32661353655` from `f2c6e1a` passed with delivery UUID
`4ccd7c30-b0db-4c7b-920a-e1028c868f5a`; exact `86.226 (1091)` is
`VALID`/`IN_BETA_TESTING`, assigned to all builds in `Otlobli Internal`, and the
expected tester state is `INSTALLED`. Public review was skipped. The downloaded
IPA is `10,459,918` bytes/SHA-256
`B26A1FF26F4352EC9A91DD45478EA23B5D74B430FA6877CEF86A77C7F3DBE3BB`;
dSYMs are `14,858,923` bytes/SHA-256
`05DB8747EB0606A1355629E82438CB5FECF29B94F2617DC86FB873ACC163D12D`,
under `output/testflight-v86.226-build-1091-run-32661353655`.

The user newly confirmed that v86.213 changed the region successfully. Direct
comparison shows the drawer selection cascade itself is materially retained;
the main post-v86.213 changes are readiness and WebView coordination around it.
Treat v86.226 as the proven infinite-cover correction, then use the physical
result to distinguish “page opens but signed region remains old” from complete
recovery. Never infer device acceptance. Preserve every lifecycle invariant and
the automatic v86.71 region path restored in v86.225.

# Active handoff — v86.225/1090 exact v86.71 server-region restoration (2026-08-23)

Continue only in `C:\Users\MOHAMMAD\Projects\otlobli-v86-212-testflight-auth`
on `codex/otlobli-v86-212-testflight-auth`. Marketing is `86.225`; iOS is
`1090` and Android is `1089`.

The user physically rejected `86.224 (1089)` with both reported failures still
present. The exact old chat was found: after v86.69/v86.70, the one-time runtime
cache refresh in `v86.71` commit `56d1c56` was tested and explicitly accepted
as «كتير كتير ضابطة». Preserve the restored region contract:

- A changed Admin/server SHEIN region marks `sheinCacheResetPendingRef`, closes
  the active store session, calls `InAppBrowser.clearCache()` once on reopen,
  and preserves cookies/localStorage/signed address.
- Product routes and the semantic Home entry may automatically start the signed
  region cascade. Do not restore Home-only/manual-Add gating, visual readiness
  before signed readiness, or automatic country-exhaustion storage.
- Add remains fail-closed. The native cover requires matching country+region,
  while human verification remains visible and untouched.
- Do not reintroduce diagnostics. Preserve `otlobliForceRecompose`, 0.25s,
  Android resume, and the `JSON.stringify` region comparison.

All local release/auth/security/store guards, the full production build, low-end
budgets, both native syncs, and Android `assembleDebug` pass. The synchronized
store bundle is `249,770` bytes with SHA-256
`1EBA8CD8D892D558E1AD4E277B97777E1C8478180C6580D59E235FBF9F38179A`;
the Android artifact and hash are at the top of `CURRENT_STATE.md`. Signed run
`32660285054` from `30f7f8b` also passed Apple validation/upload/processing and
internal distribution for exact `86.225 (1090)`; delivery UUID is
`e5ba3549-a01d-406f-be7a-3495643582db`, the build is
`VALID`/`IN_BETA_TESTING`, and the tester state is `INSTALLED`. Public review
was skipped. Exact artifact paths/hashes are at the top of `CURRENT_STATE.md`.
Device acceptance remains mandatory and must not be inferred. Temu Back was not
changed by this region-only restoration and remains an honestly open issue.

# Active handoff — v86.224/1089 Home-prepared SHEIN + native Temu Back (2026-08-23)

Continue only in `C:\Users\MOHAMMAD\Projects\otlobli-v86-212-testflight-auth`
on `codex/otlobli-v86-212-testflight-auth`. Marketing is `86.224`; locally
validated source is iOS `1089` and Android `1088`.

The user physically rejected `86.223 (1088)`: Temu was somewhat smoother but
still lost its green Back after product -> Home, and SHEIN region behavior was
unchanged. The remembered fast region implementation was located at `9cea927`
(`v86.68`): prepare the signed address through the native semantic entry on
SHEIN Home before browsing products.

Preserve the new architecture:

- Every queued SHEIN PDP cold/warm open starts from Home. Home performs the
  signed Admin-region cascade; `markStoreWebviewReady` consumes the queued PDP
  only after full coordinator readiness. The obsolete Home-skip flag is gone.
- Ordinary product browsing never starts region repair. Explicit Add remains
  the only PDP fallback and stays fail-closed until the signed address matches.
- Capgo iOS republishes native Back state once from `didFinish` after the
  provisional-navigation hide. Keep it event-driven; do not add timer bursts,
  DOM scans, reloads, or a WebView rebuild.
- Temu stable-product scans short-circuit after confirmed identity; removed
  diagnostic/header-wake/forced-scroll code must not return.

All local gates, budgets, both native syncs, three-root artifact scan, and
Android assembly pass. Run `32657648658` from `7b87dc8` also passed Apple
validation/upload/processing and internal distribution for exact
`86.224 (1089)`; delivery UUID is
`941e996f-a127-4dc0-b7d2-77a113988006`, the build is
`VALID`/`IN_BETA_TESTING`, and expected tester state is `INSTALLED`. Public App
Store review was skipped. Exact files, sizes and hashes are at the top of
`CURRENT_STATE.md`. Do not claim physical acceptance until the new build passes
Temu product -> Home Back, first-open SHEIN region + several PDPs/order link,
five resume cycles, and cold launch.
Preserve `otlobliForceRecompose`, the 0.25s `appDidBecomeActive` call, Android
resume defense, and the `JSON.stringify` active-region comparison.

# Active handoff — v86.223/1088 Temu stability + Qatar completion (2026-08-23)

Continue only in `C:\Users\MOHAMMAD\Projects\otlobli-v86-212-testflight-auth`
on `codex/otlobli-v86-212-testflight-auth`. Marketing remains `86.223`; this
superseded source was iOS `1088` and Android `1087`. TestFlight run
`32651898752` delivered it internally, but the user's physical test rejected
both the remaining Temu Back loss and unchanged SHEIN region behavior. No
public App Store action was taken.

The latest ZIP contains the decisive long recordings. Temu (58.538s/3272
frames) shows the native Back present on initial Home, absent after product ->
Home, hashed header tabs flashing during route paint, and repeated content
jumps despite an iPhone 16 Pro Max. SHEIN (39.153s/2348 frames) shows Qatar
already selected and the live drawer progressing through Al Daayen/zone
levels, then being closed at the old 12-second repair timeout. Contact sheets
are under `output/video-analysis-20260823-182417`.

Preserve these corrections:

- `restoreOtlobliNavOnWake()` resets the dedupe key and directly calls
  `ensureBackButton()`; waiting only for the coordinator reproduced the loss.
- Temu header `topTabContainer` hashed `tab-*` cells are hidden at
  document-start. Never restore the scroll-forced cleaner, navigation-forced
  cleaner, or the all-container candidate list. The semantic fallback remains
  throttled, and product-vital consumers share a 240ms measurement.
- SHEIN address parsing accepts a supported country name in
  `addressCookie.value`. Repair is still explicit-Add-only and signed-address
  fail-closed. Timeout is progress-aware (16s stall/36s absolute normally,
  20s/45s low-end), not an unbounded wait.
- The order-product worktree changes are intentional: enter Home/store
  immediately on tap and preserve `orders` as the native Back target.

All full local gates, low-end budgets, native syncs, artifact scan, and Android
debug build pass. Exact sizes and hashes are at the top of `CURRENT_STATE.md`.
Preserve `WKWebViewController.otlobliForceRecompose()`, the 0.25s
`appDidBecomeActive` call, Android `otlobliOnHostResume()`, and the
`JSON.stringify` active-region comparison. Device acceptance remains the
recorded Temu sequence, Qatar zone completion, both order links, five resumes,
and cold launch. Do not claim it from build/simulator checks.

# Active handoff — v86.223/1087 three-path store correction (2026-08-23)

Continue only in `C:\Users\MOHAMMAD\Projects\otlobli-v86-212-testflight-auth`
on `codex/otlobli-v86-212-testflight-auth`. Marketing is `86.223`; iOS is build
`1087`, Android is build `1086`, and the same production bundle is synchronized
to both native projects.

The user's video is decisive: across all 495 frames, Qatar was selected and the
cascade progressed through country, municipality, area, then the empty/loading
zone-number level. The fallback then clicked the visible Qatar header tab and
reset the cascade. `sheinCountryRowsInRoot` now excludes header/cascade tabs,
and broad country fallback is disabled once two or more cascade tabs prove that
selection has progressed. Do not turn this into an eager region repair or
weaken the signed Add-only address gate.

Temu Home Back no longer depends on equality with the first session path.
`otlobliTemuHomeLikeUrl()` recognizes only the root and pure locale roots, and
`otlobliStoreHomeRoot()` feeds the existing native Back state. Products,
search, categories, and channels remain non-Home. There is no new timer,
polling, observer, DOM scan, reload, or listener.

Order details render each product as a semantic full-card button. Same-store
links reuse warm WebContent; cross-store links go through the existing guarded
store switch. The back-target union is now `home | cart | orders`; both iOS
browser implementations emit `backToOrders`, which hides the store and restores
the currently selected tracking screen. Preserve `currentOrderId`, warm-session
opening, group-cart refusal, and the explicit missing-link notice. Payment,
wallet, completed orders, auth, backend, and native lifecycle behavior are out
of scope and unchanged.

All local gates pass: targeted ESLint zero errors/16 established warnings,
TypeScript, full production build and postbuild budgets, SHEIN freeze guard,
Temu/store guards, both native syncs, three-root artifact scan, Android
`assembleDebug`, and Playwright `393x852` visual/accessibility inspection.
Exact budgets and artifact hashes are at the top of `CURRENT_STATE.md`.
Run `32646164142` failed before build/sign/upload because the manually edited
Capgo patch had stale hunk counts. It was regenerated with `patch-package`, and
a fresh `npm ci` plus full build/sync/Android assembly now pass. The signed
TestFlight retry `32646548641` succeeded from `ae9cdad`; delivery UUID is
`0d57c10d-7a8f-447a-8aee-1acfa08debcb`. Exact `86.223 (1087)` is
`VALID`/`IN_BETA_TESTING` in the verified all-builds `Otlobli Internal` group,
with expected tester state `INSTALLED`. Artifact ID `9495120142`, size
`25,118,712`, digest
`sha256:127b87e071cc819c55dfabcc935bf515d08a4113db31e0e3fdd27bac4bd3acc7`.
Downloaded IPA is `10,459,976` bytes with SHA-256
`CC1F0BE1A770EA166BDB65FFCBADB15561BBB571237733D3695E788FC7038574`;
dSYM is `14,858,751` bytes with SHA-256
`8045EECF8D5B5F76D21DF80954986B6861DF2B34F91D9AE348F93AA534E2F335`.
The App Store review step was explicitly skipped. Draft `86.223` remains on
build `1085`; do not link or submit `1087` before physical acceptance and the
owner's missing App Store metadata.

Preserve `WKWebViewController.otlobliForceRecompose()`, its
`appDidBecomeActive` call at `0.25s`, Android `otlobliOnHostResume()`, and the
`JSON.stringify` active-store comparison. Real iPhone 16 acceptance remains:
Temu product -> Home -> green Back, Qatar Add through zone number, both stores'
order links and Back-to-order, five resume cycles, and a cold launch. No real
weak Android test has been performed.

# Active handoff — v86.223/1086 Back and Temu persistence (2026-08-23)

Continue only in `C:\Users\MOHAMMAD\Projects\otlobli-v86-212-testflight-auth`
on `codex/otlobli-v86-212-testflight-auth`. Marketing stays `86.223`; iOS is
build `1086`, Android remains build `1085`, and the production bundle is built
and synchronized to both native projects.

This batch moves both iOS native green Back implementations 14pt down relative
to their prior safe-area position, matching the user's approximate 0.25cm
iPhone 16 request. Preserve the 44x44pt control, 14pt offset, and accessibility
labels. Temu Back persistence is fixed at the actual boundary: WebKit hides the
button during provisional navigation, while a bfcache-restored Home retained
the old `__otlobliNativeBackState` dedupe value and would not publish the same
visible state again. `pageshow`/visible wake now clears only that key; the
existing bounded coordinator re-announces the state. Do not replace this with
reloads, polling, observers, or navigation interception.

The store bar now displays `اضغط مرتين للتبديل` under `الرئيسية` and has a
complete Arabic accessible name. The existing 320ms double-tap behavior stays:
one tap does nothing, two quick taps open the store chooser. Navigation style
version `v86.223.1` upgrades already-mounted bars. Clean install/patch apply,
all release/security/store/Temu/SHEIN guards, TypeScript, production build and
low-end budgets, both syncs, three-root artifact scan, and Android assembly
pass. Exact hashes/budgets are at the top of `CURRENT_STATE.md`. Real iPhone 16
acceptance of button position and Temu's product→Home path is still pending.

Signed run `32642833471` from `692c835` succeeded. Apple `VERIFY`/`UPLOAD`
reported no errors; delivery UUID `eac22189-ddc5-4089-b682-176f60569c10`.
Exact `86.223 (1086)` is `VALID`/`IN_BETA_TESTING` in the verified all-builds
`Otlobli Internal` group, with expected tester state `INSTALLED`. Artifact ID
`9494161426`, size `25,115,824`, digest
`sha256:25c860d4410387f92bc6a42d4b03c61dd338a4bcd0532f6c29685ee642ce992b`.
Downloaded IPA is `10,459,456` bytes with SHA-256
`A7708933F753567509EE80456754BC30797DA698EE0E4A5010227C6C6A3F9AD1`;
dSYM is `14,858,667` bytes with SHA-256
`CA1FF14EB740065CEF6034DE27FF8683E8D4E994C6B2A760A8C460FBF3ABF36D`.
The App Store review step was deliberately skipped; the editable `86.223`
draft remains on build `1085`. Do not link/submit 1086 before device acceptance
and completion of the owner's missing App Store metadata.

The temporary SHEIN flight recorder and every enabling path are deleted:
module/stub/fixture, App state/listeners/imports, Vite env/alias, Workflow
input, injected feature flags, early-protection scans/timer, and old standalone
freeze/tap/price/region probe modules. Do not restore them. Production behavior
is the accepted v86.222 composition: document-start viewport + Otlobli bar,
post-load blockers/capture/session, native-only Back on iOS, SHEIN-owned PDP
navigation, and region repair only after explicit Add with the signed-address
gate unchanged. The consent-based customer support report remains deliberately.

All local gates/build/performance checks, both native syncs, artifact scans, and
Android assembly pass. Exact hashes/budgets are at the top of
`CURRENT_STATE.md`. Preserve `otlobliForceRecompose()`, `appDidBecomeActive`
at `0.25s`, Android `otlobliOnHostResume()`, and the `JSON.stringify` active-
store comparison. Payment, wallet, completed orders, auth, backend, and native
lifecycle code were not changed.

Workflow `ios-unsigned-build.yml` now supports
`app_store_submission=true` with `signing_mode=testflight` and
`testflight_delivery=upload-and-distribute`. It uploads the production archive,
waits for exact build processing, creates/reuses the iOS App Store version,
links the build, creates/reuses a draft review submission, adds the version,
and submits it. If Apple rejects missing metadata/screenshots/privacy/review
information, report the exact API error and leave the processed build/version
in App Store Connect; never fabricate those values. Run `32611345045` uploaded
and processed exact build `86.223 (1085)` and assigned it to internal
TestFlight. Artifact ID `9485690696`, size `25,115,693`, digest
`sha256:56008db6dfbcce1fc84b72bae45b19d3d923f8dc34e0089bd21ac0039eb3cf62`.
Its review step received Apple 409 because an older editable App Store version
already exists. `submit-app-store-review.mjs` now reuses the one
`PREPARE_FOR_SUBMISSION` iOS draft by renaming it to `86.223`, preserving all
store metadata, and replaces only its linked build. It refuses multiple/non-
editable ambiguity and does not delete a draft. Retry review submission with
the already processed build; record Apple's exact next response. Run
`32611795204` performed that safe reuse from `1.0`, linked `1085`, and created
submission `e5e27b8a-b628-4116-b135-361b91266929`, but Apple reported missing
review prerequisites in screenshots, version localization, age rating, app
info/localization, data usage/privacy, app-level details, and price. The raw
field entries were collapsed by Node logging. The submitter now includes the
full nested `associatedErrors`, and `ios-app-review.yml` can inspect/retry
`86.223/1085` in seconds without a new archive or upload. Never invent the
owner's legal/privacy/rating/pricing values to clear these checks.

Final inspection run `32612073248` confirms version `86.223` remains
`PREPARE_FOR_SUBMISSION` with exact build `1085` already linked. Apple requires:
description, keywords, support URL, iPhone 6.5-inch and iPad Pro 12.9-inch
screenshots, primary category, App Review detail/contact record, copyright,
content-rights declaration, published App Privacy/data usages, price,
privacy-policy URL, and all 22 age-rating attributes. Stop and obtain owner
decisions for those values; do not set them speculatively. Then complete them in
App Store Connect and run `ios-app-review.yml` after it is available on the
default branch, or rerun the existing signed workflow with
`testflight_delivery=distribute-existing` and `app_store_submission=true`.

Apple delivery UUID `98370121-bfc3-4e6e-943c-90ceaad9021b`; App Store version
ID `a03a0acc-2555-44aa-accd-78429a3e6a39`; review submission ID
`e5e27b8a-b628-4116-b135-361b91266929`. Accepted IPA: `10,458,318` bytes,
SHA-256 `1EDA4263A97F496E2FDB594E1395E0D297E5D84A1E90B3E110BC220E65F1B0EC`.
dSYM: `14,858,055` bytes, SHA-256
`268DC270242E1DE5C38831158ADDC791A4D6C5C46DEC8845E3392ABBA1BE6057`.

The user's functional acceptance is recorded, but no explicit evidence was
provided for five iPhone 16 resume cycles plus separate cold launch or a real
weak Android device. Do not claim those checks were performed.

# Active handoff — v86.222 safe navigation candidate (2026-08-23)

Continue only in `C:\Users\MOHAMMAD\Projects\otlobli-v86-212-testflight-auth`
on `codex/otlobli-v86-212-testflight-auth`. Source is `86.222/1084` and the
diagnostic build is synchronized to Android and iOS. It has passed local gates
and internal TestFlight delivery but is not accepted on a real device.

Treat the user's v86.221 result as authoritative. N6 was the first consistent
failure and is the proven list-to-PDP spinner trigger: document-start ran
bottom-nav/native-Add/signup scans every 250ms before SHEIN readiness. The
bootstrap now returns false for `navigationEarlyProtection` before any flag
lookup; App/customer/diagnostic defaults and normalization also force false.
Do not re-enable N6. Post-load blocker work remains fully present.

N4 also correlated with an intermittent SHEIN system-error Home that Retry
recovered. iOS `ensureBackButton()` now sends native state and returns before
creating `#otlobli-back-btn`; Android/no-native-handler retains the HTML button.
Preserve native root exit and product Back. R1 was contaminated by N6, so the
new R1 is independent. Product browsing no longer authorizes region drawer,
`location.replace`, history normalization, or native `setUrl`; explicit Add
still calls `ensureSheinSaudiStore(true)` and remains fail-closed on the signed
address. Do not weaken the Add gate.

All exact hashes, budgets, APK, and screenshot are at the top of
`CURRENT_STATE.md`. TypeScript, guards, both builds, Playwright, native syncs,
and Android assembly pass. No native lifecycle, payment, wallet, orders, auth,
or backend code changed. Signed run `32608307685` passed from `35bcaeb`;
delivery UUID `e0e18aeb-3fd0-4362-9602-f9ec451e8227`, exact build
`86.222 (1084)` is `VALID`/`IN_BETA_TESTING` in `Otlobli Internal`, expected
tester state `INSTALLED`, and signed IPA SHA-256 is
`D964F2E4264D87EC1750F2E5BE2C505D159FBEBD097CE0255E6AC367EF51CB7C`.
No public distribution occurred. After device install: cold Home, several products on N5, product/Home native Back, then R1
and one Add. Five resume cycles and a cold launch remain mandatory before any
fixed/release claim.

# Active handoff — v86.221 navigation flight recorder (2026-08-23)

Work only in `C:\Users\MOHAMMAD\Projects\otlobli-v86-212-testflight-auth` on
`codex/otlobli-v86-212-testflight-auth`. Source is `86.221/1083`, synchronized
to Android and iOS as an internal diagnostic build. It is not physical-device
acceptance or a production fix.

The user installed v86.220 and reproduced the same PDP spinner. Therefore do
not repeat its exact-cause claim: disabling the broad Navigation group proved
the trigger is somewhere inside that group, but removing only the product tap
fallback/chunk bridge did not fix it. The retained candidates are viewport,
runtime bar paint, bar touch bridge, Back state, document-start bar mount, and
the bounded early protection scan.

The v86.221 panel must be tested in order: N0 proven-safe composition, N1
viewport, N2 bar painting, N3 bar touch, N4 product Back, N5 early mount, N6
early protection, then R1 session/region. For each, open one product and press
`فتح المنتج` or `بقي يحمّل`; stop at the first failure and use
`نسخ التقرير الكامل`. The four live journey nodes distinguish no product tap,
no URL transition, document load without PDP paint, and a completed PDP. State
is bounded and persisted in the Otlobli host; never move it into SHEIN storage.

Preserve the granular gates. In customer builds absent granular flags inherit
the broad Navigation flag, so production behavior is unchanged. In diagnostic
builds `navigationViewport`, `navigationBar`, `navigationTouch`,
`navigationBack`, `navigationEarlyMount`, and `navigationEarlyProtection` are
independent. The session-interaction fast branch must respect
`navigationBar`; this removes the old visually painted but inert bar when
Navigation is off. Do not add history wrappers, synthetic clicks, recurring
timers, reloads, or new native recovery.

All local guards/builds, WebKit fixture, both native syncs, and Android assembly
pass. Exact budgets, synchronized asset hashes, and APK path/hash are at the top
of `CURRENT_STATE.md`. The customer build contains no flight-recorder markers.
Preserve `otlobliForceRecompose`, `appDidBecomeActive` at 0.25s, Android resume,
the JSON-stringified active-store comparison, payment/wallet/orders/auth, and
all performance budgets. Signed run `32606619539` from `dfc8d5a` passed Apple
validation/upload and verified exact `86.221 (1083)` as
`VALID`/`IN_BETA_TESTING` in `Otlobli Internal` with the expected tester
`INSTALLED`; delivery UUID is `048fe33e-90b2-44d8-8db9-432234e0fe33`.
Signed IPA SHA-256 is
`FA3DBA27FE713D5364190F48024CE870701C20740A22C33EE4D59852538C4509`.
No public submission occurred. Physical N0-N6/R1 acceptance is pending.
Future internal uploads use `ios-unsigned-build.yml` with
`signing_mode=testflight`, `store_script_diagnostics=true`, and
`testflight_delivery=upload-and-distribute`; never enable public distribution.

# Historical handoff — v86.220 product navigation ownership (rejected 2026-08-23)

v86.220 removed the global product touch fallback/chunk bridge and made region
repair exhaustion country-session scoped. Signed run `32604307896` delivered
exact `86.220 (1082)` to the internal group; Apple status and tester
installation were verified. The user then reproduced the same PDP spinner, so
the candidate is physically rejected and its exact-cause claim is superseded.
Do not restore the removed fallback/bridge, but do not assume they caused the
failure. Use v86.221 N0-N6 evidence to classify the retained Navigation
sublayer. No public submission occurred.

# Active handoff — v86.219 diagnostic native-cover correction (2026-08-23)

Work only in `C:\Users\MOHAMMAD\Projects\otlobli-v86-212-testflight-auth` on
`codex/otlobli-v86-212-testflight-auth`. Current source is `86.219/1081`.
Physical iPhone feedback rejects v86.218 as an isolation artifact: the user saw
only Otlobli's native `جاري تجهيز المتجر…`, so stage A and the raw PDP were
never observed.

Do not change the native safety gate. The v86.218 panel signal reached React,
but A-C intentionally lack the full coordinator payload required by the native
cover. v86.219 sets `otlobliLoadingCover` false only when the explicit internal
diagnostic build lacks runtime or session; A-C therefore show directly. D and
all marker-free customer builds retain the exact existing cover. The freeze
guard locks the expression. No native code, coordinator, session, region,
blocking, capture, privacy compatibility, navigation, auth, payment, wallet,
orders, lifecycle, recompose timing, or JSON region equality changed.

Normal and diagnostic builds/artifact scans, performance budgets, TypeScript,
guards, both native syncs, and Android `assembleDebug` pass. Exact measures and
APK hash are at the top of `CURRENT_STATE.md`. Signed run `32600407694` from
`997baeb` passed Apple validation/upload; delivery UUID is
`9824804a-63a3-4f85-9fcd-c69371869671`. The same run verified exact build
`86.219 (1081)` as `VALID`/`IN_BETA_TESTING`, internal all-builds group
`Otlobli Internal`, and expected tester state `INSTALLED`. Signed IPA SHA-256
is `A873B2C64EAF44F630114CCC58B222344ACE07D1875FEA9A18D2E28980E03F47`.
No public submission occurred. The next physical result must first confirm A
is visible; only then does raw PDP behavior classify the underlying failure.

# Active handoff — v86.218 SHEIN A-D isolation (2026-08-22)

Work only in `C:\Users\MOHAMMAD\Projects\otlobli-v86-212-testflight-auth` on
`codex/otlobli-v86-212-testflight-auth`. Current code is `86.218/1080`. This is
an internal diagnostic candidate following the user's physical rejection of
`86.217/1079`; do not describe the product spinner or region loop as fixed.

The build starts with A: normal SHEIN runtime, navigation, blocking, capture,
and session/region are all off. The mandatory bounded privacy compatibility and
small `فحص`/painted-page bridge remain so the raw page is visible and the user
can exit. From the panel select B (capture only), C (capture+blocking), then D
(full navigation+session/region). Each stage closes/reopens one WebView without
clearing persistent SHEIN website data or human-verification proof. Test the
same product at every stage and stop at the first failing stage.

Preserve the production separation: `vite.config.ts` aliases the diagnostic
module to `storeScriptDiagnosticsDisabled.ts` unless
`VITE_STORE_SCRIPT_DIAGNOSTICS=true`. A normal build must contain neither
`otlobli-script-diagnostics` nor `storeScriptFlagsChanged`; the internal build
must contain both. The iOS workflow input is `store_script_diagnostics` and
must be true only for this internal A-D artifact.

All protected business/runtime sources remain unchanged. Preserve the native
iPhone recompose, 0.25s timing, Android resume defense, WebView ownership,
`JSON.stringify` region equality, payment/wallet/orders/auth, and v86.217's
live-only verification behavior. Local normal+diagnostic builds, guards,
Playwright, both syncs, and Android build pass. Budgets/hashes/artifact details
are at the top of `CURRENT_STATE.md`.

Signed upload run `32598213562` from `0bd6b14` passed Apple validation/upload
with delivery UUID `9527dd4a-cf31-46f7-8e98-25d29678e6f8`. App Store Connect
verification run `32599164674` from `79154c3` proves exact build
`86.218 (1080)` is `VALID` and `IN_BETA_TESTING`, `Otlobli Internal` is an
internal all-builds group with no public link, and the expected tester is a
member with state `INSTALLED`. The workflow's default TestFlight lane now
uploads and ensures this internal distribution; `distribute-existing` verifies
an already uploaded exact version/build without uploading again. The first API
attempt `32598963318` produced a false-negative tester relationship and was
corrected to verify the authoritative group-member list. No public App Store
submission occurred. Real-device acceptance is still unperformed.

# Active handoff — v86.217 live challenge + v86.213 region gate (2026-08-22)

Continue only in `C:\Users\MOHAMMAD\Projects\otlobli-v86-212-testflight-auth`
on `codex/otlobli-v86-212-testflight-auth`. Current source is `86.217/1079`,
built and synchronized to both native projects. It has not been signed or
uploaded; require exact approval naming `86.217/1079` before TestFlight.

Use the exact historical boundary, not an old branch copy: v86.214 is
`04d274fcc834125facb66f0dca703c2c44785493`, parent v86.213 is
`5a2788ccb7515cce93ee9ded102e6635dfc4ac0a`. Blocking and product extraction
did not change in that transition. v86.214 added an early visual-ready release
while native address repair continued. v86.217 removes only that pre-region
release and keeps an active product cascade covered until signed readiness or
the existing 12-second timeout. Home with unknown/absent address no longer
starts/restarts the drawer; a real admin country mismatch and an unsigned PDP
still repair.

`sheinHumanCheck.ts` no longer persists a 15-minute marker, mounts a guide,
removes Otlobli nodes, unlocks drawers, or mutates body overflow. The detector
only observes a live visible/URL challenge. The single existing coordinator
pauses while it is present and calls `otlobliResolveHumanChallenge()` as soon as
it is absent, without waiting for `sheinPageLooksInteractive()`. This removes
the spinner-as-sticky-verification deadlock while leaving the store's challenge
entirely user-controlled.

Do not alter capture to continue this fix. Product extraction, message schema,
blocking rules, scheduling cadence/order, JSON store-region equality, protected
native recompose/resume, payment/wallet/orders, and auth are unchanged. The
audited coordinator hash is
`42F9A1282956DDBF91D44AC0FED7F4727BFD3D240F66DBA86CBF8C3CC0AC5F6B`.

Fresh lint, diff check, full build/all guards, performance budget, both native
syncs, and Android `assembleDebug` pass. Budgets: startup `657,198`, JS gzip
`267,929`, CSS `69,990`, shipped store scripts `240,400`, source `567,685`.
Android artifact `output/Otlobli-v86.217-Android-debug.apk` is 11,117,996 bytes,
SHA-256 `7A962975B923BAAF4BF5E599F1CDEF63D080C2843910CCDCD1A714F2A61BA5CC`.
The same store bundle hash is present in web/Android/iOS and has no persisted
challenge marker or guide. Unsigned iOS run `32567462720` passed from
`233bc4666eb3eb5d6d7259f1239335b6cd223d9d`. Artifact `9474493487`,
`otlobli-ios-v86.217-ipad-iphone-universal`, is 6,458,996 bytes, digest
`sha256:3def52542d77c84105c9ef5d9b004a49301d429575d9a746012a6af4812fd974`.
Downloaded unsigned IPA is 6,568,085 bytes, SHA-256
`3C272E70EFBD109304C6E917588000517AF832D0FF5051586D6D5791DDC6B17F`.
Inspection confirms `86.217/1079`, universal device family, current repair
markers, and no app provisioning/signature. All signing and TestFlight steps
were skipped. Real-device acceptance remains pending; never infer acceptance
from local/CI checks.

# Active handoff — v86.216 warm-recovery/region-loop correction (2026-08-22)

Continue only in `C:\Users\MOHAMMAD\Projects\otlobli-v86-212-testflight-auth`
on `codex/otlobli-v86-212-testflight-auth`. Current source is `86.216/1078`,
built, synchronized, signed, and uploaded with the user's exact approval.
Run `32551873565` succeeded from
`3f92cc51c64629d7990a34e3f6de42c46b456be8`; Apple validation/upload had no
errors and delivery UUID is `b38a9b39-ae06-46e1-8610-3b85bbc9c74f`.
App Store Connect shows the processed build as `Testing` in `Otlobli Internal`
with 1 tester and 4 builds. Tester `mhm1981dx@gmail.com` is present; its device
still reports Installed `86.215 (1077)` until the user updates. No production
App Store review submission was made.

The user's 34.92-second iPhone recording physically rejects `86.215/1077`.
It shows the shipping area selected successfully, the drawer closed and then
automatically reopened/reselected, while the earlier product spinner remains.
Do not describe v86.215 as accepted.

Root cause: the v86.215 recovery opened Home but held the PDP until full signed
region readiness. Home reached visual readiness only, so the queued product was
never navigated. The session coordinator then opened the Home shipping cascade;
after its bounded timeout it closed it, but later allowed the same route to start
again. In addition, chunk correlation accepted a failure up to ten minutes old
and armed the physical-tap timestamp only inside the 500ms fallback.

Fix: recovered Home skips automatic Home-region repair and navigates the queued
PDP as soon as its policy-safe visual state is ready. A timed-out automatic
region repair is exhausted for that country/path until route/state change. Tap
state is armed immediately at validated `touchend`; chunk recovery requires the
failure to occur after the same tap and both timestamps to be within 15 seconds.
Executable guard cases reject stale listing failures and earlier sent failures.

The implementation adds no timer, polling, observer, DOM scan, WebView,
lifecycle mutation, or persistent React state/render. It uses a ref for the
transient warm-Home handoff. Protected detach/reattach, `appDidBecomeActive`
0.25s recompose, Android host-resume defense, `JSON.stringify` region equality,
transaction gates, payments, wallet, and orders remain untouched.

Fresh freeze guard, TypeScript, targeted ESLint (zero errors), diff check, full
build, both native syncs, and post-sync Android `assembleDebug` pass. Budgets:
startup/largest JS `657,198`, total JS gzip `268,868`, CSS `69,990`, fonts
`81,364`, shipped store scripts `243,384`, source `568,240`; no limit changed.
Android artifact `output/Otlobli-v86.216-Android-debug.apk` is 11,120,845 bytes,
SHA-256
`FEFE572388DB1E830A0EA7C2B82020885576E875B6ADBAC64D82717BBAF7257D`.

Unsigned iOS run `32540635518` passed from
`7f016862fda486bbd583c085ff78b1cf8da5183d`; production assets, version
`86.216/1078`, and universal iPhone/iPad checks passed while all signing and
TestFlight steps were skipped. Artifact `9466944399`,
`otlobli-ios-v86.216-ipad-iphone-universal`, is 6,459,819 bytes with digest
`sha256:c947c6561904c3956c7dc7e383a9429e79d1651f42400969f972aff49e386d04`.
Downloaded IPA at
`output/otlobli-ios-v86.216-unsigned-run-32540635518/otlobli-ios-v86.216-ipad-iphone-universal/otlobli-v86.216-ipad-iphone-universal-unsigned.ipa`
is 6,568,990 bytes, SHA-256
`A0F5F15BF3EAC6CE1737CDF9DC79868EBB2C6AB1873124485E69D7D500393265`.
The first approved signed run `32551772188` safely stopped before signing on a
disconnected WhatsApp sender. Oracle session `0` was reconnected from stored
credentials through its protected localhost endpoint without a message or QR;
all live auth readiness fields passed before retry. Signed artifact
`9470342666`, `otlobli-ios-v86.216-build-1078-testflight`, is 25,120,826 bytes,
digest
`sha256:9778761428db6fc73d74a3be0142d71bfb4f6dac730ebc835c37f6ecdaa9313b`.
Downloaded signed IPA at
`output/otlobli-ios-v86.216-testflight-run-32551873565/otlobli-ios-v86.216-build-1078-testflight/otlobli-v86.216-build-1078-testflight.ipa`
is 10,463,515 bytes, SHA-256
`65417017ECAF9886142F0DF6FD24F81C701BDACB5D9AF5DE861AED98716FAC34`.

Real acceptance is pending: update through TestFlight, open the same PDP without
a region loop, then perform five real iPhone 16 background/resume cycles and a
separate cold launch. Do not infer acceptance from build, CI, simulator, or
portal status.

# Active handoff — v86.215 recorded-tap recovery (2026-08-22)

Continue only in `C:\Users\MOHAMMAD\Projects\otlobli-v86-212-testflight-auth`
on `codex/otlobli-v86-212-testflight-auth`. Current source is `86.215/1077`,
built, synchronized, signed, and uploaded to TestFlight. Run `32538654061`
succeeded from `6246ca88a1c92470b964e5eaac610ad4dc4ca8b3`; Apple validation and
upload had no errors, delivery UUID `d2d4a5d0-a03b-4a17-be81-3e13de802dea`.
App Store Connect app ID is `6804052538`. The build is in `Otlobli Internal`,
and the tester row shows Installed 86.215/1077 on iPhone 16 Pro Max / iOS 27.
No production App Store review was submitted. Real product/lifecycle acceptance
remains pending.

The exact internal tester `mhm1981dx@gmail.com` installed 86.214/1076 on iPhone
16 Pro Max / iOS 27 and reproduced the same product spinner. Do not describe
v86.214 as accepted. Its missing edge was that a `ChunkLoadError` could be
recorded after touch but before SPA changed the path. The 500ms tap callback
never called its own stored-error helper and treated the later PDP URL as
success. v86.215 calls that helper once before route classification. A hit uses
the existing iOS-only/60-second/cache-only recovery; a miss is unchanged.

After recovery, SHEIN now opens Home first and retains the queued product until
Home is verified, then navigates inside the same WebView. This matches the
proven Temu→SHEIN recovery and avoids a cold deep PDP immediately after cache
clear. No new timer/polling/observer/DOM scan/WebView/lifecycle work was added;
region and add-to-cart gates remain unchanged.

Fresh `npm run build`, every pre/post guard, unchanged performance budgets,
Android/iOS sync, and Android `assembleDebug` pass. Android artifact:
`output/Otlobli-v86.215-Android-debug.apk`, 11,119,208 bytes, SHA-256
`1D51B3FCB043F63D8A4437BBF81D6A81DEB52788EDBDCF0E6D5B54AF060B5EFA`.
Unsigned iOS run `32538249134` passed from
`05b81a11ab62a836e119d04a3500768dd69cc38f`. Artifact `9466159129`,
`otlobli-ios-v86.215-ipad-iphone-universal`, is 6,459,712 bytes with digest
`sha256:55580f7a74a4b64e7069a8fd8d134388136ef0bd65ccf97c18aedb100c2b1fbb`.
Downloaded unsigned IPA is 6,568,807 bytes, SHA-256
`272C92DB84FB826140D5687A2098D03923731A3CE5F6BF7C5BCA4B800BC2FD0B`.
Signing/TestFlight steps were skipped in that unsigned run. Real-device product
and lifecycle acceptance remains pending.

Signed artifact `9466326356`,
`otlobli-ios-v86.215-build-1077-testflight`, is 25,120,544 bytes with digest
`sha256:a8547ae98c6e3d09c7dd95cca5e10d27c017918a39409d7ee08675a68e0eb033`.
Downloaded signed IPA is 10,463,303 bytes, SHA-256
`340462372D7218E27FCAF3F5AF4DC062DD245DCA11F8D3C4EB18D8F04AB65402`.

The approved v86.214 upload run `32536820362` succeeded after run
`32536442526` safely stopped pre-signing on a disconnected WhatsApp sender.
The Oracle sender was reconnected from stored credentials without a message or
QR and the live release preflight passed. Artifact `9465796159` is named
`otlobli-ios-v86.214-build-1076-testflight`, size 25,120,684 bytes, digest
`sha256:eea4363706e2ddc1a9a6290f6187f7eacbdfff786d51f28cb3995309eaaedb9a`.
Signed IPA is 10,463,262 bytes, SHA-256
`11730844FAC50BCF86C2D055D551827B3CBB90E3B954EEFBA74C4A6D91880DC9`.
Apple upload UUID is `9c84ea82-e074-4a98-a2ba-20069d732600`; group
`Otlobli Internal` has 2 builds/1 tester and shows Installed 86.214/1076. No
App Store production review submission was made.

Apple Team is `36D743K87T`. Services ID `com.otlobli.app.signin` is saved with
the Supabase domain and exact Apple callback. Active SIWA key ID is
`FAMAKDMKT6`; the old unusable `Y8K8B23VK6` remains. Distribution certificate
ID is `9G84PQ34US`; App Store profile ID is `J8UJBNN6S8`, UUID
`ade603b0-8cd9-42e1-8883-a39aea1c9cb1`, expiring 2027-08-22. The only revoked
resource was unusable Distribution certificate `K99MT75HDF`, after proving its
downloaded certificate had no matching retained private key.

Future signing material is retained under ACL-restricted
`C:\Users\MOHAMMAD\Documents\Otlobli Apple Signing 2026`: new SIWA `.p8`,
Distribution private key/certificate/P12, DPAPI-protected P12 password, and App
Store profile. Never print, commit, move to the repository, or overwrite these
files. Matching GitHub Actions secrets and exact Supabase Apple secrets are set.
Live iOS and Android Apple configuration checks both return `configured=true`.

Successful TestFlight workflow is `32530248241` from commit
`a98b9b8e4e984e7928811029d98874b29cbeae18`. Artifact `9463720205` is named
`otlobli-ios-v86.213-build-1075-testflight`, has size 25,117,598 bytes and
GitHub digest
`sha256:fe8d5e310f80d406005b3426bf9ca883bfb6b2437fa0c2df7abc0627f859642b`.
The earlier run `32529401241` is superseded; it safely stopped on preflight and
Apple validation issues and did not upload a bad IPA.

The last source adjustment makes iPhone portrait-only while declaring all four
iPad orientations required for multitasking. `Info.plist` also declares
`ITSAppUsesNonExemptEncryption=false`. Local `npm run build`, all release/auth/
SHEIN/Temu/store/performance guards, iOS Capacitor sync, and `git diff --check`
pass. Do not change the protected SHEIN lifecycle/recompose, store routing or
capture, orders, payment, or wallet for follow-up TestFlight work.

The hardened phone server and Supabase functions remain deployed. The WhatsApp
sender was reconnected from stored credentials without a message or new QR so
the TestFlight preflight could pass; its live connected state is time-sensitive
and must be checked again before any later upload.

Still unverified: real iPhone/Android login for all three methods, weak Android
acceptance, all v86.215 physical behavior, five real iPhone 16 background/resume
cycles, and a separate force-quit/cold-launch test. v86.214 list→product is
explicitly rejected. Report these honestly; builds and portal status do not
prove device acceptance.

# Active handoff — v86.212 internal TestFlight authentication (2026-08-21)

Continue only in `C:\Users\MOHAMMAD\Projects\otlobli-v86-212-testflight-auth`
on `codex/otlobli-v86-212-testflight-auth`, based on
`bf654a1a84d379e1f7b2fcb8f8e0c98faa5765d3`. Version/build is `86.212/1074`.
No TestFlight upload, App Store Connect record, Apple distribution resource,
backend deployment, or invitation has happened. Google portal configuration
did change on 2026-08-21: `mhm1981x@gmail.com` is the verified sole human Owner
of `otlobli-1ccf5`, and former owner `djjd19903@gmail.com` was removed only after
the new owner opened IAM, Credentials, and Firebase successfully.

The user wants installation through Apple's TestFlight app/email—not Sideloadly.
Do not submit to App Store review. Ask for explicit confirmation immediately
before registering Apple resources, uploading a build, or sending invitations.
The Apple account chooser already works; live `apple-auth` returns 503
`apple_auth_not_configured`. The backend/portal secrets are the blocker.

Current code supports phone/WhatsApp, Google, and Apple on iOS and Android with
fail-closed configuration. Apple accepts iOS bundle ID `com.otlobli.app` and
Android Services ID `com.otlobli.app.signin`; callback is exactly
`https://dcicqdprtyhwmhegabay.supabase.co/functions/v1/apple-oauth-callback`,
returning to `otlobli://apple-auth`. Google iOS uses the new iOS OAuth client for
native configuration but the Web server client is the token audience, so both
must remain in `GOOGLE_CLIENT_IDS` and in TestFlight preflight. This is now
configured: `Otlobli iOS` uses Bundle ID `com.otlobli.app`, Team ID
`36D743K87T`, and client ID
`677396296147-n3337ehkgd51rt47dru8i9lle82in66q.apps.googleusercontent.com`.
GitHub secret `VITE_GOOGLE_IOS_CLIENT_ID` was set at
`2026-08-21T19:20:36Z`; Supabase secret `GOOGLE_CLIENT_IDS` was updated at
`2026-08-21T19:20:39.112Z` with Web+Android+iOS audiences. Values were not
committed. Google sign-in still requires a new build and real-device acceptance.
A live invalid-token call to the deployed `google-auth` function returned HTTP
`401 invalid_google_token`, proving configuration is active after the allowlist
update. The production phone mode is only `real`; mock is DEV-only and inbound
is disabled.

Do not deploy the old WhatsApp backend. The current live `/health` lacks the new
readiness contract and reports a disconnected sender. Deploy the hardened
`server/` with a persistent Baileys credential volume, a random
`OTP_HASH_SECRET` of at least 32 characters, Supabase service-role credentials,
and protected admin/session operations. Rotate the old exposed admin PIN and
re-pair the sender. CI requires `status=ok`, `whatsappConnected=true`,
`sessionStoreReady=true`, `authContract=customer-session-v1`,
`otpSecurityReady=true`, and `whatsappSenderReady=true`.

Before TestFlight, apply timestamped migrations through
`20260821193000_harden_identity_rpc_permissions.sql`; deploy current
`google-auth`, `apple-auth`, `apple-oauth-callback --no-verify-jwt`, and
`account-lifecycle`; configure Apple/Google secrets; create distribution signing
material and the App Store Connect record; then run the registered iOS workflow
with `signing_mode=testflight`. The exact authoritative checklist and secret
names are in `docs/final-enablement/MANUAL_PORTAL_ACTIONS.md`.

Fresh dependency install, production and Admin builds, all protected
store/release/performance/auth guards, Capacitor iOS/Android sync, Android Java
compile, four Deno Edge checks, three workflow YAML parses, 30 Bash syntax
checks, 13 Python heredoc parses, and `git diff --check` pass. Full lint has zero
errors and 18 existing warnings. Never touch the protected SHEIN recompose,
capture, blocking, region, store routing, orders, payment, or wallet paths for
this auth task.

Treat v86.212 as internal-test only. App Store submission remains blocked on a
separate durable Apple revocation/deletion concurrency design and an approved
retention/anonymization policy for transactional personal data.

# Active handoff — v86.211 orders sizing and Apple development signing (2026-08-21)

Continue only in `C:\Users\MOHAMMAD\Projects\otlobli-v86-211-orders-apple` on
`codex/otlobli-v86-211-orders-apple`, based on v86.210 HEAD
`ec0d76bdbaf5bda0cd305ad6ac97f9a031085922`. Version/build is `86.211/1073`.

The order footer clipping shown on the physical iPhone is fixed at the Grid
track owner: `.mobile-content--orders` now has `grid-auto-rows:max-content`.
Do not replace this with fixed card heights or remove shared `overflow:hidden`.
The guard, production build, all budgets/guards, lint, native sync, and 430x932 +
320x568 visual QA pass; measured footer clearance is 14.8px and cards do not
overflow. Order/payment behavior is untouched.

The user explicitly approved the Apple account actions. Exact App ID
`com.otlobli.app` now exists with Push Notifications and primary Sign in with
Apple. Team ID is `36D743K87T`. The new matching Apple Development certificate
and profile `Otlobli v86.211 Development` expire August 21, 2027; the profile
contains both registered iPhones. Its App ID, Team ID, development APNs,
Apple-Sign-In `Default`, devices, and certificate match were verified without
logging device identifiers. The old incorrect
`com.otlobli.app.36D743K87T` App ID was not modified.

The encrypted development P12/password/profile, Team ID, and a one-way target
device UDID fingerprint are present only in GitHub Actions secrets with separate
`IOS_DEVELOPMENT_*` names. Never commit or print these values, private keys,
profiles, passwords, or raw UDIDs. The existing
registered iOS workflow now supports a manual `development-signed` mode. It uses
an ephemeral keychain and temporarily scopes the profile/team/identity to the App
target inside the disposable runner checkout, avoiding Swift Package profile
contamination without changing the committed Xcode project. It overrides only
the signing-time APNs entitlement to `development`, exports one IPA, validates
all effective
Apple entitlements, intended-device membership, and binary metadata, then
restores the runner keychain state and cleans every temporary signing asset.
GitHub run `32492834328` succeeded from commit
`ce62ce214c0da2c158916ced6d4a58022d5e483d`; signed artifact `9450517773`
is `86.211/1073`, arm64, universal, iOS 15+, SHA-256
`13E3B3C5791167ED780E9710288217E63F08D544BFA360DA6DFACCB16F76C845`.
CI cryptographically verified its signature, profile/certificate membership,
Team ID, effective entitlements, intended-device membership, metadata, and
architecture. Local archive inspection independently matched the SHA-256 and
confirmed the embedded profile, code-signature resources, Bundle ID, version,
minimum iOS, device families, and arm64 executable. The exact downloaded file is
`C:\Users\MOHAMMAD\Desktop\otlobli-ios-v86.211-development-signed-run-32492834328\otlobli-v86.211-build-1073-development-signed.ipa`.
Install it directly; never pass it through a re-signing step because that can
strip or replace the Apple entitlement/profile. Apple login must not be called
fixed until this exact IPA succeeds on the physical iPhone. Google remains
separate: GitHub still lacks `VITE_GOOGLE_IOS_CLIENT_ID`, so the iOS Google
action remains hidden in this build.

# Active handoff — v86.210 exact bar copy and auth blockers (2026-08-21)

Continue only in `C:\Users\MOHAMMAD\Projects\otlobli-v86-210-ui-auth` on
`codex/otlobli-v86-210-ui-auth`, based on v86.209 HEAD
`7024ac56d603aedd3a52e0c82b7d13d88a498e62`. App version/build is
`86.210/1072`; this is a physical-test candidate, not an App Store release.

The user accepted v86.209 navigation behavior but saw the bar change appearance
during SHEIN loading. Source inspection proved the transient iOS bar used SF
Symbols while the permanent bar used custom Otlobli SVGs. The native loading bar
now draws the same four paths and copies the existing size, colors, typography,
spacing, indicator, safe-area footprint, and stable pressed appearance. It is
not a redesign. Order cards expose `رقم الطلب` at the lower physical-left beside
Reorder; browser QA at 320x780 and 360x800 showed the full sample ID. Preserve
all v86.209 Temu exit, single/double Home, and interactive-loading behavior.

Do not call Apple or Google fixed. v86.209 run `32483692145` built unsigned,
without `embedded.mobileprovision`; its `Info.plist` also lacked `GIDClientID`
because `VITE_GOOGLE_IOS_CLIENT_ID` was empty. Current GitHub secrets contain no
Google iOS client and none of `APPLE_TEAM_ID`,
`IOS_DISTRIBUTION_CERTIFICATE_BASE64`, `IOS_CERTIFICATE_PASSWORD`, or
`IOS_PROVISIONING_PROFILE_BASE64`. Apple error 1000 is therefore a signing/
entitlement failure; v86.210 only replaces the raw technical toast with the
exact corrective Arabic message. Create the bundle-bound Google iOS OAuth client
and a real Apple profile containing Sign in with Apple before auth acceptance.

Local `npm ci`, production build, all release/store/freeze/performance guards,
TypeScript, lint, and iOS/Android sync pass. GitHub/Xcode run `32487355586`
compiled code commit `b543b1c102636c7c98e8027692566f31e7059dfc`; artifact
`9448456832` is an unsigned arm64 universal IPA with Bundle ID
`com.otlobli.app`, version/build `86.210/1072`, and iOS 15 minimum. SHA-256 is
`D46ACEB3127F9BC866C695280D506DF0554FE7EF5F5D87C28847A107888E0149`.
Inspection reconfirmed there is no signature, provisioning profile,
`GIDClientID`, or Google callback. Physical acceptance must compare the loading
and permanent bars, confirm the full order number at the lower left, and
separately retest auth only after the missing portal/signing inputs exist. Do
not change product capture, region, cookies, website data, store lifecycle,
payment, wallet, or completed-order logic.

# Active handoff — v86.208 final enablement (2026-08-21)

Continue only in `C:\Users\MOHAMMAD\Projects\otlobli-v86-208-final-enablement`
on `codex/otlobli-v86-208-final-enablement`. Its protected source is
`codex/otlobli-final-production-release` at
`c18363c9a5712239d53bdf97880058036f9b2198`. Do not modify product capture,
Temu, root/product Back, store chooser, double-Home switching, or revive the old
freeze diagnostics. The live SHEIN administration state is QA/USD/ar.

Read every file under `docs/final-enablement/`. Code-side work and Supabase
deployment are complete; the only allowed continuation is to supply the exact
portal/signing values in `MANUAL_PORTAL_ACTIONS.md`, run the fail-closed signed
workflow once, and execute the physical matrix. Never claim APNs, Google iOS,
Apple login, account deletion, signed artifacts, or release readiness without
that evidence.

Unsigned GitHub/Xcode run `32476867979` passed with artifact `9444682658`; its
IPA SHA-256 is
`430A76756C4433719AAADB0EFF03D2E3442D491D24058E1ECDB1201836DB76EF`.
It has no signature/profile and cannot replace the pending signed candidate.

# Historical handoff — v86.207 production release candidate (2026-08-21)

Work only in `C:\Users\MOHAMMAD\Projects\otlobli-final-production-release` on
`codex/otlobli-final-production-release`. Baseline is v86.201 commit
`0b462a93030b5c7114012d5848ce61eac49b8b17`; candidate is `86.207/1069`.
Do not modify product capture, SHEIN blocking/hiding, the working admin-driven
region mechanism, or protected diagnostic branches. Do not revive clean-room,
cache-guard, RAW, Web Inspector, or freeze-probe experiments.

Code is prepared for direct APNs on iOS, Android FCM preservation, Google iOS,
Sign in with Apple, and account deletion. Local build/guards/sync and Android
debug tests pass, but live Supabase deployment, portal secrets, physical device
OAuth/push/deletion acceptance, and signed release artifacts remain. Read all
files in `docs/final-release/`, especially `FINAL_RELEASE_REPORT.md` and
`REQUIRED_PORTAL_ACTIONS.md`, before continuing. Never call the release ready
until the pending physical and signed-artifact gates pass.

# Active handoff — v86.201 injected double-Home store switch (2026-08-20)

The double-Home gesture previously existed only in `handlePersonalTemuHomeTap()` for the Android personal-Temu surface. It did not exist in SHEIN: `OTLOBLI_NAV_TOUCH_BRIDGE_JS` loaded Home immediately and its 450ms dedupe discarded the real second `touchend`. v86.201 gives injected SHEIN/Temu navigation the same contract. A single Home waits 320ms then runs the existing store-Home `location.assign`; a second physical Home tap cancels that timer and emits `closeStore`, revealing the existing `store-select` screen while parking the browser. Synthetic post-touch clicks are ignored separately and cannot count as the second tap. Another nav tab cancels a pending Home timer.

Preserve v86.198 root-Back, v86.199 `.throttle`, and v86.200 single native exit buttons. Do not close/recreate the same-store session for this gesture. Version/build `86.201/1063`, marker `2026.08.20-v86.201-double-home-store-switch`. Local gates/build/sync and GitHub/Xcode run `32395358634` pass from commit `705881c`; artifact ID `9416494357`. Inspected IPA: `6,559,013` bytes, SHA-256 `5E24D42A5E3CD600B1F76FF0E7D7918B13E53A49BED930710820ACAF42F64F8B`, ARM64, iOS 15+, iPhone/iPad, unsigned/unprovisioned, no maps or relay placeholder. Desktop path: `C:\Users\MOHAMMAD\Desktop\otlobli-ios-v86.201-double-home-store-switch\otlobli-v86.201-ipad-iphone-universal-unsigned.ipa`. Device acceptance is pending.

# Active handoff — v86.200 single store-exit controls (2026-08-20)

v86.200 is the user-facing candidate above clean v86.199. The user found that Temu root had no exit button and SHEIN displayed both the custom plugin's green native button and the dark injected fallback. `storeBlockingScript.ts` now always computes Temu visibility, but hides the HTML element whenever a WebKit native message handler is available. It still posts `otlobliBackButtonState`, so the native control remains functional. Search mode precedes root exit; Temu root emits `closeStore`. App.tsx now parks the normal Temu InAppBrowser before showing the picker, and the persistent Capgo patch maps native `exit` to `closeStore` instead of hard-coding SHEIN.

Preserve v86.198 canonical-root protection and v86.199 `.throttle`. Do not show both HTML and native controls. On iOS there must be exactly one native button; on Android/no-native-handler exactly one HTML fallback. Version/build `86.200/1062`, marker `2026.08.20-v86.200-store-exit-buttons`. GitHub/Xcode run `32394719421` and artifact `9416286514` pass; device acceptance is pending.

# Active handoff — v86.199 combined root-Back + scheduling candidate (2026-08-20)

The customer's v86.198 device result is decisive and must not be overwritten: root Back is fixed. SHEIN/product navigation works, Back at canonical Home exits correctly, and another store can be opened. However, backgrounding the whole app and returning still freezes the retained SHEIN surface. Treat these as two independent triggers, not a failed Back fix.

Branch `codex/ios-v86-199-root-back-scheduling` starts from v86.198 HEAD `16f5824` (behavior commit `a3675ff`). The only new runtime line sets `WKPreferences.inactiveSchedulingPolicy = .throttle` on iOS 17+. Preserve every v86.198 root-Back invariant and do not add `.none`, reload, rebuild, recompose, data clearing, or another lifecycle action. Version/build `86.199/1061`, marker `2026.08.20-v86.199-root-back-scheduling`. Build/archive and physical acceptance are pending.

Device test must distinguish: (A) ordinary App Switcher background/return without swiping the app away, repeated five times after Home/PDP use; (B) a separate force-quit/cold launch. For A, every return must permit immediate scroll, category, and PDP interaction. Re-run Home Back once to ensure the accepted v86.198 fix remains. Do not call scheduling proven until A passes.

# Active handoff — v86.198 native Back-at-root guard (2026-08-20)

The reproducible trigger is now entirely foreground: Home → product → native Back to Home → native Back again. The second tap called `WKWebView.goBack()` because `canGoBack` was true and the native `nativeBackTarget` could still be the asynchronous product-page value. That can enter a redirect/login/verification/Home history item; SHEIN redirects visibly back to Home but returns inert. The pressed control is the plugin's native `UIButton`, not SHEIN and not the injected HTML button.

Branch `codex/ios-v86-198-shein-root-back-guard` is based on exact v86.193 `a6e0ca9` and excludes v86.197 `.throttle`. The live native URL wins at tap time: `/ar/` or `/` emits `closeStore` before any history check, parks the same session, and returns directly to the picker. `cart` remains first; all non-root paths retain existing `goBack` and fallback behavior. The 0.8-second lock prevents overlapping native Back actions. `[OTLOBLI_BACK]` logs the current route, back list, decision, and navigation type. Do not add reload, rebuild, data clearing, or inactive-scheduling changes to this branch.

Version/build `86.198/1060`, marker `2026.08.20-v86.198-shein-root-back-guard`. Local build/gates and GitHub/Xcode run `32392833687` pass from code commit `a3675ff`; artifact ID `9415593869`. Inspected IPA: `6,558,346` bytes, SHA-256 `01BF09120BC919A614252279FD0A6890F7392C20EABC3FC8EFECAD74DE903E66`, ARM64, iOS 15+, iPhone/iPad `[1,2]`, unsigned/unprovisioned, no source maps or relay placeholder. The binary contains `[OTLOBLI_BACK]` and no inactive-scheduling selector. Desktop path: `C:\Users\MOHAMMAD\Desktop\otlobli-ios-v86.198-root-back-fix\otlobli-v86.198-ipad-iphone-universal-unsigned.ipa`. Device acceptance is pending. Required result: ten product opens/backs, one Back at Home must reveal picker without reload, re-enter SHEIN and open another product, then run five background/resume cycles and one cold launch. This prevents the proven bad edge; it does not yet explain SHEIN's internal inert state after unsafe history navigation.

# Active handoff — v86.189 disposable iOS render surfaces (2026-08-14)

v86.188 failed physical acceptance despite the dedicated plugin. Modern iPhone: first entry healthy, second entry/list visible but taps dead. iPhone 6: Home fully loaded, next list route did not complete interactively. Android remains fully healthy. Therefore never restore same-WKWebView rebind/recompose for iOS SHEIN and stop investigating normal injected script groups for these symptoms.

The only active iOS contract is now `createRenderSurface` / `destroyRenderSurface`. A render surface never becomes hidden and never crosses background. Hide/background destroys it; show/foreground creates a new WKWebView at the saved URL with `WKWebsiteDataStore.default()`. A settled SPA path change and a top-level link path change use the same replacement/full-document rule on every iPhone. No OS-version branch, process pool, CADisplayLink, snapshot, reload, same-instance detach/attach, or delay burst is allowed. The freeze guard enforces these absences and exactly one WKWebView constructor.

Version `86.189/1051`; branch `codex/ios-v86-189-disposable-render-surface`, commit `6830a04`, Xcode run `31834669885`. Inspected IPA: `6,557,711` bytes, SHA-256 `8F5D73D105483733BF9D03817300429D2D79CFC2D2A50A77C8A6572BC0B874AF`, ARM64, iOS 15+, iPhone/iPad, unsigned/unprovisioned, no maps. Required result only: modern iPhone first entry → second entry → one resume; iPhone 6 Home → list → tap one product, initially with all five diagnostic groups off.

# Active handoff — v86.188 dedicated iOS SHEIN browser (2026-08-14)

The v86.187 physical test answered the isolation question: clean install, all five normal script groups off, first SHEIN visit healthy, flags still off, background/return frozen. Therefore stop diagnosing injected scripts for this symptom. Runtime, Navigation, Blocking, Capture, and Session/Region are not the cause of the resume freeze. Do not restore speculative multi-delay recompose bursts in the Capgo patch.

iOS SHEIN now goes through `src/services/storeBrowser.ts` into the app-owned `ios/App/App/OtlobliSheinBrowserPlugin.swift`, registered by `OtlobliBridgeViewController`. It is a permanent host child with one WKWebView, `WKWebsiteDataStore.default()`, a shared process pool, a narrow native bridge, and a single foreground lifecycle. Android and non-SHEIN paths still use Capgo. Do not route iOS SHEIN back through direct `@capgo/capacitor-inappbrowser` calls from `App.tsx`; the freeze guard locks this boundary.

Preserve these native invariants: one WKWebView constructor; same instance/DOM/session across hide/show and resume; no reload on foreground; no cookie/localStorage deletion; no `willEnterForeground`; no multi-delay retry burst. One `didBecomeActive` repair is allowed only when the store was actually backgrounded and visible. It removes and reattaches the same instance across a real `CADisplayLink` frame, restores scroll, and has a single safety fallback so the view cannot remain detached. Top-level app-controlled URLs are SHEIN-only; subresources remain site-controlled. WebContent-process termination is emitted as fatal rather than silently looping.

Current version is `86.188/1050`. TypeScript, expanded freeze/architecture guard, diagnostic build, hardening, surface/size/performance gates, iOS sync, and isolated macOS/Xcode pass. Branch `codex/ios-v86-188-native-shein-browser`, commit `a9ae9e1`, run `31832999429`. Inspected IPA: `6,554,404` bytes, SHA-256 `7F92FAE968BBB51CAFA8F2C533119D9EB7654A5D2F1DBBDEC91DADC1A34619A4`, `com.otlobli.app`, ARM64, iOS 15+, iPhone/iPad `[1,2]`, unsigned/unprovisioned, no source maps. Physical acceptance on both affected iPhones remains required. Test raw/off first for ten background resumes with categories/list/PDP after each return; then all scripts on for the normal shopping path and five resumes. Do not call this fixed before that device result.

# Active handoff — v86.187 script-isolation diagnostic build (2026-08-14)

Active dirty worktree remains `claude/temu-issues-v86134`; preserve unrelated/user changes. Current diagnostic version is `86.187/1049`. Standard marker is `2026.08.14-v86.187-script-isolation`; Personal Android marker is `2026.08.14-v86.187-personal-script-isolation`. This is not a customer production release. `STORE_SCRIPT_DIAGNOSTICS` is compile-time gated by `VITE_STORE_SCRIPT_DIAGNOSTICS=true`; normal builds exclude the panel.

Preserve the v86.186 lifecycle repair in `src/App.tsx`: if the store chooser is visible while native close is still active, retain one `pendingStoreOpenAfterCloseRef` request, close the exact old WebView ID with `isAnimated:false`, ignore that old ID's delayed close event, and replay the requested store only after close finishes. The observed first-open/second-open freeze followed by Temu→SHEIN recovery is exactly consistent with the old request being discarded by `webviewClosingRef`.

The diagnostic surface is implemented in `src/services/storeScriptDiagnostics.ts` and composed through `storeCaptureBundle.ts`. It offers raw/all presets plus Runtime, Navigation, Blocking, Capture, and Session/Region flags. `storeScriptFlagsChanged` is handled by the host, saved under `otlobli.storeScriptDiagnostics.flags.v1`, and recreates the current WebView without clearing `WKWebsiteDataStore.default()`, cookies, cache, or verification state. Raw mode must continue to omit the full coordinator, recurring `tick`, and region diagnostic while retaining only the diagnostic panel/readiness bridge. Do not move the panel into the full runtime, or raw mode will be unable to diagnose a full-runtime failure.

Device protocol: reproduce in full mode using enter SHEIN → leave to chooser → enter SHEIN again → categories/products. Then choose `فحص` → `المتجر خام` and repeat the identical sequence. Raw failure means the next lane is native WebView/plugin lifecycle, not injected scripts. Raw success means restore all and disable one group per repetition in this order: Blocking, Session/Region, Navigation, Capture. Record the exact first working combination. Never solve/click human verification automatically.

Validation passes: TypeScript, executable freeze/isolation guard, Temu product-loading guard, Standard and Personal diagnostic builds, hardening/store-surface/size/performance gates, both native syncs, Android ARM64 Debug, Playwright at `390×844` and `320×568`, and isolated Xcode. Android output is `Otlobli-v86.187-Android-Script-Isolation-DIAGNOSTIC.apk`, `205,012,092` bytes, SHA-256 `DC1EB324B9C01B434D2BF64836958D9359CE2F0F3563278403AD10B5E253E394`. iOS branch `codex/ios-v86-187-script-isolation`, commit `7259faf`, run `31830165263`; IPA `Otlobli-v86.187-iPhone-iPad-Script-Isolation-DIAGNOSTIC-UNSIGNED.ipa`, `6,532,034` bytes, SHA-256 `87560FCF9C09DA39E922BD489EDF07670876722C86148471A504E5F5C86625D5`. The IPA is ARM64 Universal, iOS 15+, unprovisioned/unsigned, and has no source maps.

No physical-device acceptance has been performed. Do not claim that the freeze is fixed until both affected iPhones report the raw/full outcome. The diagnostic panel is the shortest path to a measured cause, and must be removed/disabled for a customer release after that cause is isolated.

# Active handoff — v86.185 store runtime cleanup and session preservation (2026-08-14)

Active dirty worktree remains `claude/temu-issues-v86134`; preserve all unrelated/user changes and do not replace it with the isolated iOS build branch. Current version is `86.185/1047`, with standard marker `2026.08.14-v86.185-store-runtime-cleanup` and Personal marker `2026.08.14-v86.185-personal-store-runtime-cleanup`.

The injected runtime is now separated by responsibility: `sheinNavigationScript.ts`, `sheinSessionScript.ts`, `storeProductCaptureScript.ts`, `storeBlockingScript.ts`, `temuBrowserScript.ts`, and `storeRuntimeCoordinator.ts`; `sheinBrowserScript.ts` only composes them. `src/services/STORE_RUNTIME.md` is the map. Keep that boundary. `scripts/store-script-sources.mjs` lets verifiers inspect the whole graph, and `verify-shein-freeze-guard` parses the actual composed/minified output.

Most important compatibility decision: SHEIN owns all cookies and web storage. Never restore the removed `Storage.prototype.setItem` override, scalar country/currency writes, broad cookie writes, `addressCookie` deletion, or product-bootstrap reload. The live site's `currency` is structured JSON, not a plain `USD` scalar. Region truth is the signed `addressCookie` plus the visible shipping label; repair uses SHEIN's native UI. Challenge mode must remain ahead of all cleanup and must never click, solve, reload, or mutate verification. iOS uses `WKWebsiteDataStore.default()` and normal app navigation hides/re-shows the WebView; do not add cookie clearing.

Performance decision: keep one recurring due-time coordinator, no full-document MutationObserver, and the proven blocker intervals `120/650 ms`. The bounded document-start protection timer must stop on `window.__otlobliStoreRuntimeReady`. Preserve the bounded selected-SKU price observer. The React best-practice review also confirmed the heavy capture graph remains dynamically imported only when a store opens.

Validation passes: Standard and Personal builds; release hardening; freeze, Temu size, store surface, and Temu product-loading fixtures; performance budgets; iOS/Android sync; Personal ARM64 Android Debug; isolated macOS/Xcode. Personal budget: startup `639,347`, gzip JS `259,740`, CSS `69,819`, fonts `81,364`, shipped scripts `243,698`, combined source `545,738` bytes, all below gates. Full lint has a pre-existing `40` errors / `19` warnings baseline outside this refactor and remains non-gating.

Artifacts: Personal Debug APK `C:\Users\MOHAMMAD\Documents\Codex\2026-08-14\files-pasted-by-the-user-otlobli\outputs\Otlobli-v86.185-personal-store-runtime-cleanup-debug.apk`, `205,006,508` bytes, SHA-256 `693CA50D0168E4A092A907866319B802B643814A9195CDCE7CC051D0FB2274C0`. iOS isolated branch `codex/ios-v86-185-store-runtime-cleanup`, commit `26bdd5bd69f6586203d02c7fa89d2f6b3be11b97`, run `31827354199`; IPA `Otlobli-v86.185-iPhone-iPad-Store-Runtime-Cleanup-UNSIGNED.ipa`, `6,527,689` bytes, SHA-256 `AA75998F5CAF2C7B82CAEDDF61D84C11D1D3573DC54B07613403A61A4F45DBEE`. It is unprovisioned/unsigned. Android release was blocked only by missing independent `OTLOBLI_LISTENER_*` signing values; debug build passed.

No physical iPhone acceptance was performed. Both affected phones must pass Home → list → PDP, manually solve a challenge once if shown, then prove the session remains accepted on store re-entry. iPhone 16 additionally needs five resume cycles and a cold launch. Preserve native `otlobliForceRecompose`, the 0.25-second `appDidBecomeActive` path, scroll/constraint restoration, Android `otlobliOnHostResume`, and `JSON.stringify` active-store region equality.

# Active handoff — v86.184 SHEIN live verification compatibility guard (2026-08-14)

Active dirty worktree remains `claude/temu-issues-v86134`; preserve all unrelated/user changes. Current version is `86.184/1046`, standard/iOS marker `2026.08.14-v86.184-shein-live-risk-guard`, Personal marker `2026.08.14-v86.184-personal-shein-live-risk-guard`. v86.183 is superseded: live Playwright reproduction proved Home → Super Deals → canonical PDP and HTTP-200 product APIs work, after which current SHEIN opens `.sui-dialog__wrapper` containing `.risk-one-pass-*` and `أنا إنسان`. Old Otlobli detectors did not recognize that server-side markup, so the existing challenge safe mode did not start; this also explains clean-installed old `86.134/994` failing now.

Keep the new bounded behavior: exact visible `risk-one-pass` detection plus semantic verification text over the last 12 visible dialog/security candidates only. Do not restore full-body challenge scans, auto-click, reload, CAPTCHA solving/bypass, or region writes during a pending verification. Challenge detection must remain before all SHEIN popup/product cleanup. The iOS tap fallback now finds the nearest ancestor whose at-most-16 PDP links resolve to one product ID; it must refuse a container with multiple distinct IDs and retain the metadata-card guard. Preserve all native freeze/host-resume/region invariants.

Validation passes: both web modes, hardening, freeze/Temu/store fixtures, low-end budgets, both native syncs, Android standard and Personal ARM64 Debug compilation, and macOS/Xcode. The synced platform chunks contain `risk-one-pass`. Personal APK: `C:\Users\MOHAMMAD\Documents\Codex\2026-08-14\files-pasted-by-the-user-otlobli\outputs\Otlobli-v86.184-Personal-ARM64-Debug.apk`, `205,009,860` bytes, SHA-256 `6B0C7CA57000CEDC5CAAAC33C2481776FD4392E39A05AEE797D126F033392ECB`; debug-signed test only. Isolated iOS branch `codex/ios-v86-184-shein-live-risk-guard`, commit `e74a6fab45fcc1bbe32ebaffcbb843d58dc98973`, run `31824376802`, produced the inspected Universal ARM64 unsigned IPA, `6,529,146` bytes, SHA-256 `F4CD547901E1D5675BD3E3C9BBC9E263F2765F86B049D678672F015CCC7B002D`. It is iOS 15+, iPhone/iPad, unprovisioned/unsigned, with no maps; sign it normally.

No phone was connected. Do not call the issue device-accepted until both affected iPhones pass Home → collection → PDP, manually complete `أنا إنسان` if offered, and show the PDP after verification. iPhone 16 still requires five resume cycles plus a cold launch. Literal immunity to arbitrary third-party changes is impossible; the implemented decision is bounded semantic compatibility plus fail-visible safe mode and fixtures.

# Active handoff — v86.183 live SHEIN product-card target correction (2026-08-14)

Active dirty worktree remains `claude/temu-issues-v86134`; preserve all unrelated/user changes and do not replace it with the isolated build branch. Current version is `86.183/1045`, with standard/iOS marker `2026.08.14-v86.183-shein-product-card-target` and Personal Android marker `2026.08.14-v86.183-personal-shein-product-card-target`. Both connected phones were confirmed to have received `86.182/1044`, and the customer reports no behavioral change on either. The customer subsequently deleted the app and clean-installed `86.134/994` on the iPhone 16 Pro Max; `pymobiledevice3` confirmed that exact installed bundle version before the phone disconnected, and the same failure remained. This rules out post-v86.134 regression/stale app data but is consistent with the current SHEIN DOM being incompatible with both old selectors. v86.182 is superseded and must not be presented as the fix.

The corrected diagnosis comes from the current live SHEIN mobile DOM matching the reported Batman search/list screen. A real search card is `.bs-product-card.multi-product-card`; the tapped image is nested under it but its `-p-<id>` anchor is a sibling, so v86.182's ancestor/exact-class lookup never armed. A real flash-sale item is `.flash-sale__product-item` with numeric `data-id` and can have no direct anchor. Separately, v86.182 skipped fallback after any URL change, including a wrong list/brand SPA route. Generic `sd-ccc-products__item` carousel/collection entries without a product href or product ID are legitimate list navigation and must remain untouched.

The iOS fallback now resolves bounded actual card shapes, direct sibling/descendant PDP anchors, or numeric product metadata; metadata-only cards map to `/<locale>/product-p-<id>.html`. The existing one-shot 500 ms fallback skips only when SHEIN is already on the same product ID and overrides a wrong non-product route once. Never restore synthetic `.click()`, generic collection interception, polling, observers, extra timers, or product-specific exceptions. Preserve `otlobliForceRecompose`, 0.25-second `appDidBecomeActive`, scroll/constraint guards, Android host-resume, and `JSON.stringify` region equality.

All relevant guards/builds pass. Isolated branch `codex/ios-v86-183-shein-product-card-target`, commit `05f123e`, GitHub run `31818768808`, produced the unsigned Universal ARM64 artifact `Otlobli-v86.183-iPhone-iPad-SHEIN-Product-Card-Target-UNSIGNED.ipa`, `6,528,874` bytes, SHA-256 `D1931BDDCB4AC3BCF1458F8FDE781BE81346F4A27173B071DC47719CFF1FCF8C`. Archive inspection confirms `com.otlobli.app`, `86.183/1045`, iOS 15+, iPhone/iPad, new fallback markers, no source maps, no app-level signature, and no provisioning profile. Sign/provision before installation. Do not close the issue until both phones pass the exact three-stage route; iPhone 16 also requires five background/resume cycles and one cold launch.

# Active handoff — v86.182 SHEIN iPhone PDP routing (2026-08-14)

Active dirty worktree remains `claude/temu-issues-v86134`; preserve all unrelated/user changes and do not replace it with the isolated build branch. Current version is `86.182/1044`, with standard/iOS marker `2026.08.14-v86.182-shein-pdp-route` and Personal Android marker `2026.08.14-v86.182-personal-shein-pdp-route`.

Customer flow is specifically three stages: SHEIN Home → a collection/list containing the selected item → the actual item PDP. On iPhone8,1 / iOS 15.8.8, Home and the collection loaded, but the collection-to-PDP tap produced an empty/error-like SHEIN listing surface; the customer reports the same on iPhone 16. Preserve the first natural navigation. The fix in `OTLOBLI_IOS_PRODUCT_TAP_FALLBACK_JS` only captures a direct `-p-<id>` href and, after one bounded 500 ms window, assigns it once if the natural route did not change. Generic `sd-ccc-products__item` containers without a direct PDP href are ignored. Never restore the broad `n[0].click()` replay or no-href chunk-recovery path.

`scripts/verify-shein-freeze-guard.mjs` now proves: a direct PDP anchor receives one fallback assignment with no synthetic click/recovery; a generic collection card receives no click/assignment/recovery; and successful natural navigation is not assigned twice. Do not weaken the protected `otlobliForceRecompose`, 0.25-second `appDidBecomeActive`, scroll/constraints, Android host-resume, or `JSON.stringify` region-equality invariants. No polling/observer/DOM scan/additional timer was introduced.

Standard and Personal web builds, iOS/Android sync, and Android `assembleDebug` pass. Isolated iOS branch `codex/ios-v86-182-shein-pdp-route`, commit `54a9991`, GitHub run `31816661268`, built the unsigned ARM64 iPhone/iPad artifact `Otlobli-v86.182-iPhone-iPad-SHEIN-Product-Route-UNSIGNED.ipa`; SHA-256 `4FF5C1B346E29B6AFF9FADBB22427EF06CFEA354B68866DEFA021C0F6F5A17FD`. Sign/provision before installing. Acceptance is still pending: test the exact three-stage path on the old iPhone and iPhone 16; on iPhone 16 perform five background/resume cycles and one force-quit/cold launch before calling the fix complete.

# Active handoff — v86.181 online diagnostics (2026-08-14)

Active dirty worktree remains `claude/temu-issues-v86134`; preserve all unrelated/user changes. Current app version is `86.181/1043`, with Personal Android marker `2026.08.14-v86.181-personal-online-diagnostics` and standard/iOS marker `2026.08.14-v86.181-online-diagnostics`. v86.181 includes the unrecorded v86.180 repeated-Temu-capture fix and store-switch UX. Do not revert to the documented v86.179 artifact.

Online diagnostics is implemented in `src/services/appDiagnostics.ts`, `src/services/issueReports.ts`, and the Support screen in `src/App.tsx`. The trace is a module-level, in-memory 60-event ring with no interval, React state churn, localStorage persistence, console interception, DOM scan, or auto-upload. Both client and Edge Function redact sensitive keys plus JWT/bearer, URL, email, phone, and long-identifier values. Never add cookies, auth headers/tokens, full URLs, store HTML/body, product titles/images, screenshots, names, addresses, or selected option text to diagnostic events. Submission requires a customer note and explicit consent. Android shake reports remain visual and attach the safe snapshot.

Live backend state: migration `20260814164500_app_report_diagnostics.sql` is applied to Supabase `dcicqdprtyhwmhegabay`; `app-reports` was deployed after the final server-side privacy pass. It accepts screenshot-free `reportKind=diagnostic`, caps diagnostics at 32 KB/60 events, and preserves visual screenshot validation/rate limiting. `supabase/schema.sql`, the original create migration, the additive migration, and the Edge Function are consistent. One intentional automated diagnostic acceptance report remains in the inbox with note `اختبار آلي: التحقق من إرسال تشخيص آمن عبر الإنترنت`.

Admin `AppIssueReportsPanel` renders report-kind badges, a diagnostic placeholder, and a bounded `<details>` timeline. Production deployment is live at `https://talabieh-admin.vercel.app`; deployment inspect id `77hfhRmfrLLBJpFjeVDQcnvQQ1Bi`, live asset `index-Cg9mc4cb.js`. Local admin build and Playwright checks passed at 1365×900 and 390×844. Customer Support passed at 390×844, including inline missing-consent validation and a real successful POST.

Build/sync: standard + Personal builds pass all hardening/freeze/Temu/store-surface/performance guards; final Personal budget is JS startup `640,029/720,000`, JS gzip `260,668/370,000`, CSS `69,819/70,000`, fonts `81,364/100,000`, shipped store scripts `248,358/470,000`, SHEIN source `554,331/600,000`. Standard was synced to iOS, Personal to Android. The iPhone 0.25-second `appDidBecomeActive` recompose, scroll/constraints, Android host-resume defense, and region `JSON.stringify` equality guard were untouched.

Android test artifact is `C:\Users\MOHAMMAD\Desktop\Otlobli-v86.181-Android-Online-Diagnostics-Test.apk`, ARM64 Personal Release, `195,372,614` bytes, SHA-256 `A984FE415827B31621276F33BE08AA023E260837CF00380DAB5107B23CC6A549`, debug-certificate signed for device testing only. x86_64 debug was installed on emulator and the native Support form was visually checked (`output/v86.181-emulator-online-diagnostics.png`), with no matching fatal/ANR/crash. Real Note 8 was unavailable; do not claim weak physical-device acceptance.

iOS unsigned Universal artifact is `C:\Users\MOHAMMAD\Desktop\Otlobli-v86.181-iPhone-iPad-Online-Diagnostics-UNSIGNED.ipa`, `6,528,632` bytes, SHA-256 `80487AB4E95BFFF74731CBFCE1A4B9C937F933AA235FE74FE099D2510A1CA09C`. GitHub run `31807331199` passed from isolated branch `codex/ios-v86-181-online-diagnostics`, commit `8b813be226719c53654d21f72e70d1aa13862834`. Archive is ARM64 iPhoneOS, iOS 15+, family `[1,2]`, `com.otlobli.app`, `86.181/1043`, unsigned/unprovisioned, no maps, current Syrian flag, diagnostics marker, and protected native recompose symbols present.

Remaining acceptance: sign/provision the IPA, install on the affected iPhone, reproduce the failure, send the report through Account → Support, and inspect it in Admin → App reports. Run five iPhone 16 background/resume cycles and force-quit/cold-launch. The v1 trace is consented and memory-only, so it intentionally cannot auto-upload after a hard process death.

# Active handoff — v86.179 Temu return and capture acknowledgement (2026-08-14)

Current Personal Android test release is `86.179-personal-temu-capture-ack/1041`. When the persistent Personal Temu surface is active, React's first tab deliberately renders as `المتاجر`, not `الرئيسية`: pressing it sends the existing `closeStore` path, hides Gecko without deactivating/destroying the session, and returns to the store hub in one press. `talabieh.storeSwitchHintSeen.v1` makes the small `بدّل هنا ↑` learning cue one-time. Keep it event-driven and do not turn it into an animated onboarding overlay or a timer.

The capture acknowledgement contract is now explicit. `TemuEmbeddedBrowserPlugin.handleExtensionMessage()` returns a pending `GeckoResult` for `addToCart`; React persists the cart through `useStoredState` and then calls `TemuEmbeddedBrowser.acknowledgeAdd()`. Only that completion lets the extension dispatch `addToCartAck`. The native request rejects after `ADD_ACK_TIMEOUT_MS = 3500L` or plugin destruction, while the injected page owns a single five-second safety timer that starts immediately after `showAddingOverlay()`. Exceptions and rejected hand-offs call `failAddFlow()`, release the scroll lock, and show a retry message. Preserve the in-place PDP behavior—do not auto-open Cart after capture—and do not add persistent polling.

Exact code `CA5773086` was reached before the patch and its red-gradient/M options were confirmed. The v86.179 debug reinstall triggered a Temu visual security CAPTCHA; it was not solved or bypassed, so exact post-fix live capture remains pending. Emulator acceptance did prove the new learning cue, one-tap return, preserved session, and cue disappearance on the next entry. Evidence: `output/v86.179-emulator-temu-store-tab.png`, `output/v86.179-emulator-one-tap-store-return.png`, and `output/v86.179-emulator-store-tab-after-hint.png`.

Standard/Personal builds, TypeScript, hardening, SHEIN freeze, Temu gate, store surface, low-end budgets, Android Debug/Release compilation, and Android/iOS sync passed. Final Personal budget: startup JS `630,865/720,000`, CSS `69,978/70,000`, shipped store scripts `248,358/470,000`. Android artifact: `C:\Users\MOHAMMAD\Desktop\Otlobli-v86.179-Android-Temu-Capture-Fixed-Release-Test.apk`, workspace copy `output/otlobli-v86.179-personal-arm64-temu-capture-ack-release.apk`, `195,369,394` bytes, SHA-256 `28997FE21FD4CF7D573FC9D6D2FC1118EA4A5891198D7266A59982610F1F1CD8`. It is ARM64, minSdk 26, non-debuggable R8 Release, but debug-certificate signed for testing only.

iOS Universal artifact: `C:\Users\MOHAMMAD\Desktop\Otlobli-v86.179-iPhone-iPad-Universal-Final-Test-UNSIGNED.ipa`, `6,525,440` bytes, SHA-256 `E86403F3079CCB7C6A1CBB75260B0A01B7FC726BA7970EB658E751C4605F4615`. GitHub run `31799688321` completed in `3m15s` from `codex/ios-v86-179-universal` at `77598df9bf59090f322f388db4b6efbcdb0ef811`. Parsed archive facts: `UIDeviceFamily=[1,2]`, ARM64, `com.otlobli.app`, iOS 15+, `86.179/1041`, Syrian flag present, no source maps, no app-level signature/provisioning profile. This is unsigned and must be signed before installation. No real iPhone/iPad or Note 8 acceptance was performed.

# Active handoff — v86.178 low-end Android runtime (2026-08-14)

The current Personal Android test release is `86.178-personal-low-end-runtime/1040`. Preserve the new on-demand boundary: `App.tsx` dynamically imports `src/services/storeCaptureBundle.ts` only when entering a non-personal store or when SHEIN page-load injection actually needs it. The store hub must not request `storeCaptureBundle-*.js`; the first store tap may request it. `scripts/verify-performance-budget.mjs` now locks the actual startup entry below `720,000` raw bytes in addition to the existing largest/total/CSS/font/store-script budgets. Final startup entry is `629,961` raw bytes versus v86.177 `883,614` (`28.7%` smaller); do not fold the deferred module back into startup.

Android Gecko lifecycle is deliberately asymmetric. `handleOnPause()` sets the session inactive/unfocused, `handleOnResume()` reactivates only a visible store surface, and media is suspended while inactive. `hideStoreLayer()` must continue to preserve the active session during ordinary Cart/Profile navigation because Temu may still be completing its security hand-off; both the Temu gate and store-surface guards enforce this. Do not add `setActive(false)` to ordinary hide or release the session without a deliberate comparison and real Note 8 acceptance. The pre-paint low-end profile in `src/main.tsx` targets Android with <=4 GB reported memory, <=4 logical cores, or Android <=10 and reduces fixed-layer effects plus off-screen list rendering without removing features. Keep lazy image dimensions/decoding in cart, orders, and tracking.

Validation passed: TypeScript; standard and Personal builds; hardening; SHEIN freeze, Temu price/size, store-surface, and performance guards; Android/iOS sync; Playwright `320×568` and `360×640`; Personal ARM64 R8 Release packaging; and a Personal x86_64 Release run on an Android 15 emulator constrained to 4 cores/4 GB. Clean cold launch was `998 ms`, store-hub PSS `73,364 KB`, Temu opened, Cart switched on first press, returning to Store preserved the Temu session, and a background/resume returned hot in `164 ms` without matching FATAL/ANR/MOZ_CRASH. Background package PSS settled near `274 MB`; do not claim emulator proof of memory release or real weak-phone acceptance. A physical weak/old Android device still needs scrolling, Store ↔ Cart/Profile, SHEIN ↔ Temu, product capture, and repeated background/resume acceptance.

Authoritative ARM64 file: `C:\Users\MOHAMMAD\Desktop\Otlobli-v86.178-Android-4GB-Smooth-Release-Test.apk` (workspace copy `output/otlobli-v86.178-personal-arm64-low-end-release.apk`), size `195,368,613`, SHA-256 `B4B6809398F170F510C85E28917172B89B1BF4E84A3E3F9122BCE10B906E03ED`. It is ARM64, minSdk 26, non-debuggable Release with R8/resource shrinking, but locally debug-certificate signed for testing only. Do not use the current `android/app/build/outputs/apk/release/app-release.apk` as the ARM64 handoff: that path was intentionally overwritten by the later x86_64 emulator build. Dirty-worktree changes remain unstaged/uncommitted.

iOS `86.178/1040` Universal unsigned IPA exists at `C:\Users\MOHAMMAD\Desktop\Otlobli-v86.178-iPad-iPhone-Universal-Final-Test-UNSIGNED.ipa`, size `6,524,846` bytes (`6.52 MB` / `6.22 MiB`), SHA-256 `ED10F4C41A358CD144854B2138B7709C2CAFF7F4B792D2B3620AF767F5135938`. GitHub Actions run `31796588474` built it from isolated branch `codex/ios-v86-178-ipad-universal`, commit `d803a2046ef65494a55645ff75d895516cc84e78`. Post-build parsing proves `UIDeviceFamily=[1,2]`, bundle `com.otlobli.app`, iOS 15+, ARM64 device binary, and version/build `86.178/1040`. The archive contains the local Syrian flag and deferred store chunk, no source maps, no app-level signature, and no provisioning profile; it must be signed before installation. The primary workflow now fails if the Xcode target or built app stops supporting either iPhone or iPad.

Playwright visual checks passed at `768×1024` and `1024×1366` with no horizontal overflow and no eager store-chunk request. There was no real iPad/iPhone installation or acceptance; do not claim it. Any signed v86.178 release must preserve `otlobliForceRecompose()`, `appDidBecomeActive`, the `0.25s` recompose delay, and the `JSON.stringify` store-region comparison, then pass five real iPhone 16 background/resume cycles and one force-quit/cold launch. The owner has an Apple Developer account but chose not to connect signing/TestFlight yet. Payment, wallet, completed orders, Temu selected-price behavior, and capture semantics were not changed.

# Active handoff — v86.177 Temu selected-variant price (2026-08-14)

Scope was intentionally narrow. Exact Note 8 product `607534043768396` proved Temu keeps the PDP `curPrice` at `531.03 SAR` while the open SKU dialog changes from blue `531.03` to gray `528.93`. `temuPriceUsd()` now reads a visible, structurally proven SKU dialog first (`salePriceRich`, current price, then dialog curPrice), bounded to the last eight dialogs, then falls back to the PDP. Do not replace this with first-global-price logic, a permanent observer, polling, a price cache, or a broad page scan.

The new guard in `scripts/verify-temu-size-gate.mjs` locks gray-vs-stale-PDP, blue-vs-stale-PDP, hidden old drawer, and unrelated promo dialog behavior. Exact live-DOM evaluation produced gray `$141.22` and blue `$141.79`. Standard/Personal builds, hardening, SHEIN freeze, Temu/store guards, TypeScript, performance budget, and Android/iOS sync passed. Preserve v86.176 SHEIN fast-entry behavior, v86.175 repeat-capture semantics, existing Temu SKU/session logic, payments/wallet/orders, and native iPhone recompose timing.

Physical Note 8 now has in-place Personal ARM64 debug `86.177-personal-temu-variant-price/1039`; data/cart were preserved, app/Temu launched, and no matching FATAL/ANR/MOZ_CRASH appeared. Desktop APK: `C:\Users\MOHAMMAD\Desktop\Otlobli-v86.177-Android-Temu-Variant-Price-Final-Test.apk`, size `205,003,387`, SHA-256 `B441E2FA4B10C8D7A99F3EB41EE091B02CCB185F733E0B34332FC92429E05904`. Post-install reopening of the exact product hit Temu's visual security verification; it was not bypassed, so do not claim a post-install end-to-end cart add. No test item was added or removed.

iPhone IPA `86.177/1039` was built successfully through GitHub Actions run `31755017217` from isolated branch `codex/ios-v86-177-temu-variant-price`, commit `0421f5b3b0535720a015e956d47ec300f2102465`. Desktop file: `C:\Users\MOHAMMAD\Desktop\Otlobli-v86.177-iPhone-Latest-Final-Test-UNSIGNED.ipa`, size `6,524,330` bytes (`6.52 MB`, `6.22 MiB`), SHA-256 `DB60DB27F7E2936E5F60F476D9C6991805CA93B6BD5630CD82E72436F36B293E`. It is ARM64 iPhoneOS, iOS 15+, unsigned, with no embedded provisioning profile, app-level signature, or source maps. Inspection confirmed the v86.177 Temu selected-price marker, `salePriceRich`, the current local Syrian flag, and retained `otlobliForceRecompose`/`appDidBecomeActive`. It still needs the owner's normal signing path. No real iPhone acceptance occurred; five real iPhone 16 resume cycles and a separate force-quit/cold-launch test remain mandatory. Dirty-worktree user/AI changes remain unstaged and uncommitted.

# Active handoff — v86.176 SHEIN fast entry only (2026-08-14)

User corrected the scope emphatically: this batch is **only** to speed up entering SHEIN before making the iPhone build. Do not resume the older request about capturing a second Temu option unless the user asks again. The temporary Temu fingerprint dedupe experiment was removed; final `src/App.tsx` retains v86.175 `temuAddInFlightRef`, and the isolated iOS build commit contains no Temu capture/SKU/session change.

The exact fix is two small SHEIN-entry changes in `src/App.tsx`: ordinary `switchSelectedStore()` no longer calls `InAppBrowser.clearCache()` when switching to SHEIN, while the existing bounded damaged-session/cart-product recovery still clears cache; and SHEIN's `isPresentAfterPageLoad` is `isIosNative`, so Android shows the native branded cover immediately while iOS keeps the pre-existing hidden/readiness behavior. `scripts/verify-shein-freeze-guard.mjs` guards both facts. Do not change the iPhone recompose lifecycle or its `0.25s` delay.

Final Note 8 measurement on the corrected in-place build `86.176-personal-shein-fast-entry/1038`: branded cover visible in the ~`0.9s` screenshot, `openWebView` `01:36:13.959`, first `browserPageLoaded` `01:36:18.351` (~`4.39s`), signed `sheinSaudiReady` `01:36:19.168` (~`5.21s`), no FATAL/ANR/MOZ_CRASH. Proof: `output/v86176-final-cover.png`. The device's app data was preserved; no Temu product was added during the abandoned test.

Final IPA: `C:\Users\MOHAMMAD\Desktop\Otlobli-v86.176-iPhone-SHEIN-Fast-Final-Test-UNSIGNED.ipa`, `6,524,164` bytes, SHA-256 `4FDADE9249EF115DD55C9EC66DE8FE1FB2BCBBF37C134935354F556CE927F292`. It came from successful GitHub run `31750234595`, isolated branch `codex/ios-v86-176-shein-fast-entry`, commit `efed15b58757531cce6552bf95a510494da07475`. Metadata: `com.otlobli.app`, `86.176/1038`, iOS 15+, unsigned/no provisioning/no app signature/no source maps; current local Syrian flag present; freeze recompose symbols retained.

All standard/personal builds, hardening, TypeScript, freeze guard, unchanged Temu guard, store-surface guard, performance budget, native syncs, macOS/Xcode build, archive inspection, and Note 8 install/launch passed. No real iPhone was tested. Before calling this accepted, sign/provision it normally, run five real iPhone 16 background/resume cycles and a separate force-quit/cold-launch test. No payment/wallet/completed-order/backend/admin/deployment change occurred. Active dirty worktree remains uncommitted; do not stage or overwrite it.

# Active handoff — v86.175 release hardening + current Syrian flag login (2026-08-13)

Use `C:\Users\MOHAMMAD\Desktop\Otlobli-v86.175-Personal-Note8-Final-Test.apk` for the owner's Note 8/Personal Android acceptance. It is the ARM64 R8/resource-shrunk Release `86.175-personal-release-hardening/1037`, signed with the local debug certificate strictly for installation, non-debuggable, and verified with APK Signature v2/v3. Size `195,367,479`; SHA-256 `5BFF729F8920C96A71CCB7BF600ECA5E19ECFAA288427F97466418115A4C7E86`. It contains Gecko `libxul.so`, the bundled Temu WebExtension, and the current Syrian flag, with no source maps. It was clean-installed on the physical `SM-N950F` Note 8 running Android 9. Do not upload it to Play.

Do **not** use `C:\Users\MOHAMMAD\Desktop\Otlobli-v86.175-Android-Final-Test.apk` for Personal/Note 8 acceptance. It is the 4 MB standard customer variant and intentionally has neither `TEMU_PERSONAL_SITE` nor the packaged Gecko engine. Replacing the previous `86.172-personal` build with it was the concrete reason the recent Temu work appeared completely absent.

Use `C:\Users\MOHAMMAD\Desktop\Otlobli-v86.175-iPhone-Final-Test-UNSIGNED.ipa` for both weak and strong iPhone acceptance after signing it with the owner's normal certificate/provisioning method. It is the ARM64 iOS 15+ archive for `com.otlobli.app`, version/build `86.175/1037`, size `6,524,183`, SHA-256 `BB70D4CE394A61CCEA18E895340C1CE1B77C8503DF3BCBEFFABD219A91BFE182`. GitHub Actions run `31742547246` built it successfully with Xcode from isolated branch `codex/ios-v86-175-final-test`, commit `d5f96ef81657b98c5332f45cde930c820dd67055`. It is deliberately unsigned, has no embedded provisioning profile, and is not an App Store upload artifact. Inspection confirmed no source maps/old Syrian emoji, the current local flag, minified injected scripts, and the required native SHEIN recompose/lifecycle symbols.

Current version is `86.175/1037`; personal Android is `86.175-personal-release-hardening`. The login shown by the installed Android 15 emulator build now uses `public/flags/syria-independence-flag.svg` (green/white/black with three red stars), never the platform Syrian emoji. Keep the local image path in both the country picker and auth route; the accessible select must keep full country names. Verified responsive proofs: `output/playwright/auth-login-small-320x568-final.png`, `output/playwright/auth-login-mobile-360x740-final.png`, and `output/playwright/native-v86.175-standard-launch.png`. Zoom is intentionally enabled and the page has no horizontal overflow.

Do not weaken the new publication guards. Android Release must retain R8 `minifyEnabled`, `shrinkResources`, optimized ProGuard, non-debuggable/JNI-non-debuggable output, extraction/backup exclusions, and the narrowed Capacitor annotation keep rules. iOS Release must retain stripping/dead-code/post-processing settings. Vite must keep `minifyInjectedScripts()` and `sourcemap: false`; the huge injected SHEIN/Temu strings are otherwise readable even when the outer bundle is minified. Keep `verify:release-hardening` in both build paths and do not broadly run `npm update`: critical Capacitor/Capgo/Vite/Terser versions are exact because the native freeze patch is version-specific.

**Security boundary:** the repository patch now has placeholders instead of the live relay credential, and the verifier rejects committed secrets. Postinstall still injects a static local key into both native clients, therefore the published binary cannot make that key secret. The next security phase is server work, not more obfuscation: implement Play Integrity standard requests and Apple App Attest challenges, validate them on the backend, mint 60–120 second request-bound/replay-protected relay tokens, release compatibly, then remove and rotate the static relay key. See `docs/APP_BINARY_PROTECTION.md`. Do not rotate/deploy prematurely, and never claim client code is impossible to reverse engineer.

All local validation passed: standard/personal builds, TypeScript, hardening checks, freeze/size/surface guards, low-end budgets, Android personal R8, Android standard shrunk Release packaging, Android/iOS sync, and emulator launch with zero FATAL/ANR. CSS is close to the locked ceiling at `69,838/70,000`; preserve features and reduce/split before adding more. Test artifacts: personal ARM64 debug SHA-256 `400FC43463398DE67ADC5BB76277BC64847B975FBC12811E16A3EB2EACDDA3A5`, standard debug SHA-256 `7B920C13A704E048A01BA23DCBDD4E050A6B4C6B06B65A5B54B071CF1C91ADD8`. They are not publication builds. The Release audit APK is unsigned (SHA-256 `9A3161B5EC637E02FAA52C843A8EB00B89BBA4714DD0F617A98B419238F2D7EF`) because production signing properties are absent.

Real Note 8 acceptance now proves: clean install/launch; Gecko plus bundled WebExtension registration; live `https://www.temu.com/sa/`; continuation to the live product feed after dismissing Temu's own security challenge; first-press switch to Otlobli Cart; and three background/resume cycles with no matching FATAL/ANR/MOZ_CRASH. Proofs are `output/note8-v86.175-personal-launch.png`, `output/note8-v86.175-personal-temu.png`, `output/note8-v86.175-personal-temu-after-captcha-close.png`, `output/note8-v86.175-personal-cart.png`, and `output/note8-v86.175-personal-resume3.png`. Store-open metrics were 73 frames, 16 janky (`21.92%`), p50 `12ms`, p90 `26ms`, p95 `42ms`, p99 `150ms`; Gecko-active total PSS was about `289,692 KB`. Do not claim product add/checkout or SHEIN acceptance from this run: the first Temu navigation presented its security challenge and those flows were not completed.

The standard login route has an open weak-phone UX defect despite its earlier narrow Playwright proof: on the real Note 8 the keyboard clips the submit and alternate-login content, and startup-plus-keyboard sampled 16/34 janky frames (`47.06%`). Personal starts at store selection, so this does not block the corrected Personal artifact, but it must be addressed before accepting the standard customer app. iOS was built successfully by macOS/Xcode but remains unsigned and unaccepted on real devices. No required weak/strong iPhone acceptance, five iPhone 16 lifecycle cycles, or cold-launch acceptance occurred. Payment, wallet, completed orders, SHEIN lifecycle/recompose, Temu session identity/SKU, and backend production state were not changed. The active dirty worktree/index was not committed, and no PR or deployment occurred.

# Active handoff — v86.174 measured Temu surface/nav colour fix (2026-08-13)

Current personal Android version is `86.174-personal-surface-colors/1036`. It is installed and measured on the Android 15 emulator. ARM64 artifact: `output/otlobli-v86.174-temu-personal-arm64-debug.apk`, `205,045,396` bytes, SHA-256 `408B41F463CB558BD3E75D2CF224D276AB9EFEF2EE3486D5AC1833783B3917EB`. It has not been installed on the physical Note 8.

**The pale bar cause is proven; do not compensate with CSS colours.** Before the fix, SurfaceFlinger showed sRGB and dimming ratio `1.0`, stable Temu whites were `255`, and there was no lingering dim window. The embedded Temu layer ended at `y=2164` while React nav began at `y=2102`, overlapping 62px, and its `24dp` elevation cast the exact grey gradient measured across the rest of the bar (`204 → 212 → 233 → 249`). v86.174 removes that elevation and adds the system navigation-bar inset to the 90dp React-nav reserve. The installed build ends the store surface at `y=2101`; the nav begins at `y=2102` and samples as pure `255` throughout.

Keep `scripts/verify-store-surface.mjs` wired into both build paths. It locks the navigation inset, zero elevation/dim, alpha restoration, session-preserving hide, and `SurfaceView` screenshot path. Emulator regression passed for profile → Temu, background/resume, opening and backing out of a real Temu product, and shake-dialog preview/dismissal, with no FATAL/ANR. Existing v86.173 Temu size and report invariants below remain mandatory.

Android and iOS shared assets are synchronized at `86.174/1036`; standard, x86_64 personal, and ARM64 personal Android builds pass. iOS was not built or device-tested. Do not claim Note 8 or iPhone acceptance, and do not change payment, wallet, completed orders, SHEIN recompose timing, Temu session identity, or SKU behaviour in follow-up architecture work.

# Active handoff — v86.173 exact size selection and Android shake reports (2026-08-13)

Current personal Android version is `86.173-personal-size-reports/1035`. It is installed and accepted on the Android 15 emulator; the final ARM64 APK is `output/otlobli-v86.173-temu-personal-arm64-debug.apk` with SHA-256 `385A2D27EE3066D0FBD5917BB4513574D7CCD2DFAF164624FFA97109BA9DFB26`. It has **not** been installed on the physical Note 8 yet.

**Do not weaken the Temu dialog allowlist back to text matching.** The exact product `601101949689075` has a real size dialog that also repeats `خصم 75%`; the old first-paint blocker hid it as a promo. A real SKU dialog is identified structurally (`role=dialog` plus radio/spec/SKU descendants). The size parser must continue to recognize Arabic `الحجم`, `.specTypes-*`, and expanded authoritative radio groups. `scripts/verify-temu-size-gate.mjs` locks these details plus the template-literal regex escaping. Live acceptance on the exact product proved: unselected add says `حدد المقاس أولاً` without closing the drawer; selecting a radio then captures successfully.

**Shake reports capture before opening the dialog.** `OtlobliIssueReporterPlugin.java` listens only while resumed, requires two 2.65g peaks within 720 ms (or one 3.55g peak), has a four-second cooldown, captures the current screen, then shows the RTL native note dialog. Never replace the `SurfaceView` PixelCopy path with window-only capture: GeckoView is rendered on a separate surface and window-only capture was measured as black. The present path captures the product image and the live Temu page when the shake occurs inside a product.

Live backend state: Supabase project `dcicqdprtyhwmhegabay` has migration `20260813170000_app_issue_reports.sql`, a private `app-issue-reports` bucket, and active `app-reports` edge function with JWT verification. GET/PATCH use `x-admin-pin`; screenshots are returned only through one-hour signed URLs. Acceptance reports `3efc830f-9eff-4af8-9c2d-d3f0b1438e48` and `1e108393-d2ea-4676-a7a5-3cdba6713dbb` are intentionally left in production as clearly labeled `resolved` emulator tests. The second was triggered while inside a real Temu product; its signed JPEG was downloaded and visually verified to contain the actual product image, title, price, quantity controls, and page state. Proof files are `output/v86.173-shake-report-product.png` (dialog preview) and `output/v86.173-live-product-report.jpg` (the production readback).

Admin has a `reports` tab in `admin/src/AdminApp.tsx` and responsive styles in `admin/src/styles.css`. It is deployed at the official production alias `https://talabieh-admin.vercel.app`, deployment `dpl_7JAQTMXiFEipNpX1VzgEwjxhFXqM`; live asset `index-CInC2dbj.js` was read back without cache and contains both `بلاغات التطبيق` and `app-reports`. Desktop and mobile Playwright screenshots are in `output/playwright/admin-reports-desktop.png` and `output/playwright/admin-reports-mobile.png`; the native product-screenshot proof is `output/v86.173-shake-report-surface.png`.

**Platform limit:** this batch implements the native shake sensor/screenshot dialog on Android only. iOS has synchronized shared web assets/version `86.173/1035`, but no iOS native shake plugin, Xcode build, or device acceptance. Preserve `WKWebViewController.otlobliForceRecompose()`, the 0.25-second `appDidBecomeActive` call, Android `otlobliOnHostResume()`, and the JSON-stringified active-store comparison.

**Only newly reported issue:** entering Temu reportedly makes the Otlobli bar pale and the Temu surface look darker. This is not diagnosed. Start with before/after screenshots and pixel/state inspection; compare normal entry, shake-dialog dismissal, and foreground resume. Check native dim/scrim flags, Gecko/SurfaceView alpha, leftover overlays, and focus/visibility restoration. Do not patch CSS colors without proving the source. `HANDOFF_TO_CODEX.md` has been refreshed to v86.173 and is the concise next-chat entry point.

# Active handoff — v86.172 no invisible gate over the Temu layer (2026-08-12)

Installed personal build on Note 8: `86.172-personal-invisible-gate-fix/1034`.

**Never render a full-screen React gate while the personal Temu surface is up.** Gecko paints over React, so the gate is invisible and still swallows every touch: the customer sees a live Temu page that answers nothing. This is what "the product page freezes and I can't reach the size" actually was. Any new blocking UI on `screen === 'home'` must call `TemuEmbeddedBrowser.hide()` first — see the `storeGateVisible` effect.

**Debugging technique that solved it, use it again.** Debug builds now enable Gecko remote debugging (`GeckoRuntimeSettings.remoteDebuggingEnabled(BuildConfig.DEBUG)`). Forward it with `adb forward tcp:9333 localabstract:com.otlobli.app/firefox-debugger-socket` and speak the length-prefixed JSON protocol (`listTabs` → `getTarget` → `evaluateJSAsync`, and wait for the `evaluationResult` packet — `frameUpdate` packets arrive first). That plus `uiautomator dump` distinguishes "page is broken" from "something is on top of the page" in minutes. Screenshots alone sent three hypotheses down dead ends here.

**Two changes were tried and reverted as unproven:** a Gecko display detach/reattach in the plugin, and blaming CPU load. Do not reintroduce them without evidence.

# v86.170 — cart product checks in place, no forced gate (2026-08-12)

Installed personal build on Note 8: `86.170-personal-cart-stays-put/1030`.

**A cart product tap must never move the customer to Home before the connection check answers.** v86.168 did exactly that and the user reported the cart had stopped opening products: a slow or failed probe dropped them onto the full VPN gate with no route back. Stay in Cart during `checking`; the effect keyed on `[vpnState, screen]` enters the store only on `ok`, and on `no-vpn`/`bad-region`/`offline` clears the queued product and reports the reason in Cart. Re-checking instead of refusing from a stale verdict (the v86.168 insight) is still correct — only the destination changed.

Everything below from v86.169 and v86.168 still applies.

# v86.169 — no writes during a SHEIN challenge (2026-08-12)

Installed personal build on Note 8: `86.169-personal-challenge-cookie-fix/1029`.

**Never call `writeSheinSaudiState()` while a challenge is outstanding.** It writes 26 `.shein.com` cookies plus `localStorage` keys; doing that when SHEIN has issued a token and is waiting for the answer changes the session fingerprint and turns a correctly solved check into `Access timed out, please refresh the page and try again`. `ensureSheinSaudiStore()` already stated this rule and honored it; `otlobliEnterChallengeMode()` and the early challenge-URL branch were violating it. The region is now seeded in the resolution branch instead, once `otlobliChallengeActive` clears and the page is interactive — verified that ordinary pages still read `country=SA`, `currency=USD`, `site_uid=pwar`, `language=ar`.

**Still to confirm:** a live challenge did not appear during the verification run, so the end-to-end "solve succeeds" observation is outstanding. Watch the next real challenge before calling this closed.

Everything below from v86.168 still applies.

# v86.168 — no false VPN gate, cart products open over the store (2026-08-12)

The installed personal build on Note 8 is `86.168-personal-no-false-vpn-gate/1028`, device-verified across two full cycles.

**Never restore a refusal based on a stored `vpnStateRef`.** This was proven, not inferred: with `window.fetch` instrumented, the entire failing path fired **zero** geo probes while the app displayed «شغّل VPN». Run from inside the app's own WebView, all four probes answered `QA` — a supported exit — in 52–77ms, on a device with no VPN interface at all. In `openStoreProductFromCart()`, any non-`ok` state must re-check and let Home resolve it; the connection right now is the only thing that may block a product, never a verdict recorded minutes ago.

**Do not reset `vpnStateRef` in `switchSelectedStore()` when the current exit is supported.** Store reachability is per-store and is still cleared. The exit country is a property of the device's connection and must survive a store switch — discarding it left the next SHEIN cart tap with no geo to trust. `switchCartStore()` was fixed for this earlier; both paths must now stay fixed.

**Cart products open over the store screen, not over Cart.** The personal Temu branch sets `pendingBackTargetRef` to `home` and switches the screen before `TemuEmbeddedBrowser.open()`. Leaving Cart mounted under Gecko made the bottom bar disagree with the screen and broke backing out.

**Any Otlobli tab handler that hides `InAppBrowser` must also call `hidePersonalTemuSurface()`.** `openCart`/`openOrders`/`openProfile` previously hid only the Chromium view, so a tab press while Temu was open changed React state under a still-painted Gecko surface and looked completely dead.

SHEIN issued a genuine human-verification after the fix and the app left it usable behind its guidance strip. Never claim or implement a CAPTCHA bypass. iOS is synced at `86.168` but unbuilt and unaccepted on device.

# Superseded — v86.167 exact SHEIN PDP + Temu cart/VPN diagnosis (2026-08-12)

The current installed personal build on Note 8 is `86.167-personal-cart-links-pdp-perf/1027`. Do not reintroduce the VPN check before `TemuEmbeddedBrowser.open()` inside the personal-Android branch of `openStoreProductFromCart()`: the user-reported notice was conclusively reproduced with the device network reporting `NOT_VPN`, and was caused by `switchSelectedStore()` resetting `vpnStateRef` to `idle`. The personal Gecko session is already the correct Saudi guest route and cart product links must use it directly. A real Temu cart product was opened twice after the fix with no VPN notice and without losing the browser session.

The reported SHEIN product is exactly id `130872819`. Pre-fix DevTools profiling on its route found `isAddToCartText` at `81.14%` of JavaScript samples because large `[class*=add]` wrappers had `textContent` flattened before geometry rejection every 650 ms. Keep the v86.167 guardrails in `src/services/sheinBrowserScript.ts`: geometry before label inspection, descendant text only for controls with at most six children, cookie discovery capped at 16 scans, no `innerText` whole-page reads, and skip the short carrier-error text detector on real 900+ element PDPs. Post-fix, the exact route was re-opened and SHEIN redirected it to the real `/risk/challenge`; a 12-second profile recorded `isAddToCartText` at `0%` and `idle` at `96.67%`. Never claim the app bypasses CAPTCHA.

`TemuEmbeddedBrowserPlugin.hide()` intentionally calls `setFocused(false)`, `setActive(false)`, and `releaseSession()` on the view only; it retains the `GeckoSession`. `show()` reattaches and reactivates that same session. This preserves cookies/history/scroll while removing the hidden rendering attachment. The regression script checks this lifecycle.

All validation passed: TypeScript, both store guards, both standard and personal web builds, performance budget, Android/iOS sync, and standard/personal Android Gradle builds. Artifacts: personal `output/otlobli-v86.167-temu-personal-arm64-debug.apk`, 205,026,308 bytes, SHA-256 `F41F11614F58797DF787E45A0A5138624E47973FE07349590DC40A8C3F328F0E`; standard `output/otlobli-v86.167-standard-universal-debug.apk`, 11,128,500 bytes, SHA-256 `BF913B434C5E1B1272A6F7E6CF8A03010EE57F5B8F4DF2EB2ADE41363F645B2E`. Note 8 has the personal APK installed and showed no recent FATAL/ANR. iOS is synced to standard `86.167/1027`, but no Xcode build or real iPhone 16 acceptance cycle was performed.

# v86.166 — strict Temu size gate and bounded add path (2026-08-12)

Current Android personal build is `86.166-personal-fast-size/1026`; Temu WebExtension is `1.3.14`. For multi-size Temu products, never infer a selected size from CSS borders, background, shadows, or rings. `temuSelectedSize()` now returns empty when the structural size dimension has more than one option without explicit Temu selection, except for a same-product user-click cache whose text is still visible and available. `otlobliTemuSku()` may retain visual fallback for a default color only. Preserve automatic acceptance for exactly one size and products with no size dimension.

The prior latency was deterministic: `temuFinalizeAdd(10)` delayed blocking messages by 5s, `temuWatchPickThenAdd(20)` could poll for 10s, capture retried `10 × 500ms`, and image preload could add 2.5s. Temu decisions are now immediate; capture is `3 × 150ms` maximum and skips duplicate image preload. Do not restore `temuAwaitOptionsThenAdd`, `temuWatchPickThenAdd`, delayed `temuFinalizeAdd`, diagnostic native messages, or trace globals. `npm run verify:temu-size-gate` is mandatory and is chained into `prebuild` and `build:temu-personal`.

Maintenance in `App.tsx` pauses payment-clock rendering and WhatsApp/Telegram OTP, cart-group, and order-detail polling while `document.hidden`, then refreshes once on visibility. Payment, wallet, exchange-rate, and completed-order semantics were not changed. Builds, TypeScript, freeze/size/performance guards, Android standard/personal assembly, and Android/iOS sync pass. Targeted ESLint still reports pre-existing project debt; do not describe lint as passing.

Real Note 8 evidence: cold launch `ThisTime=2299ms`; unselected multi-size PDP immediately showed `حدد المقاس أولاً` and did not add; single-size product entered the add overlay immediately; background/resume kept the same PDP and selected `M`, with no FATAL/ANR. A Temu-owned advance-reservation modal intercepted repeated add taps on the selected-size test product, so this batch does not claim an isolated end-to-end selected-size timing through that external modal. Personal APK SHA-256 `EF826AAA833D72EFCB4286082AE804D84F28DB2718E43DB0B6F47F9782D25A4C`; standard APK SHA-256 `6F82549098166B7B93B81B1DE0A800BEFEFF236438DFC388FEA2745D0C52DDE1`. iOS is synced at `86.166/1026`, but Xcode build and required iPhone 16 lifecycle/cold-launch acceptance were not performed.

# v86.164 — Temu capture stays on the product page (2026-08-12)

Current Android personal build is `86.164-personal-integrated/1024`; Temu WebExtension is `1.3.12`. The Temu browser is an integrated GeckoView layer owned by `TemuEmbeddedBrowserPlugin`, while the React Otlobli bottom navigation remains visible. Preserve `TemuEmbeddedBrowser.show()` when returning from cart/home: it resumes the same `GeckoSession`; replacing it with `open()` reloads Temu and loses the customer's product position.

Latest required behavior: an `addToCart` message appends to the Temu cart in React but must not change `screen`, hide GeckoView, or navigate to cart. The extension dispatches `addToCartAck` only after `browser.runtime.sendNativeMessage('otlobli', payload)` resolves, so the in-page capture overlay can show `✓ تم جذب المنتج بنجاح` and remove itself while leaving the PDP visible. Do not reintroduce the removed cart-navigation timeout. The manifest permissions `geckoViewAddons`, `nativeMessaging`, and `nativeMessagingFromContent` are required for this bridge.

Real Note 8 acceptance passed with size `S`: `output/temu-no-auto-success.png` proves the success state, `output/temu-no-auto-stays-product.png` proves the same PDP remained after five seconds, and `output/temu-no-auto-cart-manual2.png` proves the item appeared only after manually opening the Temu cart. Log evidence is `output/temu-no-auto-logcat.txt` and contains the complete `addToCart` payload (`8.56 USD`, size `S`) plus `messageFromWebview`.

Artifacts: personal ARM64 `output/otlobli-v86.164-temu-personal-arm64-debug.apk`, 205,028,280 bytes, SHA-256 `4B4DEDBE3089E7D860BDC041C578D51C9320E7955ACC3C970BDB02FFE5A022D0`; standard universal `output/otlobli-v86.164-standard-universal-debug.apk`, 11,466,337 bytes, SHA-256 `575B502B7DBC7F57D48EE812DF6E3F9C3C86B3105863F8019CCDFCAFF546E54B`. Standard/personal builds, SHEIN freeze guard, performance budget, Android builds, and Android/iOS sync passed. iOS was synced only; Xcode build and the mandatory five real iPhone 16 resume cycles plus cold launch were not performed.

# Handoff v86.163 — store hub, independent carts, and explicit Temu exit (2026-08-12)

- Current versions are standard `86.163/1023`, personal `86.163-personal-inapp/1023`, and Temu WebExtension `1.3.8`.
- Startup now lands on `store-select`; VPN/connectivity and store WebView work remain idle until the user chooses SHEIN or Temu. `StoreHubScreen` is Arabic-first, compact, and shows per-store cart counts.
- Carts remain persisted per `StoreId`. The cart screen has an accessible SHEIN/TEMU tablist with separate quantities, totals, shipping, and checkout. Switching the cart tab changes the active store but does not open its WebView or probe the VPN. It is blocked while an open shared cart/group is bound to the other store; do not merge carts or payment flows.
- Navigation invariant: host Home from cart/orders/profile opens the active store; store Home opens that store's own home URL; the store picker is reached only through an explicit store-exit action or its profile link. On Temu home, the native back button is always visible and `TemuGeckoActivity.goBackOrClose()` shows an `AlertDialog`; positive exit finishes the Activity and returns `storeClosed`, which opens `store-select`. On a non-home Temu page, back uses Gecko history first.
- Preserve the existing serialized `switchSelectedStore()` close/reset flow; it prevents the previous stale-WebView/white-screen race. Preserve the SHEIN iPhone freeze invariant and the Temu confirmed-product guard from v86.161.
- Final Note 8 acceptance (`SM-N950F`, serial `988e16384e4f51395230`): cold MainActivity start `2649ms`; cart Home returned to Temu; Temu home showed native back; exit confirmation appeared; positive exit resumed `MainActivity`, dismissed the dialog, and exposed the store hub. Screenshots: `output/note8-v86.163-store-hub-fixed.png`, `output/note8-v86.163-cart-tabs.png`, `output/note8-v86.163-temu-home.png`, `output/note8-v86.163-temu-exit-confirm.png`, `output/note8-v86.163-after-confirm-exit.png`.
- Installed personal APK: `output/otlobli-v86.163-store-hub-cart-temu-arm64-debug.apk`, `205,027,368` bytes, SHA-256 `BA9DD25C7A0A81F5722CCE7F4F9235D1109BB602AA305AFA5915DC916B79C186`. Synced standard APK: `output/otlobli-v86.163-store-hub-cart-universal-debug.apk`, `11,128,628` bytes, SHA-256 `6FE083FE8A75FFA8EF2CAD544BCF6432F74DCDAFA6D6ED4EB69142E3F8AF15CF`.
- Passed standard/personal Vite+TypeScript builds, Android standard/personal builds, Android+iOS Capacitor sync, SHEIN freeze guard, and the low-end budgets. Final standard/personal largest JS is `1,082,529/1,082,528`; gzip `286,628/286,625`; CSS `69,766`; store scripts `455,791`. iOS was synced and versioned `86.163/1023`, but no Xcode/device build, five iPhone 16 resume cycles, or iPhone cold launch was performed; do not claim iPhone acceptance.

# Handoff v86.161 — false Temu product-loading cover fixed on Note 8 (2026-08-12)

- The reported `جاري فتح المنتج…` screen was conclusively Otlobli's `#otlobli-temu-product-loading`, created by `otlobliTemuBlankProductNotice()`. Gecko remained on the same product URL with no `/login`; this was not Temu auth, Android native loading, or a network redirect.
- Root cause: the notice treated the absence of a large image/price in the **current viewport** as an empty product. After a valid PDP opened, Temu could change carousel/DOM state or the hero/price could leave the viewport, making the visibility probe false while product DOM remained healthy. The full fixed notice then covered the healthy page.
- Personal version is `86.161-personal-inapp/1021`; WebExtension is `1.3.7`. `otlobliPostTemuProductVisibleIfReady()` now records `__otlobliTemuConfirmedProductIdentity` after the existing stable-readiness period. The loading notice requires an unconfirmed product with `!v.domHasContent`, and blank-page reload also exits for a confirmed identity. Preserve these three markers; do not regress to viewport visibility as page readiness.
- No timer, observer, DOM scan, WebView rebuild, retry loop, or lifecycle work was added. The genuine new-route/empty-DOM recovery remains. Run `node scripts/verify-temu-product-loading-guard.mjs`; it covers empty new DOM, loaded content outside viewport, confirmed transient replacement, and a different new product.
- Real Note 8 `SM-N950F` (`988e16384e4f51395230`) has `86.161/1021` installed in place. Product `606482062007357` opened with the green add button and Otlobli nav, stayed open from 11:13 to 11:18 while gallery content changed, and ended with `LOADING_TEXT_COUNT=0`, `LOGIN_TEXT_COUNT=0`, no `/login` navigation, and no FATAL/ANR. Screenshot: `output/temu-v86161-note8-long-swipe.png`.
- Note 8 APK: `output/otlobli-v86.161-temu-inapp-arm64-debug.apk`, `205,023,908` bytes, SHA-256 `FB8FF58987EACF1FAA1288C2A96CDD262AEDE99F33626E69C0DBA1C087C91900`. Alias has the same hash.
- Emulator APK: `output/otlobli-v86.161-temu-inapp-x86_64-emulator-debug.apk`, `224,446,802` bytes, SHA-256 `5739C1332A84805C09E61C039C20D9C56EA78EE9153A792A3C4EDB794EAF7232`.
- Standard APK remains `86.156/1016`, isolated with zero Gecko/Temu-extension entries: `output/otlobli-v86.156-standard-debug.apk`, `11,125,420` bytes, SHA-256 `AE2D03603742DC5BDCD9300E0ACE7BF33E839B7B9F1AFA86EFD4755282425617`.
- Standard/personal builds, freeze guard, low-end budget, standard Android/iOS sync, standard Android assemble, and both personal ABI builds passed. iOS was synchronized with the standard web build only and was not built/device-tested.

# Handoff v86.160 — Android Temu login regression diagnosed and fixed (2026-08-12)

- Root cause was proven by a same-product/same-network A/B test, not a retry workaround. `TemuGeckoActivity` forced an iPhone Safari UA while the real client remained Android GeckoView; Temu redirected product `607511226757592` to `/login.html?login_scene=2`. Chrome Android reached guest verification, and GeckoView did the same immediately after the contradictory override was removed.
- Keep the native Gecko/Android identity. Do not restore `userAgentOverride(IPHONE_USER_AGENT)`. The persistent non-private context is now `otlobli-temu-android-guest-v86160-final`. WebExtension is `1.3.6`; personal app version is `86.160-personal-inapp/1020`.
- The rejected experimental login retry was removed completely. There must be no `recoverGuestProductFromLogin` or `otlobli_guest_retry`; do not reintroduce navigation loops as a login fix.
- Preserve the current embedded-app UX: native Otlobli bottom bar, green capture button, Temu CTA/icon blocking, native back control, and Saudi `/sa/` routing. Do not move Temu to Chrome and do not change CM, cart, payment, wallet, or completed-order logic.
- Emulator Android 15 acceptance: guest verification completed once, then force-stop/cold product launch opened directly with `LOGIN_COUNT=0`, `CHALLENGE_COUNT=0`, and no FATAL/ANR. Real Note 8 `SM-N950F` (`988e16384e4f51395230`) has the final ARM64 APK installed; its new context initially showed Temu guest verification, not login, and a later cold launch opened a real product with the Otlobli add button and bottom bar, `LOGIN_COUNT=0`, no FATAL/ANR. The Note 8 CAPTCHA was not automated. Never claim the server cannot legitimately request verification again.
- Note 8 artifact: `output/otlobli-v86.160-temu-inapp-arm64-debug.apk`, `205,023,728` bytes, SHA-256 `CD3AC4D50847BEA44F0A129DCE317BAC8FD272D7AF546E5C43BC72F79C8E1E5A`. Alias: `output/otlobli-v86.160-temu-inapp-debug.apk`.
- Emulator artifact: `output/otlobli-v86.160-temu-inapp-x86_64-emulator-debug.apk`, `224,446,622` bytes, SHA-256 `0305D5FB55ED752D380C705844E3184A6E5683B38858F83DB77FE6262F87DE22`.
- Standard artifact remains isolated at `86.156/1016`: `output/otlobli-v86.156-standard-debug.apk`, `11,125,340` bytes, SHA-256 `47C92DE395B513758AC1A86E6E0800AC1AE98670FC9F2C663CB720E2E114FAE9`, with zero Gecko entries.
- Both web builds, SHEIN freeze guard, low-end performance budget, Android/iOS standard sync, Android standard build, Android personal sync, and ARM64/x86_64 personal builds passed. iOS was not built or device-tested; this fix targets the Android personal Temu path.

# تسليم v86.159 — أصلح مسار المنتج ولا تمسح جلسة Temu (2026-08-12)

- البناء الشخصي `npm run build:temu-personal` ثم `npx cap sync android` وGradle مع `-PtemuPersonalSite=true` ينتج `86.159-personal-inapp/1019`. الافتراضي `arm64-v8a` لـ Note 8؛ للمحاكي أضف `-PtemuPersonalAbi=x86_64`.
- أصل غياب زر Otlobli كان حارساً قديماً في `scripts/build-temu-gecko-extension.mjs`: قبل فقط `/goods.html` و`goods_id=` ولم يقبل مسار iPhone الحالي `-g-<id>.html`. الحارس المولد و`looksLikeProductPage()` يقبلان الصيغ الثلاث الآن. لا تعكس هذا الإصلاح.
- WebExtension `1.3.4` تُظهر زر Otlobli الأخضر وتخفي `حدد خياراً`/`اختر خياراً` وشريط شراء Temu والتحكم العائم الزائد على صفحة المنتج فقط، مع استثناء كل عنصر `id` يبدأ بـ`otlobli`. الزر الأخضر عند `bottom:16px` لأن شريط Android الأصلي يقصّر مساحة GeckoView.
- زر الرجوع الأصلي يأخذ status-bar inset + `24dp` ويختفي على `/sa` و`/sa/`. شريط Otlobli السفلي، حجب حساب/سلة/قائمة Temu والعجلة والنوافذ وأشرطة فتح التطبيق باقية. لا تعِد Chrome/System WebView ولا تغيّر CM أو الدفع أو المحفظة.
- أبقِ `contextId=otlobli-temu-ios-guest-v86158-final2` حرفياً ولا تستبدله باسم إصدار جديد. الجلسة non-private ولا توجد أي عملية clear؛ تغيير المعرف أو مسح بياناته يعيد CAPTCHA. أول منتج بعد تحديث APK و`force-stop` فتح بلا تحقق أو دخول، ما أثبت الاستمرار. بعد نقرات ADB سريعة أعاد خادم Temu منتجات لاحقة إلى `/login.html`؛ سجّلها كقيد خادم ولا تحاول تجاوز CAPTCHA أو تدّعي أن كل المنتجات مقبولة.
- على `Pixel_7_API_35_Test`/Android 15 نجح cold launch بلا مسح البيانات، الرئيسية السعودية بلا زر رجوع زائد، المنتج الأول أظهر زرنا وأخفى `حدد خياراً`، ولا توجد FATAL/ANR. تُرك المحاكي على الرئيسية.
- نسخة Note 8: `output/otlobli-v86.159-temu-inapp-arm64-debug.apk`، `205,023,728` بايت، SHA-256 `F3C403436BA4FA8E9E467FE06D1D9B0FFB7E6E2CD2233595D10214E0F7CFE5F9`. Note 8 غير متصل؛ لا تدّع التثبيت أو القبول عليه.
- نسخة المحاكي المثبتة: `output/otlobli-v86.159-temu-inapp-x86_64-emulator-debug.apk`، `224,446,622` بايت، SHA-256 `DB0880D1C30A6242EBF3B13720D1EF4D1350C1374A6E455A21D874365246F72B`.
- البناء العادي بقي `86.156/1016` وصفر Gecko entries: `output/otlobli-v86.156-standard-debug.apk`، `11,125,340` بايت، SHA-256 `B3789760FC756E459C43951844CD1CBF87781FFD6DBADDB1BEEA97FB93F08EDC`. نجح build/freeze guard/performance budget وAndroid+iOS sync وAndroid assemble. iOS لم يُبن أو يُختبر على iPhone.

# تسليم v86.156 — Temu الداخلي مستعاد، لا تعِد تجارب Chrome (2026-08-12)

- المصدر الحالي `86.156/1016` ومثبت على Note 8. Temu داخل WebView Otlobli بنفس الشكل والحجب، السعودية
  ثابتة (`/sa/` وSAR)، ولا يوجد فيه Custom Tab أو فتح متصفح خارجي؛ ذلك محصور ببناء `temu-personal` أعلاه.
- Chrome الحقيقي/المؤقت فتح منتجين سعوديين كضيف بعد تحقق يدوي، لكن WebView الداخلي أعاد دائماً
  `424/40001` ثم `403 NEED_LOGIN` حتى بعد cookies وUA والتحقق اليدوي ورمز صالح وإعادة واجهات المنتج عبر
  VPN الجهاز، ثم تجربة تمرير كل واجهات Temu بهوية Chrome. لا تكرر هذه الفرضيات ولا تدّعِ أن المنتج الداخلي فتح.
- المستخدم طلب صراحةً إعادة الشكل والحجب كما كان. لذلك حُذفت كل طبقة البروكسي، هوية Chrome، مسار Temu
  المباشر في Android، والسجلات التشخيصية الحساسة. رقعة InAppBrowser أُعيد توليدها ولا تحتوي التجارب.
- السلوك المقبول الآن: الحجب القديم يعمل، ولا توجد عجلة جوائز كاملة الشاشة، وصفحة الدخول التي يفرضها Temu
  تظهر داخل التطبيق بدل شاشة بيضاء/طرد. لا تغيّر هذا إلى متصفح خارجي بلا طلب صريح.
- نجح build + freeze guard + performance budget + Android/iOS sync + `assembleDebug`. APK النهائي:
  `android/app/build/outputs/apk/debug/app-debug.apk`، الحجم `11,126,604`، SHA-256
  `3A14535400020A21E4AF85D8DB4DD307514612320647796B648EBF66ADE03CC4`.
- الجهاز أكد `86.156/1016` ولا توجد FATAL/ANR أو `TemuGuestProxy`. iOS متزامن فقط ولم يُبنَ أو يُختبر؛
  أبقِ حارس تجمّد SHEIN وتوقيت recompose كما هما.

# تسليم v86.153 — حافظ على صفحات حساب تيمو ولا تعِد عجلة الجوائز (2026-08-12)

- النسخة الحالية `86.153/1013` على الفرع `claude/temu-issues-v86134`، ومثبّتة
  على Note 8 (`988e16384e4f51395230`). لا تعد منطق الدفع أو المحفظة جزءاً من هذه
  الدفعة؛ الصيانة محصورة بتيمو.
- أصل الشاشة البيضاء على `/login.html` كان محلياً: `otlobliCleanTemuBlockers()`
  أخفى الحاوية العامة لنموذج الحساب ووضع `data-otlobli-temu-clean-hidden=1`.
  الحارس الحالي يعيد العناصر التي أخفاها الكود ثم يرجع فوراً على account routes.
  لا تنظف أو تخفِ صفحة دخول/تحقق تيمو، ولا تعِد `temuLoginBlocked` أو التحويل
  الإجباري للرئيسية؛ Temu قد يفرض الدخول فعلياً عبر `403 NEED_LOGIN`.
- عجلة الجوائز تُكتشف بمرساة selectors رخيصة قبل استدعاء
  `hideTemuSpinWheelPopup()`. أبقِ شرط ancestor
  `[data-otlobli-blocked="1"]` كي لا يتحول الحل إلى مسح DOM ثقيل في كل tick.
- `App.tsx` يعرض تحقق تيمو الحقيقي لمنتج السلة المعلّق، و
  `humanCheckResolved` ينهي حالة التحدي لكل متجر. `sheinHumanCheck.ts` يستخدم
  تسمية Temu الدقيقة عند المتجر الحالي. لا تعكس هذه التغييرات إلى SHEIN.
- دليل الجهاز: الرئيسية والمنتجات ظاهرة بلا wheel؛ منتج فرض الدخول فأظهر النموذج
  الكامل؛ الرجوع والسلة عملا؛ ثلاث دورات resume حافظت على `PID 29796`؛ cold
  launch نجح بـ`PID 31641`. لا Crash/ANR، ولا `temuLoginBlocked`، ولا تكرار
  `clearCookies`. لم يُتجاوز تسجيل الدخول أو CAPTCHA آلياً.
- `npm run build` وحراس SHEIN/الأداء ومزامنة Android+iOS و`assembleDebug` نجحت.
  APK المثبّت حجمه `11,124,980` بايت وبصمته
  `05E0885CE5D406D74F551AEE0E9A320E46305FFC5EFE1E90A468AB45EA3E4952`.
  ESLint المستهدف يعرض الدين السابق `31 error/15 warning`.
- iOS متزامن فقط ولم يُبنَ أو يُختبر على iPhone. لا تدّع قبول iPhone 16 قبل
  خمس دورات background/resume واختبار force-quit/cold-launch الحقيقيين.

# تسليم v86.150 — لا تحوّل تحقق تيمو إلى نفاد أو رجوع للرئيسية (2026-08-11)

- المرشح المحلي `86.150/1010` على الفرع
  `claude/temu-issues-v86134`. لا تعتمد ادعاء قبول `86.147` القديم: المستخدم
  أثبت أن المنتجات الظاهرة كلها كانت تقول «نفدت» ثم تطرده للرئيسية.
- السبب المثبت: `token/touch` أعاد `424/40001` و`integration/render` أعاد
  `403 NEED_LOGIN`، ثم اعتراضاتنا في React والسكربت المحقون كانت تستبدل صفحة
  الدخول/التحقق برئيسية السعودية. أزيلت اعتراضات `temuLoginBlocked` والرجوع
  الإجباري؛ أبقِ التحقق أو الدخول مرئياً وتفاعلياً.
- لا تعِد `writeTemuSaudiUsdState` أو أي كتابة لمفاتيح تيمو في cookies/storage.
  الرئيسية `/sa/` بلا فرض USD، والروابط الأصلية `/goods.html` لا تُسبق بـ`/sa`.
  السعودية ثابتة من إعداد المتجر والمسار؛ عملة واجهة تيمو عادية (SAR على الجهاز).
- الهجرة `otlobli.temu-guest-session-repair.v2` تنظف كوكيز تيمو مرة واحدة فقط.
  رقعة Android لـ`clearCookies` الآن تنتهي صلاحية host/domain cookies فعلياً
  وتعمل قبل فتح WebView؛ iOS يحذف كوكيز المضيف بعد الفتح. أي فشل cleanup يجب
  ألا يمنع فتح المتجر.
- دليل الجهاز: بعد تنظيف محصور لـ`temu.com` أصبحت الجلسة
  `region=174 / ar / SAR` وظهر تحقق تيمو الحقيقي بدل «نفد المنتج». لم يتم
  التحايل على CAPTCHA آلياً، ولذلك ما زال قبول عدة منتجات بعد إكمال التحقق
  يدوياً مطلوباً. لا تدّع قبول صفحة المنتج من سجلات الشاشة وحدها.
- `npm run build` وحارس SHEIN وميزانية الأداء نجحت؛ Android وiOS متزامنان.
  lint الشامل له دين سابق (33 error/16 warning). لم يُبنَ APK `86.150` لأن
  تبعيات Gradle غير موجودة offline، والوصول الخارجي رُفض بسبب حد استخدام
  البيئة. لا تسلّم APK `86.149` القديم على أنه هذا الإصلاح.
- iOS لم يُبنَ أو يُختبر على جهاز. حافظ على حارس تجمّد SHEIN واختبارات iPhone
  16 الخمس + cold launch قبل أي ادعاء قبول iOS.

# تسليم v86.147 — أساس تيمو v85.8.77، السعودية، والجذب محفوظ (2026-08-11)

- النسخة الحالية `86.147/1007` ومثبّتة على Note 8. أساس تيمو المقصود هو خط
  `v85.8.77` من GitHub، ومرجعه `b22f5d1`. لا تُعد طبقات المنطقة/التحدي وإعادة
  التوجيه المتشابكة التي أضيفت لاحقاً بلا مقارنة مقصودة واختبار جهاز حقيقي.
- السعودية ثابتة حصراً: `SA` و`/sa/` و`region=174` و`ar`. تجاهل إعداد تيمو
  المخزن أو البعيد مقصود. عرض الموقع `ر.س` وعملة سلة التطبيق الداخلية USD مقصودان.
- حافظ على `temuStripQuantity()` في مسارات اللون والمقاس وpayload؛ هذا هو إصلاح
  الجذب الذي ثبُت سابقاً، وقد أُعيد وحده فوق الأساس القديم.
- اعتراض `/login.html` في الغلاف الأصلي باتجاه واحد إلى رئيسية السعودية أو سلة
  التطبيق مقصود. لا تعاود فتح منتج رفضه خادم تيمو. إعادة الصفحة الفارغة محدودة
  بمحاولة واحدة في sessionStorage. تيمو قد يفرض الدخول على بعض المنتجات والبحث؛
  التطبيق لا يتجاوز ذلك.
- دليل القبول: `temu-acceptance-86146.mp4` (`149.964s`، كل `1427` إطار محلل،
  أطول بياض صارم `0.289s`) و`temu-cdp-acceptance-86146.jsonl` (صفر blank، وصفر
  منطقة/لغة خاطئة). لقطات smoke النهائية تبدأ بـ`temu147-` في مجلد الأدلة نفسه.
- البناء وحارس SHEIN وميزانية الأداء ومزامنة Android+iOS وAndroid debug build
  نجحت. APK: `11,125,532` بايت، SHA-256
  `29B2250CBA057459440048C758A6566F99243256E579A99A07FDC11533B3666E`.
- iOS لم يُبنَ أو يُختبر على جهاز حقيقي. لا تدّع قبول iPhone 16 قبل الخمس دورات
  واختبار التشغيل البارد المطلوبين في حارس التجمّد.

# تسليم v86.142 — تيمو السعودية، بلا حلقات استرداد (2026-08-11)

- النسخة المحلية الحالية `86.142/1002`. لا تغيّر قفل تيمو: السعودية حصراً،
  `TEMU_REQUIRED_COUNTRY='SA'` و`region=174`. بقاء USD في رابط/سلة التطبيق مقصود.
- لا تُعد حارس محاولة تسجيل الدخول إلى cookie أو Storage. تيمو مسحت الكوكي وسببت
  حلقة خفية. المصدر الصحيح الآن علامة `otlobli_guest_retry=1` داخل رابط `from`؛
  وفشل الرندر الحقيقي يستخدم `otlobli_blank_retry=1` للتحميل الواحد فقط.
- الاختبار الحاسم لمنتج السلة `goods_id=601102744253630`: المنتج عند 2.920s،
  login عند 5.420s، محاولة موسومة عند 5.680s، login ثانٍ عند 9.000s، ثم رئيسية
  السعودية عند 9.266s بلا أي انتقال حتى 90.18s. PID بقي `9325` بعد خمس عودات.
- سجل الفحص: `C:\Users\MOHAMMAD\.codex\visualizations\2026\08\11\019ff1d4-5219-7900-8034-266991113e4c\temu-cdp-final-86142.jsonl`.
  الفيديو: `temu-final-86142.mp4` (89.747s). تحليل 359 عينة أعطى صفر إطار قريب
  من الأبيض الكامل. أخطاء 403/429 من API تيمو خارجية وتفسر بوابة الدخول/التحقق.
- البناء والحراس والميزانية ومزامنة Android+iOS و`assembleDebug` نجحت. APK حجمه
  `11,125,180` وبصمته `BD7E012E459B9CFA0AB30E36310E715C7CDAE0A2D6B24088588E79D2E4BF606A`.
- لم يتم بناء/اختبار iOS على جهاز حقيقي؛ لا تدّعِ قبول iPhone 16 قبل خمس دورات
  background/resume مستقلة واختبار force-quit/cold-launch.

# v86.134 — تيمو: قصّ ذيل «الكمية» من اللون/المقاس (2026-08-11)

فُحص تيمو على النوت 8 (`988e16384e4f51395230`) عبر CDP + `screencap` مع نقرات
`adb input` حقيقية. المُثبت وقت الفحص كان **v86.67**، لا 86.125.

ما ثبت على الجهاز:

1. **تلوث اللون بالكمية.** صف «الكمية» في تيمو شقيق لصفّ اللون/المقاس داخل نفس
   الحاضن، فأي قراءة نصية تصعد مستوى واحداً تلتصق به. العنصر الحقيقي في DOM
   نصّه `اللونالكمية1`، والسلة كانت تحمل `color = "【أبيض】الكمية1"`، و
   `__otlobliDiag.color()` أعاد `الكمية1` كـ«لون مختار» على منتج بلا أي اختيار.
   الإصلاح: `temuStripQuantity()` تقصّ `الكمية/كمية/quantity/qty` وما بعدها، وتُطبَّق
   في `temuColor()` و`temuColorFromHeading()` وعند تخزين نقرة كرت اللون، ثم حارس
   أخير على `color`/`size` داخل `captureProductPayload`. القيمة التي ليست إلا
   كمية تصير فارغة، فيطالب التطبيق الزبون باختيار اللون بدل إرسال قيمة ملفّقة.
   **مُتحقَّق على الجهاز:** إضافة «قميص بولو» بعد اختيار L أعطت
   `size = "L"`, `color = ""`, `priceUsd = 7.74` (28.15 ر.ق × 0.275) — بلا أي ذيل كمية.

2. **موت العملية وإعادة الفتح (شكوى «يضوي ويطفي ويعيد تحميل»).** على v86.67 مات
   `com.otlobli.app` مرتين أثناء تصفّح تيمو بلا تدخّل (pid 8876→10822 و
   12970→14479)، وفي لقطة واحدة كانت **نافذتا WebView لتيمو حيّتين معاً** على نفس
   الرابط. هذا هو بالضبط ما عالجه **v86.126** (`onRenderProcessGone` في رقعة
   InAppBrowser وفي `MainActivity`) وهو غير موجود في 86.67. بعد تثبيت v86.134 لم
   تمت العملية خلال جولة الفحص الكاملة (pid 15246 ثابت).

3. **المنطقة/العملة.** الأسعار تظهر بالريال القطري (`ر.ق`) وعنوان الصفحة
   `Temu Qatar` رغم `/sa/` و`currency=USD` — تيمو تتبع IP الـVPN لا المعاملات.
   التحويل QAR→USD في `temuPriceUsd()` سليم (0.275 مثبّت)، فالسعر المحفوظ صحيح.
   لم يُغيَّر شيء هنا؛ مسجَّل للمتابعة.

4. **بوابة الدخول من المتصفّح لا من الجهاز.** من متصفّح المطوّر ترتدّ كل صفحات
   المنتجات إلى `/login.html`؛ على النوت 8 (VPN قطر) تفتح المنتجات طبيعياً. لا
   تغيير في منطق `otlobliTemuRecoverFromLoginRedirect`.

البناء ودليل التجميد وميزانية الأداء ومزامنة أندرويد و`assembleDebug` تمرّ كلها.
النسخة `86.134/994`، مثبَّتة على النوت 8. لم يُبنَ iOS في هذه الجلسة.

# Current candidate — v86.125 strips injected-script comments at build time (2026-08-10)

- **Base is still v86.117 (`bf40b1c`).** Runtime behaviour is unchanged from
  v86.124: same timings, same hiders, same checks, same back fix.
- The store scripts are injected into the SHEIN/Temu page **as source text**, so
  comments were being shipped and tokenised on the device at every page load —
  92,969 of 546,397 bytes, 17%. A Vite plugin
  (`scripts/strip-injected-comments.mjs`) removes whole-line comments at build.
  **Write comments freely in that file now; they cost the device nothing.**
- Shipped into the store page: 546,397 → 453,428. App bundle: 1,167,084 →
  1,073,774 raw, 322,756 → 283,701 gzip.
- The stripper removes only lines whose trimmed form starts with `//`. Do not
  extend it to trailing or block comments without a tokeniser — that needs real
  parsing to be safe, and line comments were nearly all the weight.
- `verify-shein-freeze-guard.mjs` now parses the **stripped** module, since that
  is what the WebView receives. Keep it that way: validating raw source would
  let a stripping bug reach a device.
- Budget metrics changed. `shipped store scripts raw` (470,000) is the real
  device budget — hold the line there. `SHEIN script source raw` was raised
  550,000 → 600,000 because comments no longer reach the device and the old
  ceiling had tightened to 67 bytes, where documenting an optimisation cost more
  than it saved. **This is not permission to grow the shipped scripts.**
- Still open from v86.124: `document.body.innerText` in
  `checkForSheinSecurityBlock` forces a full-page layout every 1.6s. It already
  skips while the user is interacting, so it is not a scroll-jank source — lower
  priority than it first appeared. If addressed, gate on a total element count
  of 600+ and test against a real block page; a previous
  `body.children.length > 8` gate silently disabled the detector.
- Version `86.125/985`; diagnostics off. Build, freeze guard, performance
  budget, Android sync and Android debug assemble pass. ESLint 49 before/after.
- **Nothing measured on a device.** Acceptance: faster product-page start,
  concealment exactly as immediate as v86.117, back button never dead-ending.

# Current candidate — v86.124 low-end speedups on the v86.117 base (2026-08-10)

- **Base is v86.117 (`bf40b1c`).** The whole functional diff against it is five
  lines-groups: `otlobliBackOrLeave()` + its call site (v86.123), and three
  speedups (v86.124). Verify with
  `git diff bf40b1c -- src/services/sheinBrowserScript.ts`. Keep it that small.
- **The rule: cut work per pass, never lengthen the interval.** v86.118 and
  v86.121 both bought speed by stretching the concealment pass to ~950ms and
  both were rejected on the iPhone 6. The guard now forbids
  `OTLOBLI_VERY_LOW_END`. Both add-hiders still run on every 650ms pass.
- `if (OTLOBLI_LOW_END) return true;` in `observeOtlobliDocumentRoot` — low-end
  devices do not observe DOM mutations at all. `scheduleTick()` returns
  immediately there, so the observer's only effect was clearing
  `sheinBlockReported`, at the price of a mutation record and a microtask on
  every DOM change SHEIN makes. The history hooks still clear that flag. Do not
  re-enable observation on low-end without re-checking that reasoning.
- The two hot hiders skip already-hidden nodes before reading geometry. This is
  a layout-thrashing fix: a rect read after a style write forces a synchronous
  layout per iteration. Inline-style reads are layout-free — keep the skip
  before `getBoundingClientRect()`, never after.
- Still open: `document.body.innerText` in `checkForSheinSecurityBlock` forces a
  full-page layout every 1.6s. The safe gate is a total element count, but a
  previous `body.children.length > 8` gate silently disabled the detector
  because the block page exceeded it. Use 600+ and test on a real block page.
- Version `86.124/984`; diagnostics off. Build, freeze guard, performance
  budget, Android sync and Android debug assemble pass. ESLint 49 before and
  after. APK SHA `AE987756CFC0EB90352F41D1D71589B8C5D75F682E042C183B0E04B9A82CAE30`.
- **Budget wall: SHEIN source is 549,933/550,000 — 67 bytes free.** Every change
  was funded by condensing comments on the code it touched; no ceiling raised.
  17% of this file (93,739 bytes) is comments that ship into the page as part of
  the injected string and are parsed on-device for nothing. Stripping them at
  build time would ship ~456,195 bytes and unblock further optimisation, but it
  needs a build transform plus a guard measuring the emitted script. Undecided.
- **Nothing was measured on a device.** Acceptance: smoother scrolling on a
  SHEIN listing and product page on the iPhone 6, concealment as immediate as
  v86.117, and the back button never dead-ending.

# Current candidate — v86.123 is v86.117 plus a back button that cannot dead-end (2026-08-10)

- **Base is v86.117 (`bf40b1c`), restored verbatim.** `src/`, `patches/` and the
  freeze guard were checked out from that commit; one change is applied on top.
  Do not reintroduce anything from v86.118 → v86.122 without new device
  evidence. The customer rejected v86.116 (button gone) and v86.118 (concealment
  traded for speed), and v86.119/120/121 chased problems v86.117 never had.
- **The v86.122 false-VPN-gate work is abandoned on purpose.** Those defects
  belong to the v86.121 lineage, which is no longer in this tree. If a VPN
  false alarm is ever reported against a v86.117 base, re-derive it there.
- Root cause of the one real defect: the native back button forwards its tap to
  the in-page button, whose handler ended in a bare `history.back()`. That call
  is a SILENT no-op once the back stack is spent — no error, no navigation. Each
  back consumes an entry while re-entering a product does not always add one, so
  the stack runs dry and the button dead-ends while still looking live.
- `otlobliBackOrLeave()` records the URL, calls `history.back()`, and 900ms
  later goes to the recorded `__otlobliHomePath` if nothing moved. A real
  navigation tears the JS context down before the timer fires, so a slow but
  working back is never overridden. Keep the wrapper; the guard forbids the
  bare call.
- **Do not chase the v86.117 slowness.** That is exactly what produced v86.118's
  rejected concealment. Both add-hiders must run every pass, and no "very low
  end" interval tier may be added — that shape was rejected on device twice.
- Version `86.123/983`; diagnostics off. Build, freeze guard, performance
  budget, Android sync and Android debug assemble pass. Local JS SHA is
  `F387266DD31FA09D61E9306EBA989A9491236B1E90396CCE94ED3CB4867E7F0D`; APK SHA is
  `2543C69A28B75437816B4CD066E2D4B7898FEEB14363BEA0E89576D606DB765F`.
- SHEIN source is `549,909/550,000` — 91 bytes spare, and only because the
  comment on the replaced code was condensed to fund the fix. The next edit to
  that file must remove at least what it adds. Do not raise the ceiling.
- Desktop APK: `C:\Users\MOHAMMAD\Desktop\otlobli-v86.123-debug.apk`. Debug
  signing only; the production key is absent on this machine.
- **Nothing was validated on a device.** Acceptance: on the iPhone 6, hop
  through five or more products and confirm back never stops responding; when
  the stack is genuinely spent it must land on SHEIN home, not freeze. Confirm
  concealment still matches v86.117.

# Current candidate — v86.121 restores the v86.118 runtime (2026-08-10)

- Real-device evidence: v86.120 displayed the corrected supported-region text
  but did not enter SHEIN; the user identified v86.118 as the last working IPA.
- `src/services/sheinBrowserScript.ts` now matches v86.118 commit `c2cc383`
  exactly. Do not reapply v86.119's faster two-core intervals/immediate critical
  scan without new device evidence.
- A supported geo/reachability result authorizes opening but must not arm
  `sheinCacheResetPendingRef`. That v86.120 change made every healthy start a
  cold-cache launch. Cache reset stays limited to the existing bounded recovery
  and Temu → SHEIN fresh-session paths.
- Keep the corrected Qatar/preparation copy, coordinated manual retry, approved
  back behavior, iPhone 16 recompose lifecycle, Android resume defense and
  `JSON.stringify` region comparison. No new polling/timers/effects were added.
- Version `86.121/981`; diagnostics off. Build, freeze/performance guards,
  native syncs, Android debug assemble and Xcode run `31340886636` pass. Local
  JS SHA is `683F1D6EB6F004F1F85D4BCB5C1E29129DE4DF9A59CAE81F02DD3FB36BA89CD4`;
  APK SHA is `DB955A35C9F48AFF4775EBCDC1BFA634FEF25E02E5F036DD34D35A4F10A9F492`.
- Desktop IPA:
  `C:\Users\MOHAMMAD\Desktop\otlobli-ios-v86.121-iphone\otlobli-v86.121-iphone16-unsigned.ipa`,
  7,050,682 bytes, SHA-256
  `43C31B9BEBECA834DD74DACA038CCD7EAB774CA73D2AB7462316A7A4D81303BF`.
  Archive is `com.otlobli.app`, `86.121/981`; CI JS SHA is
  `4D774702530EA647D7CF7AE84529AF128FD9B449E989242F608D6EA6F0994525`.
  It is unsigned/unprovisioned and lacks production APNs/Google iOS setup.
- Required acceptance: clean/cold Qatar entry on the pictured iPhone, cart
  product open/back/concealment, five iPhone 16 resumes, separate cold launch,
  and SHEIN → Temu → SHEIN.

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
# v86.135 — Temu Saudi storefront lock (2026-08-11)

- Do not remove the `region=174` enforcement in `writeTemuSaudiUsdState`/`enforceTemuRegion`. Temu's `/sa/`, `country=SA`, and `countryCode=SA` do not determine the served storefront when the VPN exits elsewhere.
- Device evidence before the fix: `region=165`, title `Temu Qatar`, locale `ar-QA`. Temu's own `window.__REGION_CONFIG__` maps `sa.id=174` and `qa.id=165`.
- Device evidence after installing `86.135/995`: title `Temu Saudi Arabia`, cookie `region=174`, storage country `SA`, locale `ar-SA`; VPN/device timezone remained Qatar.
- The reload is guarded per wanted region. A successful Saudi load clears the guard so a later Temu overwrite can be repaired again; a server that repeatedly rejects the cookie cannot cause an infinite loop.
- Web build, freeze guard, performance budget, Android+iOS sync, and Android debug assemble passed. iPhone 16 acceptance and IPA build were not performed.
# Handoff v86.165 — live SYP/new-lira chain fixed and device-verified (2026-08-12)

The live source, Oracle, and Supabase all currently agree on new SYP: sp-today Buy `131.20` / Sell `131.70`; Oracle `/api/exchange-rate` returns `131.7` from `sp-today.com`; Supabase public settings returns `131.7` and `syp_denomination=new`. The v86.164 client was the broken leg: both its Oracle and Supabase writers accepted only old-unit rates above 1000. v86.165 accepts only a positive one-dollar FX rate below 1000, parses decimals, rejects stale 13,000-style local/env values, repairs unmistakably old `priceSyp` cart rows from `priceUsd`, and uses Oracle every 30 visible minutes with Supabase as startup fallback. The 1000 ceiling is only an FX sanity boundary, never an order cap; the live verifier proves `$1,000 -> 131,700 new SYP`.

`npm run verify:live-syp-rate` verifies source + Oracle + Supabase + a >1000 order-total case. The standard/personal/admin builds, standard/personal Android builds, Android/iOS sync, freeze guard, and performance budget passed. Note 8 is updated in place to `86.165-personal-live-syp/1025`; CDP proved Oracle `[200]`, app-settings `[200]`, and `talabieh.exchangeRate=131.7`, with both carts retained. Personal artifact: `output/otlobli-v86.165-temu-personal-arm64-debug.apk`, 205,028,564 bytes, SHA-256 `8CB8ADB246E5E2161D43E18CA1372D716DE9FF32D96B8AA4F76751D18DD22C09`. Standard artifact: `output/otlobli-v86.165-standard-universal-debug.apk`, 11,129,572 bytes, SHA-256 `C729CA8528A06A6F085EE880AA96D8D01C391E0833287C52258BF8D2FB5BE7A7`.

Production DB/Oracle were already converted/deployed by the earlier v86.134 currency batch. The two matching local migrations are now present and idempotent; do not re-divide production data. No real order or ShamCash payment was created in this batch. GitHub Actions `exchange-rate.yml` is still a broken **secondary writer** because repo secrets `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are absent; latest inspected run `31589190785` failed for exactly that reason. Oracle is the healthy primary writer. No service-role key was found locally, so do not fabricate or expose one. iOS is synced/versioned `86.165/1025`, but Xcode/device build, five iPhone 16 resume cycles, and cold launch remain unperformed.
# Active handoff — v86.238/1103 final Android artifact, iOS upload pending (2026-08-25)

Work only in `C:\Users\MOHAMMAD\Projects\otlobli-v86-212-testflight-auth` on
`codex/otlobli-v86-212-testflight-auth`. Standard Android/iOS are
`86.238 (1103)` and Gecko is `1.3.22`. Preserve all existing dirty-batch work;
do not restore from an older branch.

The remaining Android 15/16 geometry fault was a duplicate status inset in
Capgo's blank Temu toolbar. Keep the narrow predicate: native Otlobli
navigation + Temu session + `toolbarType == "blank"` gets `topMargin=0`; every
other WebView keeps the upstream status inset. A53 evidence was collected
before the final build and proves the cause, not final physical acceptance.

Entry education is native on all shipped store surfaces. After actual
visibility, a bounded one-shot says `انقر «الرئيسية» مرتين لفتح قائمة المتاجر`.
The first Home tap says `انقر مرة ثانية لفتح قائمة المتاجر`; a second tap
within `320ms` routes to `store-select`, never directly to another store.
Assistive activation opens the chooser directly. Keep the hint outside WebView,
challenge-gated, and cancelled on hide/dismiss. Capgo iOS must retain
`otlobliSetStoreSurfaceVisible(!hidden)` so an attached hidden controller
re-arms an unconsumed one-shot after show. Dedicated iOS SHEIN schedules the
same one-shot from both show paths.

The fallback navigation uses `window.__otlobliStoreNavigationChallengeLocked`,
set on challenge entry and cleared only after the settlement window. Its URL
fallback uses exact path segments/query keys, not free substring matching.
Do not replace it with `otlobliInterventionPausedForHumanChallenge()`; that
prevents Terser DCE and expands both store scripts to about `242KB`.

Android document-start Temu blocking/cookie preparation is bounded and has no
persistent observer, interval, or broad DOM scan. Real human verification is
untouched and remains user-controlled. The native bar remains outside WebView.
Keep the standard WebView owner `{store, sessionId, id}` independent from the
visible Cart tab; late capture/ACK must stay source-owned.

Final standard APK:

- `artifacts/release-86.238/Otlobli-86.238-1103-release.apk`
- `4,110,560` bytes
- SHA-256 `A123FFA957EFFAB8FEC44CDABC0C37B5CD9EB09166C00326A6F8581ECC0E61B9`
- package `com.otlobli.app`, `minSdk 24`, `targetSdk 36`
- expected certificate SHA-256
  `e0b0f44cc677888f9535c01c9125077e09b014bdb9096dc2813e3bd06f17f784`

The final APK is installed and launch-checked only on the Android 15/API 35
emulator, which is logged out. Note 8 disconnected before the final artifact
could be installed. Earlier v86.238 evidence proves the Note 8 button gap and
cart-tab ownership, but not a real-finger double tap on the final artifact.
Do not claim the missing cookie-clean-profile, A52/Android 16 final acceptance,
or the inverse store selection as passed.

All source/release/freeze/store/size/security guards, TypeScript, Java compile,
personal and standard builds, and Android/iOS sync pass. Final budgets are
startup `669,808/720,000`, JS gzip `298,229/370,000`, CSS `69,932/70,000`,
fonts `81,364/100,000`, shipped scripts `316,976/470,000`, Gecko
`172,005/180,000`, and source `580,141/600,000`. SHEIN/Temu minified runtime
sizes are `146,069/170,907` bytes.

Preserve `WKWebViewController.otlobliForceRecompose()`, the exact
`appDidBecomeActive` `0.25s` delay, scroll/constraint restoration, Android
`otlobliOnHostResume()`, and the `JSON.stringify` region comparison. iOS is
synced but device acceptance still requires five iPhone 16 resume cycles plus
a separate force-quit/cold-launch.

The current source commit is `a53fbf9b5d6377a159794d570c239c53f7e71d40` and
is pushed. TestFlight runs `32886967159`, `32887220144`, and `32887640272`
all failed in `Verify TestFlight authentication configuration` because the
production health response had `whatsappConnected=false`. They stopped before
signing, IPA creation, upload, or App Store submission. Do not bypass or weaken
that guard. Reconnect the existing WhatsApp sender outside this Temu task, then
rerun `ios-unsigned-build.yml` with `signing_mode=testflight`,
`testflight_delivery=upload-and-distribute`, and `app_store_submission=false`.

# Active handoff — v86.239/1104 OTP OS-autofill best effort (2026-08-25)

Work only in `C:\Users\MOHAMMAD\Projects\otlobli-v86-212-testflight-auth`.
The standard Android/iOS source is now `86.239 (1104)`; Gecko remains
`1.3.22`. Preserve all prior Temu/store-session work and the existing dirty
artifacts.

The OTP receiver fix is deliberately small. The first of six inputs now accepts
all six characters and retains `autocomplete="one-time-code"`, a numeric
keyboard hint, and stable `id`/`name`; the existing distributor fills the six
boxes and submits. Explicit paste is synchronous and calls `preventDefault`, so
the removed zero-delay timer cannot submit the same code a second time. Do not
replace this with notification access, background clipboard reads, WebOTP,
polling, or a hidden native listener. The visual layout did not change.

`server/src/otpMessage.js` validates and formats a six-digit message with the
code once, as the only numeric sequence. `sendOtpMessage` uses it. The two files
were narrowly deployed to Oracle after a byte-level diff against the live
sender. Backup:
`/home/ubuntu/otlobli-server/backups/pre-v86239-20260825T195204Z`.
Remote/local SHA-256 values match: `whatsapp.js`
`8854E6A7CFBBEFE02CFC1DC728643750D3352AD725866E25FE4D4B730FC5D65F` and
`otpMessage.js`
`F37411D9049B62EB584E54C9D6C8480EB1580C64418172DE394456FDA0295F28`.
The PM2 process is online. Session `0` was found idle with credentials, no QR,
no pause, and zero risk; it was reconnected through the protected admin endpoint
without deleting or replacing the session. Final production health after the
TestFlight run reports `whatsappConnected=true`, `whatsappSenderReady=true`,
`whatsappCredentialsPresent=true`, `sessionStoreReady=true`, and
`otpSecurityReady=true`. No test OTP was sent to a customer number, so real
delivery/autofill remains a physical-device acceptance item. Plain
WhatsApp/Baileys autofill is an OS/keyboard heuristic; documented Meta
authentication templates are needed if guaranteed WhatsApp behavior is later
required.

Validated: all OTP/release tests, full production build and guards, Android+iOS
Capacitor sync, signed APK+AAB release build, APK signature/certificate, and an
Android 15 emulator update/launch with no matching fatal/ANR. Scoped ESLint has
zero errors; full lint retains three unrelated pre-existing SHEIN navigation
escape errors. Do not fix those in this OTP batch. Artifacts:

- `artifacts/release-86.239/Otlobli-86.239-1104-release.apk`, 4,110,593 bytes,
  SHA-256 `55F045753739087B03BE6B7D394D07D6E135D7A16626EA0C01864EED1F86DACB`.
- `artifacts/release-86.239/Otlobli-86.239-1104-release.aab`, 5,770,899 bytes,
  SHA-256 `FE987CAB470FDE3271A31AEE21EE06999A7DE000D82A524E6784945D0CE23C3F`.

Commit `8624f59d712df7e07a743f1853e53ee014891a03` is pushed. GitHub Actions run
`32892860453` succeeded in `7m33s`: TestFlight auth preflight passed, the signed
App Store IPA validated and uploaded without errors, Apple delivery UUID is
`52f69212-271d-4564-8b60-48368e161b59`, and exact build `86.239 (1104)` became
`VALID` then `IN_BETA_TESTING` in the all-builds `Otlobli Internal` group. The
expected tester membership was verified with state `INSTALLED`. App Review was
explicitly disabled/skipped. GitHub signed artifact `9580341324` is 25,250,769
bytes with archive SHA-256
`60BED115072CCDBC15F000E91296D87E2F6835C4B846C3109548FAF805FE7F2F`.

No real Note 8, A52, or iPhone was connected; physical keyboard-suggestion and
five-cycle iPhone acceptance did not occur. SHEIN, regions, store sessions,
human verification, payment, orders, and wallet were untouched.
Preserve `otlobliForceRecompose()`, the `0.25s` `appDidBecomeActive` delay,
Android resume defense, and `JSON.stringify` region comparison.

# Active handoff — v86.240/1105 host destination, cart, and iOS Temu gap (2026-08-26)

The user-visible store session and the host Home destination are now separate.
`hostHomeDestinationRef` is transient and must not be persisted or merged back
into `selectedStore`. Parking a store for the chooser sets `store-select` but
does not close the native session. Explicit store entry sets `home`; same-store
entry reuses the existing owner, while a different store still goes through
the serialized close path in `switchSelectedStore`. All visible `MobileShell`
navigation resolves Home through `resolveHostNavigationTarget`. Preserve this
separation; it fixes chooser → Cart/Orders → Home without regressing warm
same-store reentry or the independent cart tabs.

Cart is now a compact Otlobli-green surface. The sticky checkout area is a
two-column grid with a 44px action, quantity uses fixed centered grid columns,
and item/store cards are quieter and smaller. Playwright acceptance passed at
320x844 and 390x844; screenshots are under `output/playwright/`.

Temu's empty download wrapper collapse is intentionally native Home-only on
both Android and iOS. It is still the same bounded single-wrapper detector:
depth <= 8, search exclusion, top/width/height bounds, no broad scan, observer,
or added timer. The sticky-header transform repair remains Android-only. The
iOS native Back button remains an overlay and no protected lifecycle code was
changed.

Final full build, release/security/freeze/Temu/store guards, TypeScript, scoped
ESLint, performance budgets, Android+iOS sync, signed APK/AAB, signature
verification, and Note 8 update all passed. Budgets are JS 670139/720000,
gzip 298417/370000, CSS 69985/70000, fonts 81364/100000, shipped store scripts
317333/470000, Gecko 172005/180000, and source 580582/600000. Artifacts:

- `artifacts/release-86.240/Otlobli-86.240-1105-release.apk`, 4,110,723 bytes,
  SHA-256 `F8E4C7429AF2AE47383102631CE87E3556D308395152DFA84049C923C7FB75BF`.
- `artifacts/release-86.240/Otlobli-86.240-1105-release.aab`, 5,771,013 bytes,
  SHA-256 `04313B8ED0435AE106CD70361F1028321B72E9BA4019DD56787F65A65F82FA30`.

Note 8 runs `86.240 (1105)` with data preserved and screen timeout set to two
minutes. Chooser → Orders → Home and Chooser → Cart → Home both stayed on the
chooser; live Temu and the redesigned cart rendered without matching
fatal/ANR/OOM. The exact final APK was reinstalled after the last auth-target
coverage change. The two paths were replayed on that exact artifact;
`102-final-home-after-orders.png` and `104-final-home-after-cart.png` record the
chooser results, while `103-final-cart.png` records the final real-data cart.
Evidence is in `artifacts/device-captures/v86.240-note8/`.
Do not claim automated double-tap acceptance: one ADB tap took about 534ms,
outside the 320ms real-finger window. iPhone white-gap acceptance, five resume
cycles, and cold launch remain unperformed.

Source commit `b7623e538942187db6ce0b33c9d6e1302d350b01` is pushed. TestFlight run
`32905062307` stopped safely before signing because the persisted WhatsApp
sender was disconnected. Session `0` was reconnected from stored credentials
through the protected loopback admin endpoint; no QR, reset, or message was
produced. Health then passed with connected/ready sender, persisted customer
sessions, and hardened OTP storage. Retry `32905392346` succeeded in `8m43s`.
Apple delivery UUID is `0470dc1f-5a1e-4b1f-918c-4e09c6b3de9e`; exact build
`86.240 (1105)` is `VALID` and `IN_BETA_TESTING` in all-builds group
`Otlobli Internal`, and expected tester membership is `INSTALLED`. App Review
was disabled and skipped.

Signed GitHub artifact `9584831793`,
`otlobli-ios-v86.240-build-1105-testflight`, is 25,250,403 bytes with archive
SHA-256 `70AF49A8D40B20D68130B1555620E61947B9DE2F57B7B11AABAB74D9698DF409`.
Downloaded IPA under `output/testflight-v86.240-build-1105-run-32905392346/`
is 10,543,182 bytes with SHA-256
`0F1382E07C4E7ABC4C011DE90F9A2CE8048433CB4CF4B6B1F6D90696A898E382`.

SHEIN, region policy, human verification, payment, orders, and wallet were not
changed. Preserve `otlobliForceRecompose()`, exact 0.25s appDidBecomeActive,
Android resume defense, and JSON.stringify region comparison.
