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

## ⚡ الطريق السريع (بعد إنشاء الجهاز)

بعد إنشاء جهاز Oracle (الخطوة 1) وفتح المنفذ (الخطوة 2) والاتصال به (الخطوة 3)،
معظم العمل صار بأمر واحد:

```bash
# 1) ارفع مجلّد server إلى الجهاز (من جهازك):
scp -i /path/to/key -r "C:/Users/MOHAMMAD/Projects/SHEIN IN SIRYA/server" ubuntu@YOUR_PUBLIC_IP:~/otlobli-server
# 2) على الجهاز: عبّئ الأسرار ثم شغّل سكربت النشر الجاهز:
cd ~/otlobli-server
cp .env.example .env && nano .env    # الصق القيم من Railway
bash deploy-oracle.sh                # يثبّت Node+pm2، الاعتماديات، يفتح المنفذ، ويشغّل السيرفر
```

السكربت يقوم بالخطوات 4–8 تلقائياً. يبقى عليك فقط: **ربط الواتساب (QR) وإضافة الأرقام**
من لوحة الإدارة (الخطوة 8.5)، و**توجيه التطبيق** (الخطوة 9). التفاصيل اليدوية أدناه
للرجوع عند الحاجة.

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
> لا تنقل `.env` أو أي سر عبر Git. بيانات الجلسات الفعالة موجودة في
> `wa-sessions/`؛ انقلها فقط بقناة إدارية مشفرة وموثوقة إن كنت متأكدًا أنها لم
> تتعرض سابقًا. عند الشك، ألغِ الجهاز المرتبط القديم وأعد الربط من لوحة الإدارة
> بعد نشر الحماية الجديدة.

ثم داخل SSH:
```bash
cd ~/otlobli-server
rm -rf node_modules
npm ci --omit=dev
```

---

## 6) إعداد متغيّرات البيئة (`.env`)

أنشئ ملف `.env` داخل `~/otlobli-server` بنفس القيم التي كانت على Railway. المتغيّرات
المطلوبة:
```env
PORT=3001
SUPABASE_URL=...
SUPABASE_SERVICE_ROLE_KEY=...
OTP_HASH_SECRET=<at-least-32-random-bytes>
WHATSAPP_ADMIN_SECRET=<different-at-least-32-random-bytes>
ADMIN_PIN=...
ADMIN_URL=...
ORDER_NOTIFY_SECRET=...
TELEGRAM_BOT_TOKEN=...
TELEGRAM_CHAT_ID=...
VITE_USD_TO_SYP_RATE=131.7
```
> انسخ القيم من مخزن الأسرار، لا من ملف متعقّب. دوّر `ADMIN_PIN` القديم قبل
> التشغيل، ولا تعِد استخدامه كـ`WHATSAPP_ADMIN_SECRET`. تغيير
> `OTP_HASH_SECRET` يلغي كل رموز OTP المعلّقة. متغيّرات `RAILWAY_*` لا تلزم على
> Oracle.

---

## 7) أول تشغيل + ربط الواتساب المحمي

شغّل السيرفر يدوياً أول مرة:
```bash
node src/index.js
```
- إن كانت جلسة `wa-sessions/` صالحة، سيتصل مباشرة.
- لا توجد صفحة QR عامة ولا خدمة QR خارجية. أدخل `WHATSAPP_ADMIN_SECRET` في لوحة
  الإدارة، أنشئ جلسة، ثم امسح صورة QR المحلية المحمية من واتساب → الأجهزة
  المرتبطة → ربط جهاز.
- تأكّد محليًا من `/health`. لا تعتبر الخدمة جاهزة حتى تكون القيم
  `sessionStoreReady=true` و`authContract=customer-session-v1` و
  `otpSecurityReady=true` و`whatsappConnected=true` و
  `whatsappSenderReady=true`.
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

اختبر من الخارج عبر عنوان HTTPS النهائي فقط. لا تضع عنوان HTTP أو IP مباشرًا
داخل التطبيق. اتبع [دليل الإعداد الكامل](../WHATSAPP_SETUP.md) قبل TestFlight.

---

## 8.5) إضافة عدة أرقام واتساب (مدعوم أصلاً)

سيرفرك يدعم **عدة أرقام** جاهزاً مع **تبديل تلقائي** بينها (إن فشل رقم يُجرّب التالي)،
وإيقاع مضادّ للحظر مدمج (فاصل ≥4 ثوانٍ بين الرسائل + مؤشّر «يكتب» + تأخير عشوائي).
لا حاجة لأي أداة خارجية.

لإضافة رقم من **لوحة الإدارة** (بعد نجاح النشر وتوجيه العنوان في الخطوة 9):
1. افتح لوحة الإدارة → قسم **جلسات واتساب**، وأدخل سر واتساب الإداري المنفصل.
2. اضغط «إضافة رقم» → سيظهر **QR محلي ومحمي** → امسحه من هاتف الرقم الجديد
   (واتساب → الأجهزة المرتبطة → ربط جهاز).
3. كرّر لكل رقم تريده. الأرقام المتصلة تتناوب على الإرسال تلقائياً.

> نصيحة لتقليل الحظر: استخدم أرقاماً **قديمة/مُفعّلة** (ليست جديدة)، ووزّع الإرسال
> على أكثر من رقم، ولا ترسل رسائل جماعية. التفاصيل في `WHATSAPP_ANTI_BAN.md`.

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
