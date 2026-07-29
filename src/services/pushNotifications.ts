// تسجيل إشعارات Push (واجهة العميل).
// خامل تماماً حتى: (1) تُثبَّت @capacitor/push-notifications، (2) يُضبط
// VITE_PUSH_ENABLED=true، (3) يعمل داخل تطبيق أصلي (أندرويد/iOS) لا الويب.
// تُضمَّن إضافتا Capacitor في حزمة Vite حتى لا تُترك bare specifiers داخل WebView.
import { Capacitor } from '@capacitor/core'
import { PushNotifications } from '@capacitor/push-notifications'
import { cleanEnvValue } from '../config'
import { supabase } from './supabaseClient'

// Push is enabled for native builds unless it is explicitly disabled.
const ENABLED_FLAG = cleanEnvValue(import.meta.env.VITE_PUSH_ENABLED) !== 'false'

let nativeRegistrationStarted = false
let activeSessionToken = ''
let activePlatform: 'android' | 'ios' | null = null
let latestDeviceToken = ''

// يقرأ المنصّة من Capacitor (native فقط).
function getNativePlatform(): 'android' | 'ios' | null {
  const platform = Capacitor.getPlatform()
  if (platform === 'android' || platform === 'ios') return platform
  return null
}

async function syncDeviceToken(token: string, sessionToken: string, platform: 'android' | 'ios'): Promise<void> {
  if (!supabase || !token || !sessionToken) return

  let lastError: unknown = null
  for (const delayMs of [0, 1500, 5000]) {
    if (delayMs) await new Promise((resolve) => setTimeout(resolve, delayMs))
    const { error } = await supabase.rpc('upsert_device_token', {
      p_session_token: sessionToken,
      p_platform: platform,
      p_token: token,
      p_device_id: null,
    })
    if (!error) return
    lastError = error
  }

  throw lastError instanceof Error ? lastError : new Error(String(lastError ?? 'Push token sync failed'))
}

// يسجّل الجهاز لاستقبال الإشعارات ويحفظ الرمز في قاعدة البيانات مربوطاً بالجلسة.
// آمن للاستدعاء دائماً: يخرج بهدوء إن لم تتوفّر الشروط.
export async function registerPushNotifications(sessionToken: string): Promise<void> {
  if (!ENABLED_FLAG || !sessionToken || !supabase) return
  const platform = getNativePlatform()
  if (!platform) return

  activeSessionToken = sessionToken
  activePlatform = platform

  // Rebind an already-issued native token when the active customer changes
  // without restarting the application process.
  if (latestDeviceToken) {
    try {
      await syncDeviceToken(latestDeviceToken, sessionToken, platform)
    } catch (e) {
      console.error('Push token sync failed:', (e as Error).message)
    }
  }
  if (nativeRegistrationStarted) return

  try {
    let perm = await PushNotifications.checkPermissions()
    if (perm.receive !== 'granted') perm = await PushNotifications.requestPermissions()
    if (perm.receive !== 'granted') return

    if (platform === 'android') {
      await PushNotifications.createChannel({
        id: 'otlobli_general',
        name: 'إشعارات otlobli',
        description: 'تحديثات الطلبات والتنبيهات المهمة من otlobli',
        importance: 5,
        visibility: 1,
        lights: true,
        lightColor: '#007A55',
        vibration: true,
      })
    }

    await PushNotifications.addListener('registration', (data) => {
      const token = data.value
      if (!token || !activeSessionToken || !activePlatform) return
      latestDeviceToken = token
      void syncDeviceToken(token, activeSessionToken, activePlatform).catch((e: unknown) => {
        console.error('Push token sync failed:', e instanceof Error ? e.message : String(e))
      })
    })

    await PushNotifications.addListener('registrationError', (err) => {
      console.error('Push registration error:', err)
    })

    nativeRegistrationStarted = true
    await PushNotifications.register()
  } catch (e) {
    nativeRegistrationStarted = false
    console.error('Push setup failed:', (e as Error).message)
  }
}
