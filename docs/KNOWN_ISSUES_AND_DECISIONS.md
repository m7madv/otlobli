# Otlobli — سجل المشاكل والقرارات الدائم

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
