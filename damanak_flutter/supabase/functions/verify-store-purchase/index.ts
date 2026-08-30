import { createClient } from "@supabase/supabase-js";
import { decodeJwt, importPKCS8, SignJWT } from "jose";

const bundleId = "com.damanak.damanak";
const googleScope = "https://www.googleapis.com/auth/androidpublisher";

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
};

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
  userId: string,
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
  if (transaction.appAccountToken !== userId) {
    throw new Error("APPLE_ACCOUNT_MISMATCH");
  }
  const productId = String(transaction.productId ?? "");
  if (!productId.startsWith("com.damanak.subscription.")) {
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
    periodEnd: toIso(transaction.expiresDate),
    autoRenews: Number(current.renewal.autoRenewStatus ?? 0) === 1,
  };
}

type GoogleServiceAccount = {
  client_email: string;
  private_key: string;
  token_uri?: string;
};

async function googleAccessToken() {
  const account = JSON.parse(
    requiredEnv("GOOGLE_PLAY_SERVICE_ACCOUNT_JSON"),
  ) as GoogleServiceAccount;
  if (!account.client_email || !account.private_key) {
    throw new Error("INVALID_GOOGLE_SERVICE_ACCOUNT");
  }
  const tokenUri = account.token_uri ?? "https://oauth2.googleapis.com/token";
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
  return tokenBody.access_token;
}

export async function verifyGooglePurchase(
  body: PurchaseBody,
  userId: string,
): Promise<VerifiedEntitlement> {
  const purchaseToken = body.verificationData?.trim();
  if (!purchaseToken || purchaseToken.length < 20) {
    throw new Error("GOOGLE_PURCHASE_TOKEN_REQUIRED");
  }
  if (body.verificationSource !== "google_play") {
    throw new Error("GOOGLE_SOURCE_MISMATCH");
  }

  const accessToken = await googleAccessToken();
  const url =
    `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${bundleId}/purchases/subscriptionsv2/tokens/${
      encodeURIComponent(purchaseToken)
    }`;
  const result = await fetch(url, {
    headers: { Authorization: `Bearer ${accessToken}` },
    signal: AbortSignal.timeout(12_000),
  });
  if (!result.ok) throw new Error(`GOOGLE_STATUS_${result.status}`);
  const purchase = await result.json() as Record<string, unknown>;
  const identifiers = (purchase.externalAccountIdentifiers ?? {}) as Record<
    string,
    unknown
  >;
  if (identifiers.obfuscatedExternalAccountId !== userId) {
    throw new Error("GOOGLE_ACCOUNT_MISMATCH");
  }

  const lineItems = Array.isArray(purchase.lineItems)
    ? purchase.lineItems as Array<Record<string, unknown>>
    : [];
  lineItems.sort((a, b) =>
    new Date(String(b.expiryTime ?? 0)).getTime() -
    new Date(String(a.expiryTime ?? 0)).getTime()
  );
  const line = lineItems[0];
  if (!line) throw new Error("GOOGLE_LINE_ITEM_MISSING");
  const productId = String(line.productId ?? "");
  if (!productId.startsWith("com.damanak.subscription.")) {
    throw new Error("GOOGLE_PRODUCT_MISMATCH");
  }
  const offer = (line.offerDetails ?? {}) as Record<string, unknown>;
  const basePlanId = String(offer.basePlanId ?? "");
  if (basePlanId !== "monthly" && basePlanId !== "yearly") {
    throw new Error("GOOGLE_BASE_PLAN_MISMATCH");
  }

  const state = String(purchase.subscriptionState ?? "");
  const expiry = toIso(line.expiryTime);
  const stillEntitled = expiry != null &&
    new Date(expiry).getTime() > Date.now();
  const status: VerifiedEntitlement["status"] =
    state === "SUBSCRIPTION_STATE_ACTIVE"
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
  const autoRenewing = (line.autoRenewingPlan ?? {}) as Record<string, unknown>;
  const tokenHash = await sha256(purchaseToken);
  const accountHash = await sha256(userId);
  return {
    platform: "google_play",
    productId,
    basePlanId,
    transactionId: `token_${tokenHash}`,
    originalTransactionId: `account_${accountHash}`,
    status,
    environment: purchase.testPurchase == null ? "production" : "sandbox",
    periodStart: toIso(purchase.startTime),
    periodEnd: expiry,
    autoRenews: autoRenewing.autoRenewEnabled === true,
  };
}

