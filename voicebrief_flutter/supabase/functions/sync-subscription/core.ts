import { boundedJson, BoundedJsonError } from "../_shared/bounded_json.ts";
import { sha256 } from "../_shared/http.ts";
import {
  parseRevenueCatSubscriptionSnapshot,
  RevenueCatCustomerError,
  type RevenueCatCustomerFetcher,
  type RevenueCatSubscriptionSnapshot,
} from "../revenuecat-webhook/core.ts";

export const SUBSCRIPTION_SYNC_EVENT_ID_PREFIX = "voicebrief-sync-v1-";
export const MAX_SUBSCRIPTION_SYNC_BODY_BYTES = 256;

export interface SubscriptionSyncRequestBody {
  expectedPro: boolean;
}

export interface RevenueCatSubscriptionSyncLookup {
  snapshot: RevenueCatSubscriptionSnapshot;
  createdCustomer: boolean;
}

export interface StoredSubscriptionState {
  entitlement: "pro" | "free";
  productId: string;
  quotaGenerationKey: string | null;
  revenueCatEventId: string | null;
  expiresAt: string | null;
}

export interface SubscriptionSyncRpcArguments {
  p_event_id: string;
  p_event_type: "SUBSCRIPTION_SYNC" | "EXPIRATION";
  p_user_id: string;
  p_is_pro: boolean;
  p_product_id: string;
  p_store: string;
  p_event_at: string;
  p_period_start: string;
  p_period_end: string;
  p_access_end: string;
}

export type ClaimedSubscriptionSyncResult =
  | { kind: "rate_limited" }
  | { kind: "pending"; snapshot: RevenueCatSubscriptionSnapshot }
  | {
    kind: "synced";
    snapshot: RevenueCatSubscriptionSnapshot;
    applied: boolean;
  };

/// Keeps the rate-limit claim before every external lookup or entitlement
/// mutation. expectedPro is only a fail-closed hint: it can delay a stale Free
/// response, but it can never turn a Free RevenueCat snapshot into Pro.
export async function executeClaimedSubscriptionSync(options: {
  expectedPro: boolean;
  claim: () => Promise<boolean>;
  fetchSnapshot: () => Promise<RevenueCatSubscriptionSyncLookup>;
  hasCurrentProGeneration: (
    snapshot: RevenueCatSubscriptionSnapshot,
  ) => Promise<boolean>;
  applySnapshot: (
    snapshot: RevenueCatSubscriptionSnapshot,
  ) => Promise<boolean>;
}): Promise<ClaimedSubscriptionSyncResult> {
  if (!await options.claim()) return { kind: "rate_limited" };
  const lookup = await options.fetchSnapshot();
  const snapshot = lookup.snapshot;
  if (
    !snapshot.isPro &&
    (options.expectedPro || lookup.createdCustomer)
  ) {
    return { kind: "pending", snapshot };
  }
  if (snapshot.isPro && !await options.hasCurrentProGeneration(snapshot)) {
    return { kind: "pending", snapshot };
  }
  if (snapshot.isPro) {
    // A matching server generation is already reconciled. Client input cannot
    // authorize a new Pro generation: only the signed webhook/TRANSFER path
    // may create it. Avoiding a redundant write also prevents a concurrent
    // transfer from being overwritten by an older customer snapshot.
    return { kind: "synced", snapshot, applied: false };
  }
  const applied = await options.applySnapshot(snapshot);
  return { kind: "synced", snapshot, applied };
}

/// RevenueCat's v1 customer endpoint returns 201 when the lookup itself creates
/// an empty customer. Preserve that signal so it can never immediately revoke
/// a just-restored Pro entitlement; a later 200 Free response remains
/// authoritative when expectedPro is false.
export async function fetchRevenueCatSubscriptionSyncLookup(
  appUserId: string,
  secretApiKey: string,
  options: {
    nowMs: number;
    eventTimestampMs: number;
    fetcher?: RevenueCatCustomerFetcher;
    timeoutMs?: number;
  },
): Promise<RevenueCatSubscriptionSyncLookup> {
  if (secretApiKey.trim().length === 0) {
    throw new RevenueCatCustomerError("revenuecat_not_configured");
  }
  const controller = new AbortController();
  const timeout = setTimeout(
    () => controller.abort(),
    options.timeoutMs ?? 15_000,
  );
  let response: Response;
  try {
    response = await (options.fetcher ?? fetch)(
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
        signal: controller.signal,
      },
    );
  } catch (_error) {
    clearTimeout(timeout);
    throw new RevenueCatCustomerError("revenuecat_unavailable");
  }
  if (!response.ok) {
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
  return {
    snapshot: parseRevenueCatSubscriptionSnapshot(payload, {
      nowMs: options.nowMs,
      eventTimestampMs: options.eventTimestampMs,
    }),
    createdCustomer: response.status === 201,
  };
}

export async function subscriptionSyncRequestBody(
  request: Request,
): Promise<SubscriptionSyncRequestBody> {
  const value = await boundedJson(request, MAX_SUBSCRIPTION_SYNC_BODY_BYTES);
  if (value == null || typeof value !== "object" || Array.isArray(value)) {
    throw new BoundedJsonError(400);
  }
  const record = value as Record<string, unknown>;
  if (
    Object.keys(record).length !== 1 ||
    typeof record.expectedPro !== "boolean"
  ) {
    throw new BoundedJsonError(400);
  }
  return { expectedPro: record.expectedPro };
}

