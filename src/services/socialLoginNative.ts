import { Capacitor } from '@capacitor/core'
import { SocialLogin } from '@capgo/capacitor-social-login'
import { cleanEnvValue } from '../config'

export const GOOGLE_WEB_CLIENT_ID = cleanEnvValue(import.meta.env.VITE_GOOGLE_WEB_CLIENT_ID)
  || '677396296147-o5q0rt5qk2rq0rqh714kuki7gabkdmcu.apps.googleusercontent.com'
export const GOOGLE_IOS_CLIENT_ID = cleanEnvValue(import.meta.env.VITE_GOOGLE_IOS_CLIENT_ID)
export const APPLE_ANDROID_CLIENT_ID = cleanEnvValue(import.meta.env.VITE_APPLE_ANDROID_CLIENT_ID)
export const APPLE_ANDROID_REDIRECT_URL = cleanEnvValue(import.meta.env.VITE_APPLE_ANDROID_REDIRECT_URL)

function isSecureAppleRedirect(value: string): boolean {
  try {
    const url = new URL(value)
    return url.protocol === 'https:' && !url.username && !url.password && !url.hash
  } catch {
    return false
  }
}

export const isAndroidAppleConfigured = !!APPLE_ANDROID_CLIENT_ID
  && isSecureAppleRedirect(APPLE_ANDROID_REDIRECT_URL)

let initialization: Promise<void> | null = null

export function initializeSocialLogin(): Promise<void> {
  if (initialization) return initialization
  const platform = Capacitor.getPlatform()
  const google = {
      webClientId: GOOGLE_WEB_CLIENT_ID,
      iOSClientId: GOOGLE_IOS_CLIENT_ID || undefined,
      iOSServerClientId: GOOGLE_WEB_CLIENT_ID,
      mode: 'online' as const,
  }
  const options = platform === 'ios'
    ? {
        ...(GOOGLE_IOS_CLIENT_ID ? { google } : {}),
        apple: { clientId: 'com.otlobli.app', useProperTokenExchange: true },
      }
    : {
        google,
        ...(platform === 'android' && isAndroidAppleConfigured
          ? {
              apple: {
                // Android uses Apple's web flow. This must be a Services ID
                // and an allowlisted HTTPS callback; token exchange remains
                // exclusively on the Otlobli backend.
                clientId: APPLE_ANDROID_CLIENT_ID,
                redirectUrl: APPLE_ANDROID_REDIRECT_URL,
                useProperTokenExchange: true,
                useBroadcastChannel: false,
              },
            }
          : {}),
      }
  initialization = SocialLogin.initialize(options).catch((error) => {
    initialization = null
    throw error
  })
  return initialization
}

export async function signOutNativeIdentityProviders(): Promise<void> {
  await initializeSocialLogin().catch(() => undefined)
  await Promise.allSettled([
    SocialLogin.logout({ provider: 'google' }),
    ...(Capacitor.getPlatform() === 'ios' || (Capacitor.getPlatform() === 'android' && isAndroidAppleConfigured)
      ? [SocialLogin.logout({ provider: 'apple' })]
      : []),
  ])
}

export { SocialLogin }
