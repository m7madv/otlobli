# SESSION_SUMMARY.md

## Codex follow-up (2026-07-11)

- Exchange-rate source-label fix `9f42cf5` is deployed in Railway deployment
  `32116896-5c2c-4088-b8d5-40c7a058ba44` (`SUCCESS/RUNNING`). Production API and
  Supabase `app_settings.usd_to_syp_rate` both verify at `13050` SYP/USD.
- Applied structured issue/payment hardening migrations `20260712031000` and
  `20260712032000`; deployed `admin-orders` version 28. Production probes for the
  empty account RPC and protected issue-resolve RPC returned controlled results, and
  the root client build passed.
- `admin-orders` was redeployed with stale-draft merging so a late admin save cannot
  reopen or delete a customer-resolved issue.

---

# 📋 تسليم مفصّل لكودكس — جلسة Claude (v58 → v65، 2026-07-10/12)

الفرع `codex/customer-wallet-group-orders`. كل ما يلي **مطبّق على الإنتاج**
(قاعدة البيانات + دوال Edge + Vercel admin + Railway server) ومدفوع لـ GitHub.
النسخ الأحدث على سطح مكتب المستخدم: `otlobli-v65.apk` و`otlobli-v65.ipa`.

## حدود العمل بيننا (مهم جداً)
- **لم ألمس مسار الدفع/الجلسات المقوّى الذي بنيته** (webhook، wallet reservation،
  create_pending_order، require_customer_session، ShamCash). فقط **أستهلكه**.
- كل RPC جديدة لي تتبع نمطك: **نواة `service_role` + غلاف موقّع بـ
  `p_session_token`** يستدعي `require_customer_session`.
- تعارض ترتيب migrations: أي ملف تاريخه `20260711` (بلا طابع كامل) يُرتّب CLI
  قبل ملفات `20260712xxxxxx` نصياً. لذلك كل migrations الجديدة لي بطابع
  14 رقماً `20260712xxxxxx` لتُرتّب بعد `20260711_harden_customer_payments`.

## Migrations التي طبّقتُها على الإنتاج (بالترتيب)
1. `20260712000000_order_item_custom_fields` — أعمدة `order_items`:
   `custom_text`, `custom_photo`, `custom_photo_note` + تحديث `submit_order`/
   `create_pending_order`/`customer_orders_json` + RPC `submit_order_custom_fix`.
   (كانت بيانات التخصيص تُسقط عند الإدراج فلا تصل الإدارة.)
2. `20260712010000_order_invoice_and_option_fix` — عمود `orders.invoice` jsonb
   + RPC `submit_order_option_fix` (مقاس/لون). **يعيد سحب صلاحيات anon** عن
   4 دوال قديمة كانت `20260712000000` أعادت منحها بعد تقويتك.
3. `20260712015000_fix_session_digest` — `require_customer_session` كانت
   `search_path=public` فلا ترى `digest()` (pgcrypto في مخطط extensions) —
   **كل إنشاء طلب كان يفشل** بـ `function digest(text, unknown) does not exist`.
   الحل: `set search_path = extensions, public`.
4. `20260712016000_add_admin_set_order_payment_status` — الدالة كانت مفقودة
   من الإنتاج (النسخة المطبقة من تقويتك كانت مسودة أقدم) فزر «تأكيد الدفع»
   بالإدارة معطّل. زُرعت **حرفياً من صيغتك النهائية**.
5. `20260712030000_structured_order_issues` — عمود `orders.issues` jsonb +
   RPC `submit_order_issue_resolve` + `customer_orders_json` يُخرج issues.

> ملاحظة: `schema.sql` مُزامن مع كل ما سبق. ملف hotfix `20260712020000`
> الخاص بك طُبّق (حسب متابعتك أعلاه) — لم أعدّله.

## Edge functions المنشورة
- `admin-orders`: يمرر `customText`/`customPhotoDataUrl`/`customPhotoNote`
  و`invoice` و`issues` (GET) ويقبلها في PATCH.
- `app-settings`: مفتاح جديد `support_whatsapp_phone`.

## ميزات المنتج (v58→v65) — أماكن الكود
- **كشف المنتجات المخصصة** (`sheinBrowserScript.ts`): `temuCustomRequirements`/
  `otlobliCustomTextSignal`... إشارات صارمة من العنوان + بادج «التخصيص» أعلى
  الصفحة فقط. «نقش» تُطابق فقط بسياق صريح (نقش اسم/قابل للنقش) — «بنقشة» لا.
