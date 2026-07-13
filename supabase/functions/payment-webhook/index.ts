// Receives signed ShamCash notification events from the dedicated Android
// listener. The signature covers the exact raw request bytes and request
// identity, so this function must never parse or re-serialize before HMAC
// verification.
import { createClient } from "@supabase/supabase-js";
import {
  isFreshTimestamp,
  isRetryableUnmatchedTimestamp,
  isValidDeviceId,
  isValidEventId,
  type ListenerPayload,
  notificationTextFromPayload,
  parseIncomingPayment,
  parseListenerPayload,
  type PaymentParseResult,
  sha256Hex,
  TARGET_PACKAGE,
  verifyHmacSignature,
} from "./core.ts";

const PAYMENT_WEBHOOK_SECRET = Deno.env.get("PAYMENT_WEBHOOK_SECRET") ?? "";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const WHATSAPP_SERVER_URL = Deno.env.get("WHATSAPP_SERVER_URL") ?? "";
const ORDER_NOTIFY_SECRET = Deno.env.get("ORDER_NOTIFY_SECRET") ?? "";
const MAX_BODY_BYTES = 32 * 1024;
const MAX_OCCURRED_AGE_MS = 30 * 24 * 60 * 60 * 1000;

type PaymentEventRow = {
  status?: string;
  received_at?: string;
  result?: Record<string, unknown> | null;
  matched_type?: string | null;
  matched_id?: string | null;
};

function jsonResponse(body: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
      "cache-control": "no-store",
    },
  });
}

function consistentHeader(
  headers: Headers,
  primary: string,
  alias?: string,
): string {
  const primaryValue = headers.get(primary)?.trim() ?? "";
  const aliasValue = alias ? headers.get(alias)?.trim() ?? "" : "";
  if (primaryValue && aliasValue && primaryValue !== aliasValue) return "";
  return primaryValue || aliasValue;
}

function occurredAt(payload: ListenerPayload, now: number): string | null {
  if (!payload.sentAt) return null;
  if (
    payload.sentAt > now + 5 * 60 * 1000 ||
    payload.sentAt < now - MAX_OCCURRED_AGE_MS
  ) return null;
  return new Date(payload.sentAt).toISOString();
}

function sanitizedPayload(
  payload: ListenerPayload | null,
  redactNotificationContent = false,
): Record<string, unknown> {
  if (!payload) return { validJson: false };
  return {
    packageName: payload.packageName,
    title: redactNotificationContent ? "" : payload.title,
    body: redactNotificationContent ? "" : payload.body,
    bigText: redactNotificationContent ? "" : payload.bigText,
    notificationText: redactNotificationContent ? "" : payload.notificationText,
    sentAt: payload.sentAt,
    eventId: payload.eventId,
    deviceId: payload.deviceId,
  };
}

function duplicateResponse(row: PaymentEventRow | null): Response {
  const eventStatus = typeof row?.status === "string" ? row.status : "received";
  return jsonResponse({
    ok: true,
    status: "duplicate",
    eventStatus,
    matched: eventStatus === "matched",
    type: typeof row?.matched_type === "string" ? row.matched_type : undefined,
    matchedId: typeof row?.matched_id === "string" ? row.matched_id : undefined,
  });
}

function isUniqueViolation(
  error: { code?: string; message?: string } | null,
): boolean {
  return error?.code === "23505" ||
    /duplicate key|unique constraint/iu.test(error?.message ?? "");
}

function safeIdentifier(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const trimmed = value.trim();
  if (!trimmed || trimmed.length > 160) return null;
  return trimmed;
}

function publicMatchResult(data: unknown): {
  matched: boolean;
  reason?: string;
  type?: string;
  matchedId?: string;
} {
  if (!data || typeof data !== "object" || Array.isArray(data)) {
    return { matched: false, reason: "invalid_rpc_result" };
  }

  const result = data as Record<string, unknown>;
  if (result.matched !== true) {
    const reason = result.reason === "ambiguous" ? "ambiguous" : "not_found";
    return { matched: false, reason };
  }

  const allowedTypes = new Set([
    "order_payment",
    "wallet_topup",
    "order_issue_payment",
  ]);
  const type = typeof result.type === "string" && allowedTypes.has(result.type)
    ? result.type
    : "order_payment";
  const matchedId = safeIdentifier(
    type === "wallet_topup"
      ? result.topUpId
      : type === "order_issue_payment"
      ? result.issuePaymentId ?? result.orderId
      : result.orderId,
  );
  return { matched: true, type, matchedId: matchedId ?? undefined };
}

