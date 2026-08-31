import { createClient } from "@supabase/supabase-js";
import { decodeJwt, importPKCS8, SignJWT } from "jose";

const bundleId = "com.damanak.damanak";
const googleScope = "https://www.googleapis.com/auth/androidpublisher";
const maxPurchaseRequestBytes = 64 * 1024;
const appStoreProducts = new Set([
  "com.damanak.subscription.starter.monthly",
  "com.damanak.subscription.starter.yearly",
  "com.damanak.subscription.growth.monthly",
  "com.damanak.subscription.growth.yearly",
  "com.damanak.subscription.scale.monthly",
  "com.damanak.subscription.scale.yearly",
]);
const googlePlayProducts = new Set([
  "com.damanak.subscription.starter",
  "com.damanak.subscription.growth",
  "com.damanak.subscription.scale",
]);
const googlePlayBasePlans = new Set(["monthly", "yearly"]);

type PurchaseBody = {
  storeId?: string;
  refresh?: boolean;
  platform?: "app_store" | "google_play";
  productId?: string;
  basePlanId?: string | null;
  purchaseId?: string | null;
  transactionDate?: string | null;
  verificationData?: string;
  verificationSource?: string;
  knownOriginalTransactionId?: string;
  acknowledgeOnServer?: boolean;
};

export type VerifiedEntitlement = {
  platform: "app_store" | "google_play";
  productId: string;
  basePlanId: string;
  transactionId: string;
  originalTransactionId: string;
  status: "active" | "grace" | "past_due" | "canceled" | "expired" | "revoked";
  environment: "sandbox" | "production";
  periodStart: string | null;
  periodEnd: string | null;
  autoRenews: boolean;
  purchaseTokenHash?: string;
  linkedPurchaseTokenHash?: string | null;
  appleAccountToken?: string | null;
  googleAcknowledgementPending?: boolean;
  googleOutOfApp?: boolean;
};

export type VerificationFailure = {
  status: number;
  code:
    | "PURCHASE_NOT_VALID"
    | "PURCHASE_CONFLICT"
    | "STORE_PURCHASE_PENDING"
    | "STORE_PURCHASE_PENDING_CANCELED"
    | "SANDBOX_NOT_AVAILABLE"
    | "PURCHASE_PROVIDER_UNAVAILABLE"
    | "PURCHASE_VERIFICATION_UNAVAILABLE";
  retryable: boolean;
};

export class RequestBodyTooLargeError extends Error {}

function response(
  status: number,
  body: Record<string, unknown>,
  extraHeaders: Record<string, string> = {},
) {
  return Response.json(body, {
    status,
    headers: { "Cache-Control": "no-store", ...extraHeaders },
  });
}

function boundedRequestBody(request: Request, byteLimit: number) {
  if (!Number.isSafeInteger(byteLimit) || byteLimit <= 0) {
    throw new RangeError("INVALID_BODY_LIMIT");
  }
  if (!request.body) throw new TypeError("REQUEST_BODY_REQUIRED");

  const advertisedLength = Number(request.headers.get("content-length"));
  if (
    Number.isFinite(advertisedLength) &&
    advertisedLength >= 0 &&
    advertisedLength > byteLimit
  ) {
    throw new RequestBodyTooLargeError("REQUEST_TOO_LARGE");
  }

  let consumedBytes = 0;
  return request.body.pipeThrough(
    new TransformStream<Uint8Array, Uint8Array>({
      transform(chunk, controller) {
        consumedBytes += chunk.byteLength;
        if (consumedBytes > byteLimit) {
          controller.error(new RequestBodyTooLargeError("REQUEST_TOO_LARGE"));
          return;
        }
        controller.enqueue(chunk);
      },
    }),
  );
}

export async function parseBoundedJsonBody<T>(
  request: Request,
  byteLimit = maxPurchaseRequestBytes,
): Promise<T> {
  return await new Response(boundedRequestBody(request, byteLimit)).json() as T;
}

function requiredEnv(name: string) {
  const value = Deno.env.get(name)?.trim();
  if (!value) throw new Error(`MISSING_SECRET_${name}`);
  return value;
}

function normalizePem(value: string) {
  return value.replaceAll("\\n", "\n");
}

function toIso(value: unknown): string | null {
  if (typeof value === "number" && Number.isFinite(value)) {
    return new Date(value).toISOString();
  }
  if (typeof value === "string" && value.length > 0) {
    const parsed = new Date(value);
    return Number.isNaN(parsed.getTime()) ? null : parsed.toISOString();
  }
  return null;
}

export function isAllowedStoreProduct(
  platform: "app_store" | "google_play",
  productId: string,
  basePlanId = "",
) {
  return platform === "app_store"
    ? basePlanId === "" && appStoreProducts.has(productId)
    : googlePlayProducts.has(productId) &&
      googlePlayBasePlans.has(basePlanId);
}

export function appleEntitlementPeriodEnd(
  status: VerifiedEntitlement["status"],
  transaction: Record<string, unknown>,
  renewal: Record<string, unknown>,
) {
  if (status === "grace") {
    return toIso(renewal.gracePeriodExpiresDate) ??
      toIso(transaction.expiresDate);
  }
  return toIso(transaction.expiresDate);
}

type GoogleLineSelection = {
  line: Record<string, unknown>;
  productId: string;
  basePlanId: string;
  expiry: string;
};

