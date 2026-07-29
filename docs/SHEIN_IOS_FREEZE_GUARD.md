# SHEIN iPhone 16 WKWebView Freeze Guard

هذه قاعدة إصدار إلزامية وليست ملاحظة تاريخية.

## حارس حقن وتشخيص المنطقة — v86.18

- اختبار iPhone 16 الحقيقي رفض v86.17: لا تعتبر route bootstrap أو نجاح البناء دليلاً أن قلب المنطقة بدأ. شريط Otlobli يأتي من `OTLOBLI_NAV_BOOTSTRAP_SCRIPT` عند document start، بينما منطق المنطقة الكامل يأتي لاحقاً من `browserPageLoaded`; ظهور الشريط وحده لا يثبت حقن `SHEIN_CAPTURE_SCRIPT`.
- أول `browserPageLoaded` ذو `id` لا يجوز إسقاطه لمجرد أن `webviewIdRef.current` ما يزال فارغاً. أثناء فتح الـWebView singleton يجب اعتماد هذا المعرّف ثم حقن السكربت الكامل؛ يحمي الحارس علامتي `loadedWebviewId` و`host-page-loaded-id-adopted`.
- التشخيص المؤقت المحدود يرسل `sheinRegionDiagnostic` من WebView إلى React لمراحل: بدء/نجاح الحقن، اكتشاف route، prime، repair/cooldown، veil، مسح درج الشحن، العثور على زر الدخول/فقده، click، cookie الموقّع، والمهلة. يحتفظ host بآخر 80 سجلاً فقط في `window.__OTLOBLI_SHEIN_REGION_DIAGNOSTICS__`.
- تشخيص WebView لا يضيف polling دائماً: يعيد محاولة تفريغ الرسائل المعلقة لمدة أقصاها 20 × 250ms ثم يوقف مؤقته. لا يغيّر قرار `sheinSignedSaudiAddressReady()` ولا يفتح السلة ولا يضيف reload/setUrl.
- قبول الجهاز التالي يجب أن يُظهر التسلسل الفعلي في console: `capture-evaluation-start` ثم `capture-script-injected`، وبعد فتح المنتج `tick-product-route`/`prime-called` ثم `repair-started`. إن توقف التسلسل قبل مرحلة محددة، تُعالج تلك المرحلة فقط؛ لا تُعدّل DOM selectors عشوائياً.

## حارس أول منتج وغطاء تبديل المنطقة — v86.17

- أول منتج SHEIN يجب أن يطلق إصلاح المنطقة من مسار الرابط نفسه، حتى قبل ظهور عناصر الشحن. حافظ على `sheinLooksLikeProductRouteForShipping()` و`sheinPrimeRegionRepairFromRoute()` واستدعاء `if (IS_SHEIN) sheinPrimeRegionRepairFromRoute();` قبل early-return الخاص باللمس/التمرير.
- إذا كان رابط المنتج لا يحمل دولة/عملة/لغة الإعداد الحالي، مسموح فقط بإعادة تحميل واحدة محكومة بالمفتاح `__otlobliRegionBootstrapReload:<country>:<path>`. لا تحول هذا إلى reload/setUrl loop، ولا تشغله على صفحات التحقق البشري.
- إخفاء تبديل المنطقة يتم عبر غطاء HTML خفيف داخل WebView: `#otlobli-region-switching`. هذا ليس غطاء `sheinSaudiRepairStart` native القديم. يجب أن يبقى شريط Otlobli فوقه، وأن تختفي أزرار add/back فقط أثناء التهيئة.
- الجاهزية النهائية ما زالت `sheinSignedSaudiAddressReady()` فقط. لا تجعل ظهور الصفحة أو URL params كافيين للسلة.

## حارس قلب المنطقة بالخلفية — v86.16