async function notifyMatchedOrder(data: unknown): Promise<void> {
  if (
    !WHATSAPP_SERVER_URL || !ORDER_NOTIFY_SECRET || !data ||
    typeof data !== "object"
  ) return;
  const result = data as Record<string, unknown>;
  if (result.matched !== true || result.type !== "order_payment") return;
  const orderId = safeIdentifier(result.orderId);
  if (!orderId) return;

  const baseUrl = WHATSAPP_SERVER_URL.replace(/\/+$/u, "");
  if (!/^https:\/\//iu.test(baseUrl)) return;
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 5000);
  try {
    const response = await fetch(`${baseUrl}/api/orders/notify`, {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "x-service-secret": ORDER_NOTIFY_SECRET,
      },
      body: JSON.stringify({
        order: {
          id: orderId,
          customer: typeof result.customerName === "string"
            ? result.customerName.slice(0, 160)
            : "",
          phone: typeof result.phone === "string"
            ? result.phone.slice(0, 40)
            : "",
          paymentStatus: "paid",
          paymentMatchedBy: "shamcash-signed-webhook",
        },
      }),
      signal: controller.signal,
    });
    if (!response.ok) {
      console.error(
        "payment webhook order notification failed",
        response.status,
        orderId,
      );
    }
  } catch (error) {
    console.error(
      "payment webhook order notification failed",
      (error as Error).message,
      orderId,
    );
  } finally {
    clearTimeout(timeout);
  }
}

