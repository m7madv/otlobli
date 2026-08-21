export type PhoneAuthBackend = 'whatsapp-api' | 'local-mock' | 'unavailable'

export type PhoneAuthConfiguration = {
  mode: string
  isDevelopment: boolean
  localMockExplicitlyEnabled: boolean
}

/**
 * Production builds must never become authenticated through the in-memory
 * demo API merely because an environment variable is missing or misspelled.
 * The mock backend is therefore available only when development mode and both
 * explicit mock switches agree.
 */
export function resolvePhoneAuthBackend({
  mode,
  isDevelopment,
  localMockExplicitlyEnabled,
}: PhoneAuthConfiguration): PhoneAuthBackend {
  const normalizedMode = mode.trim().toLowerCase()

  // `inbound` is intentionally unavailable until its server-side message
  // listener and challenge completion flow exist end to end.
  if (normalizedMode === 'real') {
    return 'whatsapp-api'
  }

  if (normalizedMode === 'mock' && isDevelopment && localMockExplicitlyEnabled) {
    return 'local-mock'
  }

  return 'unavailable'
}
