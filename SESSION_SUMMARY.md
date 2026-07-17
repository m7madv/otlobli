# SESSION_SUMMARY.md

## 2026-07-17 Temu v85.8.24 Search Layout Fix

- Workspace: `C:\Users\MOHAMMAD\Projects\SHEIN IN SIRYA`.
- Branch: `claude/ios6-cover-fix`.
- Current local candidate: v85.8.24 / `APP_VERSION = 2026.07.17-v85.8.24-temu-search-layout-no-otp-test`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.24-temu-search-layout.ipa`.
- Build run: `29577463207` (success), built from code commit `b061da5`.
- IPA SHA-256: `15A3FD16D00F8BB04316D05A70F55FA54DCB90EDABF21AF5B96249E4637E9426`.
- Scope: only the follow-up Temu search layout issues after v85.8.23: search bar clipped from the bottom on entry, and home header/category shape breaking after backing out.
- Fix: active Temu search now marks a scoped search shell plus nearest frame, expands only that frame temporarily, and lowers the shell with `transform` instead of the old layout-changing `margin-top`.
- Home return: Otlobli search-back clears active search shell/frame markers and restarts a bounded home-header wake window even when the URL stays the same, with one extra delayed reset for low-end iPhones.
- Validation passed: targeted ESLint, injected-script parse, `npm run build`, WebKit iPhone 6-sized clipped-search -> Otlobli-back -> home fixture, GitHub unsigned iOS build, embedded v85.8.24 marker check.
- Next real-device check: install v85.8.24 and verify only this loop before moving to any next issue.

## 2026-07-17 Temu v85.8.23 Search Exit Home Fix

- Workspace: `C:\Users\MOHAMMAD\Projects\SHEIN IN SIRYA`.
- Branch: `claude/ios6-cover-fix`.
- Current local candidate: v85.8.23 / `APP_VERSION = 2026.07.17-v85.8.23-temu-search-exit-home-no-otp-test`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.23-temu-search-exit-home.ipa`.
- Build run: `29554026083` (success), built from code commit `47bdfaa`.
- IPA SHA-256: `119DA708BE544BD2AF2CA74F0EE1C33F482A4A969ACFD66BAA025B3A67F87857`.
- Scope: only the first new issue, where Temu home looked correct on first entry but broke after entering search and returning home.
- Fix: Otlobli back from Temu search remembers/falls back to the last search input, clears it, dispatches `input/search/change`, briefly suppresses stale search-mode, and hides only search suggestion/recent/trending overlays from that session.
- Guard: search suggestion overlays are marked so Temu search/category restoration cannot revive them as category strips; category detection now excludes search/suggest/trending text.
- Validation passed: targeted ESLint, injected-script parse, `npm run build`, WebKit iPhone-sized home -> search -> back fixture, GitHub unsigned iOS build, embedded v85.8.23 marker check.
- Next real-device check: install v85.8.23 and verify only home -> search -> back returns to the same clean home layout before moving to the second issue.

## 2026-07-17 Temu v85.8.22 GitHub Build

