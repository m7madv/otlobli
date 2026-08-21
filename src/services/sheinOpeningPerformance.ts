export const SHEIN_OPENING_PHASES = [
  'userTap',
  'browserOpenRequested',
  'nativeBrowserCreatedShown',
  'policyInstallation',
  'regionStateApplication',
  'initialNavigationStart',
  'navigationCommit',
  'navigationFinish',
  'humanVerificationDetection',
  'regionVerification',
  'policyVerification',
  'captureReady',
  'storeVisibleInteractive',
] as const

export type SheinOpeningPhase = typeof SHEIN_OPENING_PHASES[number]
export type SheinOpeningTrace = {
  id: string
  startedAt: number
  marks: Partial<Record<SheinOpeningPhase, number>>
}
export type SheinOpeningRecord = {
  id: string
  totalMs: number
  durationsMs: Partial<Record<SheinOpeningPhase, number>>
  humanVerification: boolean
}

export const createSheinOpeningTrace = (at = Date.now()): SheinOpeningTrace => ({
  id: `shein-${at.toString(36)}`,
  startedAt: at,
  marks: { userTap: at },
})

export function markSheinOpeningPhase(trace: SheinOpeningTrace, phase: SheinOpeningPhase, at = Date.now()): SheinOpeningTrace {
  if (trace.marks[phase] !== undefined) return trace
  return { ...trace, marks: { ...trace.marks, [phase]: Math.max(trace.startedAt, at) } }
}

export function completeSheinOpeningTrace(trace: SheinOpeningTrace): SheinOpeningRecord | null {
  const end = trace.marks.storeVisibleInteractive
  if (end === undefined || end < trace.startedAt) return null
  const durationsMs: Partial<Record<SheinOpeningPhase, number>> = {}
  for (const phase of SHEIN_OPENING_PHASES) {
    const mark = trace.marks[phase]
    if (mark !== undefined) durationsMs[phase] = Math.max(0, Math.round(mark - trace.startedAt))
  }
  return {
    id: trace.id,
    totalMs: Math.round(end - trace.startedAt),
    durationsMs,
    humanVerification: trace.marks.humanVerificationDetection !== undefined,
  }
}

const percentile = (sorted: number[], ratio: number) => {
  if (sorted.length === 0) return null
  return sorted[Math.min(sorted.length - 1, Math.ceil(sorted.length * ratio) - 1)]
}

export function summarizeSheinOpeningRecords(records: SheinOpeningRecord[]) {
  const values = records.map((record) => record.totalMs).filter((value) => Number.isFinite(value) && value >= 0).sort((a, b) => a - b)
  return {
    samples: values.length,
    medianMs: percentile(values, 0.5),
    p95Ms: percentile(values, 0.95),
    slowestMs: values.length ? values[values.length - 1] : null,
  }
}

