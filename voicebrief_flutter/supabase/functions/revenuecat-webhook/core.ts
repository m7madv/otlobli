export interface MonthlyQuotaWindow {
  index: number;
  startsAt: string;
  endsAt: string;
  quotaMinutes: 300;
}

export interface RevenueCatSubscriptionSnapshot {
  isPro: boolean;
  productId: string;
  store: string;
  periodStartMs: number;
  periodEndMs: number;
  accessEndMs: number;
}

export type RevenueCatCustomerFetcher = (
  input: string | URL | Request,
  init?: RequestInit,
) => Promise<Response>;

export class RevenueCatCustomerError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "RevenueCatCustomerError";
  }
}

const MAX_MONTHLY_QUOTA_WINDOWS = 24;
const REVENUECAT_REQUEST_TIMEOUT_MS = 15_000;
const UUID_PATTERN =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const MAX_TRANSFER_IDENTIFIERS = 100;
const MAX_REVENUECAT_APP_USER_ID_LENGTH = 100;

function containsControlCharacter(value: string): boolean {
  for (let index = 0; index < value.length; index += 1) {
    const code = value.charCodeAt(index);
    if (code <= 31 || code === 127) return true;
  }
  return false;
}
const SUBSCRIPTION_STATE_EVENT_TYPES = new Set([
  "INITIAL_PURCHASE",
  "RENEWAL",
  "CANCELLATION",
  "UNCANCELLATION",
  "BILLING_ISSUE",
  "SUBSCRIPTION_PAUSED",
  "EXPIRATION",
  "PRODUCT_CHANGE",
  "SUBSCRIPTION_EXTENDED",
  "REFUND_REVERSED",
]);

export type RevenueCatEventMode =
  | "subscription_state"
  | "transfer"
  | "temporary_grant"
  | "ignore";

export function revenueCatEventMode(
  eventType: string,
): RevenueCatEventMode {
  if (eventType === "TRANSFER") return "transfer";
  if (eventType === "TEMPORARY_ENTITLEMENT_GRANT") {
    return "temporary_grant";
  }
  return SUBSCRIPTION_STATE_EVENT_TYPES.has(eventType)
    ? "subscription_state"
    : "ignore";
}

export function needsRevenueCatCustomerSnapshot(
  mode: RevenueCatEventMode,
): boolean {
  return mode !== "ignore";
}

export function quotaWindowLimitForProduct(productId: string): 1 | 12 {
  const baseProductId = productId.split(":", 1)[0];
  return baseProductId === "voicebrief_pro_annual" ? 12 : 1;
}

export function shouldCarrySubscriptionUsage(options: {
  eventType: string;
  previousEventType?: string | null;
  previousProductId?: string | null;
  productId: string;
  generationChanged: boolean;
  overlapsPreviousAccess: boolean;
}): boolean {
  if (!options.generationChanged || !options.overlapsPreviousAccess) {
    return false;
  }
  const startsPaidCycle = options.eventType === "INITIAL_PURCHASE" ||
    options.eventType === "RENEWAL" ||
    options.eventType === "SUBSCRIPTION_SYNC";
  return !startsPaidCycle ||
    options.previousEventType === "PRODUCT_CHANGE" ||
    options.previousEventType === "TEMPORARY_ENTITLEMENT_GRANT" ||
    options.previousProductId !== options.productId;
}

export function shouldRetryRevenueCatTransfer(
  destinationSnapshot: RevenueCatSubscriptionSnapshot,
  sourceSnapshots: RevenueCatSubscriptionSnapshot[],
): boolean {
  return !destinationSnapshot.isPro &&
    sourceSnapshots.some((snapshot) => snapshot.isPro);
}

function addUtcMonthsClamped(origin: Date, months: number): Date {
  const targetMonth = new Date(Date.UTC(
    origin.getUTCFullYear(),
    origin.getUTCMonth() + months,
    1,
    origin.getUTCHours(),
    origin.getUTCMinutes(),
    origin.getUTCSeconds(),
    origin.getUTCMilliseconds(),
  ));
  const lastDay = new Date(Date.UTC(
    targetMonth.getUTCFullYear(),
    targetMonth.getUTCMonth() + 1,
    0,
  )).getUTCDate();
  targetMonth.setUTCDate(Math.min(origin.getUTCDate(), lastDay));
  return targetMonth;
}

