# تفعيل ميزات v86 — دليل المفاتيح خطوة بخطوة

> كل الكود جاهز ومنشور. هذا الملف يشرح المفاتيح الثلاثة التي **لا يستطيع Claude إنشاءها**
> لأنها تتطلّب حساباتك الشخصية (Firebase / Apple / Google). بعد إدخالها، الميزات تعمل فوراً.
>
> **الوضع الآن:** الميزات كلها **خاملة وآمنة** — التطبيق والخوادم تعمل بشكل طبيعي تماماً،
> وزر جوجل مخفي، والإشعارات لا تُسجَّل، حتى تُكمل الخطوات أدناه.

---

## ✅ ما أُنجز تلقائياً (منشور وحيّ)

| الطبقة | الحالة |
|--------|--------|
| جداول قاعدة البيانات (`customer_identities`, `device_tokens`) + ٦ دوال | ✅ مطبّقة على الإنتاج |
| دالة `google-auth` (تحقّق + ربط + إصدار جلسة) | ✅ منشورة (تفشل مغلقة حتى تُضبط المعرّفات) |
| دالة `send-push` (FCM + APNs) | ✅ منشورة (خاملة حتى تُضبط المفاتيح) |
| ربط إشعار الطلب بتغيّر الحالة (`admin-orders`) | ✅ منشور (خامل حتى يُضبط السرّ) |
| واجهة زر جوجل + تسجيل الإشعارات | ✅ في الكود (خلف أعلام بيئة، البناء ناجح) |
| تنبيه تيليغرام عند حظر رقم واتساب | ✅ في كود السيرفر (يحتاج نشر Oracle فقط) |

---

## 🔔 المهمة ١: إشعارات Push

### أ) أندرويد (FCM) — ✅ **تمّ إعداده بالكامل والتحقق منه**

أُنجز تلقائياً في الجلسة:
- مشروع Firebase **`otlobli-1ccf5`** (Spark plan المجاني) + تطبيق أندرويد `com.otlobli.app`.
- `android/app/google-services.json` مضاف للمستودع.
- `@capacitor/push-notifications@8.1.2` مثبّت ومسجّل في gradle.
- مفتاح حساب الخدمة مضبوط كسرّ `FCM_SERVICE_ACCOUNT_JSON` + `PUSH_TRIGGER_SECRET` في Supabase.
- **تحقّق فعلي:** أرسلنا اختباراً فقبِلت Google الرسالة (رفضت رمزاً وهمياً كما هو متوقّع) → FCM يعمل.

**يتبقّى خطوة واحدة فقط: بناء APK بالعلم مفعّلاً وتركيبه.** في المستودع الرئيسي
(`C:\Users\MOHAMMAD\Projects\SHEIN IN SIRYA`، وليس الـ worktree — البناء يفشل في مسار به مسافات عميقة):
```bash
# اجلب فرع v86 أولاً، ثم:
# أنشئ .env يحوي قيم الإنتاج + السطر التالي (أو أضِفه في بيئة البناء):
#   VITE_PUSH_ENABLED=true
npm run build && npx cap sync android
cd android && ./gradlew assembleDebug
# ثم ركّبه على الجهاز:
adb install -r app/build/outputs/apk/debug/app-debug.apk
```
بمجرّد تشغيل النسخة الجديدة وتسجيل الدخول، يسجّل الجهاز رمزه تلقائياً، وتصله الإشعارات
(من تبويب "الإشعارات" بلوحة الإدارة، ومن تغيّر حالة الطلب تلقائياً).

> ملاحظة: مفتاح حساب الخدمة السرّي حُذف من مجلد التنزيلات بعد تخزينه (يمكن إعادة توليده من
> Firebase → Project settings → Service accounts وقت الحاجة). ملف `google-services.json` غير سرّي.

### ب) آيفون (APNs) — ✅ مضبوط إنتاجياً

> حالة الإنتاج في 2026-08-24: المفتاح المخصص `4GGVNXQ9UT` مفعّل لـ
> `com.otlobli.app`، والأسرار الأربعة موجودة في Supabase. تم التحقق مباشرة
> من قبول Apple للمفتاح/Team/Topic عبر بوابة APNs الإنتاجية. يبقى فقط
> اختبار التسليم على الآيفون الحقيقي.

- ✅ أنشئ مفتاح Apple Push Notifications service المخصص واحتُفظ بملف `.p8` خارج المشروع.
- ✅ ضُبط المسار المباشر المستخدم حالياً في `send-push`: `APNS_KEY`،
  `APNS_KEY_ID`، `APNS_TEAM_ID=36D743K87T`، و`APNS_BUNDLE_ID=com.otlobli.app`.
- ✅ قدرة Push Notifications وملف entitlements موجودان في مشروع iOS، ونسخة TestFlight الحالية سجلت رمز APNs إنتاجياً.
- ⏳ المتبقي: إرسال اختبار موجّه لهاتف المالك والتحقق من الظهور ومسار الضغط.

### ج) الربط بالطلبات — ✅ مضبوط

`PUSH_TRIGGER_SECRET` مضبوط في Supabase ومشترك بين `admin-orders` و`send-push`.
لذلك عند تغيّر حالة أي طلب من لوحة الإدارة، يُرسَل إشعار Push للعميل تلقائياً (بالتوازي مع واتساب).
كما يمكنك الإرسال اليدوي من تبويب **"الإشعارات"** بلوحة الإدارة (للكل أو لعميل واحد).