- Workspace: `C:\Users\MOHAMMAD\Projects\SHEIN IN SIRYA`.
- Branch: `claude/ios6-cover-fix`.
- Current local candidate: v85.8.22 / `APP_VERSION = 2026.07.17-v85.8.22-temu-focused-search-no-otp-test`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.22-temu-focused-search.ipa`.
- Build run: `29553022990` (success), built from code commit `8b665ed`.
- IPA SHA-256: `1233327C658582DA8D4B11EFF5D621CC4728B13C132CEC93D3AF52391B14CEB5`.
- Temu focus: category strip visible from first entry, cleaner header/search state, faster focused search path, no login/account or available-offers interruption during search/back.
- Implementation is targeted: verified category strips get `display:flex`; focused searchboxes count as Temu search mode; the active search shell is lowered 18px; Temu native search back is hidden; Otlobli back exits search without opening Temu offer sheets.
- Real Temu account routes are preserved when opened intentionally; account-route WebKit fixture passed.
- iOS splash PNGs are blank white so the blue splash logo should not show in the app switcher/background preview.
- Validation passed: targeted ESLint, injected-script parse, `npm run build`, WebKit iPhone-sized home/search/back fixture, WebKit account-route fixture, GitHub unsigned iOS build, embedded v85.8.22 marker check.
- Do not use the simulator for final judgment; install on the real iPhone 6/iPhone 16. Do not touch payment, wallet, completed orders, or account-route logic unless explicitly requested.

## 2026-07-17 Temu v85.8.21 Local Update

- Workspace: `C:\Users\MOHAMMAD\Projects\SHEIN IN SIRYA`.
- Branch: `claude/ios6-cover-fix`.
- Current local candidate: v85.8.21 / `APP_VERSION = 2026.07.17-v85.8.21-temu-category-search-account-no-otp-test`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.21-temu-category-search-account.ipa`.
- Build run: `29551174390` (success), built from code commit `603c902`.
- IPA SHA-256: `E42467AD3BB2F13E6F82E0638AB8AE04846C9036514E94B497E4B2018E53CA1E`.
- Focus stayed Temu-only: first-entry category strip, header startup stability, search typing/focus, and login/account panel removal outside real account routes.
- Fixed early WebKit document-start aborts by guarding Cairo font injection and deferring the MutationObserver until a root node exists.
- Added a bounded Temu home wake nudge that triggers the same tiny scroll/resize path needed to reveal categories, then returns to top.
- Hid Temu account/login surfaces by observed live WebKit/iPhone classes and removed the heavy 90ms full-page account text scan to keep typing responsive.
- Validation passed: `git diff --check`, targeted ESLint, injected-script parse, `npm run build`, WebKit iPhone-sized live smoke, and a routed Temu fixture reproducing hidden categories plus recreated account panels.
- Do not use the simulator for final judgment; install the GitHub-built IPA on the real iPhone. Do not touch payment, wallet, completed orders, or real account routes unless explicitly requested.

## 2026-07-17 Temu v85.8.20 Local Update

- Workspace: `C:\Users\MOHAMMAD\Projects\SHEIN IN SIRYA`.
- Branch: `claude/ios6-cover-fix`.
- Last real-device Temu IPA tested: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.19-temu-search-keyboard.ipa`.
- Last tested commit: `0426529` (`fix: v85.8.19 keep Temu search keyboard open`).
- v85.8.19 is not fixed: Temu still shows an empty/white header band, search typing is slow/unstable, and the login/account panel can appear over search and keyboard.
- Current local candidate: v85.8.20 / `APP_VERSION = 2026.07.17-v85.8.20-temu-header-search-login-no-otp-test`.
- Current iOS IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.20-temu-header-search-login.ipa`.
- Build run: `29543466932` (success), built from code commit `5a5b0c6`.
- IPA SHA-256: `16EFD9C2C1C38FE88C87404CF24BD157A1DC7DED4B265CF914BCE5FC4C9BEEC5`.
- Local changes are limited to Temu in `src/services/sheinBrowserScript.ts`: broader live search-input detection, short search-mode probe cache, safer search chrome restoration that avoids account panel ancestors, search-only login panel re-hide, and less aggressive home-header forcing.
- Do not use the simulator for final judgment; test on the real iPhone. Do not touch payment, wallet, completed orders, or account route logic unless explicitly requested.

انسخ هذا لأي شات جديد قبل المتابعة. آخر تحديث: 2026-07-16.

## المسار والفرع والبناء

```text
C:\Users\MOHAMMAD\Projects\SHEIN IN SIRYA
```

