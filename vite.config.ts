import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import { stripInjectedComments, INJECTED_SCRIPT_SOURCE } from './scripts/strip-injected-comments.mjs'

// خادم واتساب على Railway
const WHATSAPP_API = process.env.VITE_WHATSAPP_API_URL || 'https://otlobli-whatsapp-production.up.railway.app'

// سكربتات المتجر تُحقن كنص داخل صفحة SHEIN/Temu، فتعليقاتها تُشحن إلى الجهاز
// ويحلّلها محرّك JavaScript قبل أن تُرسم الصفحة. تجريدها وقت البناء يوفّر نحو
// 93 كيلوبايت على كل تحميل صفحة، بلا أي تغيير في السلوك. المصدر يبقى موثّقاً
// بالكامل؛ الجهاز وحده هو من يتلقّى النسخة المجرّدة. حارس التجمّد يعيد تحليل
// كل سكربت بعد التجريد، فأي خطأ هنا يُفشل البناء بدل أن يصل للمستخدم.
const stripStoreScriptComments = () => ({
  name: 'otlobli-strip-injected-comments',
  enforce: 'pre' as const,
  transform(code: string, id: string) {
    if (!id.replace(/\\/g, '/').endsWith(INJECTED_SCRIPT_SOURCE)) return null
    return { code: stripInjectedComments(code), map: null }
  },
})

export default defineConfig({
  plugins: [stripStoreScriptComments(), react()],
  server: {
    proxy: {
      '/api': {
        target: WHATSAPP_API,
        changeOrigin: true,
      },
    },
  },
})
