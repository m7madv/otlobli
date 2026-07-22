import fs from 'node:fs'
import path from 'node:path'
import { createRequire } from 'node:module'
import { fileURLToPath } from 'node:url'
import ts from 'typescript'
import { chromium } from 'playwright'

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)
const require = createRequire(import.meta.url)
const repoRoot = path.resolve(__dirname, '..')
const outDir = path.join(repoRoot, 'output', 'playwright', 'shein-cart-harness')

const SHEIN_HOME_URL =
  'https://m.shein.com/ar/?currency=USD&localcountry=SA&country=SA&countryCode=SA&country_code=SA&lang=ar&language=ar&ship_to=SA&shipTo=SA&shipToCountry=SA&shippingCountry=SA&shipping_country=SA&store_country=SA'

function argValue(name) {
  const prefix = `--${name}=`
  const found = process.argv.find((arg) => arg.startsWith(prefix))
  return found ? found.slice(prefix.length) : ''
}

function flagEnabled(name) {
  const value = argValue(name)
  return value === '1' || value === 'true' || value === 'yes'
}

function numericArg(name, fallback) {
  const value = Number(argValue(name))
  return Number.isFinite(value) && value > 0 ? value : fallback
}

const NAV_TIMEOUT_MS = numericArg('nav-timeout', 25000)
const HOME_WAIT_MS = numericArg('home-wait', 12000)
const PRODUCT_WAIT_MS = numericArg('product-wait', 12000)
const KEEP_OPEN = flagEnabled('keep-open')
const SCENARIO = argValue('scenario') || 'both'

function normalizeSheinUrl(rawUrl) {
  const url = new URL(rawUrl || SHEIN_HOME_URL, SHEIN_HOME_URL)
  url.protocol = 'https:'
  url.hostname = 'm.shein.com'
  const params = {
    currency: 'USD',
    localcountry: 'SA',
    country: 'SA',
    countryCode: 'SA',
    country_code: 'SA',
    lang: 'ar',
    language: 'ar',
    ship_to: 'SA',
    shipTo: 'SA',
    shipToCountry: 'SA',
    shippingCountry: 'SA',
    shipping_country: 'SA',
    store_country: 'SA',
  }
  for (const [key, value] of Object.entries(params)) url.searchParams.set(key, value)
  return url.toString()
}

function loadInjectedScripts() {
  const file = path.join(repoRoot, 'src', 'services', 'sheinBrowserScript.ts')
  const source = fs.readFileSync(file, 'utf8')
  const js = ts.transpileModule(source, {
    compilerOptions: {
      module: ts.ModuleKind.CommonJS,
      target: ts.ScriptTarget.ES2020,
      esModuleInterop: true,
    },
  }).outputText
  const mod = { exports: {} }
  const stubRequire = (spec) => {
    if (/\.woff2(?:\?|$)/i.test(spec) || spec.includes('@fontsource-variable/cairo')) {
      return '/assets/font.woff2'
    }
    return require(spec)
  }
  new Function('exports', 'require', 'module', '__filename', '__dirname', js)(
    mod.exports,
    stubRequire,
    mod,
    file,
    path.dirname(file),
  )
  return {
    bootstrap: mod.exports.OTLOBLI_NAV_BOOTSTRAP_SCRIPT,
    capture: mod.exports.SHEIN_CAPTURE_SCRIPT,
  }
}

async function installAppBridge(page, label) {
  await page.addInitScript(() => {
    window.__otlobliHarnessMessages = []
    window.mobileApp = {
      postMessage(payload) {
        window.__otlobliHarnessMessages.push({
          at: Date.now(),
          href: location.href,
          payload,
        })
      },
    }
  })
  page.on('console', (msg) => {
    const text = msg.text()
    if (/otlobli|error|warning|warn|TypeError|ReferenceError/i.test(text)) {
      console.log(`[${label}] console ${msg.type()}: ${text}`)
    }
  })
  page.on('pageerror', (err) => {
    console.log(`[${label}] pageerror: ${err.message}`)
  })
}

async function injectCapture(page, scripts) {
  await page.evaluate(scripts.bootstrap).catch(() => undefined)
  await page.evaluate(scripts.capture)
}