export function selectGoogleLineItem(
  purchase: Record<string, unknown>,
  nowMs = Date.now(),
): GoogleLineSelection | null {
  const rawLines = Array.isArray(purchase.lineItems)
    ? purchase.lineItems as Array<Record<string, unknown>>
    : [];
  const candidates = rawLines.flatMap((line) => {
    const productId = String(line.productId ?? "");
    const offer = (line.offerDetails ?? {}) as Record<string, unknown>;
    const basePlanId = String(offer.basePlanId ?? "");
    const expiry = toIso(line.expiryTime);
    if (
      expiry == null ||
      !isAllowedStoreProduct("google_play", productId, basePlanId)
    ) {
      return [];
    }
    return [{ line, productId, basePlanId, expiry }];
  });
  if (candidates.length === 0) return null;

  // Google puts deferredItemReplacement on the item that is entitled now;
  // its nested productId is only the future replacement and must not be
  // granted before the current item expires.
  const deferredCurrent = candidates.filter((candidate) =>
    candidate.line.deferredItemReplacement != null
  );
  if (deferredCurrent.length > 0) {
    deferredCurrent.sort((a, b) =>
      new Date(b.expiry).getTime() - new Date(a.expiry).getTime()
    );
    return deferredCurrent[0];
  }

  const future = candidates.filter((candidate) =>
    new Date(candidate.expiry).getTime() > nowMs
  );
  if (future.length > 0) {
    // A future scheduled item can have the farthest expiry. The nearest
    // unexpired item is the conservative current entitlement.
    future.sort((a, b) =>
      new Date(a.expiry).getTime() - new Date(b.expiry).getTime()
    );
    return future[0];
  }
  candidates.sort((a, b) =>
    new Date(b.expiry).getTime() - new Date(a.expiry).getTime()
  );
  return candidates[0];
}

export function googleEntitlementStatus(
  subscriptionState: unknown,
  expiry: string | null,
  nowMs = Date.now(),
): VerifiedEntitlement["status"] {
  const state = String(subscriptionState ?? "");
  const stillEntitled = expiry != null &&
    new Date(expiry).getTime() > nowMs;
  return state === "SUBSCRIPTION_STATE_ACTIVE"
    ? "active"
    : state === "SUBSCRIPTION_STATE_IN_GRACE_PERIOD"
    ? "grace"
    : state === "SUBSCRIPTION_STATE_CANCELED" && stillEntitled
    ? "active"
    : state === "SUBSCRIPTION_STATE_ON_HOLD"
    ? "past_due"
    : state === "SUBSCRIPTION_STATE_PAUSED"
    ? "past_due"
    : "expired";
}

export function assertGoogleSubscriptionStateIsVerifiable(
  subscriptionState: unknown,
) {
  const state = String(subscriptionState ?? "");
  if (state === "SUBSCRIPTION_STATE_PENDING") {
    throw new Error("GOOGLE_SUBSCRIPTION_PENDING");
  }
  if (state === "SUBSCRIPTION_STATE_PENDING_PURCHASE_CANCELED") {
    throw new Error("GOOGLE_SUBSCRIPTION_PENDING_PURCHASE_CANCELED");
  }
  if (
    ![
      "SUBSCRIPTION_STATE_ACTIVE",
      "SUBSCRIPTION_STATE_IN_GRACE_PERIOD",
      "SUBSCRIPTION_STATE_CANCELED",
      "SUBSCRIPTION_STATE_ON_HOLD",
      "SUBSCRIPTION_STATE_PAUSED",
      "SUBSCRIPTION_STATE_EXPIRED",
    ].includes(state)
  ) {
    throw new Error("GOOGLE_SUBSCRIPTION_STATE_UNSUPPORTED");
  }
}

function recordValue(value: unknown): Record<string, unknown> | null {
  return value != null && typeof value === "object" && !Array.isArray(value)
    ? value as Record<string, unknown>
    : null;
}

type GoogleIdentityOptions = {
  allowMissingDirectProfile?: boolean;
  trustedOutOfAppLineage?: boolean;
};

function assertGoogleIdentifierPair(
  identifiers: Record<string, unknown>,
  body: PurchaseBody,
  userId: string,
  allowMissingProfile: boolean,
  allowMissingAccount = false,
) {
  const accountId = identifiers.obfuscatedExternalAccountId;
  if (
    accountId !== userId &&
    !(allowMissingAccount && accountId == null)
  ) {
    throw new Error("GOOGLE_ACCOUNT_MISMATCH");
  }
  const profileId = identifiers.obfuscatedExternalProfileId;
  if (
    profileId !== body.storeId &&
    !(allowMissingProfile && profileId == null)
  ) {
    throw new Error("GOOGLE_PROFILE_MISMATCH");
  }
}

export function assertGooglePurchaseIdentity(
  purchase: Record<string, unknown>,
  body: PurchaseBody,
  userId: string,
  options: GoogleIdentityOptions = {},
) {
  const knownOriginalTransactionId = body.knownOriginalTransactionId?.trim();
  const currentValue = purchase.externalAccountIdentifiers;
  const currentIdentifiers = recordValue(currentValue);
  const outOfAppValue = purchase.outOfAppPurchaseContext;
  const outOfAppContext = recordValue(outOfAppValue);

  if (outOfAppValue != null) {
    if (!outOfAppContext) {
      throw new Error("GOOGLE_OUT_OF_APP_CONTEXT_INVALID");
    }
    const expiredIdentifiers = recordValue(
      outOfAppContext.expiredExternalAccountIdentifiers,
    );
    const trustedLineage = options.trustedOutOfAppLineage === true;
    if (!expiredIdentifiers && !trustedLineage) {
      throw new Error("GOOGLE_OUT_OF_APP_CONTEXT_INVALID");
    }
    if (expiredIdentifiers) {
      assertGoogleIdentifierPair(
        expiredIdentifiers,
        body,
        userId,
        trustedLineage,
        trustedLineage,
      );
    }

    // Google can omit the identifiers on the new out-of-app purchase. If it
    // does include either field, both values must remain bound to the same
    // account and store as the expired purchase.
    const hasCurrentIdentity = currentIdentifiers != null &&
      (currentIdentifiers.obfuscatedExternalAccountId !== undefined ||
        currentIdentifiers.obfuscatedExternalProfileId !== undefined);
    if (hasCurrentIdentity) {
      assertGoogleIdentifierPair(
        currentIdentifiers,
        body,
        userId,
        trustedLineage,
        trustedLineage,
      );
    } else if (currentValue != null && !currentIdentifiers) {
      throw new Error("GOOGLE_ACCOUNT_MISMATCH");
    }
    return;
  }

  if (!currentIdentifiers) {
    throw new Error("GOOGLE_ACCOUNT_MISMATCH");
  }
  assertGoogleIdentifierPair(
    currentIdentifiers,
    body,
    userId,
    Boolean(knownOriginalTransactionId) ||
      options.allowMissingDirectProfile === true,
  );
}

