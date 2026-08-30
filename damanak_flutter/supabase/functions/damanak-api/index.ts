import { createClient } from "@supabase/supabase-js";

const corsHeaders = {
  "access-control-allow-origin": "*",
  "access-control-allow-headers": "authorization, content-type",
  "access-control-allow-methods": "GET, POST, OPTIONS",
};
const claimCategories = new Set([
  "malfunction",
  "battery",
  "software",
  "physical_damage",
  "missing_parts",
  "other",
]);
const claimPriorities = new Set(["low", "normal", "high", "urgent"]);

function env(name: string) {
  const value = Deno.env.get(name)?.trim();
  if (!value) throw new Error(`MISSING_SECRET_${name}`);
  return value;
}

function response(status: number, body: Record<string, unknown>) {
  return Response.json(body, {
    status,
    headers: {
      ...corsHeaders,
      "cache-control": "no-store",
      "x-content-type-options": "nosniff",
    },
  });
}

function bearer(request: Request) {
  const header = request.headers.get("authorization")?.trim() || "";
  return header.startsWith("Bearer ") ? header.slice(7).trim() : "";
}

function text(value: unknown, maxLength: number) {
  return typeof value === "string" ? value.trim().slice(0, maxLength) : "";
}

if (import.meta.main) {
  Deno.serve(async (request) => {
    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: corsHeaders });
    }
    const presentedKey = bearer(request);
    if (!presentedKey) return response(401, { error: "API_KEY_REQUIRED" });

    const admin = createClient(
      env("SUPABASE_URL"),
      env("SUPABASE_SERVICE_ROLE_KEY"),
      { auth: { persistSession: false, autoRefreshToken: false } },
    );
    const { data: identity, error: identityError } = await admin.rpc(
      "authenticate_store_api_key",
      { presented_key: presentedKey },
    );
    if (identityError || !identity || typeof identity !== "object") {
      return response(401, { error: "API_KEY_INVALID" });
    }
    const keyId = String((identity as Record<string, unknown>).keyId || "");
    const storeId = String((identity as Record<string, unknown>).storeId || "");
    const scopes = Array.isArray((identity as Record<string, unknown>).scopes)
      ? (identity as Record<string, unknown>).scopes as string[]
      : [];
    const url = new URL(request.url);
    const path = url.pathname.replace(/^.*\/damanak-api/, "") || "/";

    const { count } = await admin.from("api_request_logs")
      .select("id", { count: "exact", head: true })
      .eq("key_id", keyId)
      .gte("created_at", new Date(Date.now() - 3_600_000).toISOString());
    if ((count ?? 0) >= 300) {
      return response(429, { error: "API_RATE_LIMIT" });
    }

    const finish = async (status: number, body: Record<string, unknown>) => {
      await admin.from("api_request_logs").insert({
        key_id: keyId,
        store_id: storeId,
        method: request.method,
        path: path.slice(0, 200),
        response_status: status,
      });
      return response(status, body);
    };

    try {
      if (request.method === "GET" && path === "/v1/warranties") {
        if (!scopes.includes("warranties:read")) {
          return await finish(403, { error: "SCOPE_REQUIRED" });
        }
        const warrantyNumber = text(url.searchParams.get("warrantyNumber"), 80);
        const serialNumber = text(url.searchParams.get("serialNumber"), 160);
        const customerPhone = text(url.searchParams.get("customerPhone"), 30);
        if (!warrantyNumber && !serialNumber && !customerPhone) {
          return await finish(400, { error: "WARRANTY_FILTER_REQUIRED" });
        }
        let query = admin.from("warranties").select(
          "id,warranty_number,product_name,serial_number,purchase_date,expiry_date,customer_name,customer_phone,created_at",
        ).eq("store_id", storeId).is("voided_at", null).limit(50);
        if (warrantyNumber) query = query.eq("warranty_number", warrantyNumber);
        if (serialNumber) query = query.eq("serial_number", serialNumber);
        if (customerPhone) query = query.eq("customer_phone", customerPhone);
        const { data, error } = await query;
        if (error) return await finish(500, { error: "QUERY_FAILED" });
        return await finish(200, { data: data ?? [] });
      }

      if (request.method === "GET" && path === "/v1/claims") {
        if (!scopes.includes("claims:read")) {
          return await finish(403, { error: "SCOPE_REQUIRED" });
        }
        const updatedAfter = text(url.searchParams.get("updatedAfter"), 40);
        let query = admin.from("maintenance_requests").select(
          "id,claim_number,warranty_id,status,category,priority,channel,sla_due_at,created_at,updated_at",
        ).eq("store_id", storeId).order("updated_at", { ascending: false })
          .limit(100);
        if (updatedAfter && !Number.isNaN(Date.parse(updatedAfter))) {
          query = query.gte("updated_at", updatedAfter);
        }
        const { data, error } = await query;
        if (error) return await finish(500, { error: "QUERY_FAILED" });
        return await finish(200, { data: data ?? [] });
      }

      if (request.method === "POST" && path === "/v1/claims") {
        if (!scopes.includes("claims:write")) {
          return await finish(403, { error: "SCOPE_REQUIRED" });
        }
        let body: Record<string, unknown>;
        try {
          body = await request.json();
        } catch {
          return await finish(400, { error: "JSON_INVALID" });
        }
        const warrantyId = text(body.warrantyId, 36);
        const issue = text(body.issue, 2000);
        const category = text(body.category, 40) || "other";
        const priority = text(body.priority, 20) || "normal";
        if (
          !/^[0-9a-f-]{36}$/i.test(warrantyId) || issue.length < 3 ||
          !claimCategories.has(category) || !claimPriorities.has(priority)
        ) {
          return await finish(400, { error: "CLAIM_INPUT_INVALID" });
        }
        const { data: warranty } = await admin.from("warranties")
          .select("id,expiry_date").eq("id", warrantyId)
          .eq("store_id", storeId).is("voided_at", null).maybeSingle();
        if (!warranty) return await finish(404, { error: "WARRANTY_NOT_FOUND" });
        const today = new Date().toISOString().slice(0, 10);
        if (warranty.expiry_date < today) {
          return await finish(409, { error: "WARRANTY_EXPIRED" });
        }
        const { data, error } = await admin.from("maintenance_requests").insert({
          store_id: storeId,
          warranty_id: warrantyId,
          issue,
          category,
          priority,
          channel: "api",
          created_by: null,
        }).select("id,claim_number,status,created_at").single();
        if (error || !data) return await finish(500, { error: "CLAIM_CREATE_FAILED" });
        return await finish(201, { data });
      }

      return await finish(404, { error: "ENDPOINT_NOT_FOUND" });
    } catch {
      return await finish(500, { error: "API_UNAVAILABLE" });
    }
  });
}