- **شاشة قص صور** (`App.tsx` `PhotoCropModal`): سحب/تكبير/إطار مقفول بالنسبة،
  إخراج JPEG ≤1080px. تُستخدم في السلة وفي حل مشكلة قياس الصورة.
- **نظام مشاكل متعدد احترافي**: الإدارة `OrderIssuesField` (`AdminApp.tsx`) —
  عدة مشاكل/طلب، تُشتق منها `paymentIssue`/`extraAmountUsd`/note للتوافق.
  الزبون `App.tsx` قسم «مشاكل تحتاج حلّك» — أزرار مقاس/لون، قص صورة، نص، دفع.
  `submitOptionFix`/`submitCustomFix`/`submitIssueResolve` في `supabaseAppApi.ts`.
- **فاتورة الطلب**: `InvoiceField` (إدارة) + `invoice-view` (تطبيق).
- **محفظة**: عرض «تم الإيداع/السحب» + رقم الطلب والمتجر (`payment-methods`).
- **رقم دعم قابل للتعديل**: `support_whatsapp_phone` → `openWhatsappSupport`.
- **إصلاح شاشة تعديل الاستلام**: زر recipient-detail يضيف `setScreen('profile')`.
- **VPN ذكي** (`App.tsx`): فحص وصول المتجر بالصور فقط (لا `fetch no-cors` — يكذب)
  + geo (ipwho.is/ipapi.co): سوريا=شغّل VPN، خارجها+محجوب=غيّر المنطقة، لا شبكة=offline.
- **شي إن كلاودفلير** (v62/v65): `otlobliIsHumanChallenge()` يجمّد tick أثناء
  «Just a moment». v65: حارس السعودية صار **شريطاً علوياً غير حاجب** بدل طبقة
  تحجب الصفحة+حلقة location.replace («يطلعني»). منع إعادة التحميل أثناء التحقق.
- **تيمو**: v57 عطّل `killStorePopups` لتيمو (سبب وميض 500ms) — **لا تُعده**.
  v65 `dismissTemuLoginPopup` يغلق نافذة دخول عائمة (لا صفحة كاملة).

## واتساب (server/src/whatsapp.js) — عدة إصلاحات
- **«في انتظار هذه الرسالة»**: كان `getMessage: () => undefined` يمنع إعادة
  إرسال الرسائل غير المفكوكة. أضفت مخزن رسائل `__waMsgStore` + `getMessage`
  يعيدها. **والأهم**: أزلت `fireInitQueries:false` (كانت تمنع رفع prekeys
  فيتعذر على المستلم تأسيس جلسة Signal) + `shouldSyncConnectionMessage:false`
  + `emitOwnEvents:false`.
- **تصليب ضد الحظر**: هوية جهاز ثابتة، `sendHumanLike` (حضور+تأخير) + `paceSend`
  (فاصل 4ث). `server/WHATSAPP_ANTI_BAN.md` يشرح بصدق أن الحظر سلوك واتساب.

## 🔴 معلّق / يحتاج قراراً أو جهاز
1. **واتساب — إعادة ربط الرقم**: من فحص السيرفر المباشر: جلسة 0 متصلة
   (963990782172 = رقم البوت في صورة المستخدم)، جلسة 1 فارغة. رسائل هذا
   الرقم تصل «في انتظار». الإصلاحات أعلاه تعالج الجذر للرسائل الجديدة، لكن
   **المحادثات القديمة المكسورة تحتاج إعادة ربط الرقم** (يغيّر الهوية فيجبر
   كل الأجهزة على تأسيس تشفير نظيف). ينتظر قرار المستخدم (إعادة الربط توقف
   الرقم للحظات). endpoints: `POST/DELETE /api/whatsapp/sessions/:id`,
   صفحة QR `/api/qr`. Baileys 6.6.0 قديم — ترقيته قد تساعد لكنها محفوفة.
2. **شي إن/تيمو**: كل إصلاحات المتجر **غير مُعاينة** (المطور لا يصل للمتجرين).
   تحتاج اختبار المستخدم على جهاز حقيقي عبر VPN. تيمو: يُحتاج تأكيد إن كانت
   شاشة الدخول نافذة (يغلقها v65) أم صفحة كاملة (سياسة تيمو للمنطقة).

## Copy this into a new AI chat before continuing work.

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

## 🟡 Codex (2026-07-11): Note 8 + ShamCash + تقوية الدفع — عطل NTC مؤكد

هذا العمل منفصل عن تعديلات Claude المتزامنة على الواجهات. لا تخلط الملفات أو
ترجع commits الخاصة به.

