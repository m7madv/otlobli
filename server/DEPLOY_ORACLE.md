# نشر سيرفر الواتساب على Oracle Cloud (مجاني دائم)

هذا الدليل ينقل سيرفر `server/` (OTP واتساب عبر Baileys + إشعارات تيليجرام) من
Railway إلى **Oracle Cloud Always Free** — جهاز افتراضي مجاني للأبد، دائم التشغيل،
مع قرص ثابت يحفظ جلسة الواتساب فلا تحتاج إعادة ربط QR كل مرة.

> ملاحظات مهمة قبل البدء:
> - سعر الصرف لم يعد على هذا السيرفر — انتقل إلى مهمة GitHub Actions المجانية
>   (`.github/workflows/exchange-rate.yml`). هذا السيرفر الآن للواتساب/تيليجرام فقط.
> - الخطوات التي تحتاج **حسابك وكلمة مرورك** (إنشاء حساب Oracle، مفاتيح SSH) تنفّذها
>   **أنت**؛ لا يمكنني إدخال بيانات دخولك نيابةً عنك.
> - ملفات `baileys-auth/` و`.env` **سرّية** (جلسة واتساب + مفاتيح). لا تنشرها ولا
>   ترفعها لأي مكان عام.

---

## 1) إنشاء الجهاز الافتراضي المجاني (أنت)

1. أنشئ حساباً على <https://www.oracle.com/cloud/free/> (يتطلب بطاقة للتحقق فقط،
   لا يُسحب منها ضمن Always Free).
2. من لوحة Oracle: **Compute → Instances → Create Instance**.
3. الإعدادات:
   - **Image:** Ubuntu 22.04.
   - **Shape:** اختر **Always Free eligible** — الأفضل `VM.Standard.A1.Flex`
     (Ampere ARM، 1 OCPU + 6GB كافية جداً)، أو `VM.Standard.E2.1.Micro`.
   - **SSH keys:** أنشئ زوج مفاتيح (Download private key) واحفظ الملف الخاص.
4. أنشئ الجهاز وانتظر حتى يصبح **Running**، وسجّل **Public IP address**.

---

## 2) فتح المنفذ (Port)

السيرفر يستمع على منفذ (نستخدم `3001`). افتحه من مكانين:

**أ. شبكة Oracle (Security List / NSG):**
- **Networking → Virtual Cloud Networks → (شبكتك) → Security Lists → Default**.
- **Add Ingress Rule:** Source `0.0.0.0/0`، IP Protocol `TCP`، Destination Port `3001`.

**ب. جدار الجهاز نفسه** (بعد الاتصال في الخطوة 3):
```bash
sudo iptables -I INPUT -p tcp --dport 3001 -j ACCEPT
sudo netfilter-persistent save   # لو غير مثبّت: sudo apt install -y iptables-persistent
```

---

## 3) الاتصال بالجهاز (SSH)

من جهازك (استبدل المسار والـ IP):
```bash
ssh -i /path/to/your-private-key ubuntu@YOUR_PUBLIC_IP
```

---

## 4) تثبيت Node.js 20 و pm2

```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs git
sudo npm install -g pm2
node -v   # يجب أن يكون 20 أو أعلى
```

---

## 5) وضع كود السيرفر على الجهاز

**الطريقة الأسهل — رفع مجلّد `server/` عبر scp** (من جهازك، ليس داخل SSH):
```bash
# استبعد node_modules لتسريع الرفع
scp -i /path/to/your-private-key -r "C:/Users/MOHAMMAD/Projects/SHEIN IN SIRYA/server" ubuntu@YOUR_PUBLIC_IP:~/otlobli-server
```
> يتضمّن هذا مجلّد `baileys-auth/` الحالي — وهذا مطلوب: ينقل جلسة الواتساب الحالية
> فلا تحتاج إعادة ربط QR. (إن أردت رقماً جديداً، احذف `baileys-auth/` على الجهاز
> وأعد الربط في الخطوة 7.)

