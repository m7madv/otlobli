# CLAUDE.md

تعليمات خاصة بـ Claude Code عند العمل على هذا المشروع.

## اقرأ هذا أولاً

قبل أي تعديل:

1. اقرأ `AGENTS.md`.
2. اقرأ `CURRENT_STATE.md`.
3. اقرأ `AI-HANDOFF.md`.
4. شغّل:
   - `git status --short`
   - `git rev-parse --abbrev-ref HEAD`
   - `git log -5 --oneline`

لا تبدأ من `main`، ولا تستخدم ملخصات قديمة كمصدر حقيقة.

## تحذير سبب مشاكل سابقة

المشروع مرّ على أكثر من AI وأكثر من فرع. المشكلة التي تكررت:

- AI يقرأ ملف قديم.
- يظن أن admin/coupons/wallet/group-orders غير موجودة.
- يرجع كود أو UI من نسخة أقدم.
- النتيجة: ميزات مكتملة تختفي أو ترجع بسلوك قديم.

لذلك: لا تستبدل ملفات كاملة من branch قديم. قارن، ثم عدّل أقل مساحة ممكنة.

## أوامر شائعة

Frontend:

```bash
npm run build
npm run dev
npm run preview
```

Android:

```bash
npm run build
npx cap sync android
cd android
./gradlew assembleDebug
```

APK:

```text
android/app/build/outputs/apk/debug/app-debug.apk
```

iOS unsigned build:

```bash
gh workflow run ios-unsigned-build.yml --ref codex/customer-wallet-group-orders
```

## خريطة الملفات الحالية

- تطبيق الزبون: `src/App.tsx`
- سكربت SHEIN/Temu داخل WebView: `src/services/sheinBrowserScript.ts`
- API التطبيق: `src/services/supabaseAppApi.ts`, `src/services/appApi.ts`
- localStorage/session/device ids: `src/infrastructure/localStorage.ts`
- لوحة الإدارة: `admin/src/AdminApp.tsx`
- تنسيقات الإدارة: `admin/src/styles.css`
- قاعدة البيانات: `supabase/schema.sql`
- دوال الإدارة: `supabase/functions/admin-orders`, `admin-coupons`, `admin-drivers`, `app-settings`
- السلة المشتركة: `supabase/functions/cart-groups`

## SHEIN الحالي

- SHEIN يجب أن يفتح على `https://m.shein.com/ar/`.
- الدولة المطلوبة: السعودية.
- العملة المطلوبة: USD.
- اللغة المطلوبة: Arabic.
- `site_uid` على mobile SHEIN يجب أن يبقى `pwar`.
- لا تعمل spoof مخصص لـ User-Agent؛ استخدم فقط `Accept-Language: ar-SA`.
- لا تفحص أسماء الدول داخل وصف/عنوان المنتج لتقرر أن البلد خطأ. افحص فقط عبارات الشحن/التوصيل.
- لا تكتب broadly على كل storage key يحتوي `country/currency/lang` لأن هذا يسبب skeleton loading.
- إذا ظهر تحقق "أنا إنسان"، لا تحاول تجاوزه. فقط اجعل الصفحة قابلة للنقر ولا تحجبها.

## Temu والشريط السفلي

- شريط otlobli السفلي داخل WebView حساس جداً.
- لا تغيّر `z-index`, `position: fixed`, `safe bottom margin`, أو `__resize` بدون اختبار Android/iOS.
- لا تحجب البحث في Temu.
- احجب فقط عناصر الحساب/السلة/تسجيل الدخول الخاصة بTemu عندما تكون مؤكدة، ولا تحجب محتوى المنتجات.

## الدفع والمحفظة

لا تغيّر منطق الدفع أو المحفظة إلا إذا طلب المستخدم ذلك صراحة.

المسارات الحساسة:

- ShamCash payment verification
- wallet top-up
- order issue payment request
- coupon redemption
- group order checkout

## بروتوكول التسليم

بعد كل تغيير مهم:

1. حدّث `CURRENT_STATE.md`.
2. حدّث `AI-HANDOFF.md`.
3. حدّث `SESSION_SUMMARY.md` بملخص قابل للنسخ لشات جديد.

إذا اقتربت من نهاية الجلسة أو خفت من نفاد الفاتورة/السياق، اجعل آخر رد هو ملخص شات واضح.

ملاحظة: Claude/Codex قد لا يعرفان الفاتورة فعلياً. لا تدّعي معرفة وقت نفادها، لكن تصرف بحذر واكتب ملخصات متكررة.

