import { Capacitor } from '@capacitor/core'
import { SocialLogin } from '@capgo/capacitor-social-login'
import { cleanEnvValue } from '../config'

export const GOOGLE_WEB_CLIENT_ID = cleanEnvValue(import.meta.env.VITE_GOOGLE_WEB_CLIENT_ID)
  || '677396296147-o5q0rt5qk2rq0rqh714kuki7gabkdmcu.apps.googleusercontent.com'
export const GOOGLE_IOS_CLIENT_ID = cleanEnvValue(import.meta.env.VITE_GOOGLE_IOS_CLIENT_ID)

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
    : { google }
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
    ...(Capacitor.getPlatform() === 'ios' ? [SocialLogin.logout({ provider: 'apple' })] : []),
  ])
}

export { SocialLogin }
