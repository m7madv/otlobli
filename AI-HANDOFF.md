# Otlobli AI Handoff

Read `CURRENT_STATE.md`, then `AGENTS.md`, before editing.

## مشروع مستقل (2026-08-27) — VoiceBrief 0.1.0 build 9

- اعمل فقط داخل `voicebrief_flutter/` وملفي workflow الخاصين به على الفرع `codex/voicebrief-ios`. مشروع Supabase الصحيح `jyehqpdbayslhzebdycj`؛ لا تستخدم Damanak أو `talabieh`.
- `ShareViewController.swift` يحفظ manifest ذرياً في App Group ثم يستعمل public `NSExtensionContext.open` لطلب `voicebrief://shared-audio`. هذا best-effort لأن iOS قد يرفض فتح التطبيق من Share Extension؛ عند الرفض يظهر زر إعادة محاولة. لا تضف `UIApplication.shared` أو responder-chain hacks.
- `process-audio/date_normalization.ts` يصحح فقط العبارات ذات علامة تاريخ صريحة (`يوم`/`بتاريخ`/`تاريخ`) كي لا تتحول أوقات الساعة إلى تواريخ. `يوم خمسة تسعة` ينتج 5 سبتمبر القادم، ويظل الوقت غير المذكور بحاجة إلى تأكيد.
- مرشح السرعة يرسل `languageHint` مضبوطاً على `ar/en`، يضبط التفريغ الافتراضي على `gpt-4o-mini-transcribe`، ويكتب stage timing لا يحتوي أي محتوى. لا تسجل transcript أو اسم ملف أو هوية المستخدم.
- التحقق المحلي الحالي: format نظيف، analyze نظيف، 30 non-golden، 11 golden، خمسة date tests، وAndroid debug build كلها ناجحة. CI يضيف Deno `fmt/test/check`.
- الإصدار المصدر `0.1.0+9` وShare Extension `9`، وworkflow TestFlight محدث للبناء 9. Supabase CLI المحلي يرى حساباً آخر فقط؛ جلسة Edge ترى مشروع VoiceBrief. لا تدّع نشر الدالة أو TestFlight حتى ينجح كل منهما ويُسجل run/hash.


## مشروع مستقل (2026-08-25) — ضمانك 4.1.0+7

