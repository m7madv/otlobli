import { Capacitor, registerPlugin } from '@capacitor/core'
import { InAppBrowser as CapgoInAppBrowser } from '@capgo/capacitor-inappbrowser'

type ListenerHandle = { remove: () => Promise<void> }
type OpenOptions = Parameters<typeof CapgoInAppBrowser.openWebView>[0]
type CloseOptions = Parameters<typeof CapgoInAppBrowser.close>[0]
type SetUrlOptions = Parameters<typeof CapgoInAppBrowser.setUrl>[0]
type ExecuteScriptOptions = Parameters<typeof CapgoInAppBrowser.executeScript>[0]
type PostMessageOptions = Parameters<typeof CapgoInAppBrowser.postMessage>[0]

interface NativeSheinBrowserApi {
  openWebView(options: OpenOptions): Promise<{ id?: string }>
  show(): Promise<void>
  hide(): Promise<void>
  close(options?: CloseOptions): Promise<void>
  setUrl(options: SetUrlOptions): Promise<void>
  executeScript(options: ExecuteScriptOptions): Promise<void>
  postMessage(options: PostMessageOptions): Promise<void>
  clearCache(): Promise<void>
  recordDiagnostic(options: { detail: Record<string, unknown> }): Promise<void>
  addListener(
    eventName: string,
    listener: (event: Record<string, unknown>) => void,
  ): Promise<ListenerHandle>
}

const NativeSheinBrowser = registerPlugin<NativeSheinBrowserApi>('OtlobliSheinBrowser')
const isIos = () => Capacitor.getPlatform() === 'ios'
const isSheinUrl = (url: string) => /^https?:\/\/(?:[^/]+\.)?shein\.com(?:[/:?#]|$)/i.test(url)
const isNativeSheinId = (id?: string) => !!id && id.startsWith('otlobli-shein-')

let activeBackend: 'capgo' | 'native-shein' | 'none' = 'none'
let activeNativeId = ''

const useNativeBackend = (id?: string) =>
  isIos() && (isNativeSheinId(id) || (!id && activeBackend === 'native-shein'))

/**
 * One store-facing API with a clean platform boundary:
 * - iOS SHEIN uses Otlobli's dedicated WKWebView implementation.
 * - Android and non-SHEIN surfaces retain the existing Capgo plugin.
 */
export const StoreBrowser = {
  async openWebView(options: OpenOptions) {
    if (isIos() && isSheinUrl(options.url)) {
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
    return useNativeBackend() ? NativeSheinBrowser.show() : CapgoInAppBrowser.show()
  },

  hide() {
    return useNativeBackend() ? NativeSheinBrowser.hide() : CapgoInAppBrowser.hide()
  },

  async close(options?: CloseOptions) {
    if (useNativeBackend(options?.id)) {
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
    return useNativeBackend(options.id)
      ? NativeSheinBrowser.setUrl(options)
      : CapgoInAppBrowser.setUrl(options)
  },

  executeScript(options: ExecuteScriptOptions) {
    return useNativeBackend(options.id)
      ? NativeSheinBrowser.executeScript(options)
      : CapgoInAppBrowser.executeScript(options)
  },

  postMessage(options: PostMessageOptions) {
    return useNativeBackend(options.id)
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

  recordDiagnostic(detail: Record<string, unknown>) {
    if (!isIos()) return Promise.resolve()
    return NativeSheinBrowser.recordDiagnostic({ detail })
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
    }

    return {
      remove: async () => {
        await Promise.all(handles.map((handle) => handle.remove()))
      },
    }
  },
}
