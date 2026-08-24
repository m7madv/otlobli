# إعداد الدخول ودعوات الفريق

آخر تحديث: 2026-08-24

## الحالة الحية

- مشروع Supabase الإنتاجي: `exxayzlklvgeyqhvtzgi` في Mumbai `ap-south-1`، مع migrations الأربع ودالة `verify-store-purchase` منشورة.
- Email auth معطل ورابط العودة `com.damanak.damanak://login-callback` مسموح.
- إعدادا Supabase العامان موجودان في GitHub Secrets.
- Google Cloud Project `Damanak Production` (`damanak-production`، الرقم `521030062021`) مكتمل، وعميل Web مربوط برد Supabase، ومزود Google مفعّل ومختبر حتى صفحة حساب Google.
- Apple App ID هو `com.damanak.damanak`، وServices ID هو `com.damanak.damanak.signin`. مفتاح Apple محفوظ خارج Git ومزود Apple مفعّل ومختبر حتى صفحة Apple.
- ملف التوزيع الحالي `Damanak App Store 2026` يتضمن `Sign in with Apple`، ومصدر iOS يعلن الاستحقاق نفسه في `Runner.entitlements`.

## القرار المعتمد

- تسجيل الدخول وإنشاء الحساب متاحان عبر `Apple` و`Google` فقط.
- لا تعرض الواجهة بريداً أو كلمة مرور أو استعادة كلمة مرور.
- كل موظف يستخدم حسابه الشخصي؛ لا يشارك جلسة المالك أو كلمة مروره.
- دعوة الفريق لشخص واحد وصالحة 48 ساعة. يحدد المالك أو المدير الصلاحية، ثم يرسل رابطاً أو رمز `QR`. يبقى الرمز النصي بديلاً إذا لم يفتح الرابط.
- بعد فتح الدعوة، يحتفظ التطبيق بها أثناء تسجيل الدخول ويجهز نموذج الانضمام تلقائياً.

## إعداد Supabase

المشروع المستقل موجود فعلياً. عند نشر تغيير قاعدة بيانات جديد، طبّق الهجرة ودالة `verify-store-purchase` على `exxayzlklvgeyqhvtzgi` فقط كما هو موثق في `STORE_BILLING_SETUP.md`.

في `Authentication → URL Configuration` أضف رابط العودة:

```text
com.damanak.damanak://login-callback
```

في إعدادات البريد عطّل التسجيل بالبريد وكلمة المرور. يجب أن يبقى `Apple` و`Google` فقط مفعّلين في الإنتاج.

## إعداد Google

1. أنشئ مشروع `Google Cloud` خاصاً بضمانك.
2. جهّز شاشة الموافقة باسم ضمانك وروابط الخصوصية والشروط.
3. عميل `OAuth Web` الحالي يستخدم رابط Supabase التالي في `Authorized redirect URIs`:

```text
https://exxayzlklvgeyqhvtzgi.supabase.co/auth/v1/callback
```

4. فعّل مزود `Google` في Supabase وأدخل `Client ID` و`Client secret`.
5. لا تطلب نطاقات إضافية؛ يحتاج ضمانك إلى الهوية الأساسية والبريد فقط.

## إعداد Apple

1. أنشئ `Services ID` لتسجيل ضمانك واربطه بـApp ID ذي المعرّف `com.damanak.damanak`.
2. أضف نطاق Supabase ورابط العودة:

```text
https://exxayzlklvgeyqhvtzgi.supabase.co/auth/v1/callback
```

3. أنشئ مفتاح `Sign in with Apple` واحفظ ملف `.p8` خارج Git.
4. فعّل مزود `Apple` في Supabase وأدخل `Services ID` و`Team ID` و`Key ID` والمفتاح.
5. سر Apple الحالي مدته ستة أشهر من 2026-08-24؛ دوّره قبل 2027-02-20. يبقى تسجيل Apple الحقيقي على جهاز وSandbox ضمن اختبار القبول.

## أسرار بناء GitHub

يجب أن تفشل نسخ المتاجر إذا غابت إعدادات الخادم. أضف:

```text
DAMANAK_SUPABASE_URL
DAMANAK_SUPABASE_PUBLISHABLE_KEY
```

يستخدم iOS هذه القيم في `.github/workflows/damanak-ios-signed.yml`، ويستخدم Android القيم نفسها في `.github/workflows/damanak-android-release.yml`.

يتطلب Android أيضاً أسرار مفتاح ضمانك المستقل:

```text
DAMANAK_ANDROID_UPLOAD_KEYSTORE_BASE64
DAMANAK_ANDROID_UPLOAD_KEY_PASSWORD
DAMANAK_ANDROID_UPLOAD_KEY_ALIAS
```

ولا تستخدم أسرار توقيع Otlobli لتطبيق ضمانك.

مفتاح رفع Android الإنتاجي الحالي محفوظ محلياً فقط في:

```text
C:\Users\MOHAMMAD\.damanak\android\damanak-upload-v2.p12
```

كلمة مروره مخزنة بترميز Windows DPAPI، وشهادة الرفع SHA-256 هي `BF:0B:37:36:99:91:1F:DA:B8:BD:46:DE:90:66:4D:09:15:CE:D3:5E:2E:D0:46:A6:AD:4E:4B:03:0F:81:45:74`. لم يُرفع هذا المفتاح إلى GitHub.

## اختبار القبول

نفّذ الحالات التالية على iPhone وAndroid حقيقيين:

1. مالك جديد يدخل عبر Apple وينشئ متجراً.
2. مالك جديد يدخل عبر Google وينشئ متجراً.
3. المدير ينشئ دعوة موظف ويرسلها عبر واتساب.
4. الموظف يفتح الرابط، يدخل عبر مزود مختلف عن المالك، ويرى الرمز والصلاحية جاهزين ثم يؤكد الانضمام.
5. محاولة استخدام الدعوة مرة ثانية تفشل برسالة واضحة.
6. دعوة منتهية أو مشوهة لا تنضم إلى أي متجر.
7. إيقاف الموظف يقطع وصوله، من دون التأثير في حسابات بقية الفريق.
8. حذف الحساب يبقى متاحاً من شاشة الحساب، مع توضيح أثر الاشتراك للمالك.

لا يُعد نجاح التحليل أو المحاكي بديلاً عن تسجيل دخول حقيقي من المزودين على الجهازين.
