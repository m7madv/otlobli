import { cleanEnvValue } from '../config'
import type { TalabiehApi } from './appApi'
import { localAppApi } from './localAppApi'
import { resolvePhoneAuthBackend } from './phoneAuthMode'
import { whatsappAuthApi, whatsappAuthMode } from './whatsappAuthApi'

const localMockExplicitlyEnabled =
  cleanEnvValue(import.meta.env.VITE_LOCAL_AUTH_MOCK_ENABLED).toLowerCase() === 'true'

export const phoneAuthBackend = resolvePhoneAuthBackend({
  mode: whatsappAuthMode,
  isDevelopment: import.meta.env.DEV,
  localMockExplicitlyEnabled,
})

const PHONE_AUTH_CONFIGURATION_ERROR =
  'تسجيل الدخول برقم واتساب غير مهيأ في هذه النسخة. ثبّت النسخة الرسمية أو تواصل مع الدعم.'

const unavailablePhoneAuthApi: TalabiehApi['auth'] = {
  async startWhatsappLogin() {
    throw new Error(PHONE_AUTH_CONFIGURATION_ERROR)
  },
  async verifyOtp() {
    throw new Error(PHONE_AUTH_CONFIGURATION_ERROR)
  },
}

export const phoneAuthApi: TalabiehApi['auth'] = phoneAuthBackend === 'whatsapp-api'
  ? whatsappAuthApi
  : phoneAuthBackend === 'local-mock'
    ? localAppApi.auth
    : unavailablePhoneAuthApi
