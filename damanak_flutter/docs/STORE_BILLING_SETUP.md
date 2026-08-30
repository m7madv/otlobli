# إعداد فوترة ضمانك عبر المتاجر

الإصدار الاختباري الحالي: `4.3.1+19` — معرّف التطبيق: `com.damanak.damanak`

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

اكتملت الترجمة العربية، والتوافر في دول الخليج الست، وصور المراجعة، واتفاقية التطبيقات المدفوعة والحساب البنكي والضرائب وDSA. أسعار واجهة قطر الحالية هي: بداية `39.99/399.99 QAR`، نمو `79.99/799.99 QAR`، وتوسع `199.99/1999.99 QAR`.

منذ App Store Connect API `4.4.1` أصبحت بيانات المجموعة والمنتج مرجعية عبر `subscriptionGroupVersions` و`subscriptionVersions` وترجماتها، لا من حقل الحالة القديم على أصل المنتج. الفحص [33074176969](https://github.com/m7madv/otlobli/actions/runs/33074176969) يؤكد `catalogMetadataReady=true` للمنتجات `6/6`، ومجموعة بحالة `READY_FOR_REVIEW`، وستة إصدارات منتج بحالة `PREPARE_FOR_SUBMISSION` وترجمات عربية مطابقة. يعيد أصل كل منتج القديم `MISSING_METADATA`، لكنه ليس الحالة المرجعية بعد الانتقال إلى نموذج الإصدارات.

التوفر مضبوط كخطط `UPFRONT` في `SA/AE/BH/KW/OM/QA` فقط، و`planAvailabilityReady=true` للمنتجات `6/6`. كل أسعار قطر فورية (`startDate=null`) وموجودة في التقرير. أول اشتراك عام يجب إرفاقه بإصدار تطبيق عند الإرسال إلى مراجعة Apple، لكن لا يلزم إرسال التطبيق عاماً حتى يعمل كتالوج Sandbox/TestFlight. رفضت Apple محاولة ربط إصدارات المنتجات بمسودة المجموعة بـ`STATE_ERROR.ENTITY_STATE_INVALID`، وأضافت المحاولة `0` عناصر ولم تُرسل شيئاً للمراجعة.

Build `17` أعاد `storekit_no_response` على الجهاز بسبب اجتماع إعداد توفر قديم مع مسار كتالوج ينهي العملية عند أول نتيجة ناقصة. Build `18` يجمع النتائج الجزئية تحت مهلة كلية، ويستخدم StoreKit 2 ثم StoreKit 1 ثم الطلبات المجمعة، ويضيف مهل شراء واستعادة. رفعه التشغيل [33071848783](https://github.com/m7madv/otlobli/actions/runs/33071848783) وأصبح `VALID` داخل مجموعة `Damanak Internal`. IPA المحلية في `output/github-run-33071848783/ضمانك.ipa`، حجمها `23,303,261` وبصمتها SHA-256 `E697D870320F768458DF626C06F3EB6545A4488D6D1CD851B13CB7D5C0AED4E8`. لا يُعتبر ذلك بديلاً عن اختبار ظهور الأسعار والاستعادة على iPhone حقيقي يحمل Build `18`.

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

الأسعار التي أعادها مسار الاختبار الداخلي قبل Build `18` كانت `33/330` و`84/835` و`170/1700 QAR`. الهدف الموحد في سكربت الإعداد هو: بداية `39.99/399.99 QAR`، نمو `79.99/799.99 QAR`، وتوسع `199.99/1999.99 QAR`. لا يوجد عرض تمهيدي مطلوب؛ التطبيق يختار العرض الأساسي المباشر الذي لا يحمل `offerId`. محاولة `activate` الأخيرة أعادت `The caller does not have permission`، لذلك لم تتغير الأسعار القديمة ولا يجوز وصف الأسعار الجديدة بأنها مفعلة على Google.

حساب الخدمة `damanak-play-verifier@damanak-production.iam.gserviceaccount.com` نشط داخل Play Console بأذونات التطبيق المحدودة. فُعّلت `Google Play Android Developer API`، وحُفظ كائن الحساب في Supabase وGitHub كسِر:

```text
GOOGLE_PLAY_SERVICE_ACCOUNT_JSON
```

المفتاح العامل هو `426377cca3335db2db9a17611153fb1b37e92a1d`. المفتاح الأول `d86a3e51984e7ba7b942f00595a37c268b367316` لم يصل ملفه إلى القرص وبقي مسجلاً عند آخر فحص؛ احذفه من Google Cloud بعد تأكيد المالك، ولا تستخدمه أو تعتبره نسخة احتياطية.

سكربت `scripts/google_play_setup.mjs` يدعم:

```bash
node scripts/google_play_setup.mjs
node scripts/google_play_setup.mjs --apply
node scripts/google_play_setup.mjs --activate
```

الفحص للقراءة فقط. `--apply` ينشئ المنتجات والخطط المسعرة لدول `SA/AE/BH/KW/OM/QA` كمسودات ويحدّث الوصف العربي، و`--activate` ينشئ الناقص ثم يفعّل الخطط الأساسية. التشغيل [33071309057](https://github.com/m7madv/otlobli/actions/runs/33071309057) نشر Build `18` إلى مسار الاختبار الداخلي. AAB المحلية في `output/github-run-33071309057/app/outputs/bundle/release/app-release.aab`، حجمها `56,313,036` وبصمتها SHA-256 `8FDC30EE19EE850649171E90A619BF40ACEC2D9E028B32D296A48D71607A7E08`. جهاز Note 8 كان ما يزال على نسخة Play `16` عند آخر فحص؛ يجب تحديثه من Play إلى Build `18`، لأن التثبيت الجانبي لا يكفي لاختبار `Google Play Billing`.

## نشر قاعدة البيانات ودالة التحقق

مشروع Supabase المستقل لضمانك مرتبط بالمرجع `exxayzlklvgeyqhvtzgi`. نُشرت جميع migrations حتى `20260827150000` بتاريخ 27 أغسطس 2026، كما أن دوال `verify-store-purchase` و`legal` و`warranty-card` نشطة. لإعادة النشر في بيئة أخرى:

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