export function googleAcknowledgementRequired(value: unknown) {
  if (value === "ACKNOWLEDGEMENT_STATE_PENDING") return true;
  if (value === "ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED") return false;
  throw new Error("GOOGLE_ACKNOWLEDGEMENT_STATE_UNSUPPORTED");
}

export function googleLinkedPurchaseToken(
  purchase: Record<string, unknown>,
) {
  const directValue = typeof purchase.linkedPurchaseToken === "string"
    ? purchase.linkedPurchaseToken.trim()
    : "";
  const directToken = directValue.length >= 20 ? directValue : null;
  const outOfAppContext = recordValue(purchase.outOfAppPurchaseContext);
  if (!outOfAppContext) return directToken;

  const expiredValue = typeof outOfAppContext.expiredPurchaseToken === "string"
    ? outOfAppContext.expiredPurchaseToken.trim()
    : "";
  if (expiredValue.length < 20) {
    throw new Error("GOOGLE_EXPIRED_PURCHASE_TOKEN_REQUIRED");
  }
  if (directToken != null && directToken !== expiredValue) {
    throw new Error("GOOGLE_PURCHASE_LINEAGE_CONFLICT");
  }
  return directToken ?? expiredValue;
}

export function googleAutoRenews(line: Record<string, unknown>) {
  const autoRenewing = (line.autoRenewingPlan ?? {}) as Record<string, unknown>;
  return autoRenewing.autoRenewEnabled === true ||
    line.deferredItemReplacement != null;
}

export function classifyVerificationFailure(
  rawMessage: string,
): VerificationFailure {
  const message = rawMessage.toUpperCase();
  if (message.includes("GOOGLE_SUBSCRIPTION_PENDING_PURCHASE_CANCELED")) {
    return {
      status: 409,
      code: "STORE_PURCHASE_PENDING_CANCELED",
      retryable: false,
    };
  }
  if (message.includes("GOOGLE_SUBSCRIPTION_PENDING")) {
    return { status: 409, code: "STORE_PURCHASE_PENDING", retryable: true };
  }
  if (message.includes("STORE_RECEIPT_STALE")) {
    return {
      status: 409,
      code: "PURCHASE_VERIFICATION_UNAVAILABLE",
      retryable: true,
    };
  }
  if (message.includes("GOOGLE_SUBSCRIPTION_STATE_UNSUPPORTED")) {
    return {
      status: 503,
      code: "PURCHASE_VERIFICATION_UNAVAILABLE",
      retryable: true,
    };
  }
  if (
    message.includes("SANDBOX_REVIEW_") ||
    message.includes("SANDBOX_TESTER_NOT_ALLOWED")
  ) {
    return { status: 403, code: "SANDBOX_NOT_AVAILABLE", retryable: false };
  }
  if (
    message.includes("STORE_PURCHASE_ALREADY_LINKED") ||
    message.includes("ACTIVE_STORE_PROVIDER_CHANGE_BLOCKED") ||
    message.includes("ACTIVE_STORE_SUBSCRIPTION_REPLACEMENT_BLOCKED") ||
    message.includes("SANDBOX_CANNOT_REPLACE_PRODUCTION") ||
    message.includes("GOOGLE_LINKED_PURCHASE_UNRESOLVED") ||
    message.includes("GOOGLE_PURCHASE_LINEAGE_CONFLICT") ||
    message.includes("GOOGLE_PURCHASE_TOKEN_SUPERSEDED")
  ) {
    return { status: 409, code: "PURCHASE_CONFLICT", retryable: false };
  }
  if (
    message.includes("APPLE_STATUS_404") ||
    message.includes("GOOGLE_STATUS_400") ||
    message.includes("GOOGLE_STATUS_404") ||
    message.includes("GOOGLE_STATUS_410") ||
    message.includes("TRANSACTION_REQUIRED") ||
    message.includes("SOURCE_MISMATCH") ||
    message.includes("BUNDLE_MISMATCH") ||
    message.includes("ACCOUNT_MISMATCH") ||
    message.includes("PROFILE_MISMATCH") ||
    message.includes("PRODUCT_MISMATCH") ||
    message.includes("BASE_PLAN_MISMATCH") ||
    message.includes("SUBSCRIPTION_NOT_FOUND") ||
    message.includes("LINE_ITEM_MISSING") ||
    message.includes("PURCHASE_TOKEN_REQUIRED") ||
    message.includes("EXPIRED_PURCHASE_TOKEN_REQUIRED") ||
    message.includes("OUT_OF_APP_CONTEXT_INVALID") ||
    message.includes("APPLE_STORE_BINDING_UNRESOLVED") ||
    message.includes("STORE_PRODUCT_UNMAPPED") ||
    message.includes("STORE_ACTIVE_PERIOD_INVALID") ||
    message.includes("INVALID_STORE_ENTITLEMENT")
  ) {
    return { status: 422, code: "PURCHASE_NOT_VALID", retryable: false };
  }
  if (
    message.includes("APPLE_STATUS_") ||
    message.includes("GOOGLE_STATUS_") ||
    message.includes("GOOGLE_AUTH_") ||
    message.includes("GOOGLE_ACKNOWLEDGE_") ||
    message.includes("GOOGLE_ACKNOWLEDGEMENT_STATE_UNSUPPORTED") ||
    message.includes("MISSING_SECRET_") ||
    message.includes("INVALID_GOOGLE_SERVICE_ACCOUNT") ||
    message.includes("ABORTERROR") ||
    message.includes("TIMED OUT") ||
    message.includes("NETWORK") ||
    message.includes("CONNECTION") ||
    message.includes("SENDING REQUEST") ||
    message.includes("FETCH")
  ) {
    return {
      status: 503,
      code: "PURCHASE_PROVIDER_UNAVAILABLE",
      retryable: true,
    };
  }
  return {
    status: 500,
    code: "PURCHASE_VERIFICATION_UNAVAILABLE",
    retryable: true,
  };
}

