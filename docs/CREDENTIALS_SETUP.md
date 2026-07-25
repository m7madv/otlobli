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

تحتاج مشروع **Firebase** (أندرويد مجاني) و — للآيفون — مفتاح **APNs** (يتطلّب حساب Apple Developer مدفوع).
ابدأ بأندرويد؛ الآيفون لاحقاً.

### أ) أندرويد (FCM) — مجاني

1. افتح <https://console.firebase.google.com> → **Add project** → سمِّه مثلاً `otlobli`.
2. داخل المشروع: **Add app → Android**. اسم الحزمة (package name) لازم يطابق التطبيق:
   افحصه في `android/app/build.gradle` (`applicationId`) أو `capacitor.config.*`.
3. نزّل ملف **`google-services.json`** وضعه في: `android/app/google-services.json`.
4. ثبّت الإضافة وأضِف مُلحق Gradle:
   ```bash
   npm install @capacitor/push-notifications
   ```
   - في `android/build.gradle` (المستوى الأعلى) ضِف ضمن `dependencies`:
     `classpath 'com.google.gms:google-services:4.4.2'`
   - في نهاية `android/app/build.gradle` ضِف سطراً:
     `apply plugin: 'com.google.gms.google-services'`
5. من إعدادات مشروع Firebase → **Service accounts** → **Generate new private key**.
   سينزّل ملف JSON. **هذا سرّي جداً — لا ترفعه إلى Git.**
6. ضع محتوى ذلك الـ JSON كاملاً في متغيّر بيئة دالة `send-push`:
   ```bash
   supabase secrets set FCM_SERVICE_ACCOUNT_JSON="$(cat ~/Downloads/otlobli-xxxx.json)" --project-ref dcicqdprtyhwmhegabay
   ```
7. فعّل التسجيل في التطبيق: في `.env` (وVercel) ضع `VITE_PUSH_ENABLED=true`، ثم أعد البناء والمزامنة:
   ```bash
   npm run build && npx cap sync android
   ```

### ب) آيفون (APNs) — يحتاج Apple Developer (مدفوع)

1. من <https://developer.apple.com/account> → **Keys** → أنشئ مفتاح **APNs** (نوع Apple Push Notifications service).
   نزّل ملف `.p8` وسجّل **Key ID** و**Team ID**.
2. في Firebase → إعدادات مشروع → **Cloud Messaging** → **Apple app configuration** → ارفع مفتاح APNs.
   (بهذا يرسل FCM للآيفون أيضاً، ولن تحتاج APNs مباشرة.)
   — أو بدل ذلك اضبط متغيّرات `send-push`: `APNS_KEY` (محتوى p8)، `APNS_KEY_ID`، `APNS_TEAM_ID`،
   `APNS_BUNDLE_ID`، `APNS_PRODUCTION=true`.
3. في Xcode: أضِف قدرة **Push Notifications** و**Background Modes → Remote notifications**.

### ج) تشغيل الربط بالطلبات

بعد ضبط FCM، فعّل استدعاء الإشعار من لوحة الإدارة عند تغيّر حالة الطلب:
```bash
# سرّ مشترك بين admin-orders و send-push (اختر قيمة عشوائية طويلة)
supabase secrets set PUSH_TRIGGER_SECRET="ضع-سرّاً-عشوائياً-طويلاً" --project-ref dcicqdprtyhwmhegabay
```
(الدالتان تقرآن نفس السرّ. بدونه لا يُرسَل أي Push — آمن.)

---

## 🔐 المهمة ٢: تسجيل الدخول عبر جوجل

تحتاج **Google OAuth Client IDs** من Google Cloud Console.

1. افتح <https://console.cloud.google.com> → أنشئ مشروعاً (أو استخدم مشروع Firebase نفسه).
2. **APIs & Services → OAuth consent screen** → اضبطه (External، اسم التطبيق، بريد الدعم).
3. **Credentials → Create credentials → OAuth client ID**، أنشئ ثلاثة:
   - **Web application** → انسخ **Client ID** (هذا الأهم — يستخدمه التطبيق والخادم).
   - **Android** → أدخل package name + بصمة **SHA‑1**:
     ```bash
     cd android && ./gradlew signingReport   # انسخ SHA1 من variant: debug (وrelease لاحقاً)
     ```
   - **iOS** → أدخل Bundle ID.
4. ثبّت إضافة جوجل واضبطها:
   ```bash
   npm install @codetrix-studio/capacitor-google-auth
   ```
   - أندرويد: في `android/app/src/main/res/values/strings.xml` أضِف:
     `<string name="server_client_id">WEB_CLIENT_ID_هنا</string>`
   - iOS: في `ios/App/App/Info.plist` أضِف `CFBundleURLTypes` مع **reversed client ID** لعميل iOS.
5. أخبر الخادم بالمعرّفات المسموح بها (Web + Android + iOS، مفصولة بفواصل):
   ```bash
   supabase secrets set GOOGLE_CLIENT_IDS="WEB_ID.apps.googleusercontent.com,ANDROID_ID.apps.googleusercontent.com,IOS_ID.apps.googleusercontent.com" --project-ref dcicqdprtyhwmhegabay
   ```
6. فعّل الزر في التطبيق: في `.env` (وVercel) ضع:
   ```
   VITE_GOOGLE_AUTH_ENABLED=true
   VITE_GOOGLE_WEB_CLIENT_ID=WEB_ID.apps.googleusercontent.com
   ```
   ثم `npm run build && npx cap sync`.

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
