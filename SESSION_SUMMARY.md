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
