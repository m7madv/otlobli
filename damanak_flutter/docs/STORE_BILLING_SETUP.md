# إعداد فوترة ضمانك عبر المتاجر

الإصدار المستهدف: `4.1.0+7` — معرّف التطبيق: `com.damanak.damanak`

هذه هي قناة تحصيل اشتراك صاحب المتجر في ضمانك. مبيعات صاحب المتجر لعملائه داخل نقطة البيع تبقى عمليات محاسبية مستقلة ولا تمر عبر `App Store` أو `Google Play`.

## ما ينفذه التطبيق والخادم

- يعرض السعر والعملة المحليين كما يرسلهما متجر الجهاز؛ لا يعتمد سعراً مكتوباً داخل التطبيق.
- يربط الشراء بمعرّف حساب المالك، ولا يفعّل الخطة عند حالة الدفع المعلّق.
- يرسل الإيصال إلى دالة `verify-store-purchase`، ثم يتحقق الخادم مباشرة من `Apple App Store Server API` أو `Google Play Developer API`.
- يمنح الاستحقاق فقط عبر دالة قاعدة بيانات مقصورة على `service_role`، ثم يكمل معاملة المتجر بعد نجاح التحقق.
- يدعم استعادة المشتريات، والترقية والخفض، والتبديل بين شهري وسنوي، وإدارة الإلغاء من صفحة اشتراكات المتجر.
- يحتفظ برمز شراء `Google Play` في مخطط `private` غير المتاح للتطبيق، ويعيد التحقق خادميّاً عند تسجيل مالك المتجر إذا مضت 6 ساعات على آخر تحقق.
- تنتهي صلاحية العمليات الحساسة تلقائياً عند تجاوز `current_period_end` حتى لو تعذر تحديث حالة الواجهة مؤقتاً.

## منتجات App Store Connect

مجموعة `Damanak Plans` والمنتجات الستة موجودة فعلياً داخل سجل App Store Connect رقم `6804792494`:

| الخطة | شهري | سنوي |
|---|---|---|
| بداية | `com.damanak.subscription.starter.monthly` | `com.damanak.subscription.starter.yearly` |
| نمو | `com.damanak.subscription.growth.monthly` | `com.damanak.subscription.growth.yearly` |
| توسع | `com.damanak.subscription.scale.monthly` | `com.damanak.subscription.scale.yearly` |

اكتملت الترجمة العربية، والتوافر في دول الخليج الست، وصور المراجعة، واتفاقية التطبيقات المدفوعة والحساب البنكي والضرائب وDSA. الأسعار الحالية `39/390` و`99/990` و`199/1989.99 SAR`؛ اختيرت `1989.99` لأنها أقرب نقطة سعر سنوية توفرها Apple إلى `1990`.

عند تعديل أي منتج مستقبلاً:

1. اختر مدة التجديد المطابقة: شهر أو سنة.
2. أضف الاسم والوصف بالعربية والإنجليزية.
3. حدّد السعر في البلدان المستهدفة واترك المتجر يعرض العملة والضرائب المحلية.
4. أكمل اتفاقيات التطبيقات المدفوعة والضرائب والحساب البنكي في `App Store Connect`.
5. أضف لقطة شاشة المراجعة، وسياسة الخصوصية، وشروط الاستخدام، واشرح طريقة فتح شاشة الاشتراك والاستعادة للمراجع.
6. اختبر المنتجات بحساب `Sandbox Apple ID` ثم عبر `TestFlight` قبل الإرسال العام.

مفتاح `In-App Purchase` الحالي رقمه `49HN3HGNM2`، والقيم التالية محفوظة بالفعل في أسرار Supabase من دون وضعها في التطبيق أو `Git`:

```text
APPLE_IAP_ISSUER_ID
APPLE_IAP_KEY_ID
APPLE_IAP_PRIVATE_KEY_P8
```

## منتجات Google Play Console

تطبيق Google Play موجود باسم `Damanak - ضمانك` ورقمه `4975804725938350009`. أول إصدار داخلي `4.1.0 (7)` مرفوع ومتاح لمسار الاختبار الداخلي. المنتجات المطلوبة هي:

- `com.damanak.subscription.starter`
- `com.damanak.subscription.growth`
- `com.damanak.subscription.scale`

