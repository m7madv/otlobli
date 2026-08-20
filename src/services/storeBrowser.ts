import { Capacitor, registerPlugin } from '@capacitor/core'
import { InAppBrowser as CapgoInAppBrowser } from '@capgo/capacitor-inappbrowser'
import { SHEIN_CLEAN_ROOM_DIAGNOSTICS } from '../config'

type ListenerHandle = { remove: () => Promise<void> }
type OpenOptions = Parameters<typeof CapgoInAppBrowser.openWebView>[0]
type CloseOptions = Parameters<typeof CapgoInAppBrowser.close>[0]
type SetUrlOptions = Parameters<typeof CapgoInAppBrowser.setUrl>[0]
type ExecuteScriptOptions = Parameters<typeof CapgoInAppBrowser.executeScript>[0]
type PostMessageOptions = Parameters<typeof CapgoInAppBrowser.postMessage>[0]

interface NativeSheinBrowserApi {
  openWebView(options: OpenOptions): Promise<{
    id?: string
    implementation?: 'clean-controller' | 'legacy-control'
    mode?: string
    runId?: string
  }>
  show(): Promise<void>
  hide(): Promise<void>
  close(options?: CloseOptions): Promise<void>
  setUrl(options: SetUrlOptions): Promise<void>
  executeScript(options: ExecuteScriptOptions): Promise<void>
  postMessage(options: PostMessageOptions): Promise<void>
  clearCache(): Promise<void>
  addListener(
    eventName: string,
    listener: (event: Record<string, unknown>) => void,
  ): Promise<ListenerHandle>
}

const NativeSheinBrowser = registerPlugin<NativeSheinBrowserApi>('OtlobliSheinBrowser')
const CleanSheinBrowser = registerPlugin<NativeSheinBrowserApi>('SheinCleanBrowser')
const isIos = () => Capacitor.getPlatform() === 'ios'
const isSheinUrl = (url: string) => /^https?:\/\/(?:[^/]+\.)?shein\.com(?:[/:?#]|$)/i.test(url)
const isNativeSheinId = (id?: string) => !!id && id.startsWith('otlobli-shein-')
const isCleanSheinId = (id?: string) => !!id && id.startsWith('otlobli-shein-clean-')

let activeBackend: 'capgo' | 'native-shein' | 'clean-shein' | 'none' = 'none'
let activeNativeId = ''

const isCleanBackendActive = (id?: string) =>
  isIos() && (isCleanSheinId(id) || (!id && activeBackend === 'clean-shein'))
const isLegacyNativeBackendActive = (id?: string) =>
  isIos() && ((isNativeSheinId(id) && !isCleanSheinId(id)) || (!id && activeBackend === 'native-shein'))

/**
 * One store-facing API with a clean platform boundary:
 * - iOS SHEIN uses Otlobli's dedicated WKWebView implementation.
 * - Android and non-SHEIN surfaces retain the existing Capgo plugin.
 */
export const StoreBrowser = {
  isCleanSheinSession() {
    return activeBackend === 'clean-shein'
  },

  async openWebView(options: OpenOptions) {
    if (isIos() && isSheinUrl(options.url)) {
      if (SHEIN_CLEAN_ROOM_DIAGNOSTICS) {
        const cleanResult = await CleanSheinBrowser.openWebView(options)
        if (cleanResult.implementation !== 'legacy-control') {
          activeBackend = 'clean-shein'
          activeNativeId = cleanResult.id ?? ''
          return cleanResult
        }
      }
      const result = await NativeSheinBrowser.openWebView(options)
      activeBackend = 'native-shein'
      activeNativeId = result.id ?? ''
      return result
    }
    const result = await CapgoInAppBrowser.openWebView(options)
    activeBackend = 'capgo'
    activeNativeId = ''
    return result
  },

  show() {
    if (isCleanBackendActive()) return CleanSheinBrowser.show()
    return isLegacyNativeBackendActive() ? NativeSheinBrowser.show() : CapgoInAppBrowser.show()
  },

  hide() {
    if (isCleanBackendActive()) return CleanSheinBrowser.hide()
    return isLegacyNativeBackendActive() ? NativeSheinBrowser.hide() : CapgoInAppBrowser.hide()
  },

  async close(options?: CloseOptions) {
    if (isCleanBackendActive(options?.id)) {
      await CleanSheinBrowser.close(options)
      if (!options?.id || options.id === activeNativeId) {
        activeBackend = 'none'
        activeNativeId = ''
      }
      return
    }
    if (isLegacyNativeBackendActive(options?.id)) {
      await NativeSheinBrowser.close(options)
      if (!options?.id || options.id === activeNativeId) {
        activeBackend = 'none'
        activeNativeId = ''
      }
      return
    }
    await CapgoInAppBrowser.close(options)
    if (!options?.id) activeBackend = 'none'
  },

  setUrl(options: SetUrlOptions) {
    if (isCleanBackendActive(options.id)) return CleanSheinBrowser.setUrl(options)
    return isLegacyNativeBackendActive(options.id)
      ? NativeSheinBrowser.setUrl(options)
      : CapgoInAppBrowser.setUrl(options)
  },

  executeScript(options: ExecuteScriptOptions) {
    if (isCleanBackendActive(options.id)) return CleanSheinBrowser.executeScript(options)
    return isLegacyNativeBackendActive(options.id)
      ? NativeSheinBrowser.executeScript(options)
      : CapgoInAppBrowser.executeScript(options)
  },

  postMessage(options: PostMessageOptions) {
    if (isCleanBackendActive(options.id)) return CleanSheinBrowser.postMessage(options)
    return isLegacyNativeBackendActive(options.id)
      ? NativeSheinBrowser.postMessage(options)
      : CapgoInAppBrowser.postMessage(options)
  },

  async clearCache() {
    if (!isIos()) return CapgoInAppBrowser.clearCache()
    // Cache is not session state. Clear both possible iOS browser owners while
    // preserving cookies/localStorage in WKWebsiteDataStore.default().
    await Promise.all([
      NativeSheinBrowser.clearCache(),
      CapgoInAppBrowser.clearCache(),
    ])
  },

  async addListener<T extends object>(eventName: string, listener: (event: T) => void): Promise<ListenerHandle> {
    const handles: ListenerHandle[] = []
    const capgoHandle = await CapgoInAppBrowser.addListener(
      eventName as Parameters<typeof CapgoInAppBrowser.addListener>[0],
      listener as never,
    )
    handles.push(capgoHandle)

    if (isIos()) {
      const nativeHandle = await NativeSheinBrowser.addListener(eventName, (event) => {
        if (eventName === 'closeEvent' && event.id === activeNativeId) {
          activeBackend = 'none'
          activeNativeId = ''
        }
        listener(event as T)
      })
      handles.push(nativeHandle)

      const cleanHandle = await CleanSheinBrowser.addListener(eventName, (event) => {
        if (eventName === 'closeEvent' && event.id === activeNativeId) {
          activeBackend = 'none'
          activeNativeId = ''
        }
        listener(event as T)
      })
      handles.push(cleanHandle)
    }

    return {
      remove: async () => {
        await Promise.all(handles.map((handle) => handle.remove()))
      },
    }
  },
}
