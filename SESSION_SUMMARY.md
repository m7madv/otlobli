# ملخّص الجلسة — otlobli (2026-07-25)

> انسخ هذا الملف كاملاً في بداية أي شات جديد لمتابعة العمل.

## الفرع والوصول
- **الفرع الفعّال:** `claude/ios6-cover-fix` (وليس main). كل العمل هنا. آخر نسخة: **v85.8.92**.
- **Supabase CLI مربوط ومسجّل دخول** → أطبّق تغييرات قاعدة البيانات بنفسي:
  `supabase db query --linked -f file.sql` / `supabase functions deploy <fn> --project-ref dcicqdprtyhwmhegabay [--no-verify-jwt]`.
  ⚠️ **`schema.sql` غير مطابق للسيرفر الحيّ** — افحص الحيّ دائماً عبر `supabase db query --linked`، لا الملف.
- **Vercel CLI مسجّل دخول** (`mhm1981x-4333`) → واجهة الإدارة: `cd admin && vercel --prod --yes` (مشروع `talabieh-admin`).
- **النوت 8 (SM-N950F) على USB** عبر `adb` (`C:/Users/MOHAMMAD/AppData/Local/Android/Sdk/platform-tools/adb.exe`, serial `988e16384e4f51395230`). التطبيق debuggable → قراءة إعداداته عبر `run-as` (مع `export MSYS_NO_PATHCONV=1`).
- بناء iOS: `gh workflow run ios-unsigned-build.yml --ref claude/ios6-cover-fix --repo m7madv/otlobli`. بناء Android: `npm run build && npx cap sync android && cd android && ./gradlew assembleDebug`.
- علم `src/config.ts` (يجب false قبل الإنتاج): `TEST_ONLY_AUTH_BYPASS = true`.

## ما أُنجز هذه الجلسة (كله حيّ ومُختبَر)
1. **تجمّد SHEIN على آيفون 16 — محلول (v85.8.91/92).** السبب: iOS 27 لا يعيد إرفاق طبقة رسم WKWebView عند الرجوع من الخلفية. الإصلاح native بالباتش: `otlobliForceRecompose` يفصل ويعيد إرفاق الـWebView على `appDidBecomeActive` + حماية Android عبر `handleOnResume`. الأساس أُعيد إلى v85.8.77 النظيفة (المستخدم أكّد الرقم).
2. **عطل المطابقة التلقائية للدفع — محلول.** النوت 8 كان يشغّل مستمع v1.0 قديم بلا توقيع HMAC فالـwebhook يرفضه 401. ثُبِّت v2.0.0 عبر adb + دُوِّر السرّ (`PAYMENT_WEBHOOK_SECRET`) عبر CLI ليتطابق الطرفان. مُختبَر: طلب موقّع رجع 200.
3. **أمان:** سُحبت `anon` عن `get_customer_account(text)` و`get_wallet(text)` القديمتين (كانتا تسرّبان حساب/رصيد أي زبون بالهاتف).
4. **حد الكوبون لكل مستخدم قابل للضبط** — `coupons.per_user_max_uses` + عدّاد `coupon_redemptions.uses`، مفروض ذرّياً (`ON CONFLICT DO UPDATE ... WHERE uses<cap`) مع بقاء الفهارس الفريدة. حقل بلوحة الإدارة. مُختبَر.
5. **نافذة دفع الطلب 5 دقائق** (قابلة للضبط عبر `order_payment_window_minutes`) في `create_pending_order`.
6. **زر "لقد دفعت":** يسجّل ضغطة الزبون (`claim_order_payment`) لتظهر بلوحة الإدارة، ويتعطّل بعد انتهاء المهلة ويظهر "راسلنا". (يحتاج نسخة الموبايل الجديدة للوصول للأجهزة.)
7. **واتساب anti-ban (على `server/` الفعّال):** تحقق onWhatsApp قبل الإرسال + إحماء تدريجي + سقف يومي لكل رقم + نقاط خطر/إيقاف تلقائي + معالجة 429/463/403 + تنبيه تيليغرام. **النشر على Oracle:** `cd ~/otlobli && git pull && cd server && npm install && pm2 restart talabieh-whatsapp`.

## فخاخ مهمة (لا تقع فيها)
- **سيرفران واتساب:** `server/` هو الفعّال (متعدّد أرقام، Oracle). `server-whatsapp/` نسخة ميتة مكرّرة — **لا تعدّلها**.
- **الفرع القديم:** الـ harness قد يبدأ على فرع متأخّر بأشهر — تأكّد من الفرع + APP_VERSION أولاً.
- منطق الدفع/المحفظة/الكوبون حسّاس — عدّل أقل مساحة وبعد فهم النسخة الحيّة.

## المطلوب التالي (طلب المستخدم)
1. **إشعارات push للتطبيق** (Android FCM + iOS APNs) — يحتاج مشروع Firebase + مفتاح APNs (حساب Apple Developer).
2. **تسجيل دخول عبر جوجل + ربط الحساب** — نفس الحساب يدخل بالرقم أو بجوجل. يحتاج Google OAuth Client (Google Cloud Console) + ربط هوية جوجل بسجلّ العميل (المفتاح الحالي = رقم الهاتف).
3. متبقّي: تحصين دوال السلة المشتركة (جلسات).