- `damanak_flutter/` مستقل عن Otlobli. لا تطبق مخططه على مشروع الجذر ولا تستخدم مشروع `talabieh` أو `VoiceBrief` لضمانك.
- الإصدار المصدر `4.1.0+7`. الدخول حصراً عبر Apple أو Google؛ لا تعِد مسارات البريد وكلمة المرور. دعوة الموظف استخدام واحد لمدة 48 ساعة عبر رابط أو `QR` مع رمز بديل، وتُملأ تلقائياً من deep link `com.damanak.damanak://join`. صاحب المتجر وحده يستطيع إنشاء دعوة مدير، أما المدير فيدعو موظفاً أو مشرفاً فقط.
- `app_links` يلتقط الرابط عند التشغيل البارد وأثناء التشغيل. `AppController.handleIncomingUri` يتحقق من صيغة `DMN-[A-Z0-9]{6,16}`، وتستخدم شاشة onboarding الدعوة المعلقة ثم تمسحها بعد الانضمام الناجح. الدور في الرابط للعرض فقط؛ قرار الخادم المرتبط بالرمز هو المرجع الأمني.
- مشروع Supabase الحي المستقل `exxayzlklvgeyqhvtzgi` في Mumbai `ap-south-1`؛ migrations الأربع ودالة `verify-store-purchase` منشورة، Email auth معطل، ورابط العودة مضبوط. GitHub Secrets العامة موجودة. لا تطبع مفاتيح المشروع ولا تستخدم `talabieh` أو `VoiceBrief`.
- Google Cloud Project `Damanak Production` هو `damanak-production`، رقم `521030062021`، والحساب `mhm1981x@gmail.com`. Google OAuth مكتمل ومزود Supabase مفعّل، ونجح redirect الحي. Apple App ID `com.damanak.damanak` وServices ID `com.damanak.damanak.signin` ومفتاح `4GF7TP229W` جاهزة، ومزود Supabase مفعّل ونجح redirect الحي. دوّر سر Apple قبل 2027-02-20.
- التصميم يستخدم أخضر `#087F5B` وحياديات فقط. آخر تحقق: analyze نظيف و21 اختباراً. تسجيل OAuth الحقيقي على الأجهزة وشراء Sandbox ما زالا مطلوبين.
- Android build `7` الحي مرفوع إلى الاختبار الداخلي: AAB SHA-256 `88073698D408A62D5D6C548C0B2BFD0320D4B5CCB2EA281381853917CC5C1F72`، وشهادة الرفع SHA-256 `BF0B373699911FDAB8BD46DE90664D0915CED35E2ED046A6AD4E4B030F814574`. المفتاح المحلي `C:\Users\MOHAMMAD\.damanak\android\damanak-upload-v2.p12` وكلمة مروره المشفرة بـDPAPI ما زالا خارج Git. أسرار GitHub الثلاثة `DAMANAK_ANDROID_UPLOAD_KEYSTORE_BASE64` و`DAMANAK_ANDROID_UPLOAD_KEY_PASSWORD` و`DAMANAK_ANDROID_UPLOAD_KEY_ALIAS` موجودة الآن؛ لا تطبع قيمها.
- profile الحالي `Damanak App Store 2026` رقم `6497QWMYJ2` ويتضمن Sign in with Apple، ومحفوظ في `DAMANAK_IOS_APP_STORE_PROFILE_BASE64`. المصدر يربط `Runner.entitlements` بكل إعدادات iOS، وworkflow يتحقق من الاستحقاق داخل التطبيق والملف المضمّن.
- سجل App Store Connect موجود باسم `Damanak - ضمانك` ومعرّفه `6804792494`. مجموعة `Damanak Plans` رقمها `22332400`، والمنتجات الستة منشأة ومترجمة ومتاحة في دول الخليج الست مع أسعار `39/390` و`99/990` و`199/1989.99 SAR`؛ `1989.99` أقرب نقطة Apple المتاحة إلى `1990`. صور المراجعة الست مكتملة، واتفاقية Paid Apps والحساب البنكي والضرائب وDSA كلها `Active`.
- buildا TestFlight `5` و`6` موقعان و`VALID`، لكنهما بلا إعدادات Supabase ولا يجوز ترقيتهما. build `7` من `e575617` رُفع بنجاح إلى App Store Connect عبر run `32783227070` بعد التحقق من إعدادات الخادم وApple Sign-In. IPA: `C:\Users\MOHAMMAD\Downloads\damanak-ios-build7-32783227070\ضمانك.ipa`، SHA-256 `89187374D5BD47665614AB3518F60F84341A0B32183A84348243445ECFC27241`. انتظر معالجة Apple ثم اختبره على iPhone حقيقي.
- مجموعة TestFlight الداخلية `Damanak Internal` رقمها `18666e73-e100-42a5-a223-f3620e97bf04` وتملك `hasAccessToAllBuilds=true`. دعوة صاحب الحساب موجودة، لكن لا تطلب منه اختبار build `5/6` كنسخة وظيفية لأن الخادم غير مضمّن.
- Google Play app رقم `4975804725938350009`. الإصدار الداخلي `4.1.0 (7)` منشور، وقائمة `Damanak Internal` مرتبطة به وتضم `mhm1981x@gmail.com` فقط. رابط الانضمام `https://play.google.com/apps/internaltest/4701722430109624070`. حساب الخدمة نشط وJSON موجود في Supabase/GitHub؛ حُذف المفتاح اليتيم `d86a3e51984e7ba7b942f00595a37c268b367316`، وبقي المفتاح العامل `426377cca3335db2db9a17611153fb1b37e92a1d` وحده نشطاً.
- `google_play_setup.mjs` يدعم `inspect/apply/activate` مع أسعار دول الخليج الست. الفحص ناجح والمنتجات الثلاثة ما تزال مفقودة؛ إنشاء أسعار المناطق ينتظر انتشار أذونات Google وقد يستغرق حتى 48 ساعة. لا تمنح الحساب Admin؛ أعد `--activate` بعد الانتشار.

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
