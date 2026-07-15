import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import App from './App'
import { ErrorBoundary } from './components/ErrorBoundary'
import '@fontsource-variable/cairo/wght.css'
import './styles.css'

const rootEl = document.getElementById('root')!

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
