# SESSION_SUMMARY.md

Copy this into a new AI chat before continuing work.

## Start here

Project path:

```text
C:\Users\MOHAMMAD\Projects\SHEIN IN SIRYA
```

Active branch:

```text
codex/customer-wallet-group-orders
```

Before editing, read:

0. `AI_QUICK_HANDOFF.md`
1. `AGENTS.md`
2. `CURRENT_STATE.md`
3. `AI-HANDOFF.md`
4. `CLAUDE.md` if using Claude Code

Then run:

```bash
git status --short
git rev-parse --abbrev-ref HEAD
git log -5 --oneline
```

## 🟡 v60 (2026-07-11): فاتورة + حل مشاكل بلمسة + VPN ذكي + إصلاحات واجهة

**نتيجة اختبار v59:** جيدة عموماً؛ جراب هاتف عادي («بنقشة التنين») كُشف
مخصصاً خطأً — سببه مطابقة «نقش» داخل «بنقشة». أُصلح في v60 (سياق صريح فقط).

**ما نُفّذ (commit `609b9fa`) — قاعدة البيانات والدوال منشورة على الإنتاج:**
1. **فاتورة الطلب:** عمود `orders.invoice` jsonb + قسم كامل بلوحة الإدارة
   (بنود وصف+مبلغ$، مثال: شحن سعودية→سوريا 2$، رسوم منصة 1$) + عرضها
   للزبون في تفاصيل الطلب (`invoice-view`).
2. **حل المشاكل بلمسة:** حقل «الخيارات المتاحة» في مشكلة الإدارة (لأنواع
   المقاس/اللون) → أزرار في طلباتي يختار منها الزبون → RPC
   `submit_order_option_fix` (نواة service_role + غلاف بجلسة) تحدّث
   عنصر الطلب مباشرة.
3. **VPN ذكي:** فحص مزدوج (وصول المتجر المختار تحديداً + geo عبر
   ipwho.is/ipapi.co): سوريا=شغّل VPN، خارجها+محجوب=غيّر المنطقة (مع
   عرض الدولة/الولاية المكتشفة)، لا شيء=رسالة إنترنت. أزيل التجاوز
   التلقائي الأعمى بعد 5 ثوان.
4. **واجهة:** خط الشريط المحقون 12px يطابق شريط التطبيق؛ تصفير حشوة
   `downloadsWrapper` (الإطار الأبيض حول بحث تيمو)؛ padding سلة 260px
   (الوصول لبطاقة اطلب مع صديق)؛ ملخص إجمالي فوق زر المتابعة للدفع؛
   عملة الدفع باسم كامل بلا «...» (عنصر profile-row-value منفصل).
5. **كشف التخصيص:** «نقش» تُطابق فقط في سياق (نقش اسم/قابل للنقش/انقش).

⚠️ **تنسيق بين الجلسات (مهم للـAI التالي):**
- جلسة موازية (Codex) نفذت تقوية دفع/جلسات: migration
  `20260711_harden_customer_payments.sql` (مطبّقة) تجعل RPCs القديمة
  service_role فقط وتضيف أغلفة بتوكن جلسة `p_session_token`.
- migration `20260712000000` (تأليف سابق لتطبيق التقوية) أعادت منح anon
  على 4 دوال قديمة — **أُصلح** في `20260712010000` (سحب مجدد).
- v59 المنشورة تنادي RPCs القديمة بلا توكن → مزامنة الطلبات/التقييم
  معطلة فيها؛ v60 تحمل العميل المتوافق. **انشر vercel + وزّع v60 فوراً.**
- commit v60 يشمل أعمال الجلسة الموازية كما وُجدت (shamcash-listener،
  server/routes.js، whatsappAuthApi...) دون تعديل. أسماء migrations
  الجديدة بطوابع 14 رقماً (20260712xxxxxx) لتفادي تعارض ترتيب CLI مع
  ملف `20260711_...` (أي نسخة أطول تبدأ بنفس التاريخ تُرتّب قبله نصياً!).

