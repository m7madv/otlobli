/**
 * Talabieh WhatsApp Server — Local Service
 * شُغّل كخدمة Windows ثابتة وتطفي على terminal
 * يعيد الاتصال تلقائياً بدون QR كل مرة
 */

const path = require('path')
const fs = require('fs')
const { Service } = require('node-windows')

const scriptPath = path.join(__dirname, 'src', 'index.js')
const logDir = path.join(__dirname, 'logs')

if (!fs.existsSync(logDir)) {
  fs.mkdirSync(logDir, { recursive: true })
}

const svc = new Service({
  name: 'Talabieh WhatsApp',
  description: 'WhatsApp Gateway Service for Talabieh OTP — يشتغل وينعاد تلقائياً إذا قفل',
  script: scriptPath,
  nodeOptions: ['--experimental-modules'],
  workingdirectory: __dirname,
  grow: .25,
  maxRetries: 5,
  maxRestarts: 10,
  abortOnError: false,
})

svc.on('install', () => {
  console.log('✅ تم تثبيت الخدمة — "Talabieh WhatsApp"')
  console.log('🔄 تشغيل...')
  svc.start()
})

svc.on('alreadyinstalled', () => {
  console.log('الخدمة موجودة مسبقاً')
  console.log('جاري تشغيلها...')
  svc.start()
})

svc.on('start', () => {
  console.log('✅ خدمة واتساب شغالة الآن!')
  console.log(`📱 السيرفر على http://localhost:3001`)
  console.log(`🩺 الصحة: http://localhost:3001/health`)
})

svc.on('error', (err) => {
  console.error('❌ خطأ:', err.message)
})

svc.install()
