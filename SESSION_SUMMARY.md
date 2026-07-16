# SESSION_SUMMARY.md

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
