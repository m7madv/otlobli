# ملخّص الجلسة — otlobli (2026-07-26)

> انسخ هذا الملف كاملاً في بداية أي شات جديد لمتابعة العمل.

## الفرع والوصول
- **الفرع الفعّال:** `claude/otlobli-v86-push-google-telegram` (مبني على `claude/ios6-cover-fix`). آخر نسخة: **v86**.
  ⚠️ الـ harness قد يبدأ على فرع قديم جداً (رأينا v36) — تأكّد من الفرع + `APP_VERSION` في `src/config.ts` أولاً.
- **Supabase CLI مربوط** → طبّق تغييرات القاعدة والدوال بنفسك:
  `supabase db query --linked -f file.sql` / `supabase functions deploy <fn> --project-ref dcicqdprtyhwmhegabay [--no-verify-jwt]`.
  ⚠️ `schema.sql` غير مطابق للسيرفر الحيّ — افحص الحيّ عبر `supabase db query --linked`، لا الملف.
  ⚠️ عند إعادة نشر دالة قائمة، **حافظ على `verify_jwt` نفسه** (افحصه بـ `supabase functions list`). `admin-orders` = true.
- **Vercel CLI مسجّل دخول** → واجهة الإدارة: `cd admin && vercel --prod --yes` (مشروع `talabieh-admin`).
- النوت 8 على USB عبر `adb` (serial `988e16384e4f51395230`). بناء iOS: `gh workflow run ios-unsigned-build.yml --ref <branch> --repo m7madv/otlobli`.
- علم `src/config.ts`: `TEST_ONLY_AUTH_BYPASS = true` (يجب false قبل الإنتاج؛ يتخطّى شاشة OTP ويبدأ على home).

## ما أُنجز هذه الجلسة (v86) — الطلبات الثلاثة
> فلسفة التنفيذ: كل شي **إضافي وخامل وآمن**. التطبيق والخوادم تعمل طبيعياً؛ الميزات مخفية خلف أعلام/أسرار
> حتى يُدخل المستخدم مفاتيحه الشخصية. **الدليل الكامل خطوة بخطوة: `docs/CREDENTIALS_SETUP.md`.**

1. **تسجيل الدخول عبر جوجل + ربط الحساب** — مرتكز على الهاتف (ضروري للتوصيل).
   - قاعدة البيانات (مطبّقة حيّة): جدول `customer_identities` + دوال `find_identity_customer`,
     `link_customer_identity`, `touch_identity_login`, `create_customer_session_for_customer`.
   - دالة حافة `google-auth` (منشورة، `verify_jwt=false`): تتحقق من رمز جوجل عبر tokeninfo،
     تبحث/تربط الهوية، تصدر جلسة متوافقة مع نظام `customer_sessions` الحالي. **تفشل مغلقة** حتى يُضبط `GOOGLE_CLIENT_IDS`.
   - الواجهة: `src/services/googleAuthApi.ts` + زر "المتابعة عبر جوجل" في شاشة الدخول (`src/App.tsx`) +
     ربط بعد OTP في كل مسارات النجاح. خلف علمَي `VITE_GOOGLE_AUTH_ENABLED` + `VITE_GOOGLE_WEB_CLIENT_ID`.
   - **مُختبَر بصرياً**: الزر يظهر ويفشل بلطف (الإضافة غير مثبّتة) بلا أي خطأ console.
   - **يحتاج منك:** Google OAuth Client IDs (Web+Android+iOS) + تثبيت `@codetrix-studio/capacitor-google-auth`.

2. **إشعارات Push (أندرويد FCM + آيفون APNs)**.
   - قاعدة البيانات (مطبّقة حيّة): جدول `device_tokens` + دوال `upsert_device_token`, `disable_device_token`.
   - دالة حافة `send-push` (منشورة، `verify_jwt=false`): FCM HTTP v1 (JWT حساب خدمة) + APNs (p8/ES256).
     محميّة بـ `x-push-secret`/`x-admin-pin`. **خاملة** (sent=0) حتى تُضبط مفاتيح FCM/APNs.
   - الربط: `admin-orders` يستدعي `send-push` بالتوازي مع واتساب عند تغيّر حالة الطلب (fire-and-forget، خامل بلا `PUSH_TRIGGER_SECRET`).
     **سلوك واتساب لم يتغيّر.**
   - الواجهة: `src/services/pushNotifications.ts` يسجّل الجهاز عند وجود جلسة (خلف `VITE_PUSH_ENABLED`، native فقط).
   - **يحتاج منك:** مشروع Firebase (`google-services.json` + service account) و — للآيفون — Apple Developer/APNs.

3. **تنبيه تيليغرام عند حظر رقم واتساب** — **الكود جاهز بالكامل** في `server/src/whatsapp.js`
   (`alertAdmin` عند `loggedOut` وعند ارتفاع خطر الرقم). ينقصه فقط تشغيل أحدث كود على Oracle:
   `cd ~/otlobli && git pull && cd server && npm install && pm2 restart talabieh-whatsapp`.
   يستخدم `TELEGRAM_ALERT_CHAT_ID` أو يرجع لـ`TELEGRAM_CHAT_ID` الموجود — غالباً يعمل فور النشر بلا مفتاح جديد.

## الاستيراد الديناميكي المحروس (مهم للفهم)
`googleAuthApi.ts` و`pushNotifications.ts` يستوردان إضافات Capacitor عبر
`import(/* @vite-ignore */ pkg)` باسم حزمة في متغيّر — حتى يمرّ بناء الويب **دون تثبيت الإضافات**.
لا تحوّلها إلى `import` ثابت وإلا يكسر البناء قبل تثبيت الإضافات. البناء الحالي: `npm run build` ✅ ناجح.

## فخاخ مهمة (لا تقع فيها)
- **سيرفران واتساب:** `server/` هو الفعّال (Oracle، متعدّد أرقام). `server-whatsapp/` نسخة ميتة — لا تعدّلها.
- منطق الدفع/المحفظة/anti-ban حسّاس — عدّل أقل مساحة وبعد فهم النسخة الحيّة.
- `verify_jwt` لكل دالة حافة يجب أن يُحفظ عند إعادة النشر.

## المطلوب التالي / المتبقّي
- المستخدم يُدخل المفاتيح الثلاثة حسب `docs/CREDENTIALS_SETUP.md` لتفعيل الميزات.
- (أمان متوسط) تحصين دوال السلة المشتركة بجلسات.
- قبل الإنتاج: `TEST_ONLY_AUTH_BYPASS = false`.