**اكتمل في الإنتاج:**
- طُبق `20260712020000_payment_hardening_hotfix.sql` كاملًا بعد اختبار PGlite
  على schema حديث وتاريخي، وتشغيله مرتين، واختبار الطلب/المحفظة/دفعة المشكلة
  مع replay دون تكرار مالي.
- طُبق `20260712021000_fix_profile_wrapper_overload.sql` بعد أن كشف
  `supabase db lint` غموض استدعاء حفظ الملف الشخصي. عاد lint لمسار الدفع نظيفًا؛
  المتبقي فقط خطآن قديمان في `create_cart_group` و`join_cart_group` من نطاق Claude.
- نُشر `payment-webhook` v9: `ACTIVE`, `verify_jwt=false`, import map مفعّل.
  الحماية الآن HMAC على البايتات الأصلية + نافذة 5 دقائق + package ثابتة +
  eventId دائم + RPC ذرّي.
- دُوّر المفتاح القديم وحُفظ الجديد خارج git في Windows Credential Manager:
  `Otlobli/ShamCashWebhookSecret`. لا تطبعه.
- اختبارات الإنتاج: missing/invalid signature = 401، توقيع صحيح لإشعار OTP مرفوض
  = 200، وإعادته = duplicate 200 بلا معالجة مكررة.
- طُبق `20260712022000`: يمنع سلم المبالغ الناقص القابل للاستغلال ويجعل التصادم
  exact-only، ويمنع أكثر من شحن محفظة معلّق للعميل. وطُبق `20260712023000`:
  unmatched حديث يعاد توفيقه لدقيقتين فقط، والقديم يبقى نهائيًا.
- نُشر إصلاح مزامنة سعر الصرف من commit `d0ac78f` عبر Railway deployment
  `63fd12de-3c29-4c7b-8646-72600400de85` بحالة `SUCCESS/RUNNING`. الـAPI يكتب السعر
  إلى Supabase قبل الرد، يعيد فحص أي cache مقابل قاعدة الدفع، يمنع التحديث المتوازي
  داخل الـinstance، ويرسل `Cache-Control: no-store`. تحقق الإنتاج: الـAPI وSQL كلاهما
  `13050 SYP/USD`.

**Android Listener:**
- أزيل نهائيًا header القديم `x-payment-secret`؛ السر يستخدم فقط لتوقيع HMAC
  ومخزّن داخل Android Keystore.
- أزيل `TEST_NOTIFICATION` من release، وأصبحت هوية الحدث ثابتة عبر تحديث الإشعار،
  وتُرفض group summaries، وتُستعاد الإشعارات النشطة الحديثة بعد rebind، وحد Data
  محسوب بالـUTF-8. الاختبارات 16/16، وDeno 13/13، وR8/lint ناجحة (تحذير أيقونة واحد).
- APK موقّع جاهز:
  `android/shamcash-listener/build/outputs/apk/release/shamcash-listener-release.apk`
- SHA-256:
  `343f0213d837410b0a4069a67ece69a2cc65b8aba3c3140f65d0663ecfb226b5`
- signer SHA-256:
  `44ed0b43a41924ca67dfa44c6815e5b9286f843b7879b1f1d2c7e4ee5b1f827b`

**الهاتف/البطارية/التحكم — غير مكتمل بعد:**
- ADB صار authorized `device`: الرقم `988e16384e4f51395230` والموديل `SM-N950F`.
  لا تشغّل ShamCash على الكمبيوتر؛ الاختبار الحقيقي فقط على الهاتف والشبكة السورية.
- فحص sysfs جديد من 6 عينات حسم العطل: 0%، `health=Cold`، حرارة -20°C،
  ADC=`3950..3986`، جهد=`3.386..3.387V`، تيار=0، و`Not charging`. USB يبقي الجهاز
  حيًا لكنه لا يشحن البطارية. يجب إعادة تركيب/استبدال بطارية متوافقة وفلكسها؛ إذا بقي
  ADC قرب 3950 فالعطل في NTC/الكونكتور/مسار اللوحة. ممنوع جسر الحساس أو إجبار الشحن.
- التعديل الوحيد الظاهر في Magisk هو `/data/adb/service.d/fakebattery.sh` (SHA-256
  `9575a5e9dd37e4f1d6a738a3b83b5159816d9eb254f825fcd98c1c895a526e95`)؛ يزوّر
  BatteryService إلى AC/100%/25°C كل 15 ثانية ليمنع Android من الإطفاء. لا تحذفه قبل
  أن تصبح القراءة الخام طبيعية. بعد إصلاح العتاد: استعادة Samsung رسمية بلا روت، بهوية
  `XSG`/`N950FXXUGDVG7` وbaseband `N950FXXSGDUG6`، ثم Factory Reset.