async function sha256(value: string) {
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(value),
  );
  return [...new Uint8Array(digest)]
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

async function appleApiToken() {
  const issuer = requiredEnv("APPLE_IAP_ISSUER_ID");
  const keyId = requiredEnv("APPLE_IAP_KEY_ID");
  const key = await importPKCS8(
    normalizePem(requiredEnv("APPLE_IAP_PRIVATE_KEY_P8")),
    "ES256",
  );
  const now = Math.floor(Date.now() / 1000);
  return await new SignJWT({ bid: bundleId })
    .setProtectedHeader({ alg: "ES256", kid: keyId, typ: "JWT" })
    .setIssuer(issuer)
    .setAudience("appstoreconnect-v1")
    .setIssuedAt(now)
    .setExpirationTime(now + 300)
    .sign(key);
}

export function decodeAppleClientTransaction(body: PurchaseBody) {
  const signedTransaction = body.verificationData?.trim();
  if (!signedTransaction || signedTransaction.split(".").length !== 3) {
    return null;
  }
  try {
    return decodeJwt(signedTransaction) as Record<string, unknown>;
  } catch {
    return null;
  }
}

export function appleEnvironmentOrder(environmentHint: unknown) {
  const sandboxFirst = String(environmentHint ?? "").toLowerCase() ===
    "sandbox";
  const environments: Array<{
    name: "sandbox" | "production";
    host: string;
  }> = sandboxFirst
    ? [
      { name: "sandbox", host: "https://api.storekit-sandbox.apple.com" },
      { name: "production", host: "https://api.storekit.apple.com" },
    ]
    : [
      { name: "production", host: "https://api.storekit.apple.com" },
      { name: "sandbox", host: "https://api.storekit-sandbox.apple.com" },
    ];
  return environments;
}

export function appleAccountBindingKind(
  appAccountToken: unknown,
  storeId: string,
  userId: string,
) {
  const token = typeof appAccountToken === "string"
    ? appAccountToken.trim().toLowerCase()
    : "";
  return token === storeId.trim().toLowerCase()
    ? "store"
    : token === userId.trim().toLowerCase()
    ? "legacy_user"
    : "unresolved";
}

export function assertAppleStoreBinding(
  appAccountToken: unknown,
  storeId: string,
  userId: string,
  existingStoreIds: string[],
  legacySingleStoreAllowed: boolean,
) {
  const bindingKind = appleAccountBindingKind(
    appAccountToken,
    storeId,
    userId,
  );
  if (bindingKind === "store") return;
  if (existingStoreIds.length > 0) {
    if (
      existingStoreIds.some((existingStoreId) => existingStoreId !== storeId)
    ) {
      throw new Error("STORE_PURCHASE_ALREADY_LINKED");
    }
    return;
  }
  if (bindingKind === "legacy_user" && legacySingleStoreAllowed) return;
  throw new Error("APPLE_STORE_BINDING_UNRESOLVED");
}

async function fetchAppleStatus(
  transactionId: string,
  environmentHint: unknown,
) {
  const token = await appleApiToken();
  const path = `/inApps/v1/subscriptions/${encodeURIComponent(transactionId)}`;
  const environments = appleEnvironmentOrder(environmentHint);
  const statuses: number[] = [];
  for (const environment of environments) {
    const result = await fetch(`${environment.host}${path}`, {
      headers: { Authorization: `Bearer ${token}` },
      signal: AbortSignal.timeout(12_000),
    });
    statuses.push(result.status);
    if (result.ok) {
      return {
        environment: environment.name,
        body: await result.json() as Record<string, unknown>,
      };
    }
    // TestFlight transactions are sandbox transactions. Apple can answer 401
    // or 404 on the production host, so neither response may prevent a
    // separately authenticated sandbox lookup.
    if (result.status !== 401 && result.status !== 404) break;
  }
  throw new Error(`APPLE_STATUS_${statuses.join("_")}`);
}

