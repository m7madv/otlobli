import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { Capacitor } from '@capacitor/core'
import App from './App'
import { ErrorBoundary } from './components/ErrorBoundary'
import '@fontsource-variable/cairo/wght.css'
import './styles.css'

const rootEl = document.getElementById('root')!

// Android WebView applies the user's system font scale to ordinary app text,
// while SHEIN explicitly opts its document out of text autosizing. Keep that
// accessibility preference everywhere else, but compensate the four fixed nav
// labels once before React mounts so both WebViews render the agreed 12px tabs.
// This is a single bounded style read at startup: no timer, observer, or render.
if (Capacitor.getPlatform() === 'android') {
  const navFontProbe = document.createElement('span')
  navFontProbe.textContent = 'حسابي'
  navFontProbe.setAttribute('aria-hidden', 'true')
  navFontProbe.style.cssText =
    'position:fixed;visibility:hidden;pointer-events:none;font:700 12px/normal system-ui,-apple-system,sans-serif'
  document.body.appendChild(navFontProbe)
  const renderedNavFontPx = Number.parseFloat(window.getComputedStyle(navFontProbe).fontSize)
  navFontProbe.remove()
  if (Number.isFinite(renderedNavFontPx) && renderedNavFontPx > 0) {
    const compensatedFontPx = Math.min(16, Math.max(8, (12 * 12) / renderedNavFontPx))
    document.documentElement.style.setProperty('--otlobli-nav-font-size', `${compensatedFontPx.toFixed(4)}px`)
  }
}

// شبكة أمان عامة: تسجّل الأخطاء غير الملتقطة بدل ما تمرّ بصمت. غير حيوية -
// لا توقف التطبيق، فقط تساعد بالتشخيص.
window.addEventListener('error', (e) => {
  console.error('otlobli global error:', e.message)
})
window.addEventListener('unhandledrejection', (e) => {
  console.error('otlobli unhandled rejection:', e.reason)
})

// مراقب الشاشة الفارغة: لو رجع المستخدم للتطبيق ولقي الجذر فاضياً (شاشة
// سوداء/بيضاء نتيجة انهيار العرض)، يعيد التحميل تلقائياً للاسترداد.
document.addEventListener('visibilitychange', () => {
  if (document.visibilityState === 'visible' && rootEl.childElementCount === 0) {
    window.location.reload()
  }
})

createRoot(rootEl).render(
  <StrictMode>
    <ErrorBoundary>
      <App />
    </ErrorBoundary>
  </StrictMode>,
)