/// Builds anchored monthly quota windows for one active store period.
///
/// Monthly products produce one window and annual products normally produce
/// twelve. Clamping against the original purchase day prevents a January 31
/// subscription from drifting permanently to the 28th after February. An
/// optional grace/access end extends only the final window, never the quota
/// count.
export function monthlyQuotaWindows(
  periodStartMs: number,
  periodEndMs: number,
  maximumQuotaWindows: number,
  accessEndMs = periodEndMs,
): MonthlyQuotaWindow[] {
  if (
    !Number.isFinite(periodStartMs) || !Number.isFinite(periodEndMs) ||
    !Number.isFinite(accessEndMs) || periodStartMs < 0 ||
    periodEndMs <= periodStartMs || accessEndMs < periodEndMs ||
    !Number.isInteger(maximumQuotaWindows) || maximumQuotaWindows < 1 ||
    maximumQuotaWindows > MAX_MONTHLY_QUOTA_WINDOWS
  ) {
    throw new RangeError("invalid_subscription_period");
  }

  const origin = new Date(periodStartMs);
  const windows: MonthlyQuotaWindow[] = [];
  for (let index = 0; index < maximumQuotaWindows; index += 1) {
    const startsAt = addUtcMonthsClamped(origin, index);
    if (startsAt.getTime() >= periodEndMs) break;
    const naturalEnd = addUtcMonthsClamped(origin, index + 1);
    const naturalEndMs = Math.min(periodEndMs, naturalEnd.getTime());
    const isLastQuotaWindow = naturalEndMs >= periodEndMs ||
      index + 1 >= maximumQuotaWindows;
    const endsAt = new Date(
      isLastQuotaWindow ? accessEndMs : naturalEndMs,
    );
    if (endsAt.getTime() <= startsAt.getTime()) {
      throw new RangeError("invalid_subscription_period");
    }
    windows.push({
      index,
      startsAt: startsAt.toISOString(),
      endsAt: endsAt.toISOString(),
      quotaMinutes: 300,
    });
    if (isLastQuotaWindow) break;
  }

  if (
    windows.length === 0 ||
    Date.parse(windows[windows.length - 1].endsAt) < accessEndMs
  ) {
    throw new RangeError("subscription_period_too_long");
  }
  return windows;
}

export function voiceBriefUserIds(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  const ids = new Set<string>();
  for (const candidate of value) {
    if (typeof candidate === "string" && UUID_PATTERN.test(candidate)) {
      ids.add(candidate.toLowerCase());
    }
  }
  return [...ids];
}

export function revenueCatLookupIds(value: unknown): string[] {
  if (!Array.isArray(value) || value.length > MAX_TRANSFER_IDENTIFIERS) {
    throw new RevenueCatCustomerError("invalid_transfer_identifiers");
  }
  const ids = new Set<string>();
  for (const candidate of value) {
    if (
      typeof candidate !== "string" || candidate.length === 0 ||
      candidate.length > MAX_REVENUECAT_APP_USER_ID_LENGTH ||
      containsControlCharacter(candidate)
    ) {
      throw new RevenueCatCustomerError("invalid_transfer_identifier");
    }
    ids.add(candidate);
  }
  return [...ids];
}

export function revenueCatTransferIds(event: unknown): {
  destinationUserIds: string[];
  sourceUserIds: string[];
  sourceRevenueCatIds: string[];
} {
  if (!isRecord(event)) {
    throw new RevenueCatCustomerError("invalid_transfer_event");
  }
  const destinationRevenueCatIds = revenueCatLookupIds(event.transferred_to);
  const sourceRevenueCatIds = revenueCatLookupIds(event.transferred_from);
  const destinationUserIds = voiceBriefUserIds(destinationRevenueCatIds);
  if (destinationUserIds.length === 0) {
    throw new RevenueCatCustomerError("invalid_transfer_destination");
  }
  return {
    destinationUserIds,
    sourceUserIds: voiceBriefUserIds(sourceRevenueCatIds),
    sourceRevenueCatIds,
  };
}

export function resolveRevenueCatTransferDestination(
  destinationUserIds: string[],
  profileUserIds: string[],
): string {
  const candidates = new Set(destinationUserIds.map((id) => id.toLowerCase()));
  const matches = [...new Set(profileUserIds.map((id) => id.toLowerCase()))]
    .filter((id) => candidates.has(id));
  if (matches.length === 0) {
    throw new RevenueCatCustomerError("transfer_destination_profile_missing");
  }
  if (matches.length > 1) {
    throw new RevenueCatCustomerError("ambiguous_transfer_destination");
  }
  return matches[0];
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return value != null && typeof value === "object" && !Array.isArray(value);
}

function timestamp(value: unknown): number | null {
  if (typeof value !== "string") return null;
  const parsed = Date.parse(value);
  return Number.isFinite(parsed) ? parsed : null;
}