export async function verifyApplePurchase(
  body: PurchaseBody,
  _userId: string,
): Promise<VerifiedEntitlement> {
  const clientTransaction = decodeAppleClientTransaction(body);
  const transactionId = body.purchaseId?.trim() ||
    (typeof clientTransaction?.transactionId === "string"
      ? clientTransaction.transactionId
      : null);
  if (!transactionId || !/^\d{6,30}$/.test(transactionId)) {
    throw new Error("APPLE_TRANSACTION_REQUIRED");
  }
  if (body.verificationSource !== "app_store") {
    throw new Error("APPLE_SOURCE_MISMATCH");
  }

  const apple = await fetchAppleStatus(
    transactionId,
    clientTransaction?.environment,
  );
  if (apple.body.bundleId !== bundleId) {
    throw new Error("APPLE_BUNDLE_MISMATCH");
  }

  const groups = Array.isArray(apple.body.data) ? apple.body.data : [];
  const transactions: Array<{
    item: Record<string, unknown>;
    transaction: Record<string, unknown>;
    renewal: Record<string, unknown>;
  }> = [];
  for (const rawGroup of groups) {
    const group = rawGroup as Record<string, unknown>;
    const last = Array.isArray(group.lastTransactions)
      ? group.lastTransactions
      : [];
    for (const rawItem of last) {
      const item = rawItem as Record<string, unknown>;
      const signedTransaction = item.signedTransactionInfo;
      const signedRenewal = item.signedRenewalInfo;
      if (typeof signedTransaction !== "string") continue;
      transactions.push({
        item,
        transaction: decodeJwt(signedTransaction),
        renewal: typeof signedRenewal === "string"
          ? decodeJwt(signedRenewal)
          : {},
      });
    }
  }
  transactions.sort((a, b) =>
    Number(b.transaction.expiresDate ?? 0) -
    Number(a.transaction.expiresDate ?? 0)
  );
  const current = transactions[0];
  if (!current) throw new Error("APPLE_SUBSCRIPTION_NOT_FOUND");

  const transaction = current.transaction;
  if (transaction.bundleId !== bundleId) {
    throw new Error("APPLE_BUNDLE_MISMATCH");
  }
  const appAccountToken = typeof transaction.appAccountToken === "string"
    ? transaction.appAccountToken.trim()
    : null;
  const productId = String(transaction.productId ?? "");
  if (!isAllowedStoreProduct("app_store", productId)) {
    throw new Error("APPLE_PRODUCT_MISMATCH");
  }

  const statusCode = Number(current.item.status ?? 0);
  const status: VerifiedEntitlement["status"] = statusCode === 1
    ? "active"
    : statusCode === 4
    ? "grace"
    : statusCode === 3
    ? "past_due"
    : statusCode === 5
    ? "revoked"
    : "expired";
  return {
    platform: "app_store",
    productId,
    basePlanId: "",
    transactionId: String(transaction.transactionId ?? transactionId),
    originalTransactionId: String(
      transaction.originalTransactionId ?? transactionId,
    ),
    status,
    environment: String(apple.body.environment ?? apple.environment)
        .toLowerCase() === "sandbox"
      ? "sandbox"
      : "production",
    periodStart: toIso(transaction.purchaseDate),
    periodEnd: appleEntitlementPeriodEnd(
      status,
      transaction,
      current.renewal,
    ),
    autoRenews: Number(current.renewal.autoRenewStatus ?? 0) === 1,
    appleAccountToken: appAccountToken || null,
  };
}

type GoogleServiceAccount = {
  client_email: string;
  private_key: string;
  token_uri?: string;
};

type GoogleAccessTokenResult = {
  accessToken: string;
  expiresInSeconds: number;
};

export type GoogleAccessTokenTestHook = {
  fetchToken: () => Promise<GoogleAccessTokenResult>;
  now?: () => number;
};

let googleAccessTokenTestHook: GoogleAccessTokenTestHook | null = null;
let googleAccessTokenCache: {
  cacheKey: string;
  accessToken: string;
  expiresAtMs: number;
} | null = null;
let googleAccessTokenInFlight: {
  cacheKey: string;
  generation: number;
  promise: Promise<string>;
} | null = null;
let googleAccessTokenGeneration = 0;

export function setGoogleAccessTokenTestHook(
  hook: GoogleAccessTokenTestHook | null,
) {
  googleAccessTokenGeneration += 1;
  googleAccessTokenTestHook = hook;
  googleAccessTokenCache = null;
  googleAccessTokenInFlight = null;
}

function googleAccessTokenNow() {
  return googleAccessTokenTestHook?.now?.() ?? Date.now();
}

async function fetchGoogleAccessToken(
  account: GoogleServiceAccount,
  tokenUri: string,
): Promise<GoogleAccessTokenResult> {
  if (!account.client_email || !account.private_key) {
    throw new Error("INVALID_GOOGLE_SERVICE_ACCOUNT");
  }
  const key = await importPKCS8(normalizePem(account.private_key), "RS256");
  const now = Math.floor(Date.now() / 1000);
  const assertion = await new SignJWT({ scope: googleScope })
    .setProtectedHeader({ alg: "RS256", typ: "JWT" })
    .setIssuer(account.client_email)
    .setAudience(tokenUri)
    .setIssuedAt(now)
    .setExpirationTime(now + 3600)
    .sign(key);
  const tokenResponse = await fetch(tokenUri, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    signal: AbortSignal.timeout(12_000),
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });
  if (!tokenResponse.ok) {
    throw new Error(`GOOGLE_AUTH_${tokenResponse.status}`);
  }
  const tokenBody = await tokenResponse.json() as Record<string, unknown>;
  if (typeof tokenBody.access_token !== "string") {
    throw new Error("GOOGLE_AUTH_TOKEN_MISSING");
  }
  const rawExpiresIn = Number(tokenBody.expires_in);
  return {
    accessToken: tokenBody.access_token,
    expiresInSeconds: Number.isFinite(rawExpiresIn) && rawExpiresIn > 0
      ? rawExpiresIn
      : 3600,
  };
}

function googleAccessTokenSource() {
  if (googleAccessTokenTestHook != null) {
    return {
      cacheKey: `test-hook-${googleAccessTokenGeneration}`,
      fetchToken: googleAccessTokenTestHook.fetchToken,
    };
  }

  const rawAccount = requiredEnv("GOOGLE_PLAY_SERVICE_ACCOUNT_JSON");
  let account: GoogleServiceAccount;
  try {
    account = JSON.parse(rawAccount) as GoogleServiceAccount;
  } catch {
    throw new Error("INVALID_GOOGLE_SERVICE_ACCOUNT");
  }
  if (!account.client_email || !account.private_key) {
    throw new Error("INVALID_GOOGLE_SERVICE_ACCOUNT");
  }
  const tokenUri = account.token_uri ?? "https://oauth2.googleapis.com/token";
  return {
    // A single-entry cache stays bounded while this key makes a warm isolate
    // discard the token immediately if its service-account secret rotates.
    cacheKey: rawAccount,
    fetchToken: () => fetchGoogleAccessToken(account, tokenUri),
  };
}

