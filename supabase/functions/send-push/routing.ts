export type PushPlatform = 'android' | 'ios'
export type PushProvider = 'fcm' | 'apns'

export type PushProviderReadiness = {
  fcm: boolean
  apns: boolean
}

export function providerForPushDevice(
  platform: string,
  readiness: PushProviderReadiness,
): PushProvider | null {
  if (platform === 'ios') return readiness.apns ? 'apns' : null
  if (platform === 'android') return readiness.fcm ? 'fcm' : null
  return null
}