export async function handle(request: Request) {
  if (request.method !== "POST") {
    return response(405, { error: "METHOD_NOT_ALLOWED" });
  }
  try {
    const supabaseUrl = requiredEnv("SUPABASE_URL");
    const publishableKey = Deno.env.get("SUPABASE_ANON_KEY") ??
      requiredEnv("SUPABASE_PUBLISHABLE_KEY");
    const serviceRoleKey = requiredEnv("SUPABASE_SERVICE_ROLE_KEY");
    const authorization = request.headers.get("Authorization");
    if (!authorization) return response(401, { error: "AUTH_REQUIRED" });

    const scoped = createClient(supabaseUrl, publishableKey, {
      global: { headers: { Authorization: authorization } },
      auth: { persistSession: false },
    });
    const { data: authData, error: authError } = await scoped.auth.getUser();
    if (authError || !authData.user) {
      return response(401, { error: "AUTH_REQUIRED" });
    }

    let body = await request.json() as PurchaseBody;
    if (typeof body.storeId !== "string") {
      return response(400, { error: "INVALID_PURCHASE_PAYLOAD" });
    }
    const storeId = body.storeId;

    const { data: membership } = await scoped.from("store_members")
      .select("role,status")
      .eq("store_id", storeId)
      .eq("user_id", authData.user.id)
      .maybeSingle();
    if (membership?.role !== "owner" || membership.status !== "active") {
      return response(403, { error: "STORE_OWNER_REQUIRED" });
    }

    const admin = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false },
    });
    let purchaserId = authData.user.id;
    let googlePurchaseToken: string | null = null;

    if (body.refresh === true) {
      const { data: subscription, error: subscriptionError } = await admin
        .from("subscriptions")
        .select("source,billing_provider,original_transaction_id")
        .eq("store_id", storeId)
        .maybeSingle();
      if (
        subscriptionError || subscription?.source !== "store" ||
        (subscription.billing_provider !== "app_store" &&
          subscription.billing_provider !== "google_play") ||
        typeof subscription.original_transaction_id !== "string"
      ) {
        throw new Error("STORE_SUBSCRIPTION_NOT_REFRESHABLE");
      }
      const { data: existingEntitlement, error: entitlementError } = await admin
        .from("store_entitlements")
        .select("user_id")
        .eq("store_id", storeId)
        .eq("platform", subscription.billing_provider)
        .eq("original_transaction_id", subscription.original_transaction_id)
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
        };
      }
    } else if (
      body.platform !== "app_store" && body.platform !== "google_play"
    ) {
      return response(400, { error: "INVALID_PURCHASE_PAYLOAD" });
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
          retryAfterSeconds,
        },
        { "Retry-After": String(retryAfterSeconds) },
      );
    }

    const entitlement = body.platform === "app_store"
      ? await verifyApplePurchase(body, purchaserId)
      : await verifyGooglePurchase(body, purchaserId);
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
      },
    );
    if (applyError) throw new Error(`ENTITLEMENT_APPLY_${applyError.message}`);

    return response(200, {
      verified: true,
      platform: entitlement.platform,
      productId: entitlement.productId,
      status: entitlement.status,
      periodEnd: entitlement.periodEnd,
      autoRenews: entitlement.autoRenews,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    console.error("verify-store-purchase", message);
    return response(400, { error: "STORE_VERIFICATION_FAILED" });
  }
}

if (import.meta.main) Deno.serve(handle);