export async function googleAccessToken() {
  const source = googleAccessTokenSource();
  const nowMs = googleAccessTokenNow();
  if (
    googleAccessTokenCache?.cacheKey === source.cacheKey &&
    googleAccessTokenCache.expiresAtMs > nowMs
  ) {
    return googleAccessTokenCache.accessToken;
  }

  if (
    googleAccessTokenInFlight?.cacheKey === source.cacheKey &&
    googleAccessTokenInFlight.generation === googleAccessTokenGeneration
  ) {
    return await googleAccessTokenInFlight.promise;
  }

  const generation = googleAccessTokenGeneration;
  let promise: Promise<string>;
  promise = source.fetchToken().then((result) => {
    const accessToken = result.accessToken.trim();
    if (!accessToken) throw new Error("GOOGLE_AUTH_TOKEN_MISSING");

    const providerLifetimeMs = Math.min(
      Math.max(0, result.expiresInSeconds * 1000),
      60 * 60 * 1000,
    );
    const refreshMarginMs = Math.min(60_000, providerLifetimeMs / 10);
    const cacheLifetimeMs = Math.min(
      55 * 60 * 1000,
      Math.max(0, providerLifetimeMs - refreshMarginMs),
    );
    if (
      generation === googleAccessTokenGeneration &&
      cacheLifetimeMs > 0
    ) {
      googleAccessTokenCache = {
        cacheKey: source.cacheKey,
        accessToken,
        expiresAtMs: googleAccessTokenNow() + cacheLifetimeMs,
      };
    }
    return accessToken;
  }).finally(() => {
    if (googleAccessTokenInFlight?.promise === promise) {
      googleAccessTokenInFlight = null;
    }
  });
  googleAccessTokenInFlight = {
    cacheKey: source.cacheKey,
    generation,
    promise,
  };
  return await promise;
}

async function fetchGoogleSubscription(
  purchaseToken: string,
  accessToken: string,
) {
  const url =
    `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${bundleId}/purchases/subscriptionsv2/tokens/${
      encodeURIComponent(purchaseToken)
    }`;
  const result = await fetch(url, {
    headers: { Authorization: `Bearer ${accessToken}` },
    signal: AbortSignal.timeout(12_000),
  });
  if (!result.ok) throw new Error(`GOOGLE_STATUS_${result.status}`);
  return await result.json() as Record<string, unknown>;
}

type GooglePurchaseVerificationOptions = {
  allowMissingDirectProfile?: boolean;
  resolveOutOfAppLineage?: (expiredPurchaseToken: string) => Promise<boolean>;
};

export async function verifyGooglePurchase(
  body: PurchaseBody,
  userId: string,
  options: GooglePurchaseVerificationOptions = {},
): Promise<VerifiedEntitlement> {
  const purchaseToken = body.verificationData?.trim();
  if (!purchaseToken || purchaseToken.length < 20) {
    throw new Error("GOOGLE_PURCHASE_TOKEN_REQUIRED");
  }
  if (body.verificationSource !== "google_play") {
    throw new Error("GOOGLE_SOURCE_MISMATCH");
  }

  const accessToken = await googleAccessToken();
  const purchase = await fetchGoogleSubscription(purchaseToken, accessToken);
  assertGoogleSubscriptionStateIsVerifiable(purchase.subscriptionState);

  const outOfAppContext = recordValue(purchase.outOfAppPurchaseContext);
  let trustedOutOfAppLineage = false;
  if (outOfAppContext && options.resolveOutOfAppLineage) {
    const identifiers = recordValue(
      outOfAppContext.expiredExternalAccountIdentifiers,
    );
    const accountMissing = identifiers?.obfuscatedExternalAccountId == null;
    const profileMissing = identifiers?.obfuscatedExternalProfileId == null;
    if (accountMissing || profileMissing) {
      const expiredPurchaseToken = googleLinkedPurchaseToken(purchase);
      if (!expiredPurchaseToken) {
        throw new Error("GOOGLE_EXPIRED_PURCHASE_TOKEN_REQUIRED");
      }
      trustedOutOfAppLineage = await options.resolveOutOfAppLineage(
        expiredPurchaseToken,
      );
    }
  }
  assertGooglePurchaseIdentity(purchase, body, userId, {
    allowMissingDirectProfile: options.allowMissingDirectProfile,
    trustedOutOfAppLineage,
  });

  const selected = selectGoogleLineItem(purchase);
  if (!selected) throw new Error("GOOGLE_LINE_ITEM_MISSING");
  const { line, productId, basePlanId, expiry } = selected;

  const status = googleEntitlementStatus(
    purchase.subscriptionState,
    expiry,
  );
  const tokenHash = await sha256(purchaseToken);
  const linkedPurchaseToken = googleLinkedPurchaseToken(purchase);
  const linkedPurchaseTokenHash = linkedPurchaseToken != null
    ? await sha256(linkedPurchaseToken)
    : null;
  const latestSuccessfulOrderId = String(
    line.latestSuccessfulOrderId ?? "",
  ).trim();
  const transactionHash = latestSuccessfulOrderId.length > 0
    ? await sha256(latestSuccessfulOrderId)
    : tokenHash;
  const knownOriginalTransactionId = body.knownOriginalTransactionId?.trim();
  return {
    platform: "google_play",
    productId,
    basePlanId,
    transactionId: `order_${transactionHash}`,
    originalTransactionId: knownOriginalTransactionId || `token_${tokenHash}`,
    status,
    environment: purchase.testPurchase == null ? "production" : "sandbox",
    periodStart: toIso(purchase.startTime),
    periodEnd: expiry,
    autoRenews: googleAutoRenews(line),
    purchaseTokenHash: tokenHash,
    linkedPurchaseTokenHash,
    googleAcknowledgementPending: googleAcknowledgementRequired(
      purchase.acknowledgementState,
    ),
    googleOutOfApp: outOfAppContext != null,
  };
}

