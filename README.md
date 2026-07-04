# otlobli — دليل المشروع الكامل

تطبيق **otlobli**: يطلب الزبون السوري منتجات من **SHEIN / Temu**، وتُجمَّع في مركز
خارجي وتُشحن إلى سوريا عبر **القدموس**. الدفع عبر **شام كاش** (مطابقة تلقائية بالمبلغ).

هذا الملف يشرح كل جزء وأين يُنشر — نقطة البداية لأي شخص جديد.

---

## أجزاء المشروع

| المجلد | ما هو | التقنية | النشر / الرابط |
|--------|-------|---------|----------------|
| `src/` | **تطبيق الزبون** (iOS + ويب) | React + Vite + Capacitor | IPA غير موقّع عبر GitHub Actions ([`.github/workflows/ios-unsigned-build.yml`](.github/workflows/ios-unsigned-build.yml)) + ويب على `talabieh.vercel.app` |
| `admin/` | **لوحة الإدارة** | React + Vite | `talabieh-admin.vercel.app` |
| `driver/` | **بوابة السواق** (شركة الشحن) | React + Vite | Vercel (منفصل) |
| `server/` | خادم إشعارات واتساب/تيليجرام + سكرايبر SHEIN | Node.js | Railway |
| `supabase/` | قاعدة البيانات ([`schema.sql`](supabase/schema.sql)) + دوال Edge | Postgres + Deno | مشروع Supabase `talabieh` (ref `dcicqdprtyhwmhegabay`) |

---

## تطبيق الزبون (`src/`)
- منطق التقاط منتجات SHEIN/Temu المحقون: [`src/services/sheinBrowserScript.ts`](src/services/sheinBrowserScript.ts)
  (سكريبت ضخم كـtemplate literal — **كل backslash في regex يجب أن يكون مضاعفاً** `\\d`).
- الإعدادات: [`src/config.ts`](src/config.ts) — `APP_VERSION` (يُرفع مع كل تغيير)، `PAYMENT_MODE`.
- الشاشات والمنطق: [`src/App.tsx`](src/App.tsx).
- طبقة الـAPI: `src/services/appApi.ts` (الواجهة) + `supabaseAppApi.ts` (فعلي) + `localAppApi.ts` (محاكاة).
- **دورة التطوير**: عدّل → `npm run build` → ارفع `APP_VERSION` → commit+push إلى `main`
  → GitHub Actions يبني IPA → ثبّت واختبر على الآيفون.

## لوحة الإدارة (`admin/`)
- تبويبات: لوحة التحكم، الطلبات، المدفوعات، الشحن، العملاء، السواقين، **أكواد الخصم**، الإعدادات.
- مصادقة برمز `x-admin-pin`، تتصل بدوال Supabase Edge.
- **الإعدادات** (تبويب): تكلفة الشحن **لكل متجر** (SHEIN/Temu)، سعر الصرف، **نسبة الربح**.
- **أكواد الخصم** (تبويب): إنشاء/تفعيل/حذف (نسبة% أو مبلغ$، لكل متجر، استخدام واحد/هاتف+جهاز).
- **العملاء** (تبويب): بحث بالاسم/الرقم، إحصاءات، وطلبات كل عميل السابقة.
- البناء يحتاج `VITE_SUPABASE_URL` + `VITE_SUPABASE_ANON_KEY`.

## قاعدة البيانات ودوال Edge (`supabase/`)
- [`schema.sql`](supabase/schema.sql): كل الجداول + دوال RPC (idempotent — آمن إعادة تشغيله).
- الدوال (`supabase/functions/`): `admin-orders` · `admin-drivers` · `admin-coupons`
  · `app-settings` · `customer-profile` · `driver-orders` · `payment-webhook` · `telegram-notify`.
- إعدادات التشغيل في جدول `app_settings` (مفاتيح: `shipping_cost_shein_syp`,
  `shipping_cost_temu_syp`, `usd_to_syp_rate`, `profit_margin_percent`).
- نشر دالة: `supabase functions deploy <name> --project-ref dcicqdprtyhwmhegabay`.
- أكواد الخصم: راجع [`supabase/COUPONS_DEPLOY.md`](supabase/COUPONS_DEPLOY.md).

## بوابة السواق (`driver/`)
واجهة يستلم بها السواق طلباته المكلَّف بها (رمز دخول من لوحة الإدارة)، يفرزها ويشحنها.

## الخادم (`server/`)
Node على Railway: إرسال OTP واتساب، إشعارات تيليجرام للطلبات الجديدة، سكرايبر SHEIN.

---

## خارطة الميزات القادمة
راجع [`ROADMAP.md`](ROADMAP.md).