- TeamViewer Host وAnyDesk مثبتان للاختبار. قبول Samsung Knox EULA وربط حساب
  TeamViewer/كلمة مرور AnyDesk يجب أن يفعله المستخدم بنفسه. اختبر حلًا واحدًا
  ثم احذف الآخر لتقليل سطح الهجوم.

**الخطوة التالية بعد إصلاح حساس البطارية وثبوت Good/Charging في sysfs:**
1. تعطيل سكربت المحاكاة مؤقتًا ومراقبة BatteryService الحقيقي دون إجبار الشحن.
2. استعادة الروم الرسمي المطابق وإزالة Magisk/root ثم Factory Reset.
3. إزالة listener debug ذي التوقيع القديم، تثبيت release الموقّع، واسترجاع السر
   من Credential Manager داخل الذاكرة فقط ثم provisioning عبر ConfigReceiver المحمي.
4. إعادة إذن Notification Listener والـbattery whitelist وفتح شاشة الحالة؛ لا يوجد
   synthetic action في release عمدًا، والاختبار المالي لا يُزوّر عبر ADB.
5. التقاط إشعار ShamCash حقيقي وبنيته/مرجعه على الهاتف والشبكة السورية؛ هذا release
   gate لمنع أي duplicate provider event، ثم إكمال التحكم من iPhone.

**دين أمان لم يُخفَ:** سلامة HMAC والمطابقة والمبلغ الاسمي أصبحت قوية، لكن أسعار
المنتجات والإجمالي ما زالت آتية من WebView/العميل لعدم وجود price quote موثوق من
الخادم، ومسار group checkout لا يبني snapshot موثقًا بالكامل. لا تصف التجارة كلها
بأنها tamper-proof قبل price quotes وختم group snapshot على الخادم.

## 🟡 v63 (2026-07-11): نظام مشاكل احترافي + محفظة/دعم/تعديل ملف + تصليب واتساب

**نُفّذ ونُشر على الإنتاج بالكامل (DB + admin-orders + app-settings + Vercel
admin + Railway server):**
1. **نظام مشاكل متعدد احترافي:** عمود `orders.issues` jsonb + RPC
   `submit_order_issue_resolve` (نواة service_role + غلاف جلسة). لوحة
   الإدارة `OrderIssuesField`: عدة مشاكل مضغوطة لكل طلب/منتج
   (payment/size/color/custom_photo/custom_photo_size/custom_text/
   unavailable/quantity/link/other)، يُشتق منها paymentIssue/
   extraAmountUsd/note للتوافق مع مسار الدفع وإشعار الواتساب. التطبيق:
   قسم «مشاكل تحتاج حلّك» — أزرار مقاس/لون، قص صورة، إدخال نص، دفع
   الفرق، أو تواصل/معالجة. **مسار دفع Codex المقوّى لم يُمس.** البانر
   القديم يظهر فقط للطلبات بلا issues[] (توافق خلفي).
2. **تعديل معلومات الاستلام:** الزر كان يضبط editingProfile دون الانتقال
   لشاشة profile → لا يظهر ويظهر عند الرجوع. أُصلح بـ setScreen('profile').
3. **حركات المحفظة:** «تم الإيداع/تم السحب» بالدولار + رقم الطلب والمتجر
   (شي إن/تيمو) بأيقونات، بدل نص القاعدة الخام.
4. **رقم دعم قابل للتعديل:** app-settings `support_whatsapp_phone` + حقل
   بلوحة الإدارة + التطبيق يقرؤه في openWhatsappSupport.
5. **تصليب واتساب (server/src/whatsapp.js):** هوية جهاز ثابتة، sendHumanLike
   (حضور «يكتب» + تأخير) + paceSend (فاصل 4ث، طابور). صراحة موثّقة في
   `server/WHATSAPP_ANTI_BAN.md`: الحظر سلوك واتساب حسب نوع/عمر الرقم؛
   لا كود يمنعه 100%؛ الحل شرائح حقيقية مُحمّاة + inbound.

