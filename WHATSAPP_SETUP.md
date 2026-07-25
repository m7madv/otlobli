# WhatsApp inbound verification setup

This project supports the flow where the customer sends a ready WhatsApp message to your business number. The message contains a short code for better matching, but the customer only presses Send in WhatsApp.

## Vercel environment variables

Set these on the customer app project:

```txt
VITE_WHATSAPP_AUTH_MODE=inbound
VITE_SUPPORT_WHATSAPP_PHONE=9639xxxxxxxx
VITE_SUPABASE_URL=...
VITE_SUPABASE_ANON_KEY=...
SUPABASE_SERVICE_ROLE_KEY=...
OTP_HASH_SECRET=any-long-random-secret
WHATSAPP_WEBHOOK_VERIFY_TOKEN=any-random-token-you-choose
WHATSAPP_APP_SECRET=your-meta-app-secret
```

`WHATSAPP_ACCESS_TOKEN`, `WHATSAPP_PHONE_NUMBER_ID`, and template variables are only needed if the app sends WhatsApp messages itself. The inbound flow does not need them.

## Meta webhook

Use this callback URL:

```txt
https://talabieh.vercel.app/api/webhooks/whatsapp
```

Use the same value from `WHATSAPP_WEBHOOK_VERIFY_TOKEN` as the Meta verify token.

Subscribe the WhatsApp Business Account webhook to:

```txt
messages
```

## Runtime flow

1. Customer enters their WhatsApp number.
2. The app creates a challenge in `otp_challenges`.
3. The app opens `wa.me` with a ready message like `طلبية 1234`.
4. Customer presses Send in WhatsApp.
5. Meta sends the inbound message to `/api/webhooks/whatsapp`.
6. The webhook verifies Meta signature and reads the real sender phone from WhatsApp.
7. If the sender phone and code match the latest pending challenge, it becomes `verified`, and the customer is upserted in `customers` by phone only.

---

## نظام الأرقام المتعدّد الاحترافي (v2 — 2026-07-25)

Baileys طريقة غير رسمية ولا يوجد إعداد يمنع الحظر 100%. هذا النظام **يقلّل الحظر**
عبر ممارسات مشروعة، والأهم **يضمن استمرار الخدمة** عبر مجموعة أرقام + failover:
حتى لو انحظر رقم، الإرسال يكمل من الأرقام الباقية تلقائياً.

### كيف يقلّل الحظر
- **توزيع الحمل** على عدّة أرقام (اختيار الأقل استخداماً لكل رسالة).
- **حدود إرسال** لكل رقم: فاصل أدنى بين الرسائل + سقف يومي.
- **إحماء تدريجي**: الرقم الجديد يبدأ بسقف صغير ويرتفع خلال أيام.
- **التحقق أن الرقم على واتساب** قبل الإرسال (الإرسال لأرقام غير موجودة سبب حظر كبير).
- **أنماط طبيعية**: حضور "يكتب" + تأخير عشوائي بسيط قبل الإرسال.
- **كشف الحظر**: عند الحظر/الخروج يُوقف الرقم فوراً (بلا حلقة إعادة اتصال) وينبّه عبر تيليغرام.

### متغيّرات البيئة (env)
```
WHATSAPP_NUMBERS=main,n2,n3      # قائمة الأرقام (كل رقم جلسة مستقلة)
WA_PER_NUMBER_PER_MIN=6          # إرسال/دقيقة لكل رقم (إرشادي)
WA_PER_NUMBER_PER_DAY=200        # سقف يومي لكل رقم بعد الإحماء
WA_WARMUP_DAYS=3                 # مدة الإحماء
WA_WARMUP_DAY1=30                # سقف اليوم الأول لرقم جديد
WA_MIN_SEND_GAP_MS=4000          # أدنى فاصل بين رسالتين لنفس الرقم
TELEGRAM_BOT_TOKEN=...           # لتنبيهات الحظر (اختياري)
TELEGRAM_ALERT_CHAT_ID=...       # قناة/محادثة التنبيهات
```

### إضافة رقم جديد
1. أضِف اسمه إلى `WHATSAPP_NUMBERS` (مثال: `main,n2`).
2. أعد تشغيل السيرفر.
3. افتح `‏/api/qr-url?number=n2` وامسح الـQR من واتساب على ذلك الهاتف.
> الجلسة القديمة (رقم واحد) تُرحّل تلقائياً إلى الاسم `main`.

### المراقبة
- `GET /api/whatsapp/pool` — حالة كل رقم (متصل/محظور، كم أرسل اليوم، السقف).
- `GET /health` — عدد الأرقام الصحّية.
- `GET /api/qr-url?number=<label>` — QR رقم محدّد لإعادة الربط عند الحظر.

### النشر (على Oracle VM)
```bash
cd ~/otlobli && git pull && cd server-whatsapp && npm install && pm2 restart talabieh-whatsapp
```