- قلب منطقة SHEIN يجب ألّا يحبس المستخدم خلف غطاء native خاص بالمنطقة. `sheinPrepareNativeSaudiRepair()` يبدأ إصلاحاً سريعاً ومحدوداً بالخلفية، ويترك الصفحة قابلة للتصفح.
- الجاهزية قبل الإضافة للسلة يجب أن تعتمد على `addressCookie` الموقّع للبلد المحدد من لوحة الإدارة، وليس على URL/storage فقط. إذا كانت المنطقة غير موقعة، زر إضافة للسلة يبقى ممنوعاً.
- أثناء لمس/تمرير المستخدم، الـtick العام الثقيل يجب أن يتراجع. المسموح فقط هو مؤقت تقدم المنطقة الصغير `scheduleSheinShippingProgress(...)`. إذا ظهر درج الشحن، يبقى `stabilizeSheinShippingDrawerInteraction()` مسؤولاً عن قفل تمرير الصفحة خلفه وإبقاء شريط Otlobli ظاهراً.
- لا تُرجع اعتماد `sheinSaudiRepairStart` كغطاء native للمنطقة إلا بعد اختبار جهاز حقيقي ومقارنة مقصودة. إذا تغير هذا المنطق، حدّث `scripts/verify-shein-freeze-guard.mjs` وهذا الملف معاً.

## حارس استجابة التمرير والشريط — v86.11

- درج المنطقة لا يملك `pointer-events` الخاص بـ`#otlobli-nav` ضمن سجل استرجاع الستايل. الشريط له قاعدة مستقلة: ظاهر ومعتم و`pointer-events:auto` بعد إغلاق الدرج، بينما يحجب الحارس الشفاف داخل الشريط اللمس فقط أثناء التحويل.
- لا يجوز إعادة حفظ قيمة `pointer-events:none` للشريط ثم استرجاعها بعد إغلاق الدرج؛ هذا هو السبب المثبت لحالة شريط ظاهر لكنه غير قابل للضغط.
- أثناء لمس/تمرير منتج SHEIN تُعلّق مسوحات DOM والنص والـlayout الثقيلة لمدة `320ms` من آخر حدث. مستمعات الشريط تبقى مركّبة وتراسل native مباشرة، ثم تنفذ دورة الصيانة الكاملة بعد هدوء الحركة.
- إصلاح المنطقة خلف الغطاء مستثنى من التعليق حتى لا يتوقف اختيار الدولة/المحافظة/المدينة/المنطقة. نتيجة اكتشاف جذر درج المنطقة مخزنة مؤقتاً لمنع تكرار نفس المسح داخل الدورة.
- `verify:shein-freeze-guard` يثبت علامات هذا الحارس أيضاً. بعد أي تعديل يمس درج المنطقة أو الشريط أو جدولة `tick()` يجب اختبار تمرير سريع ثم ضغط الشريط، إضافة إلى اختبار الخلفية الدائم.

## العَرَض المثبت

على iPhone 16 Pro Max / iOS 27 قد تعود صفحة SHEIN من الخلفية كإطار مرسوم ثابت، مع بقاء الصفحة حيّة تحت الصورة وقد تستجيب اللمسات. لم يتكرر السلوك نفسه على iPhone 6.

السبب العملي المعتمد في المشروع هو أن شجرة الرسم البعيدة الخاصة بـ`WKWebView` لا يعاد إرفاقها دائماً بعد استرجاع التطبيق. العلاج المثبت في هذا المشروع يفصل الـWebView عن شجرة العرض ثم يعيد إضافته بالـconstraints نفسها مع حفظ موضع التمرير.

## الحماية الحالية التي يُمنع حذفها أو إضعافها

المصدر الدائم:

- `patches/@capgo+capacitor-inappbrowser+8.6.25.patch`
- `WKWebViewController.otlobliForceRecompose(force:)`
  - يحفظ `contentOffset`.
  - ينفّذ `removeFromSuperview()`.
  - يعيد `addSubview(webView)` والـconstraints.
  - يعيد موضع التمرير ويطلق حدث `resize`.
- `InAppBrowserPlugin.appDidBecomeActive(_:)` و`appWillEnterForeground(_:)`
  - يشغّلان `otlobliRecomposeAllWebViews()`.
  - ينفّذان burst محدوداً عند `0.12/0.5/1.2/2.2` ثانية.
  - يستدعيان `otlobliForceRecompose(force: true)` لكل WebView مسجل حتى تقع إعادة إرفاق بعد جهوزية طبقة WebKit البعيدة.
