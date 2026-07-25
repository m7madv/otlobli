import express from 'express'
import cors from 'cors'
import { initWhatsapp, onConnection, isWhatsappConnected, getConnectionStatus, getNumberQr, getPoolStatus } from './whatsapp.js'
import routes from './routes.js'

const PORT = process.env.PORT || 3001
const app = express()

app.use(cors())
app.use(express.json({ limit: '10mb' }))
app.use(express.urlencoded({ extended: true }))

app.use('/api', routes)

app.get('/health', (req, res) => {
  const pool = getPoolStatus()
  res.json({ status: 'ok', whatsappConnected: isWhatsappConnected(), healthyNumbers: pool.healthy, totalNumbers: pool.total })
})

// حالة مجموعة الأرقام كاملة (للمراقبة): كم رقم صحّي/محظور وكم أرسل كل رقم.
app.get('/api/whatsapp/pool', (req, res) => {
  res.json(getPoolStatus())
})

// QR لرقم محدّد (?number=main) لإضافة/إعادة ربط رقم؛ بدون معامل = الحالة العامة.
app.get('/api/qr-url', (req, res) => {
  const label = req.query.number
  if (label) return res.json(getNumberQr(String(label)))
  const status = getConnectionStatus()
  if (status.qrImageUrl) res.json({ qrUrl: status.qrImageUrl, connected: false })
  else if (status.connected) res.json({ connected: true })
  else res.json({ connected: false, message: 'QR غير متاح بعد' })
})

initWhatsapp()
  .then(() => console.log('🚀 WhatsApp جاهز'))
  .catch(err => console.error('❌ WhatsApp init:', err.message))

onConnection(event => {
  if (event.status === 'connected') console.log('\n✅ WhatsApp متصل — السيرفر جاهز\n')
  else if (event.status === 'qr') console.log('\n📲 امسح QR للتفعيل\n')
})

app.listen(PORT, () => {
  console.log(`\n🚀 Talabieh WhatsApp Server`)
  console.log(`📍 http://0.0.0.0:${PORT}\n`)
})
