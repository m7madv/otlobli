#!/usr/bin/env bash
# نشر سيرفر واتساب otlobli على جهاز Oracle Cloud (Ubuntu) بأمر واحد.
# شغّله من داخل مجلّد السيرفر على الجهاز بعد رفعه وتعبئة .env:
#   cd ~/otlobli-server && bash deploy-oracle.sh
# آمن للتكرار: يعيد التشغيل عند كل مرة.
set -euo pipefail

PORT="${PORT:-3001}"
APP_NAME="otlobli-wa"

echo "== 1) التحقق من .env =="
if [ ! -f .env ]; then
  echo "❌ لا يوجد ملف .env. انسخ .env.example إلى .env واملأ القيم أولاً:"
  echo "   cp .env.example .env && nano .env"
  exit 1
fi

echo "== 2) تثبيت Node.js 20 (إن لزم) =="
if ! command -v node >/dev/null 2>&1 || [ "$(node -v | cut -d. -f1 | tr -d v)" -lt 20 ]; then
  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
  sudo apt-get install -y nodejs
fi
node -v

echo "== 3) تثبيت git و pm2 (إن لزم) =="
command -v git >/dev/null 2>&1 || sudo apt-get install -y git
command -v pm2 >/dev/null 2>&1 || sudo npm install -g pm2

echo "== 4) تثبيت الاعتماديات =="
rm -rf node_modules
npm install --omit=dev || npm install

echo "== 5) فتح المنفذ $PORT في جدار الجهاز =="
if ! sudo iptables -C INPUT -p tcp --dport "$PORT" -j ACCEPT 2>/dev/null; then
  sudo iptables -I INPUT -p tcp --dport "$PORT" -j ACCEPT || true
  sudo bash -c 'command -v netfilter-persistent >/dev/null 2>&1 || (apt-get update && apt-get install -y iptables-persistent)' || true
  sudo netfilter-persistent save || true
fi

echo "== 6) تشغيل/إعادة تشغيل السيرفر عبر pm2 =="
if pm2 describe "$APP_NAME" >/dev/null 2>&1; then
  pm2 restart "$APP_NAME" --update-env
else
  pm2 start src/index.js --name "$APP_NAME"
fi
pm2 save

echo "== 7) تفعيل التشغيل التلقائي عند الإقلاع =="
echo "نفّذ الأمر التالي مرة واحدة إن طلب منك pm2 ذلك:"
pm2 startup systemd -u "$USER" --hp "$HOME" || true

echo ""
echo "✅ تم. تحقّق من الصحّة:  curl http://localhost:$PORT/health"
echo "   السجلّات:            pm2 logs $APP_NAME"
echo "   الحالة:              pm2 status"
echo ""
echo "الخطوة الأخيرة (أنت): من لوحة الإدارة → «جلسات واتساب» → أضف أرقامك بمسح QR،"
echo "ثم عدّل VITE_WHATSAPP_API_URL في التطبيق إلى http://<عنوان-الجهاز>:$PORT"