export async function acknowledgeGoogleSubscription(
  purchaseToken: string,
  productId: string,
  userId: string,
  storeId: string,
  outOfApp: boolean,
) {
  const accessToken = await googleAccessToken();
  const url =
    `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${bundleId}/purchases/subscriptions/${
      encodeURIComponent(productId)
    }/tokens/${encodeURIComponent(purchaseToken)}:acknowledge`;
  const result = await fetch(url, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
    signal: AbortSignal.timeout(12_000),
    body: JSON.stringify(
      outOfApp
        ? {
          externalAccountIds: {
            obfuscatedAccountId: userId,
            obfuscatedProfileId: storeId,
          },
        }
        : {},
    ),
  });
  if (result.ok) return;

  // A concurrent verifier may have acknowledged the same token after our GET.
  // Confirm provider state before turning that harmless race into an error.
  const current = await fetchGoogleSubscription(purchaseToken, accessToken);
  if (!googleAcknowledgementRequired(current.acknowledgementState)) return;
  throw new Error(`GOOGLE_ACKNOWLEDGE_${result.status}`);
}

export function expectedCurrentPurchaseTokenHash(
  refreshRequest: boolean,
  entitlement: VerifiedEntitlement,
) {
  if (!refreshRequest || entitlement.platform !== "google_play") return null;
  const hash = entitlement.purchaseTokenHash?.trim() ?? "";
  if (!/^[0-9a-f]{64}$/.test(hash)) {
    throw new Error("GOOGLE_PURCHASE_TOKEN_REQUIRED");
  }
  return hash;
}

