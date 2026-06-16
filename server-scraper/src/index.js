import express from 'express'
import cors from 'cors'
import { importSheinProduct } from './importSheinProduct.js'

const PORT = process.env.PORT || 3002
const app = express()

app.use(cors())
app.use(express.json({ limit: '10mb' }))

app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'shein-scraper' })
})

// New endpoint: full import with variants
app.post('/api/shein/import', async (req, res) => {
  const { url } = req.body
  if (!url) return res.status(400).json({ success: false, error: { code: 'INVALID_SHEIN_URL', message: 'رابط المنتج مطلوب' } })

  // 90-second hard timeout — prevents hanging requests from blocking the server
  const timer = setTimeout(() => {
    if (!res.headersSent) {
      res.status(504).json({ success: false, error: { code: 'FETCH_TIMEOUT', message: 'استغرق جلب المنتج وقتاً طويلاً، حاول مرة أخرى' } })
    }
  }, 90000)

  try {
    const product = await importSheinProduct(url)
    clearTimeout(timer)
    if (!res.headersSent) res.json({ success: true, product })
  } catch (error) {
    clearTimeout(timer)
    const code = error.code || 'FETCH_FAILED'
    console.error(`❌ Import error [${code}]:`, error.message)
    if (!res.headersSent) res.status(422).json({
      success: false,
      error: { code, message: error.message, details: error.details || {} },
    })
  }
})

// Legacy endpoint (kept for backward compat)
app.post('/api/catalog/fetch-shein-product', async (req, res) => {
  const { url } = req.body
  if (!url) return res.status(400).json({ error: 'missing_url', message: 'رابط المنتج مطلوب.' })
  if (!url.includes('shein.com')) return res.status(400).json({ error: 'invalid_url', message: 'الرابط يجب أن يكون من Shein.' })

  const timer = setTimeout(() => {
    if (!res.headersSent) res.status(504).json({ error: 'FETCH_TIMEOUT', message: 'استغرق جلب المنتج وقتاً طويلاً، حاول مرة أخرى' })
  }, 90000)

  try {
    const imported = await importSheinProduct(url)
    clearTimeout(timer)
    if (!res.headersSent) res.json({
      success: true,
      product: {
        goodsId: imported.sourceProductId,
        title: imported.title,
        price: imported.price.usd,
        images: imported.images,
        colors: imported.colors.map(c => ({ name: c.name, image: c.image })),
        sizes: imported.sizes.map(s => s.name),
        url: imported.normalizedUrl,
      },
    })
  } catch (error) {
    clearTimeout(timer)
    const code = error.code || 'FETCH_FAILED'
    console.error(`❌ Scraper error [${code}]:`, error.message)
    if (!res.headersSent) res.status(500).json({ error: code, message: error.message })
  }
})

app.listen(PORT, () => {
  console.log(`\n🕷️ Talabieh Shein Scraper`)
  console.log(`📍 http://0.0.0.0:${PORT}\n`)
  // Pre-warm browser in background so first request is fast
  import('./fetchSheinData.js').then(({ warmUpBrowser }) => {
    warmUpBrowser().catch(e => console.log('⚠️ Warmup error:', e.message))
  })
})
