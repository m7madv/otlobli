import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import { fileURLToPath, URL } from 'node:url'
import { minifyInjectedScripts } from './scripts/minify-injected-scripts.mjs'
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

export default defineConfig(({ mode }) => {
  const storeScriptDiagnostics = process.env.VITE_STORE_SCRIPT_DIAGNOSTICS === 'true'
  return {
    define: {
      'import.meta.env.VITE_TEMU_PERSONAL_SITE_MODE': JSON.stringify(mode === 'temu-personal'),
      'import.meta.env.VITE_STORE_SCRIPT_DIAGNOSTICS': JSON.stringify(storeScriptDiagnostics ? 'true' : 'false'),
    },
    resolve: {
      alias: storeScriptDiagnostics ? [] : [{
        find: './services/storeScriptDiagnostics',
        replacement: fileURLToPath(new URL('./src/services/storeScriptDiagnosticsDisabled.ts', import.meta.url)),
      }],
    },
    plugins: [minifyInjectedScripts(), stripStoreScriptComments(), react()],
    build: {
      // Never publish browser source maps. The injected store scripts are also
      // minified as executable JavaScript by the build-only plugin above.
      sourcemap: false,
    },
    server: {
      proxy: {
        '/api': {
          target: WHATSAPP_API,
          changeOrigin: true,
        },
      },
    },
  }
})