async function waitForState(page, timeoutMs = 15000) {
  const start = Date.now()
  while (Date.now() - start < timeoutMs) {
    const state = await page.evaluate(() => {
      const messages = window.__otlobliHarnessMessages || []
      const last = messages[messages.length - 1]
      const add = document.getElementById('otlobli-add-btn')
      const nav = document.getElementById('otlobli-nav')
      const bodyText = (document.body?.innerText || '').replace(/\s+/g, ' ').trim()
      const buttons = [...document.querySelectorAll('a[href],button,[role="button"],input')]
        .filter((el) => {
          const rect = el.getBoundingClientRect()
          if (!rect || rect.width < 8 || rect.height < 8 || rect.bottom <= 0 || rect.top >= innerHeight) return false
          const style = getComputedStyle(el)
          return style.display !== 'none' && style.visibility !== 'hidden' && style.pointerEvents !== 'none' && Number(style.opacity || 1) > 0.1
        }).length
      const imgs = [...document.images]
        .filter((img) => img.complete && img.naturalWidth > 40 && img.naturalHeight > 40)
        .length
      return {
        href: location.href,
        readyState: document.readyState,
        textLength: bodyText.length,
        buttons,
        imgs,
        addVisible: !!add && getComputedStyle(add).display !== 'none',
        navVisible: !!nav && getComputedStyle(nav).display !== 'none',
        messageCount: messages.length,
        lastMessage: last?.payload?.detail?.type || '',
      }
    })
    if (state.lastMessage === 'sheinPageInteractive' || state.addVisible || state.imgs >= 2) return state
    await page.waitForTimeout(500)
  }
  return page.evaluate(() => ({
    href: location.href,
    readyState: document.readyState,
    textLength: (document.body?.innerText || '').replace(/\s+/g, ' ').trim().length,
    buttons: document.querySelectorAll('a[href],button,[role="button"],input').length,
    imgs: [...document.images].filter((img) => img.complete && img.naturalWidth > 40 && img.naturalHeight > 40).length,
    addVisible: !!document.getElementById('otlobli-add-btn'),
    navVisible: !!document.getElementById('otlobli-nav'),
    messageCount: (window.__otlobliHarnessMessages || []).length,
    lastMessage: (window.__otlobliHarnessMessages || []).at(-1)?.payload?.detail?.type || '',
  }))
}

async function findProductUrl(page) {
  return page.evaluate(() => {
    const anchors = [...document.querySelectorAll('a[href]')]
    const found = anchors.find((a) => /(?:-p-\d+|goods_id=|product|\/p\/)/i.test(a.href || ''))
    return found?.href || ''
  })
}

async function runScenario(name, productUrl, mode, scripts) {
  let target = productUrl
  let browser
  let page
  const before = Date.now()
  const screenshotPath = path.join(outDir, `${name}.png`)
  try {
    browser = await chromium.launch({
      headless: flagEnabled('headless'),
      slowMo: flagEnabled('headless') ? 0 : 250,
    })
    const context = await browser.newContext({
      isMobile: true,
      hasTouch: true,
      viewport: { width: 390, height: 844 },
      userAgent:
        'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
      locale: 'ar-SA',
    })
    context.setDefaultNavigationTimeout(NAV_TIMEOUT_MS)
    context.setDefaultTimeout(NAV_TIMEOUT_MS)
    page = await context.newPage()
    await installAppBridge(page, name)
    await page.goto(SHEIN_HOME_URL, { waitUntil: 'domcontentloaded', timeout: NAV_TIMEOUT_MS })
    await injectCapture(page, scripts)
    const home = await waitForState(page, HOME_WAIT_MS)
    if (!target) target = await findProductUrl(page)
    if (!target) throw new Error('No SHEIN product link was found on the home page.')
    target = normalizeSheinUrl(target)

    if (mode === 'full') {
      await page.goto(target, { waitUntil: 'domcontentloaded', timeout: NAV_TIMEOUT_MS })
    } else {
      await page.evaluate((url) => {
        window.location.assign(url)
      }, target)
      await page.waitForLoadState('domcontentloaded', { timeout: NAV_TIMEOUT_MS }).catch(() => undefined)
    }
    await injectCapture(page, scripts).catch(() => undefined)
    const product = await waitForState(page, PRODUCT_WAIT_MS)
    await page.screenshot({ path: screenshotPath, fullPage: false }).catch(() => undefined)
    if (KEEP_OPEN) {
      console.log(`[${name}] manual browser is open. Close it when you are done.`)
      await new Promise((resolve) => page.once('close', resolve))
    }

    return {
      name,
      mode,
      elapsedMs: Date.now() - before,
      target,
      home,
      product,
      screenshotPath,
    }
  } catch (err) {
    await page?.screenshot({ path: screenshotPath, fullPage: false }).catch(() => undefined)
    return {
      name,
      mode,
      elapsedMs: Date.now() - before,
      target: target ? normalizeSheinUrl(target) : '',
      error: err?.message || String(err),
      href: await page?.evaluate(() => location.href).catch(() => ''),
      screenshotPath,
    }
  } finally {
    if (!KEEP_OPEN) await browser?.close().catch(() => undefined)
  }
}

async function main() {
  fs.mkdirSync(outDir, { recursive: true })
  const productUrl = argValue('product')
  const scripts = loadInjectedScripts()
  const results = []
  if (SCENARIO === 'full' || SCENARIO === 'both') {
    results.push(await runScenario('full-load', productUrl, 'full', scripts))
  }
  if (SCENARIO === 'in-page' || SCENARIO === 'both') {
    results.push(await runScenario('in-page-nav', productUrl || results[0]?.target || '', 'in-page', scripts))
  }
  const reportPath = path.join(outDir, 'report.json')
  fs.writeFileSync(reportPath, JSON.stringify(results, null, 2))
  console.log(JSON.stringify({ reportPath, results }, null, 2))
}

main().catch((err) => {
  console.error(err)
  process.exit(1)
})
