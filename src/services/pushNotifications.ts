import { Capacitor, registerPlugin } from '@capacitor/core'
import type { PluginListenerHandle } from '@capacitor/core'
import { PushNotifications } from '@capacitor/push-notifications'
import type { ActionPerformed, Token } from '@capacitor/push-notifications'
import { APP_VERSION, cleanEnvValue } from '../config'
import { supabase } from './supabaseClient'
import { parseSafePushPayload } from './pushPayload'
import type { SafePushDestination } from './pushPayload'

const ENABLED_FLAG = cleanEnvValue(import.meta.env.VITE_PUSH_ENABLED) !== 'false'
const INSTALLATION_KEY = 'otlobli_push_installation_id_v1'
const PERMISSION_PROMPTED_KEY = 'otlobli_push_permission_prompted_v1'

type NativePlatform = 'android' | 'ios'
export type PushPermissionState = 'granted' | 'denied' | 'prompt' | 'unsupported'
export type { SafePushDestination } from './pushPayload'

type SettingsPlugin = {
  openAppSettings(): Promise<void>
  clearBadge(): Promise<void>
  getPushContext(): Promise<{ environment: 'development' | 'production'; osVersion: string }>
}

const NativeSettings = registerPlugin<SettingsPlugin>('OtlobliSettings')
const routeListeners = new Set<(destination: SafePushDestination) => void>()
let nativeRegistrationStarted = false
let listenersInstalled = false
let activeSessionToken = ''
let activePlatform: NativePlatform | null = null
let latestDeviceToken = ''
let listenerHandles: PluginListenerHandle[] = []
let pushContextPromise: Promise<{ environment: 'development' | 'production'; osVersion: string }> | null = null

function nativePlatform(): NativePlatform | null {
  const platform = Capacitor.getPlatform()
  return platform === 'android' || platform === 'ios' ? platform : null
}

function installationId(): string {
  const existing = localStorage.getItem(INSTALLATION_KEY)?.trim()
  if (existing) return existing
  const value = globalThis.crypto?.randomUUID?.()
    ?? `install-${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 14)}`
  localStorage.setItem(INSTALLATION_KEY, value)
  return value
}

function normalizedPermission(receive: string | undefined): PushPermissionState {
  if (receive === 'granted') return 'granted'
  if (receive === 'denied') return 'denied'
  return 'prompt'
}

async function getPushContext(platform: NativePlatform): Promise<{
  environment: 'development' | 'production'
  osVersion: string
}> {
  if (platform !== 'ios') {
    return { environment: import.meta.env.PROD ? 'production' : 'development', osVersion: '' }
  }
  pushContextPromise ??= NativeSettings.getPushContext().catch(() => ({
    environment: import.meta.env.PROD ? 'production' as const : 'development' as const,
    osVersion: '',
  }))
  return pushContextPromise
}

function emitSafeRoute(data: Record<string, unknown> | undefined): void {
  const destination = parseSafePushPayload(data)
  if (!destination) return
  for (const listener of routeListeners) listener(destination)
}

async function syncDeviceToken(token: string, sessionToken: string, platform: NativePlatform): Promise<void> {
  if (!supabase || !token || !sessionToken) return
  const provider = platform === 'ios' ? 'apns' : 'fcm'
  const timezone = Intl.DateTimeFormat().resolvedOptions().timeZone || ''
  const locale = navigator.language || ''
  const pushContext = await getPushContext(platform)

  let lastError: unknown = null
  for (const delayMs of [0, 1500, 5000]) {
    if (delayMs) await new Promise((resolve) => setTimeout(resolve, delayMs))
    const { error } = await supabase.rpc('upsert_device_token_v2', {
      p_session_token: sessionToken,
      p_installation_id: installationId(),
      p_platform: platform,
      p_provider: provider,
      p_token: token,
      p_environment: pushContext.environment,
      p_app_version: APP_VERSION,
      p_os_version: pushContext.osVersion,
      p_locale: locale,
      p_timezone: timezone,
    })
    if (!error) return

    // Temporary compatibility until the production v2 migration is applied.
    if (/upsert_device_token_v2|schema cache|could not find/i.test(error.message)) {
      const fallback = await supabase.rpc('upsert_device_token', {
        p_session_token: sessionToken,
        p_platform: platform,
        p_token: token,
        p_device_id: installationId(),
      })
      if (!fallback.error) return
      lastError = fallback.error
    } else {
      lastError = error
    }
  }
  throw lastError instanceof Error ? lastError : new Error('push_token_sync_failed')
}