نسخ v63: `Desktop\otlobli-v63.apk` + iOS
[run 29158544945](https://github.com/m7madv/otlobli/actions/runs/29158544945).

---

## 🟡 v62 (2026-07-11): شي إن — وضع التحقق الآمن (كلاودفلير)

**التشخيص الحاسم (فحص مباشر من جهاز التطوير):** `m.shein.com` صارت خلف
جدار كلاودفلير — ترد **HTTP 403 + صفحة "Just a moment..."** قبل أي محتوى.
هذه هي شاشة «أنا إنسان» وهي سبب سلسلة الأعراض: هياكل رمادية بدل المنتجات
(الـAPI محجوب خلف التحدي) و«تعذر فتح شي إن» المتكرر.

**لماذا علِقت شي إن كلياً:** حارس السعودية (`ensureSheinSaudiStore`) لا يجد
مؤشرات سعودية على صفحة التحدي فيعيد تحميلها (حتى مرتين/30ث) ويصفّر حل
المستخدم قبل إتمامه. والبوابة تعدّ فشل فك ترميز صور الفحص «حجب منطقة».

**الحل (v62) — القاعدة محفوظة: لا تجاوز للتحقق ولا تغطية:**
1. `otlobliIsHumanChallenge()` (العنوان/`#challenge-form`/سكربتات
   challenges.cloudflare.com) → tick يتجمد كلياً + تُزال كل عناصر
   `[id^=otlobli]` + رسالة `humanCheck` للتطبيق (مرة لكل صفحة).
2. `ensureSheinSaudiStore` ترجع false فوراً أثناء التحدي (لا تحميل/كتابة).
3. التطبيق عند `humanCheck`: يطفئ مؤقت الخطأ، لا يغلق الصفحة، إرشاد
   لمرة واحدة «اضغط مربع التحقق وسيفتح المتجر».
4. البوابة: خارج سوريا يُفتح شي إن حتى مع فشل فحص الصور (تحدٍ متوقع).
   تيمو بلا تغيير.

**إصلاحات إنتاج إضافية بنفس اليوم (مسودة التقوية القديمة):**
- `20260712015000`: digest غير مرئية (search_path بلا extensions) — كل
  إنشاء طلب كان يفشل. ✅ مطبق.
- `20260712016000`: `admin_set_order_payment_status` غير موجودة — زر
  تأكيد الدفع بالإدارة معطل. زُرعت حرفياً من ملف Codex. ✅ مطبق ومتحقق.
- لوحة الإدارة نُشرت يدوياً عبر vercel CLI (talabieh-admin) وتحقق وجود
  الميزات الأربع في حزمة الإنتاج.
- ✅ hotfix كودكس `20260712020000` أُعيد بناؤه كاملًا، اختُبر محليًا وتاريخيًا،
  وطُبق على الإنتاج. كما طُبق `20260712021000` لإزالة غموض profile wrapper.

---

## ✅ v61 (2026-07-11): صيانة شاملة بعد اختبار v60

**شكاوى المستخدم وجذورها (كلها حُلّت):**
1. **شاشة بيضاء بدل بوابة VPN:** فحص المتجر كان يضم fetch no-cors الذي
   يعدّ صفحة الحجب السورية «نجاحاً» → البوابة تظن المتجر متاحاً وتفتح
   webview أبيض. أُصلح: الفحص بفك ترميز صور فقط (الدرس كان موثقاً بتعليق
   الكود نفسه!). + زر «فحص الاتصال والـVPN» في شاشة تعذر الفتح.
2. **طلباتي فارغة بعد إعادة تسجيل الدخول:** سيرفر Railway كان على نسخة
   9 تموز — قبل نظام جلسات الزبائن — فيصدر توكنات غير مسجلة في
   customer_sessions وترفضها كل الدوال المقواة. **نُشر السيرفر** (deploy
   f66a6f24، أقلع بنجاح). ⚠️ يجب على المستخدم تسجيل خروج/دخول مرة
   أخيرة بعد النشر ليأخذ توكناً صالحاً.
3. **إشعار المشكلة لا يصل (واتساب/داخل التطبيق):** ORDER_NOTIFY_SECRET
   كان مفقوداً في Railway وSupabase معاً → دوال الإشعار تنسحب صامتة.
   وُلّد سر وثُبّت في الطرفين. والجزء داخل التطبيق كان من مشكلة (2).
4. **قسم الفاتورة غير موجود بالإدارة:** كان مضافاً للمودال فقط —
   أضيف للوحة التفاصيل الجانبية. (يتطلب نشر Vercel للوحة الإدارة.)

نسخ v61: `Desktop\otlobli-v61.apk`، وiOS من
[run 29138979734](https://github.com/m7madv/otlobli/actions/runs/29138979734).

---

## ✅ v60 (2026-07-11): فاتورة + حل مشاكل بلمسة + VPN ذكي + إصلاحات واجهة

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