أضف داخل كل منتج خطتين أساسيتين قابلتين للتجديد التلقائي بالمعرّفين الدقيقين:

- `monthly` لمدة شهر.
- `yearly` لمدة سنة.

الأسعار المستهدفة للخليج `39/390` و`99/990` و`199/1990 SAR`. لا تنشئ عرضاً تمهيدياً مطلوباً لتشغيل النسخة الأولى؛ التطبيق يختار العرض الأساسي المباشر الذي لا يحمل `offerId`.

حساب الخدمة `damanak-play-verifier@damanak-production.iam.gserviceaccount.com` نشط داخل Play Console بأذونات التطبيق المحدودة. فُعّلت `Google Play Android Developer API`، وحُفظ كائن الحساب في Supabase وGitHub كسِر:

```text
GOOGLE_PLAY_SERVICE_ACCOUNT_JSON
```

سكربت `scripts/google_play_setup.mjs` يدعم:

```bash
node scripts/google_play_setup.mjs
node scripts/google_play_setup.mjs --apply
node scripts/google_play_setup.mjs --activate
```

الفحص للقراءة فقط. `--apply` ينشئ المنتجات والخطط المسعرة لدول `SA/AE/BH/KW/OM/QA` كمسودات. `--activate` ينشئ الناقص ثم يفعّل الخطط الأساسية. بتاريخ 2026-08-25 نجح الفحص، لكن Google ما زالت تعيد `The caller does not have permission` لعملية تحويل أسعار المناطق؛ توثق Google أن تغييرات الأذونات قد تحتاج حتى 48 ساعة للانتشار، لذلك لم تُنشأ المنتجات بعد ولم يُتحايل بمنح الحساب صلاحية مشرف.

## نشر قاعدة البيانات ودالة التحقق

بعد إنشاء مشروع `Supabase` مستقل لضمانك:

```bash
supabase link --project-ref YOUR_DAMANAK_PROJECT_REF --workdir damanak_flutter
supabase db push --workdir damanak_flutter
supabase secrets set APPLE_IAP_ISSUER_ID=... APPLE_IAP_KEY_ID=... APPLE_IAP_PRIVATE_KEY_P8=... GOOGLE_PLAY_SERVICE_ACCOUNT_JSON=... --project-ref YOUR_DAMANAK_PROJECT_REF
supabase functions deploy verify-store-purchase --project-ref YOUR_DAMANAK_PROJECT_REF
```

لا تطبّق migrations ضمانك على مشروع تطبيق آخر. ملف `20260824180000_damanak_store_billing.sql` يوقف مسارات رموز التفعيل وطلبات الاشتراك اليدوية ويجعل المتاجر القناة المدفوعة الوحيدة.

## اختبار القبول الإلزامي

نفّذ الاختبارات على إصدار منشور في مسار اختبار المتجر، لا على تثبيت جانبي فقط:

- شراء شهري لكل منصة، ثم التأكد أن السعر المعروض هو سعر المتجر وأن الخطة لا تفتح قبل التحقق.
- شراء معلّق في `Google Play` والتأكد من بقاء الخطة مغلقة حتى اكتماله.
- استعادة على جهاز آخر بالحساب نفسه.
- ترقية وخفض وتبديل دورة الفوترة، ومراجعة توقيت التطبيق النسبي في نافذة المتجر.
- إلغاء التجديد والتأكد أن الوصول يستمر حتى نهاية الفترة ثم يتوقف.
- حالة السماح المؤقت ومشكلة الدفع وانتهاء الصلاحية والاسترداد أو السحب.
- محاولة ربط الإيصال بمتجر أو حساب آخر والتأكد من رفضها.
- خمس عمليات خلفية/استئناف، وفتح بارد، واتصال ضعيف على `Android` و`iPhone` حقيقيين.

إشعارات الخادم الفورية من `App Store Server Notifications V2` و`Google Real-time Developer Notifications` تحسين لاحق مفيد لتحديث الواجهة فوراً. صلاحية الخادم الحالية لا تعتمد عليها: تاريخ نهاية الفترة مفروض في قاعدة البيانات، والتحقق يتجدد عند دخول المالك والاستعادة والشراء.
