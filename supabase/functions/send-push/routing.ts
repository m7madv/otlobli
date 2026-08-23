export type PushPlatform = 'android' | 'ios'
export type PushProvider = 'fcm' | 'apns'

export type PushProviderReadiness = {
  fcm: boolean
  apns: boolean
}

const APNS_PEM_BEGIN = ['-----BEGIN', 'PRIVATE KEY-----'].join(' ')
const APNS_PEM_END = ['-----END', 'PRIVATE KEY-----'].join(' ')

export function normalizeApnsPrivateKey(rawValue: string): string {
  const value = rawValue.trim()
  if (!value) return ''

  // Secret dashboards and CLIs commonly preserve newlines either literally or
  // as escaped `\n`. Accept both without ever logging the private material.
  const expanded = value.includes('\\n') ? value.replace(/\\n/g, '\n') : value
  if (expanded.startsWith(APNS_PEM_BEGIN) && expanded.endsWith(APNS_PEM_END)) {
    return expanded
  }

  // Prefer a single-line base64 secret in production. It survives shell/env
  // transport reliably while decoding back to the exact one-time Apple PEM.
  try {
    const bytes = Uint8Array.from(atob(value), (char) => char.charCodeAt(0))
    const decoded = new TextDecoder().decode(bytes).trim()
    if (decoded.startsWith(APNS_PEM_BEGIN) && decoded.endsWith(APNS_PEM_END)) {
      return decoded
    }
  } catch {
    // Return the expanded input so WebCrypto rejects malformed material safely.
  }
  return expanded
}

export function providerForPushDevice(
  platform: string,
  readiness: PushProviderReadiness,
): PushProvider | null {
  if (platform === 'ios') return readiness.apns ? 'apns' : null
  if (platform === 'android') return readiness.fcm ? 'fcm' : null
  return null
}