ثم داخل SSH:
```bash
cd ~/otlobli-server
rm -rf node_modules
npm install
```

---

## 6) إعداد متغيّرات البيئة (`.env`)

أنشئ ملف `.env` داخل `~/otlobli-server` بنفس القيم التي كانت على Railway. المتغيّرات
المطلوبة:
```env
PORT=3001
SUPABASE_URL=...
SUPABASE_SERVICE_ROLE_KEY=...
ADMIN_PIN=...
ADMIN_URL=...
ORDER_NOTIFY_SECRET=...
TELEGRAM_BOT_TOKEN=...
TELEGRAM_CHAT_ID=...
VITE_USD_TO_SYP_RATE=13000
```
> انسخ القيم من متغيّرات Railway الحالية (Railway → Service → Variables). متغيّرات
> `RAILWAY_*` لا تلزم على Oracle.

---

## 7) أول تشغيل + ربط الواتساب (QR)

شغّل السيرفر يدوياً أول مرة لترى الـ QR (لو احتجت ربطاً جديداً):
```bash
node src/index.js
```
- إن كانت جلسة `baileys-auth/` صالحة، سيتصل مباشرة بلا QR.
- إن ظهر QR في الطرفية أو حُفظ في `qr-code.png`: افتحه وامسحه من واتساب هاتف الخدمة
  (واتساب → الأجهزة المرتبطة → ربط جهاز).
- تأكّد من الصحّة: `curl http://localhost:3001/health` يجب أن يردّ بنجاح.
- أوقفه بـ `Ctrl+C` بعد نجاح الربط.

---

## 8) التشغيل الدائم عبر pm2 (يعيد التشغيل تلقائياً ويبقى بعد إعادة الإقلاع)

```bash
cd ~/otlobli-server
pm2 start src/index.js --name otlobli-wa
pm2 save
pm2 startup systemd    # نفّذ الأمر الذي يطبعه (يبدأ بـ sudo env ...)
```
مراقبة السجلّات: `pm2 logs otlobli-wa` — الحالة: `pm2 status`.

اختبر من الخارج: `http://YOUR_PUBLIC_IP:3001/health`.

---

## 9) توجيه التطبيق للسيرفر الجديد

في إعدادات نشر تطبيق الزبون (Vercel/البيئة):
- عدّل `VITE_WHATSAPP_API_URL` إلى `http://YOUR_PUBLIC_IP:3001`.
- أعد بناء/نشر التطبيق حتى يلتقط العنوان الجديد.

> يُفضّل لاحقاً وضع اسم نطاق + HTTPS (عبر Caddy أو Nginx + Let's Encrypt) بدل الـ IP،
> خصوصاً أن بعض المتصفّحات تمنع طلبات HTTP من صفحة HTTPS. إن واجهت مشاكل mixed-content،
> هذه الخطوة تصبح ضرورية.

---

## 10) بعد التأكّد — أوقف Railway

بعد نجاح كل شيء على Oracle لعدّة أيام، أوقف/احذف خدمة Railway حتى لا تُفاجأ بفاتورة
بعد انتهاء الرصيد المجاني.

---

## ملاحظات أمان وصيانة

- لا ترفع `.env` ولا `baileys-auth/` إلى Git أو أي مكان عام.
- حدّث النظام دورياً: `sudo apt update && sudo apt upgrade -y`.
- لو انقطع الواتساب (حظر رقم/انتهاء جلسة): احذف `baileys-auth/` وأعد الخطوة 7.
- راجع `server/WHATSAPP_ANTI_BAN.md` لتقليل خطر حظر رقم الواتساب.
- Oracle Always Free قد يستعيد أجهزة **الحساب المجاني الخاملة تماماً**؛ إبقاء السيرفر
  شغّالاً وفعّالاً (طلبات OTP دورية) يقيك ذلك.
