import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// خادم واتساب على Railway
const WHATSAPP_API = process.env.VITE_WHATSAPP_API_URL || 'https://otlobli-whatsapp-production.up.railway.app'

export default defineConfig({
  plugins: [react()],
  server: {
    proxy: {
      '/api': {
        target: WHATSAPP_API,
        changeOrigin: true,
      },
    },
  },
})