- رسالة الحارس `__otlobliRecompose` تعيد الاستدعاء عند رصد توقف الرسم.
- Android يحتفظ بالحماية الدفاعية `WebViewDialog.otlobliOnHostResume()` من دون فصل طبقة Chromium.
- `src/App.tsx` يحتفظ بمقارنة `JSON.stringify(previous[activeStore])` مع `JSON.stringify(storeRegions[activeStore])`، فلا يعاد إنشاء WebView النشط إلا إذا تغيّرت منطقة المتجر فعلاً.

العلامتان `appWillEnterForeground` و`otlobliRecomposeAllWebViews` وجدول burst عند `0.12/0.5/1.2/2.2` جزء من الباتش الحالي المثبت. يمنع حذفها أو تقليصها من دون بديل مثبت واختبار قبول حقيقي على iPhone 16. الـburst محدود بزمن الرجوع فقط ولا يضيف polling أو عملاً مستمراً على الأجهزة الضعيفة.

## ممنوعات

1. لا تحذف أو تضعف `otlobliForceRecompose` أو استدعاءات `appDidBecomeActive`/`appWillEnterForeground` أو burst أو حفظ scroll/constraints.
2. لا تغلق أو تعيد بناء WebView الخاص بـSHEIN عند resume أو عند polling الإعدادات، إلا عندما تختلف قيمة المنطقة الفعلية.
3. لا تضف عملاً متزامناً ثقيلاً إلى مسار resume.
4. لا تكبّر حقن SHEIN أو مؤقتاته الساخنة من دون مراجعة أثرها على الأجهزة الضعيفة واختبار iPhone 16.
5. لا تعتبر نجاح build أو المحاكي بديلاً عن قبول الجهاز الحقيقي.
6. لا تخلط بين المسارين التاليين:
   - Home/background ثم الرجوع من دون سحب التطبيق: استئناف لنفس العملية ونفس الـWebView؛ هذا هو مسار إعادة التركيب.
   - سحب التطبيق من App Switcher ثم فتحه: قتل للعملية وتشغيل بارد؛ يجب اختباره منفصلاً ولا يوجد WebView قديم لإعادة إرفاقه.

## فحوص البناء الإلزامية

`npm run build` يشغّل تلقائياً:

```bash
npm run verify:shein-freeze-guard
```

هذا الفحص يتأكد من:

- بقاء علامات الحماية داخل الباتش.
- تطبيق الباتش فعلياً داخل `node_modules`.
- بقاء حارس مقارنة منطقة المتجر في `App.tsx`.
- بقاء حماية Android الدفاعية.

بعد أي `npm install` أو `npx patch-package` أو ترقية `@capgo/capacitor-inappbrowser`، يجب أن ينجح الفحص. فشله يمنع التسليم إلى أن تتم مقارنة الترقية عمداً وإعادة تثبيت الحماية.

## قبول iPhone 16 الإلزامي

بعد أي تعديل يمس SHEIN أو InAppBrowser أو الباتش أو الحقن أو lifecycle:

1. افتح منتج SHEIN وتأكد أن الصفحة قابلة للتمرير.
2. انتقل إلى Home ثم ارجع إلى التطبيق، خمس مرات، من دون قتله.
3. في كل مرة، تأكد أن الرسم يتغير فور التمرير وأن اللمس وشريط Otlobli يعملان.
4. نفّذ اختباراً منفصلاً: اسحب التطبيق من App Switcher، افتحه من جديد، وتأكد أن التشغيل البارد يعيد SHEIN بشكل حي.
5. بدّل SHEIN → Temu → SHEIN مرة واحدة للتأكد من سلامة الحفظ وإعادة الإرفاق.

إذا تجمد أي مسار، لا يُوصف الإصدار بأنه مقبول على iPhone 16 ولا يُسلّم كحل نهائي.
