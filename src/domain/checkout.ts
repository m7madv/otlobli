export type CheckoutBlockerCode = 'empty' | 'customization' | 'availability' | 'minimum'

export type CheckoutBlocker = {
  code: CheckoutBlockerCode
  remainingSyp?: number
}

export type CheckoutEligibility = {
  allowed: boolean
  blockers: CheckoutBlocker[]
  minimumSyp: number
  totalSyp: number
}

export function evaluateCheckoutEligibility({
  itemCount,
  totalSyp,
  minimumSyp,
  hasIncompleteCustomization,
  hasAvailabilityIssues,
}: {
  itemCount: number
  totalSyp: number
  minimumSyp: number
  hasIncompleteCustomization: boolean
  hasAvailabilityIssues: boolean
}): CheckoutEligibility {
  const normalizedItemCount = Math.max(0, Math.trunc(Number(itemCount) || 0))
  const normalizedTotal = Math.max(0, Math.round(Number(totalSyp) || 0))
  const normalizedMinimum = Math.max(0, Math.round(Number(minimumSyp) || 0))
  const blockers: CheckoutBlocker[] = []

  if (normalizedItemCount === 0) {
    blockers.push({ code: 'empty' })
  } else {
    if (hasIncompleteCustomization) blockers.push({ code: 'customization' })
    if (hasAvailabilityIssues) blockers.push({ code: 'availability' })
    if (normalizedTotal < normalizedMinimum) {
      blockers.push({
        code: 'minimum',
        remainingSyp: normalizedMinimum - normalizedTotal,
      })
    }
  }

  return {
    allowed: blockers.length === 0,
    blockers,
    minimumSyp: normalizedMinimum,
    totalSyp: normalizedTotal,
  }
}