- الفرع النشط: `claude/ios6-cover-fix` — قاعدة نظيفة على commit `e8842d8`.
- الأساس المستقر: **v85.8.12** (commit `129630e`). نُسخ احتياطية: فرع `backup-v85.8.14-state` + تاجات `backup-before-8.12-revert` و`backup-v85.8.20-broken`.
- **iOS**: يُبنى عبر GitHub Actions فقط: `gh workflow run ios-unsigned-build.yml --ref claude/ios6-cover-fix` ثم تنزيل artifact `otlobli-ios` ووضعه على سطح المكتب. لا Mac محلي.
- **Android (للاختبار الحي)**: متوفّر ويعمل! `emulator` في `C:\Users\MOHAMMAD\AppData\Local\Android\Sdk\emulator`، AVD اسمه `Pixel_7_API_35_Test`، الحزمة `com.otlobli.app`. البناء: `npm run build && npx cap sync android && cd android && ./gradlew assembleDebug` ثم `adb install -r ...`. الاختبار: `adb shell input tap/text` + `adb exec-out screencap`.
- **مفتاح الـ relay السري**: في `.env.relay.local` (gitignored). قبل بناء Android محلياً شغّل `node scripts/inject-relay-key.cjs` (يقرأه تلقائياً) ثم `npx cap sync android`. **ممنوع** إعادة توليد الباتش بعد الحقن (يسرّب المفتاح). الباتش المُلتزَم يجب أن يبقى فيه `OTLOBLI_RELAY_KEY_PLACEHOLDER`.
- OTP معطّل في نسخ الاختبار (`no-otp-test`) — يُستعاد قبل الإنتاج.

## أهم درس تشغيلي

الشات صار طويلاً جداً وجودة العمل تدهورت (تغييرات كسرت ثم تراجعات). **ابدأ من هنا بشات نظيف.** واختبر على محاكي أندرويد الحي قبل ادعاء الإصلاح — لا تخمين.

## ما تأكّد إصلاحه (على iOS، نُسخ محفوظة على سطح المكتب)

1. رجوع المشروع من v85.8.20 المكسور إلى v85.8.12.
2. قبول كوكيز شي إن تلقائياً (`otlobliForceAcceptCookies` + `sheinSkuSelectionPending`) — تأكّد.
3. إكمال اختيار منطقة السعودية على iPhone 6 حتى الخيار الأخير.
4. تسريع تحقّق أمان شي إن (`otlobliChallengeActive` يوقف فحوصاتنا أثناء تحدي Cloudflare).
5. غطاء تحميل ذكي: iPhone 16 (safe-area>0) يبقى الشريط ظاهراً؛ iPhone 6 (safe-area=0) غطاء كامل.
6. تخفيف الفحوصات على الأجهزة الضعيفة (`OTLOBLI_LOW_END`).
7. إصلاح جذب المتغيّر: `getSizeOptions` رفع حد الطول 12→40 + كشف «انقر للشراء».
8. الشريط السفلي يتوقف عن سرقة النقر عند فتح درج شي إن (`otlobliApplyNavYield`).
9. تيمو: mojibake «بحث» أُصلح؛ حارس VPN لتيمو (`temuContentLoadedRef` يمنع بوابة كاذبة على أخطاء الموارد الفرعية).

## مشاكل تيمو المعلّقة (من اختبار المستخدم + المحاكي الحي)

كلها في `src/services/sheinBrowserScript.ts` (كتلة `if (IS_TEMU)` داخل `tick()`، ودوال `otlobliTemuSearchMode`/`stabilizeTemuSearchChrome`/`ensureBackButton`/`ensureOtlobliNav`).