function stringOrEmpty(value: unknown): string {
  return typeof value === "string" ? value : "";
}

function nullableString(value: unknown): string | null {
  return typeof value === "string" && value.length > 0 ? value : null;
}

export function normalizeStoredSubscriptionState(
  value: unknown,
): StoredSubscriptionState | null {
  if (value == null || typeof value !== "object" || Array.isArray(value)) {
    return null;
  }
  const record = value as Record<string, unknown>;
  return {
    entitlement: record.entitlement === "pro" ? "pro" : "free",
    productId: stringOrEmpty(record.product_id),
    quotaGenerationKey: nullableString(record.quota_generation_key),
    revenueCatEventId: nullableString(record.revenuecat_event_id),
    expiresAt: nullableString(record.expires_at),
  };
}

/// Active manual reconciliation is a paid-cycle event. The database compares
/// products and overlap to carry usage only for a genuine mid-cycle product
/// replacement, never merely because a new store period was observed.
export function subscriptionSyncEventType(
  snapshot: RevenueCatSubscriptionSnapshot,
): SubscriptionSyncRpcArguments["p_event_type"] {
  return snapshot.isPro ? "SUBSCRIPTION_SYNC" : "EXPIRATION";
}

function inactiveTransitionKey(
  previousState: StoredSubscriptionState | null,
): string {
  if (previousState?.entitlement !== "pro") return "free";
  return JSON.stringify([
    previousState.quotaGenerationKey ?? "unversioned",
    previousState.productId,
    previousState.expiresAt ?? "unknown",
    previousState.revenueCatEventId ?? "unknown",
  ]);
}

function storedStateMatchesActiveSnapshot(
  previousState: StoredSubscriptionState | null,
  snapshot: RevenueCatSubscriptionSnapshot,
): boolean {
  return snapshot.isPro && previousState?.entitlement === "pro" &&
    previousState.productId === snapshot.productId &&
    previousState.quotaGenerationKey != null &&
    previousState.expiresAt != null &&
    Date.parse(previousState.expiresAt) === snapshot.accessEndMs;
}

/// Produces an event identifier stable for the same RevenueCat snapshot.
///
/// A matching active period uses a canonical key based on authoritative store
/// boundaries. If local state moved away after that key was consumed, a
/// transition-scoped recovery key repairs it once and then converges back to
/// the canonical key. Free transitions likewise include the active local
/// event/generation and reuse their applied key after convergence.
export async function subscriptionSyncEventId(
  userId: string,
  snapshot: RevenueCatSubscriptionSnapshot,
  previousState: StoredSubscriptionState | null,
): Promise<string> {
  if (
    !snapshot.isPro && previousState?.entitlement === "free" &&
    previousState.revenueCatEventId?.startsWith(
      SUBSCRIPTION_SYNC_EVENT_ID_PREFIX,
    )
  ) {
    return previousState.revenueCatEventId;
  }

  const activeFingerprint = JSON.stringify([
    "active",
    userId.toLowerCase(),
    snapshot.productId,
    snapshot.store,
    snapshot.periodStartMs,
    snapshot.periodEndMs,
    snapshot.accessEndMs,
  ]);
  const fingerprint = snapshot.isPro
    ? storedStateMatchesActiveSnapshot(previousState, snapshot)
      ? activeFingerprint
      : JSON.stringify([
        "active-recovery",
        activeFingerprint,
        previousState?.entitlement ?? "missing",
        previousState?.productId ?? "missing",
        previousState?.quotaGenerationKey ?? "missing",
        previousState?.expiresAt ?? "missing",
        previousState?.revenueCatEventId ?? "missing",
      ])
    : JSON.stringify([
      "free",
      userId.toLowerCase(),
      inactiveTransitionKey(previousState),
    ]);
  return `${SUBSCRIPTION_SYNC_EVENT_ID_PREFIX}${await sha256(fingerprint)}`;
}

export function subscriptionSyncRpcArguments(options: {
  eventId: string;
  eventType: SubscriptionSyncRpcArguments["p_event_type"];
  userId: string;
  eventAtMs: number;
  snapshot: RevenueCatSubscriptionSnapshot;
}): SubscriptionSyncRpcArguments {
  if (!Number.isFinite(options.eventAtMs) || options.eventAtMs < 0) {
    throw new RangeError("invalid_event_timestamp");
  }
  const snapshot = options.snapshot;
  return {
    p_event_id: options.eventId,
    p_event_type: options.eventType,
    p_user_id: options.userId,
    p_is_pro: snapshot.isPro,
    p_product_id: snapshot.productId,
    p_store: snapshot.store,
    p_event_at: new Date(options.eventAtMs).toISOString(),
    p_period_start: new Date(snapshot.periodStartMs).toISOString(),
    p_period_end: new Date(snapshot.periodEndMs).toISOString(),
    p_access_end: new Date(snapshot.accessEndMs).toISOString(),
  };
}