---

## 🔐 المهمة ٢: تسجيل الدخول عبر جوجل — ✅ **تمّ إعداده بالكامل (أندرويد)**

أُنجز تلقائياً في الجلسة (على Chrome + الخوادم):
- في Firebase `otlobli-1ccf5`: فُعّل مزوّد **Google** (باسم عام "otlobli" وبريد دعمك)،
  وسُجّلت **بصمة SHA-1** لمفتاح التطوير → أنشأ Google عملاء OAuth تلقائياً.
- **Web Client ID:** `677396296147-o5q0rt5qk2rq0rqh714kuki7gabkdmcu.apps.googleusercontent.com`
- **Android Client ID:** `677396296147-5iqi089o84ra4bu2unofkbjfqeee3mev.apps.googleusercontent.com`
- سرّ الخادم **`GOOGLE_CLIENT_IDS`** مضبوط (Web+Android). تحقّق: `google-auth` ترجع `401 invalid_google_token`.
- الإضافة **`@capgo/capacitor-social-login@8.3.38`** مثبّتة (تدعم Capacitor 8) وواجهة `googleAuthApi.ts` محدّثة.
- `.env.example` يحوي `VITE_GOOGLE_AUTH_ENABLED=true` + Web Client ID.
- `google-services.json` محدّث بعملاء OAuth.

**يتبقّى:** بناء APK بالعلم مفعّلاً وتركيبه (نفس خطوة الإشعارات). عند التشغيل، زر
"المتابعة عبر جوجل" يظهر ويعمل.

> ⚠️ **مهم لاحقاً (الإنتاج):** بصمة SHA-1 المسجّلة هي لمفتاح **التطوير** (debug). قبل توزيع نسخة
> موقّعة بمفتاح release، سجّل بصمة SHA-1 الخاصة بمفتاح release أيضاً في Firebase (نفس المكان)،
> وإلا يفشل دخول جوجل على النسخة الموزّعة برسالة خطأ 10.
> **iOS:** يحتاج عميل OAuth آيفون + Info.plist (مؤجَّل مع Apple Developer).

### كيف يعمل الربط (القرار المتّخذ تلقائياً)

- المرتكز يبقى **رقم الهاتف** (ضروري للتوصيل أصلاً).
- أول دخول بجوجل لمستخدم جديد → يوثّق هاتفه مرة واحدة عبر OTP، فتُربط هوية جوجل بحسابه.
- بعدها: زر جوجل يدخله فوراً بلا OTP.
- مستخدم مسجّل بالهاتف يقدر يربط جوجل لاحقاً (نفس المسار).
- الحماية: هوية جوجل لا يمكن أن تُربط بحسابين (تُرفض بـ "مرتبط بحساب آخر").

---

## 📨 المهمة ٣: تنبيه تيليغرام عند حظر رقم واتساب

**الكود جاهز بالكامل** في `server/src/whatsapp.js` (تنبيه فوري عند حظر/خروج رقم، وعند ارتفاع خطره).
ينقصه فقط تشغيل أحدث كود السيرفر على Oracle:

```bash
# على خادم Oracle (SSH)
cd ~/otlobli && git pull && cd server && npm install && pm2 restart talabieh-whatsapp
```

المتغيّرات المطلوبة في `server/.env` على Oracle:
- `TELEGRAM_BOT_TOKEN` — غالباً مضبوط أصلاً (نفس بوت إشعارات الطلبات الجديدة).
- `TELEGRAM_ALERT_CHAT_ID` — **اختياري**؛ إن غاب يستخدم `TELEGRAM_CHAT_ID` الموجود.
  اضبطه فقط لو أردت وصول تنبيهات الحظر إلى محادثة/مجموعة مختلفة عن إشعارات الطلبات.

> إذا كانت إشعارات الطلبات على تيليغرام تعمل أصلاً، فتنبيهات الحظر ستعمل فوراً بمجرد `git pull` + `pm2 restart`،
> دون أي مفتاح جديد.

### إنشاء بوت تيليغرام (فقط إن لم يكن لديك واحد)

1. في تيليغرام راسل **@BotFather** → `/newbot` → احصل على **TOKEN**.
2. راسل بوتك برسالة، ثم افتح
   `https://api.telegram.org/bot<TOKEN>/getUpdates` وانسخ `chat.id` → هذا `TELEGRAM_CHAT_ID`.

---

## فحص سريع بعد التفعيل

```bash
# جوجل: يجب أن يرجع 401 invalid_google_token (بدل 503) بعد ضبط GOOGLE_CLIENT_IDS
curl -s -X POST https://dcicqdprtyhwmhegabay.supabase.co/functions/v1/google-auth \
  -H 'content-type: application/json' -d '{"idToken":"x"}'

# Push: يجب أن يرجع sent=0 reason=no_devices (بدل unauthorized) عند تمرير السرّ الصحيح
curl -s -X POST https://dcicqdprtyhwmhegabay.supabase.co/functions/v1/send-push \
  -H 'content-type: application/json' -H 'x-push-secret: نفس-قيمة-PUSH_TRIGGER_SECRET' \
  -d '{"phone":"963900000000","title":"t","body":"b"}'
```