async function onRegistration(data: Token): Promise<void> {
  const token = data.value?.trim()
  if (!token) return
  latestDeviceToken = token
  // Keep a rotation that arrives while logged out. The next authenticated
  // session can attach this current token instead of reviving the stale one.
  if (!activeSessionToken || !activePlatform) return
  try {
    await syncDeviceToken(token, activeSessionToken, activePlatform)
  } catch {
    console.error('push_token_sync_failed')
  }
}

async function installListeners(): Promise<void> {
  if (listenersInstalled) return
  listenerHandles = [
    await PushNotifications.addListener('registration', (data) => { void onRegistration(data) }),
    await PushNotifications.addListener('registrationError', () => { console.error('push_registration_failed') }),
    await PushNotifications.addListener('pushNotificationReceived', () => {
      // Foreground display is controlled by Capacitor presentationOptions.
    }),
    await PushNotifications.addListener('pushNotificationActionPerformed', (action: ActionPerformed) => {
      emitSafeRoute(action.notification.data as Record<string, unknown> | undefined)
      void clearPushBadge()
    }),
  ]
  listenersInstalled = true
}

async function beginNativeRegistration(): Promise<void> {
  if (nativeRegistrationStarted) return
  await installListeners()
  if (activePlatform === 'android') {
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
  nativeRegistrationStarted = true
  try {
    await PushNotifications.register()
  } catch (error) {
    nativeRegistrationStarted = false
    throw error
  }
}

export async function getPushPermissionStatus(): Promise<PushPermissionState> {
  if (!ENABLED_FLAG || !nativePlatform()) return 'unsupported'
  try {
    const permission = await PushNotifications.checkPermissions()
    return normalizedPermission(permission.receive)
  } catch {
    return 'unsupported'
  }
}

export async function requestPushPermission(sessionToken = activeSessionToken): Promise<PushPermissionState> {
  const platform = nativePlatform()
  if (!ENABLED_FLAG || !platform) return 'unsupported'
  activeSessionToken = sessionToken
  activePlatform = platform
  let permission = await PushNotifications.checkPermissions()
  if (permission.receive !== 'granted' && permission.receive !== 'denied') {
    localStorage.setItem(PERMISSION_PROMPTED_KEY, '1')
    permission = await PushNotifications.requestPermissions()
  }
  const state = normalizedPermission(permission.receive)
  if (state === 'granted') await beginNativeRegistration()
  return state
}

export async function registerPushNotifications(sessionToken: string): Promise<void> {
  const platform = nativePlatform()
  if (!ENABLED_FLAG || !sessionToken || !supabase || !platform) return
  activeSessionToken = sessionToken
  activePlatform = platform
  if (latestDeviceToken) await syncDeviceToken(latestDeviceToken, sessionToken, platform)

  const permission = await PushNotifications.checkPermissions()
  if (permission.receive === 'granted') {
    await beginNativeRegistration()
    return
  }
  if (permission.receive !== 'denied' && localStorage.getItem(PERMISSION_PROMPTED_KEY) !== '1') {
    await requestPushPermission(sessionToken)
  }
}

export async function detachPushToken(sessionToken: string): Promise<void> {
  if (!supabase || !sessionToken || !nativePlatform()) return
  await supabase.rpc('detach_device_token', {
    p_session_token: sessionToken,
    p_installation_id: installationId(),
  })
  activeSessionToken = ''
}

export async function openPushSettings(): Promise<void> {
  if (!nativePlatform()) return
  await NativeSettings.openAppSettings()
}

export async function clearPushBadge(): Promise<void> {
  if (!nativePlatform()) return
  await Promise.allSettled([
    NativeSettings.clearBadge(),
    PushNotifications.removeAllDeliveredNotifications(),
  ])
}

export function addPushRouteListener(listener: (destination: SafePushDestination) => void): () => void {
  routeListeners.add(listener)
  return () => routeListeners.delete(listener)
}

export async function disposePushNotifications(): Promise<void> {
  for (const handle of listenerHandles) await handle.remove()
  listenerHandles = []
  listenersInstalled = false
  nativeRegistrationStarted = false
}