export async function handle(request: Request) {
  if (request.method !== "POST") {
    return response(405, { error: "METHOD_NOT_ALLOWED", retryable: false });
  }
  try {
    const supabaseUrl = requiredEnv("SUPABASE_URL");
    const publishableKey = Deno.env.get("SUPABASE_ANON_KEY") ??
      requiredEnv("SUPABASE_PUBLISHABLE_KEY");
    const serviceRoleKey = requiredEnv("SUPABASE_SERVICE_ROLE_KEY");
    const authorization = request.headers.get("Authorization");
    if (!authorization) {
      return response(401, { error: "AUTH_REQUIRED", retryable: false });
    }

    const scoped = createClient(supabaseUrl, publishableKey, {
      global: { headers: { Authorization: authorization } },
      auth: { persistSession: false },
    });
    const { data: authData, error: authError } = await scoped.auth.getUser();
    if (authError || !authData.user) {
      return response(401, { error: "AUTH_REQUIRED", retryable: false });
    }

    let body: PurchaseBody;
    try {
      body = await parseBoundedJsonBody<PurchaseBody>(request);
    } catch (error) {
      if (error instanceof RequestBodyTooLargeError) {
        return response(413, {
          error: "REQUEST_TOO_LARGE",
          retryable: false,
        });
      }
      return response(400, {
        error: "INVALID_PURCHASE_PAYLOAD",
        retryable: false,
      });
    }
    const refreshRequest = body.refresh === true;
    if (
      typeof body.storeId !== "string" ||
      (!refreshRequest && body.knownOriginalTransactionId !== undefined) ||
      (body.acknowledgeOnServer !== undefined &&
        typeof body.acknowledgeOnServer !== "boolean") ||
      (body.acknowledgeOnServer === true &&
        body.platform !== "google_play") ||
      !/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
        .test(body.storeId)
    ) {
      return response(400, {
        error: "INVALID_PURCHASE_PAYLOAD",
        retryable: false,
      });
    }
    const storeId = body.storeId;

    const { data: membership, error: membershipError } = await scoped.from(
      "store_members",
    )
      .select("role,status")
      .eq("store_id", storeId)
      .eq("user_id", authData.user.id)
      .maybeSingle();
    if (membershipError) throw new Error("STORE_MEMBERSHIP_LOOKUP_FAILED");
    if (membership?.role !== "owner" || membership.status !== "active") {
      return response(403, {
        error: "STORE_OWNER_REQUIRED",
        retryable: false,
      });
    }

    const admin = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false },
    });
    let purchaserId = authData.user.id;
    let googlePurchaseToken: string | null = null;

    if (refreshRequest) {
      const { data: subscription, error: subscriptionError } = await admin
        .from("subscriptions")
        .select(
          "source,billing_provider,original_transaction_id,store_entitlement_id",
        )
        .eq("store_id", storeId)
        .maybeSingle();
      if (
        subscriptionError || subscription?.source !== "store" ||
        (subscription.billing_provider !== "app_store" &&
          subscription.billing_provider !== "google_play") ||
        typeof subscription.original_transaction_id !== "string" ||
        typeof subscription.store_entitlement_id !== "string"
      ) {
        throw new Error("STORE_SUBSCRIPTION_NOT_REFRESHABLE");
      }
      const { data: existingEntitlement, error: entitlementError } = await admin
        .from("store_entitlements")
        .select("user_id")
        .eq("id", subscription.store_entitlement_id)
        .eq("store_id", storeId)
        .is("superseded_at", null)
        .maybeSingle();
      if (
        entitlementError || typeof existingEntitlement?.user_id !== "string"
      ) {
        throw new Error("STORE_ENTITLEMENT_NOT_FOUND");
      }
      purchaserId = existingEntitlement.user_id;
      if (subscription.billing_provider === "app_store") {
        body = {
          storeId,
          platform: "app_store",
          purchaseId: subscription.original_transaction_id,
          verificationSource: "app_store",
        };
      } else {
        const { data: savedToken, error: tokenError } = await admin.rpc(
          "get_store_receipt_secret",
          {
            billing_platform: "google_play",
            external_original_transaction_id:
              subscription.original_transaction_id,
          },
        );
        if (tokenError || typeof savedToken !== "string") {
          throw new Error("GOOGLE_REFRESH_TOKEN_MISSING");
        }
        googlePurchaseToken = savedToken;
        body = {
          storeId,
          platform: "google_play",
          verificationData: savedToken,
          verificationSource: "google_play",
          knownOriginalTransactionId: subscription.original_transaction_id,
        };
      }
    } else if (
      body.platform !== "app_store" && body.platform !== "google_play"
    ) {
      return response(400, {
        error: "INVALID_PURCHASE_PAYLOAD",
        retryable: false,
      });
    }

    const { data: reservation, error: reservationError } = await admin.rpc(
      "reserve_store_purchase_verification",
      {
        target_store_id: storeId,
        target_user_id: authData.user.id,
      },
    );
    if (reservationError) {
      throw new Error(
        `STORE_VERIFICATION_RESERVATION_${reservationError.message}`,
      );
    }
    const allowed = reservation && typeof reservation === "object" &&
      reservation.allowed === true;
    if (!allowed) {
      const rawRetry = reservation && typeof reservation === "object"
        ? Number(reservation.retry_after_seconds)
        : 60;
      const retryAfterSeconds = Number.isFinite(rawRetry)
        ? Math.max(1, Math.ceil(rawRetry))
        : 60;
      return response(
        429,
        {
          error: "STORE_VERIFICATION_RATE_LIMITED",
          retryable: true,
          retryAfterSeconds,
        },
        { "Retry-After": String(retryAfterSeconds) },
      );
    }

    const { data: ownedStores, error: ownedStoresError } = await admin
      .from("stores")
      .select("id")
      .eq("owner_id", purchaserId)
      .limit(2);
    if (ownedStoresError) throw new Error("STORE_OWNERSHIP_LOOKUP_FAILED");
    const legacySingleStoreAllowed = ownedStores?.length === 1 &&
      ownedStores[0]?.id === storeId;

    const entitlement = body.platform === "app_store"
      ? await verifyApplePurchase(body, purchaserId)
      : await verifyGooglePurchase(body, purchaserId, {
        allowMissingDirectProfile: !refreshRequest && legacySingleStoreAllowed,
        resolveOutOfAppLineage: async (expiredPurchaseToken) => {
          const { data: rawBinding, error: bindingError } = await admin.rpc(
            "resolve_google_purchase_token_binding",
            { raw_purchase_token: expiredPurchaseToken },
          );
          if (bindingError) {
            throw new Error("GOOGLE_LINEAGE_LOOKUP_FAILED");
          }
          const binding = recordValue(rawBinding);
          return binding?.store_id === storeId &&
            binding?.user_id === purchaserId;
        },
      });

    if (entitlement.platform === "app_store") {
      const bindingKind = appleAccountBindingKind(
        entitlement.appleAccountToken,
        storeId,
        purchaserId,
      );
      let existingStoreIds: string[] = [];
      if (bindingKind !== "store") {
        const { data: existingBindings, error: existingBindingError } =
          await admin
            .from("store_entitlements")
            .select("store_id")
            .eq("platform", "app_store")
            .eq(
              "original_transaction_id",
              entitlement.originalTransactionId,
            )
            .limit(2);
        if (existingBindingError) {
          throw new Error("APPLE_STORE_BINDING_LOOKUP_FAILED");
        }
        existingStoreIds = (existingBindings ?? []).map((binding) =>
          String(binding.store_id)
        );
      }
      assertAppleStoreBinding(
        entitlement.appleAccountToken,
        storeId,
        purchaserId,
        existingStoreIds,
        legacySingleStoreAllowed,
      );
    }
    if (entitlement.platform === "google_play") {
      googlePurchaseToken ??= body.verificationData?.trim() ?? null;
    }

    const { error: applyError } = await admin.rpc(
      "apply_verified_store_entitlement_with_receipt",
      {
        target_store_id: storeId,
        target_user_id: purchaserId,
        billing_platform: entitlement.platform,
        billed_product_id: entitlement.productId,
        billed_base_plan_id: entitlement.basePlanId,
        external_transaction_id: entitlement.transactionId,
        external_original_transaction_id: entitlement.originalTransactionId,
        entitlement_status: entitlement.status,
        store_environment: entitlement.environment,
        entitlement_period_start: entitlement.periodStart,
        entitlement_period_end: entitlement.periodEnd,
        entitlement_auto_renews: entitlement.autoRenews,
        raw_purchase_token: entitlement.platform === "google_play"
          ? googlePurchaseToken
          : null,
        purchase_token_hash: entitlement.purchaseTokenHash ?? null,
        linked_purchase_token_hash: entitlement.linkedPurchaseTokenHash ?? null,
        expected_current_purchase_token_hash: expectedCurrentPurchaseTokenHash(
          refreshRequest,
          entitlement,
        ),
      },
    );
    if (applyError) throw new Error(`ENTITLEMENT_APPLY_${applyError.message}`);

    let acknowledgedByServer = false;
    if (
      entitlement.platform === "google_play" &&
      body.acknowledgeOnServer === true &&
      entitlement.googleAcknowledgementPending === true &&
      googlePurchaseToken != null
    ) {
      await acknowledgeGoogleSubscription(
        googlePurchaseToken,
        entitlement.productId,
        purchaserId,
        storeId,
        entitlement.googleOutOfApp === true,
      );
      acknowledgedByServer = true;
    }

    return response(200, {
      verified: true,
      platform: entitlement.platform,
      productId: entitlement.productId,
      status: entitlement.status,
      periodEnd: entitlement.periodEnd,
      autoRenews: entitlement.autoRenews,
      entitled: entitlement.status === "active" ||
        entitlement.status === "grace",
      acknowledgedByServer,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    const traceId = crypto.randomUUID();
    const failure = classifyVerificationFailure(message);
    console.error("verify-store-purchase", traceId, message);
    return response(failure.status, {
      error: failure.code,
      retryable: failure.retryable,
      traceId,
    });
  }
}

if (import.meta.main) Deno.serve(handle);