1. **الكتابة تغلق البحث**: عند كتابة أي حرف في بحث تيمو، تُغلق شاشة البحث وترجع للرئيسية. مؤكّد على المحاكي (adb text و keyevent كلاهما). **لا يوجد تنقّل/إعادة تحميل** (logcat). السبب من كودنا لكن لم يُحدَّد بعد. مرشّحون: `ensureViewportFitCover` (logcat يسبّم ViewportFitCover)، أو `ensureOtlobliNav` إعادة إلحاق النود، أو تدخّل على الحقل يفقده التركيز. **الأولوية القصوى** (بلا كتابة البحث عديم الفائدة).
2. **زر الرجوع غير مستقر**: يظهر/يختفي بتكرار على تيمو. سببه `otlobliTemuSearchMode` يتذبذب (تركيز/قيمة) + `ensureBackButton` كل tick.
3. **عمليات البحث الأخيرة + الاقتراحات تُحجب**: دوال إخفاء كروم تيمو تبتلعها لمّا الحقل فارغ/غير مركّز. جرّبتُ حلاً (`otlobliTemuHasProductGrid`: علّق الحجب لمّا لا توجد شبكة منتجات) ونجح لإظهارها لكن يُشتبه بأنه فاقم الكتابة — **أُلغي** ويحتاج إعادة تطبيق بحذر مع اختبار الكتابة.
4. **وميض الحجب**: عناصر تيمو تظهر ثم تُحجب بعد ~ثانية (الحجب على tick تدريجي).
5. **شريط البحث العلوي غير ثابت**: يتحرك بالتمرير وأحياناً يستقر لحظة ثم يتحرك. `stabilizeTemuSearchChrome` يُشتبه أنه يزيحه لمنتصف الشاشة أحياناً. محاولة تثبيت الهيدر بـ `transform:translateY(0)!important` **كسرت التخطيط أفقياً** (أُلغيت). ملاحظة DOM: الشريط داخل هيدر `position:fixed` (`._2UbxPzJy`) يخفي نفسه بالنزول عبر transform إنلاين (سلوك موبايل).
6. **الشريط السفلي (شريط التطبيق) يتحرك عند overscroll**: عند السحب لأقصى أعلى/أسفل، الشريط السفلي وكلماته (الرئيسية/طلباتي/السلة/حسابي) تُسحب لأسفل. يحتاج تثبيت أقوى (overscroll-behavior / native inset).
7. **الشريط السفلي يجب أن يكون «ذكياً» حسب نظام تنقّل الهاتف**: يكتشف إن كان الهاتف بأزرار تنقّل (Android buttons) أو إيماءات (iPhone-like)، ويحجز الـ inset الحقيقي ويأخذ الحجم المناسب لكل شاشة (يعتمد على مقاس الشاشة و safe-area الفعلي). حالياً يعتمد على `max(env(safe-area-inset-bottom),16px)`.

## حقائق DOM لبحث تيمو (من فحص حيّ — www.temu.com/sa/)

- حقل البحث: `input[type="search"]` (class مولّدة مثل `_7H3Q1N2_`، بلا placeholder).
- صفوف الاقتراحات: `.nTJ9YZso`، داخل overlay `._3KC0yZ4V` (position:absolute, z-index:999).
- **البحث overlay وليس مساراً** — الـ URL لا يتغيّر، فـ `history.back` لا ينفع (لهذا زر الرجوع يفرّغ الحقل بدلها).
- تفريغ قيمة الحقل + إطلاق `input` event يُخفي الاقتراحات (تأكّد حياً: 20→0 صف).
- الهيدر العلوي `._2UbxPzJy` (fixed) يحوي البحث ويخفي نفسه بالنزول.

## مناطق حسّاسة

- شي إن: `m.shein.com/ar` + السعودية + USD + عربي + `site_uid=pwar`. لا User-Agent مخصص، لا كتابة storage عريضة.
- تحدي Cloudflare «أنا إنسان»: لا نتجاوزه ولا نعيد تحميله.
- تيمو: لا نحجب البحث. الشريط السفلي داخل WebView حسّاس (z-index/position/__resize). `killStorePopups` معطّلة نهائياً لتيمو (سبّبت وميضاً).
- الدفع/المحفظة/الكوبونات/الطلب الجماعي: لا تُلمس إلا بطلب صريح.
- بوابة VPN غير مستقرة أحياناً (probe يفشل عابراً فيظهر «شغّل VPN» رغم أن الموقع يعمل) — أُضيف retry جزئي؛ يحتاج مراجعة.

## بروتوكول التسليم

بعد كل تغيير مستقر: حدّث `CURRENT_STATE.md` و`AI-HANDOFF.md` و`SESSION_SUMMARY.md`، واختم بملخص عربي قابل للنسخ.