export function parseRevenueCatSubscriptionSnapshot(
  payload: unknown,
  options: {
    nowMs: number;
    eventTimestampMs: number;
    fallbackStore?: string;
  },
): RevenueCatSubscriptionSnapshot {
  if (!isRecord(payload) || !isRecord(payload.subscriber)) {
    throw new RevenueCatCustomerError("invalid_customer_response");
  }
  const subscriber = payload.subscriber;
  const entitlements = isRecord(subscriber.entitlements)
    ? subscriber.entitlements
    : {};
  const pro = isRecord(entitlements.pro) ? entitlements.pro : null;
  if (pro == null) {
    return {
      isPro: false,
      productId: "",
      store: options.fallbackStore ?? "unknown",
      periodStartMs: options.eventTimestampMs,
      periodEndMs: options.eventTimestampMs,
      accessEndMs: options.eventTimestampMs,
    };
  }

  const productId = typeof pro.product_identifier === "string" &&
      pro.product_identifier.length > 0
    ? pro.product_identifier
    : "revenuecat_temporary_entitlement";
  const subscriptions = isRecord(subscriber.subscriptions)
    ? subscriber.subscriptions
    : {};
  const exactSubscription = isRecord(subscriptions[productId])
    ? subscriptions[productId]
    : null;
  const matchingSubscription = exactSubscription ??
    Object.entries(subscriptions).find(([key, value]) =>
      isRecord(value) && key.split(":", 1)[0] === productId.split(":", 1)[0]
    )?.[1];
  const subscription = isRecord(matchingSubscription)
    ? matchingSubscription
    : null;
  const expirationCandidates = [
    timestamp(subscription?.expires_date),
    timestamp(pro.expires_date),
  ].filter((value): value is number => value != null);
  const periodEndMs = expirationCandidates.length === 0
    ? null
    : Math.max(...expirationCandidates);
  const graceEndMs = timestamp(subscription?.grace_period_expires_date) ??
    timestamp(pro.grace_period_expires_date);
  const accessEndMs = periodEndMs == null
    ? graceEndMs
    : Math.max(periodEndMs, graceEndMs ?? periodEndMs);
  if (
    periodEndMs == null || accessEndMs == null ||
    accessEndMs <= options.nowMs
  ) {
    return {
      isPro: false,
      productId: "",
      store: options.fallbackStore ?? "unknown",
      periodStartMs: options.eventTimestampMs,
      periodEndMs: options.eventTimestampMs,
      accessEndMs: options.eventTimestampMs,
    };
  }
  const purchaseDate = timestamp(subscription?.purchase_date) ??
    timestamp(pro.purchase_date) ?? options.eventTimestampMs;
  const periodStartMs = purchaseDate < periodEndMs
    ? purchaseDate
    : options.eventTimestampMs;
  monthlyQuotaWindows(
    periodStartMs,
    periodEndMs,
    quotaWindowLimitForProduct(productId),
    accessEndMs,
  );

  return {
    isPro: true,
    productId,
    store: typeof subscription?.store === "string"
      ? subscription.store
      : options.fallbackStore ?? "unknown",
    periodStartMs,
    periodEndMs,
    accessEndMs,
  };
}

export async function fetchRevenueCatSubscriptionSnapshot(
  appUserId: string,
  secretApiKey: string,
  options: {
    nowMs: number;
    eventTimestampMs: number;
    fallbackStore?: string;
    fetcher?: RevenueCatCustomerFetcher;
    timeoutMs?: number;
    allowCreatedCustomer?: boolean;
  },
): Promise<RevenueCatSubscriptionSnapshot> {
  if (secretApiKey.trim().length === 0) {
    throw new RevenueCatCustomerError("revenuecat_not_configured");
  }
  const fetcher = options.fetcher ?? fetch;
  const abortController = new AbortController();
  const timeout = setTimeout(
    () => abortController.abort(),
    options.timeoutMs ?? REVENUECAT_REQUEST_TIMEOUT_MS,
  );
  let response: Response;
  try {
    response = await fetcher(
      `https://api.revenuecat.com/v1/subscribers/${
        encodeURIComponent(appUserId)
      }`,
      {
        method: "GET",
        headers: {
          accept: "application/json",
          authorization: `Bearer ${secretApiKey}`,
        },
        redirect: "error",
        signal: abortController.signal,
      },
    );
  } catch (_error) {
    clearTimeout(timeout);
    throw new RevenueCatCustomerError("revenuecat_unavailable");
  }
  if (
    !response.ok ||
    (response.status === 201 && options.allowCreatedCustomer !== true)
  ) {
    clearTimeout(timeout);
    throw new RevenueCatCustomerError("revenuecat_unavailable");
  }
  let payload: unknown;
  try {
    payload = await response.json();
  } catch (_error) {
    throw new RevenueCatCustomerError("invalid_customer_response");
  } finally {
    clearTimeout(timeout);
  }
  return parseRevenueCatSubscriptionSnapshot(payload, options);
}
