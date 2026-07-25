// تسجيل إشعارات Push (واجهة العميل).
// خامل تماماً حتى: (1) تُثبَّت @capacitor/push-notifications، (2) يُضبط
// VITE_PUSH_ENABLED=true، (3) يعمل داخل تطبيق أصلي (أندرويد/iOS) لا الويب.
// الاستيراد ديناميكي محروس بـ @vite-ignore حتى يمرّ بناء الويب دون تثبيت الإضافة.
import { cleanEnvValue } from '../config'
import { supabase } from './supabaseClient'

const ENABLED_FLAG = cleanEnvValue(import.meta.env.VITE_PUSH_ENABLED) === 'true'

let registered = false

// يقرأ المنصّة من Capacitor إن توفّر (native فقط).
async function getNativePlatform(): Promise<'android' | 'ios' | null> {
  try {
    const pkg = '@capacitor/core'
    const mod = (await import(/* @vite-ignore */ pkg)) as { Capacitor?: { getPlatform: () => string } }
    const platform = mod.Capacitor?.getPlatform?.() ?? 'web'
    if (platform === 'android' || platform === 'ios') return platform
    return null
  } catch {
    return null
  }
}

// يسجّل الجهاز لاستقبال الإشعارات ويحفظ الرمز في قاعدة البيانات مربوطاً بالجلسة.
// آمن للاستدعاء دائماً: يخرج بهدوء إن لم تتوفّر الشروط.
export async function registerPushNotifications(sessionToken: string): Promise<void> {
  if (!ENABLED_FLAG || !sessionToken || registered || !supabase) return
  const platform = await getNativePlatform()
  if (!platform) return

  try {
    const pkg = '@capacitor/push-notifications'
    const mod = (await import(/* @vite-ignore */ pkg)) as {
      PushNotifications: {
        checkPermissions: () => Promise<{ receive: string }>
        requestPermissions: () => Promise<{ receive: string }>
        register: () => Promise<void>
        addListener: (event: string, cb: (data: unknown) => void) => void
      }
    }
    const Push = mod.PushNotifications

    let perm = await Push.checkPermissions()
    if (perm.receive !== 'granted') perm = await Push.requestPermissions()
    if (perm.receive !== 'granted') return

    Push.addListener('registration', (data: unknown) => {
      const token = (data as { value?: string })?.value
      if (!token) return
      void supabase!.rpc('upsert_device_token', {
        p_session_token: sessionToken,
        p_platform: platform,
        p_token: token,
        p_device_id: null,
      })
    })

    Push.addListener('registrationError', (err: unknown) => {
      console.error('Push registration error:', err)
    })

    registered = true
    await Push.register()
  } catch (e) {
    console.error('Push setup failed:', (e as Error).message)
  }
}
