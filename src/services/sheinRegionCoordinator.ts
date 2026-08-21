export type SheinCoordinatorPhase =
  | 'IDLE'
  | 'OPENING'
  | 'INSTALLING_POLICY'
  | 'APPLYING_REQUIRED_STATE'
  | 'NAVIGATING'
  | 'HUMAN_VERIFICATION'
  | 'VERIFYING'
  | 'READY'
  | 'REPAIRING_ONCE'
  | 'FAILED'
  | 'CLOSED'

export type MatchState = 'unknown' | 'matching' | 'mismatch'
export type LoginState = 'unknown' | 'not-required' | 'blocked' | 'detected'
export type HumanVerificationState = 'none' | 'required' | 'resolved'
export type PolicyState = 'unknown' | 'installing' | 'installed' | 'verified' | 'mismatch'
export type CaptureState = 'unknown' | 'installing' | 'ready' | 'failed'

export type SheinRequiredState = {
  countryCode: string
  currency: string
  language: string
}
export type SheinRegionSnapshot = {
  countryState?: MatchState
  regionState?: MatchState
  currencyState?: MatchState
  languageState?: MatchState
  loginState?: LoginState
  humanVerificationState?: HumanVerificationState
  policyState?: PolicyState
  captureState?: CaptureState
  interactive?: boolean
}

export type SheinRegionCoordinatorState = {
  phase: SheinCoordinatorPhase
  required: SheinRequiredState
  countryState: MatchState
  regionState: MatchState
  currencyState: MatchState
  languageState: MatchState
  loginState: LoginState
  humanVerificationState: HumanVerificationState
  policyState: PolicyState
  captureState: CaptureState
  interactive: boolean
  repairCount: 0 | 1
  failureCode: string
}

export type SheinCoordinatorEvent =
  | { type: 'OPEN'; required: SheinRequiredState }
  | { type: 'POLICY_INSTALLING' }
  | { type: 'NAVIGATION_STARTED' }
  | { type: 'SNAPSHOT'; snapshot: SheinRegionSnapshot }
  | { type: 'HUMAN_VERIFICATION_REQUIRED' }
  | { type: 'HUMAN_VERIFICATION_RESOLVED' }
  | { type: 'REPAIR_REQUIRED'; code: string }
  | { type: 'FAIL'; code: string }
  | { type: 'CLOSE' }

const normalizeRequired = (required: SheinRequiredState): SheinRequiredState => ({
  countryCode: required.countryCode.trim().toUpperCase(),
  currency: required.currency.trim().toUpperCase(),
  language: required.language.trim().toLowerCase(),
})

export const createSheinRegionCoordinator = (required: SheinRequiredState): SheinRegionCoordinatorState => ({
  phase: 'IDLE',
  required: normalizeRequired(required),
  countryState: 'unknown',
  regionState: 'unknown',
  currencyState: 'unknown',
  languageState: 'unknown',
  loginState: 'unknown',
  humanVerificationState: 'none',
  policyState: 'unknown',
  captureState: 'unknown',
  interactive: false,
  repairCount: 0,
  failureCode: '',
})

const hasMismatch = (state: SheinRegionCoordinatorState) =>
  state.countryState === 'mismatch' || state.regionState === 'mismatch' ||
  state.currencyState === 'mismatch' || state.languageState === 'mismatch' ||
  state.policyState === 'mismatch' || state.captureState === 'failed' || state.loginState === 'detected'

export const isSheinCoordinatorReady = (state: SheinRegionCoordinatorState) =>
  state.countryState === 'matching' && state.regionState === 'matching' &&
  state.currencyState === 'matching' && state.languageState === 'matching' &&
  (state.loginState === 'not-required' || state.loginState === 'blocked') &&
  state.policyState === 'verified' && state.captureState === 'ready' && state.interactive

// Visual readiness is deliberately narrower than "the DOM painted" but does
// not wait for SHEIN's signed shipping cascade. Browsing can be revealed while
// a missing country/region is repaired in the background; transaction capture
// remains fail-closed because full READY still requires both to match.
export const isSheinCoordinatorVisuallyReady = (state: SheinRegionCoordinatorState) =>
  state.countryState !== 'mismatch' && state.regionState !== 'mismatch' &&
  state.currencyState === 'matching' && state.languageState === 'matching' &&
  (state.loginState === 'not-required' || state.loginState === 'blocked') &&
  state.humanVerificationState !== 'required' &&
  state.policyState === 'verified' && state.captureState === 'ready' && state.interactive

export function transitionSheinRegionCoordinator(
  state: SheinRegionCoordinatorState,
  event: SheinCoordinatorEvent,
): SheinRegionCoordinatorState {
  if (event.type === 'OPEN') {
    return { ...createSheinRegionCoordinator(event.required), phase: 'OPENING' }
  }
  if (event.type === 'CLOSE') return { ...state, phase: 'CLOSED', interactive: false }
  if (state.phase === 'CLOSED') return state
  if (event.type === 'POLICY_INSTALLING') return { ...state, phase: 'INSTALLING_POLICY', policyState: 'installing' }
  if (event.type === 'NAVIGATION_STARTED') return { ...state, phase: 'NAVIGATING', interactive: false }
  if (event.type === 'HUMAN_VERIFICATION_REQUIRED') {
    return { ...state, phase: 'HUMAN_VERIFICATION', humanVerificationState: 'required', interactive: true }
  }
  if (event.type === 'HUMAN_VERIFICATION_RESOLVED') {
    return { ...state, phase: 'VERIFYING', humanVerificationState: 'resolved', interactive: false }
  }
  if (event.type === 'FAIL') return { ...state, phase: 'FAILED', failureCode: event.code, interactive: false }
  if (event.type === 'REPAIR_REQUIRED') {
    if (state.repairCount >= 1) return { ...state, phase: 'FAILED', failureCode: event.code, interactive: false }
    return { ...state, phase: 'REPAIRING_ONCE', repairCount: 1, failureCode: event.code, interactive: false }
  }

  const next: SheinRegionCoordinatorState = {
    ...state,
    ...event.snapshot,
    phase: state.phase === 'INSTALLING_POLICY' ? 'APPLYING_REQUIRED_STATE' : 'VERIFYING',
    failureCode: '',
  }
  if (next.humanVerificationState === 'required') return { ...next, phase: 'HUMAN_VERIFICATION', interactive: true }
  if (hasMismatch(next)) return { ...next, phase: 'FAILED', failureCode: 'required-state-mismatch', interactive: false }
  if (isSheinCoordinatorReady(next)) return { ...next, phase: 'READY' }
  return next
}