async function handlePaymentWebhook(req: Request): Promise<Response> {
  if (req.method !== "POST") {
    return jsonResponse({ ok: false, error: "method_not_allowed" }, 405);
  }
  if (!PAYMENT_WEBHOOK_SECRET) {
    return jsonResponse({ ok: false, error: "service_not_configured" }, 503);
  }

  const declaredLength = Number(req.headers.get("content-length") ?? "0");
  if (Number.isFinite(declaredLength) && declaredLength > MAX_BODY_BYTES) {
    return jsonResponse({ ok: false, error: "payload_too_large" }, 413);
  }

  let rawBody: Uint8Array;
  try {
    rawBody = new Uint8Array(await req.arrayBuffer());
  } catch {
    return jsonResponse({ ok: false, error: "invalid_body" }, 400);
  }
  if (!rawBody.length || rawBody.length > MAX_BODY_BYTES) {
    return jsonResponse({
      ok: false,
      error: rawBody.length ? "payload_too_large" : "invalid_body",
    }, rawBody.length ? 413 : 400);
  }

  const deviceId = consistentHeader(
    req.headers,
    "x-payment-device",
    "x-device-id",
  );
  const eventId = consistentHeader(
    req.headers,
    "x-payment-event",
    "x-event-id",
  );
  const timestampText = consistentHeader(
    req.headers,
    "x-payment-timestamp",
    "x-event-timestamp",
  );
  const signature = consistentHeader(req.headers, "x-payment-signature");
  const timestamp = /^\d{13}$/u.test(timestampText)
    ? Number(timestampText)
    : Number.NaN;
  const now = Date.now();

  if (
    !isValidDeviceId(deviceId) ||
    !isValidEventId(eventId) ||
    !isFreshTimestamp(timestamp, now) ||
    !signature
  ) {
    return jsonResponse({ ok: false, error: "unauthorized" }, 401);
  }

  let signatureValid = false;
  try {
    signatureValid = await verifyHmacSignature(
      PAYMENT_WEBHOOK_SECRET,
      deviceId,
      eventId,
      timestamp,
      rawBody,
      signature,
    );
  } catch (error) {
    console.error(
      "payment webhook signature verification failed",
      (error as Error).message,
    );
  }
  if (!signatureValid) {
    return jsonResponse({ ok: false, error: "unauthorized" }, 401);
  }
  if (!SUPABASE_URL || !SERVICE_ROLE_KEY) {
    return jsonResponse({ ok: false, error: "service_not_configured" }, 503);
  }
  const bodyHash = await sha256Hex(rawBody);

  const contentType = req.headers.get("content-type")?.toLowerCase() ?? "";
  let payload: ListenerPayload | null = null;
  let rejectionReason = "";
  if (!contentType.startsWith("application/json")) {
    rejectionReason = "unsupported_content_type";
  } else {
    try {
      const decoded = new TextDecoder("utf-8", { fatal: true }).decode(rawBody);
      payload = parseListenerPayload(JSON.parse(decoded));
      if (!payload) rejectionReason = "invalid_json_payload";
    } catch {
      rejectionReason = "invalid_json_payload";
    }
  }

  let parsed: PaymentParseResult | null = null;
  if (payload && !rejectionReason) {
    if (payload.packageName !== TARGET_PACKAGE) {
      rejectionReason = "package_not_allowed";
    } else if (payload.eventId !== eventId || payload.deviceId !== deviceId) {
      rejectionReason = "body_identity_mismatch";
    } else {
      parsed = parseIncomingPayment(notificationTextFromPayload(payload));
      if (!parsed.ok) rejectionReason = parsed.reason;
    }
  }

  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const eventStatus = rejectionReason ? "rejected" : "received";
  const redactNotificationContent = rejectionReason === "otp_notification";
  const eventResult = rejectionReason
    ? { matched: false, reason: rejectionReason, bodyHash }
    : { bodyHash };
  const notificationText = redactNotificationContent
    ? ""
    : parsed?.notificationText ??
      (payload ? notificationTextFromPayload(payload) : "");
  const { error: insertError } = await supabase.from("payment_events").insert({
    provider: "shamcash",
    event_id: eventId,
    device_id: deviceId,
    package_name: payload?.packageName || "",
    occurred_at: payload ? occurredAt(payload, now) : null,
    notification_text: notificationText,
    raw_payload: sanitizedPayload(payload, redactNotificationContent),
    status: eventStatus,
    parsed_amount: parsed?.ok ? parsed.amount : null,
    parsed_currency: parsed?.ok ? parsed.currency : null,
    result: eventResult,
    updated_at: new Date(now).toISOString(),
  });
  let existingEvent: PaymentEventRow | null = null;

  if (insertError) {
    if (!isUniqueViolation(insertError)) {
      console.error(
        "payment webhook event insert failed",
        insertError.code,
        eventId,
      );
      return jsonResponse(
        { ok: false, error: "temporary_storage_failure" },
        503,
      );
    }

    const { data: existing, error: existingError } = await supabase
      .from("payment_events")
      .select("status,received_at,result,matched_type,matched_id")
      .eq("event_id", eventId)
      .maybeSingle();
    if (existingError || !existing) {
      console.error(
        "payment webhook duplicate lookup failed",
        existingError?.code,
        eventId,
      );
      return jsonResponse(
        { ok: false, error: "temporary_storage_failure" },
        503,
      );
    }
    existingEvent = existing;

    const existingBodyHash = typeof existing.result?.bodyHash === "string"
      ? existing.result.bodyHash
      : "";
    if (existingBodyHash && existingBodyHash !== bodyHash) {
      return jsonResponse({
        ok: true,
        status: "duplicate",
        eventStatus: existing.status,
        matched: existing.status === "matched",
        reason: "event_body_mismatch",
      });
    }

    // received/error events may represent a delivery that died immediately
    // after reserving the event. The transactional RPC locks that row and
    // either processes it once or returns its already-durable terminal result.
    const retryableUnmatched = existing.status === "unmatched" &&
      isRetryableUnmatchedTimestamp(existing.received_at, now);
    if (
      existing.status !== "received" && existing.status !== "error" &&
      !retryableUnmatched
    ) {
      return duplicateResponse(existing);
    }
    if (!parsed?.ok || rejectionReason) return duplicateResponse(existing);
    if (!existingBodyHash) return duplicateResponse(existing);
  }

  if (rejectionReason || !parsed?.ok) {
    return jsonResponse({
      ok: true,
      status: "rejected",
      reason: rejectionReason || "invalid_payment",
    });
  }

  const { data, error: rpcError } = await supabase.rpc(
    "process_shamcash_payment_event",
    {
      p_event_id: eventId,
      p_amount: parsed.amount,
      p_currency: parsed.currency,
      p_notification_text: parsed.notificationText,
    },
  );
  if (rpcError) {
    console.error("payment webhook match RPC failed", rpcError.code, eventId);
    const { error: updateError } = await supabase
      .from("payment_events")
      .update({
        status: "error",
        result: {
          matched: false,
          reason: "temporary_match_failure",
          bodyHash,
        },
        updated_at: new Date().toISOString(),
      })
      .eq("event_id", eventId)
      .in("status", ["received", "error"]);
    if (updateError) {
      console.error(
        "payment webhook error state update failed",
        updateError.code,
        eventId,
      );
    }
    return jsonResponse({ ok: false, error: "temporary_match_failure" }, 503);
  }

  const result = publicMatchResult(data);
  const terminalStatus = result.matched
    ? "matched"
    : result.reason === "ambiguous"
    ? "ambiguous"
    : "unmatched";

  // A correctly signed notification can race the transaction that creates its
  // payment intent. Keep the durable event row, but return a retryable status
  // briefly so WorkManager can reconcile it instead of losing it forever.
  if (
    terminalStatus === "unmatched" &&
    (!insertError ||
      isRetryableUnmatchedTimestamp(existingEvent?.received_at, now))
  ) {
    return jsonResponse(
      { ok: false, error: "payment_intent_not_ready" },
      425,
    );
  }

  // A concurrent/recovery duplicate may receive the durable matched result
  // from the RPC. Do not emit the secondary Telegram notification twice.
  if (result.matched && !insertError) await notifyMatchedOrder(data);
  return jsonResponse({ ok: true, status: terminalStatus, ...result });
}

Deno.serve(handlePaymentWebhook);

export { handlePaymentWebhook };