**🔴 معلّق:** شي إن — صور المنتجات السفلية skeleton + شاشة تحقق «أنا
إنسان». بانتظار لقطة شاشة من المستخدم. قاعدة: لا يُتجاوز التحقق؛ افحص
فرضية أن التحقق/كتابة storage تحجب feed المنتجات (تحذير CLAUDE.md).

نسخ v60: `Desktop\otlobli-v60.apk`، وiOS من
[run 29131587627](https://github.com/m7madv/otlobli/actions/runs/29131587627).

---

## ✅ v59 (2026-07-11): قصّ احترافي + مشكلة قياس الصورة + إيصال التخصيص للإدارة

**طلبات المستخدم بعد v58:** (1) لا يظهر أي ذكر للتخصيص على منتج عادي مؤكد،
(2) شاشة قصّ احترافية يقص فيها الزبون صورته على القياس المطلوب، (3) إضافة
مشكلة «قياس الصورة» لنظام مشاكل المنتجات القائم مع تحديد الإدارة للقياس،
(4) 🔴 شي إن: صور المنتجات السفلية لا تُحمّل + شاشة تحقق «أنا إنسان» —
**بانتظار لقطة شاشة من المستخدم، لم يُعمل عليها بعد**. تذكير قاعدة:
لا يُتجاوز التحقق (قد يكون سبب عدم تحميل الصور أن التحقق يحجب API المنتجات؛
وتذكر تحذير CLAUDE.md: الكتابة العشوائية على storage تسبب skeleton loading).

**ما نُفّذ (commit `740a0ff`) — مطبّق على إنتاج Supabase:**
1. **اكتشاف فجوة قاتلة وإصلاحها:** أعمدة order_items الثابتة كانت تُسقط
   بيانات التخصيص عند الإدراج — أعمدة جديدة custom_text/custom_photo/
   custom_photo_note + تحديث submit_order/create_pending_order/
   customer_orders_json + RPC جديدة `submit_order_custom_fix` +
   نشر admin-orders. **الـmigration باسم `20260712000000_...` (تاريخ الغد
   عمداً — ملف `20260711_harden_customer_payments.sql` من جلسة أخرى سبّب
   تعارض ترتيب نصي في CLI، الحل نسخة تُرتّب بعده).**
2. **شاشة قصّ** (`PhotoCropModal` في App.tsx): سحب + تكبير (شريط/قرصة) +
   إطار مقفول على النسبة + شبكة + إخراج JPEG ≤1080px. كل إرفاق صورة
   تخصيص يمر عبرها. النسبة تُقرأ من customPhotoNote أو من سطر
   «القياس المطلوب:» في ملاحظة مشكلة الإدارة (parsePhotoAspect).
3. **الإدارة:** نوع مشكلة «قياس/قصّ الصورة غير مناسب» + حقل «القياس
   المطلوب» يُدرج بالملاحظة بصيغة يقرؤها التطبيق ويقفل القص عليها.
4. **الزبون:** زر «قصّ الصورة المطلوبة وأرسلها الآن» داخل بانر مشكلة
   الطلب → قص → `submitCustomFix` → يظهر فوراً للإدارة.
5. أُزيل رابط «منتج مخصص؟» نهائياً من المنتجات العادية.

نسخ v59: `Desktop\otlobli-v59.apk`، وiOS من
[run 29128838900](https://github.com/m7madv/otlobli/actions/runs/29128838900).

---

## ✅ v58 (2026-07-10): كشف ذكي للمنتجات المخصصة — بانتظار اختبار المستخدم

**تأكيد المستخدم على v57:** «كل شي مية بالمية» — الوميض حُلّ والبحث ظاهر ومستقر.

**المشكلة التالية (طلب المستخدم):** كشف المنتجات المخصصة «غبي» — منتج عادي
يُكشف كمخصص، ولا تمييز بين حاجة نص/صورة/كليهما، ولا حدود لطول النص، ولا
إرشاد للصورة.

**ما نُفّذ في v58 (commit `c2f849d`):**
1. **الكشف** (`sheinBrowserScript.ts`): حُذفت الإشارات الفضفاضة (كلمات مفردة
   مثل اسم/نص/صورة/عين/وجه كانت تُفعّل التخصيص من المراجعات وكروت المنتجات
   المقترحة). القرار الآن: عنوان المنتج + بادج «التخصيص» أعلى الصفحة فقط
   (أول 900px — الكروت المقترحة أسفل الصفحة تحمل البادج نفسه) + حقل نقش
   حقيقي. ثم يحدد النوع: نص/صورة/كلاهما (عنوان يذكر عين/وجه/بورتريه على
   منتج مخصص = صورة؛ جراب مخصص بلا نقش = صورة). يلتقط حد أحرف النقش من
   `maxlength` أو النص المجاور → `customTextLimit`.
2. **السلة** (`App.tsx`): بطاقة «منتج مخصص» بتحكم كامل للمستخدم — زر «ليس
   مخصصاً» يلغي التخصيص الخاطئ، «إزالة» لكل حاجة، «+ إضافة نص/صورة»،
   ورابط على أي منتج عادي لتحويله مخصصاً يدوياً (شبكة أمان بالاتجاهين).
   حقل النص بحد أقصى وعدّاد أحرف. إرشادات صورة واضحة. تصغير الصورة إلى
   1280px/JPEG قبل الحفظ (كانت تُخزن بحجم كاميرا كامل في localStorage).
3. **الإدارة** (`admin/src/AdminApp.tsx`): عرض النص المطلوب + صورة التخصيص
   (مصغّرة + زر تنزيل) داخل عناصر الطلب — **كانت تصل قاعدة البيانات ولا
   تُعرض للمالك إطلاقاً** (فجوة جوهرية اكتُشفت أثناء العمل).
4. **الإشعارات** (`supabaseAppApi.ts`): حذف صورة base64 من حمولة إشعار
   واتساب/تيليغرام (تبقى في الطلب بقاعدة البيانات).

نسخ v58: `Desktop\otlobli-v58.apk`، وiOS من
[run 29096579081](https://github.com/m7madv/otlobli/actions/runs/29096579081).
**يختبر المستخدم:** منتج عادي لا يُكشف مخصصاً، ومنتجات التخصيص (سوار العين
من لقطات الشاشة) تطلب الصورة/النص الصحيحين، والإدارة تعرضهما.

---

## ✅ حُلّت (2026-07-10): الوميض سببه killStorePopups — v57 يعيد زر البحث

**تأكيد المستخدم:** بعد تعطيل `killStorePopups` لتيمو (v56-test) **توقف الوميض** —
السبب مؤكد. التعطيل لتيمو صار نهائياً (commit `d117943`). لا تُعِد تفعيلها لتيمو.

**أثر جانبي ظهر بعدها:** زر البحث اختفى ثانية. السبب: CSS v53 يخفي
`downloadsWrapper` كاملاً وشريط البحث بالرئيسية يسكن داخله على الأجهزة الفعلية
(درس v35 الموثق في الذاكرة) — كانت المراجعة الذاتية في killStorePopups تنقذه،
وبتعطيلها بقي محجوباً. **إصلاح v57:**
1. CSS يخفي `[class*="downloadUI" i]` فقط (واجهة البانر) بدل الغلاف كله.
2. حارس في `hideTemuCustomerChrome`: ممنوع حجب حاوية تضم حقل البحث
   (علامة `data-otlobli-temu-hidden` تمنع الاستعادة نهائياً).
3. مطلب المستخدم: زر البحث ظاهر **ومستقر** في تيمو؛ الشعار ثانوي.

نسخ v57 للاختبار: `Desktop\otlobli-v57.apk` (أندرويد)،
وiOS من [run 29094489702](https://github.com/m7madv/otlobli/actions/runs/29094489702).
**بانتظار تأكيد المستخدم أن البحث ظاهر ومستقر بلا وميض.**

---

## 🔴 مشكلة سابقة (2026-07-10) — وميض/شاشة بيضاء على تيمو (محلولة أعلاه)

**العَرَض (من المستخدم):** عند فتح تيمو، الشاشة بيضاء وتومض بانتظام **كل نصف ثانية**
(بياض يظهر ثم يطفي)، والمنتجات لا تفتح ولا يوجد scroll. يحدث على iOS والمحاكي عند
المستخدم (حيث تيمو تعمل عبر VPN). مستمر بعد v55.

**لم يُحلّ بعد.** جُرّب: إزالة منع login (`setUrl`) في v55 — لم يكفِ حسب المستخدم.

**🧪 اختبار جارٍ (v56-test):** عُطّل المشتبه 1 (`killStorePopups`) لتيمو فقط — commit
تشخيصي `409274f` في `src/services/sheinBrowserScript.ts` ~سطر 3659 (الاستدعاء
مُعلَّق داخل فرع `IS_TEMU`؛ الاستدعاء الثاني سطر 3669 لا يصل لتيمو لأن الفرع يعمل
`return` قبله). بُنيت نسخة اختبار: `Desktop\otlobli-v56-test.apk` (تجزئتها مختلفة عن
v55 — بناء حقيقي، وتأكد وجود التعطيل داخل الحزمة المبنية في assets). **بانتظار نتيجة
المستخدم على محاكيه**: إن توقف الوميض = السبب مؤكد، ويُعاد تفعيل الدالة بشكل مُلطّف
(مثلاً: استثناء العناصر الكبيرة/حاويات المحتوى من الحجب، أو حجب بالـ CSS الثابت بدل
الدوري). إن استمر = انتقل للمشتبه 2 أدناه. **لا تُرحّل هذا التعديل كما هو** — هو
تشخيصي مؤقت.

**أقوى المشتبهين للوميض الدوري (مرتّبة، تحتاج اختباراً فعلياً على جهاز تصله تيمو):**
1. **`killStorePopups()`** (الأقوى) — `src/services/sheinBrowserScript.ts` ~سطر 3994،
   يعمل كل 300ms ضمن `tick`. يحجب عناصر `position:fixed/absolute` بـ z≥200 ونصّها
   يطابق `PROMO` (فيه `الملياردير|خصم %|billionaire|% off`). صفحة تيمو الرئيسية مليئة
   بعروض خصم، فقد يحجب حاوية كبيرة ثم "المراجعة الذاتية" في أول الدالة تعيدها →
   حجب/إظهار دوري كل 300ms = **وميض كل نصف ثانية**. جرّب تعطيله لتيمو أولاً.
2. **temu Arabic redirect (`setUrl`)** — `src/App.tsx` معالج `urlChangeEvent` (~سطر 1905).
   على VPN بـ IP أجنبي، تيمو تحمّل locale غير عربي فكودنا يعيدها لـ `/jo/`، وقد تعيدها
   تيمو → reload loop (لكن مقيّد 3/15ث عبر `temuArabicRedirectRef`).
3. **CSS الإخفاء `[class*="downloadsWrapper"], [class*="downloadUI"]`** — قد يطابق حاوية
   محتوى أكبر على iOS (بنية مختلفة عن أندرويد) فيخفيها → شاشة بيضاء.
4. **`injectTemuHeaderHideCSS` الفوري عند documentStart** (~سطر 3775) — يحقن `<style>`
   في `documentElement` قبل `<head>`؛ قد يتفاعل مع WKWebView.

**خطة التشخيص المقترحة:** أضف `console.log` مؤقت داخل `killStorePopups` يطبع أي عنصر
يُحجب/يُعاد (tag/class/نص)، وفي `urlChangeEvent` يطبع كل تغيّر URL. اختبر على جهاز
تصله تيمو (المحاكي عند المطور لا يصل لتيمو — عطل شبكة host-side/split-VPN). عطّل
المشتبهين واحداً واحداً حتى يتوقف الوميض.

**قيد مهم:** محاكي هذه الجلسة **لا يصل لتيمو** (لا default route حتى بعد wipe-data —
عطل شبكة على مستوى المضيف/VPN split-tunnel)، فتعذّر التأكيد البصري لكل الإصلاحات
أدناه. يجب اختبارها على جهاز فعلي تصله تيمو.

## سجل تعديلات الجلسة (v53 → v55)

- **v53**: إخفاء أزرار هيدر تيمو (عربة التسوق/الحساب/الفئات = `.tab-d3nPD`) + بانر
  "تسوّق مثل الملياردير" (`.downloadsWrapper`/`.downloadUI`) عبر CSS محقون في
  `injectTemuHeaderHideCSS`، مع إبقاء البحث والشعار. + حقن CSS فوري عند documentStart
  لمنع الوميض الأول. + منع صفحة login عبر `setUrl`. اختُبر بصرياً على أندرويد ونجح.
- **v54**: قصر `restoreTemuSearchChrome`/`restoreTemuLogo` على العنصر نفسه فقط (كانتا
  تُظهران لوحة حساب تيمو قسراً عند النزول عبر `otlobliUnhideEl` على الآباء/الأطفال).
- **v55**: إزالة منع login (`setUrl`) نهائياً — سبّب حلقة إعادة تحميل (شاشة بيضاء تومض)
  لأن `setUrl` يعيد تحميل الصفحة كاملة وتيمو تُطلق login عند التحميل. **لكن الوميض
  استمر بعده** → السبب الحقيقي على الأرجح `killStorePopups` (المشتبه 1 أعلاه).

- **v56-test (غير مُرحَّل)**: تعطيل `killStorePopups` لتيمو فقط لاختبار فرضية الوميض
  (انظر «اختبار جارٍ» أعلاه). بُني ووُضع على `Desktop\otlobli-v56-test.apk`.

الفرع: `codex/customer-wallet-group-orders`. آخر commit: v56-test (`409274f`) —
تعديل تشخيصي مُرحَّل ومدفوع ليشمله بناء iOS؛ لا يُعتمد كإصلاح نهائي.
نسخ للاختبار (اختبار الوميض v56):
- أندرويد: `Desktop\otlobli-v56-test.apk`
- آيفون: `Desktop\otlobli-v56-test.ipa` (من [iOS run 29093171791](https://github.com/m7madv/otlobli/actions/runs/29093171791) — نجح)
- نسخ أقدم: `Desktop\otlobli-v55.apk`، [iOS run 29064136009](https://github.com/m7madv/otlobli/actions/runs/29064136009)

---

## آخر عمل (Claude — إخفاء أزرار هيدر تيمو + منع صفحة تسجيل الدخول)

تاريخ: 2026-07-09. اختُبر على محاكي أندرويد `emulator-5554` (`com.otlobli.app`) بصرياً + بالسجلات.

المشكلة والحل الجذري:
- أزرار هيدر تيمو (عربة التسوق / الحساب / الفئات) كلها من نوع `DIV.tab-d3nPD`،
  والبحث `DIV.searchBar-3m_IK`، وكلها كانت داخل حاوية أب `display:none` فأبعادها
  `0x0` — لهذا فشلت كل محاولات الحجب المعتمدة على الموقع/الأبعاد سابقاً، وكانت
  أسماؤها في `aria-label` (أيقونات SVG بلا نص) فتخطّتها الفحوصات النصية أيضاً.
- الحل النهائي (الأسهل والأضمن): حقن CSS في `injectTemuHeaderHideCSS()` داخل
  `src/services/sheinBrowserScript.ts` يستهدف `[class*="tab-d3nPD"]` + aria الدقيق
  (عربة التسوق/الحساب/الفئات) بـ `display:none`. النتيجة: الأزرار الثلاثة تختفي،
  ويبقى البحث والشعار.
- بانر "تسوّق مثل الملياردير" (بانر تنزيل تطبيق تيمو): حاويته الجذر
  `DIV.downloadsWrapper` وتحتها `downloadUI`. أُضيف للـ CSS نفسه
  `[class*="downloadsWrapper"], [class*="downloadUI"]` فاختفى البانر نهائياً.
- إصلاح الوميض (FOUC): كان الإخفاء يُحقن متأخراً عبر tick فتظهر العناصر لحظة عند
  أول دخول أو عند الرجوع من منتج. الحل: `OTLOBLI_TEMU_HIDE_CSS` صار ثابتاً،
  و`injectTemuHeaderHideCSS()` تُحقن **فوراً عند تحميل السكربت** (documentStart،
  في `document.head || document.documentElement`)، ولم تعد تعتمد على flag لمرة
  واحدة بل تفحص وجود `#otlobli-temu-header-hide` فتعيد الحقن لو أزالته تيمو،
  وأُضيفت لدورة الـ 120ms السريعة. تأكّد بتسجيل فيديو + استخراج 42 إطاراً حول
  لحظة الرجوع: كل الإطارات نظيفة، صفر وميض.
- منع صفحة تسجيل الدخول: في `src/App.tsx` داخل معالج `urlChangeEvent`، أُضيف
  `TEMU_LOGIN_RE` — أي انتقال لـ `login.html`/`/login`/`signin`/`login.temu.com`
  يُعاد فوراً إلى `https://www.temu.com/jo/` (مع throttle 3 محاولات/15ث عبر
  `temuLoginBlockRef`). تأكّد بالسجل: النقر على "تسجيل الدخول" أطلق `login.html`
  فاعتُرض وأُعيد للرئيسية دون ظهور صفحة login.

- إصلاح ظهور لوحة الحساب عند النزول (v54): كان `restoreTemuSearchChrome`/
  `restoreTemuLogo` يستدعيان `otlobliUnhideEl` (تفرض opacity:1/visibility:visible
  !important) على البحث/الشعار **+ آبائهما (4-5 مستويات) + كل أطفال حاوية البحث**.
  لوحة حساب تيمو (تسجيل الدخول/إنشاء حساب) تعيش داخل نفس حاوية الهيدر ومخفية بـ
  opacity:0، فكان توسيع الاستعادة يفرض ظهورها عند النزول وتقفز الصفحة لأعلى وتتجمّد.
  الإصلاح: قصر الاستعادة على العنصر نفسه فقط (`otlobliUnhideEl(el)` بلا حلقة آباء
  أو أطفال). يبقى البحث/الشعار ظاهرين دون لمس اللوحة. لم يُختبر على المحاكي (شبكة
  المحاكي لا تصل لتيمو بعد إعادة تشغيله — حجب بيئي)؛ يُختبر على جهاز iOS فعلي.

- إزالة منع تسجيل الدخول (v55) — كان يسبب شاشة بيضاء تومض على iOS: منع login
  كان يستدعي `InAppBrowser.setUrl('temu.com/jo/')` عند اكتشاف login بالرابط.
  على iOS (WKWebView) تُطلق تيمو تنقّلاً فيه login عند التحميل، فكل setUrl يعيد
  التحميل كاملاً فيُطلق تنقّل login آخر → حلقة إعادة تحميل لا تنتهي (شاشة بيضاء
  تومض). أُزيل كل منطق منع login (`TEMU_LOGIN_RE` + الـ refs + الـ setUrl). إن
  لزم منع login مستقبلاً فبطريقة لا تعيد التحميل (إخفاء عناصر/منع نقر)، لا setUrl.

ملاحظات:
- تنظيف: أُزيل كل كود التشخيص المؤقت وحقن force-open shadow DOM (لم يكن هناك shadow).
- الملفان المعدّلان: `src/services/sheinBrowserScript.ts` و `src/App.tsx`.
- نسخة iOS تُبنى عبر workflow `ios-unsigned-build.yml`.
- تعذّر التأكيد البصري على المحاكي: شبكة المحاكي لا تصل لتيمو (حجب جغرافي — تيمو
  تعمل على جهاز iOS الفعلي عبر VPN المستخدم لكن لا على اتصال المحاكي المباشر).

## Critical rule

Do not assume `main` is latest. Do not restore old code from another branch unless manually comparing and cherry-picking only the needed pieces.

Existing staged/untracked files may be work from another AI or the user. Do not revert them.

## Current fragile areas

- SHEIN mobile browsing:
  - must stay on `m.shein.com/ar`
  - country Saudi Arabia
  - currency USD
  - language Arabic
  - `site_uid=pwar`
  - no custom User-Agent spoofing
  - do not broadly overwrite SHEIN storage keys
  - do not treat random country names inside product titles/descriptions as wrong region
- Temu WebView:
  - bottom otlobli nav must remain fixed and visible
  - search must remain visible
  - hide only confirmed Temu account/cart/login distractions, not product content
- Group cart:
  - invite links must work from WhatsApp
  - recipient should confirm linking before joining
  - carts should sync quickly and unlink after order
- Admin:
  - do not auto-open the first order
  - mobile layout is important
  - coupons, drivers, product issues, wallet/order actions are current features
- Payments/wallet:
  - do not change payment/wallet logic unless explicitly requested

## Last confirmed Codex state

- 2026-07-09 group-cart invite fix:
  - `src/App.tsx` now clears a different stale local `cartGroup` when a WhatsApp invite opens, so the recipient sees the confirmation card and can join the host group instead of seeing their old "waiting for friend" state.
  - `android/app/src/main/AndroidManifest.xml` now handles `https://talabieh.vercel.app/group` links in addition to the existing app/deep links.
  - `npm run build` passed after the fix.
- 2026-07-09 group-cart member-key fix:
  - Group membership/items now use a per-device `memberKey`, so two devices using the same WhatsApp phone during testing can still become two distinct members.
  - Creating a group no longer reuses the host's old open group; each create action generates a new code/link.
  - Group totals and per-person shares display via the app currency formatter from SYP totals/exchange rate, avoiding the old `$current / $40` line.
  - Production Supabase migration `20260709_group_cart_member_keys.sql` was pushed, `cart-groups` was deployed, and same-phone/two-member production test returned `members=2` and both owners' products.
- Android APK was built and installed on emulator.
- SHEIN home opened Arabic/Saudi/USD.
- SHEIN product page opened successfully after fixing the Saudi guard.
- AI guardrail files were added so Claude/Codex/other models read current state before editing.
- Dangerous uncommitted Claude WIP that reverted SHEIN to older `/jo` behavior and removed group/wallet schema was backed up to Temp and removed from the working tree.
- Customer/admin builds passed after cleanup.
- Latest iOS unsigned GitHub workflow succeeded:
  - `https://github.com/m7madv/otlobli/actions/runs/28971384749`
- Previous iOS unsigned workflow succeeded:
  - `https://github.com/m7madv/otlobli/actions/runs/28935943927`
- Supabase customer reset helper exists:
  - `supabase/RESET_CUSTOMER_DATA.sql`
  - Not executed automatically because local env files do not contain a usable Supabase service role/database password.

## Handoff habit

At the end of every long session, update:

- `CURRENT_STATE.md`
- `AI-HANDOFF.md`
- `SESSION_SUMMARY.md`

Then give the user a short Arabic summary with:

- what changed
- what was tested
- what was pushed/built
- what the next AI must read first
