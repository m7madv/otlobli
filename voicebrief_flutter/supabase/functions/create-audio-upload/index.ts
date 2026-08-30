import { createClient } from "@supabase/supabase-js";
import { boundedJson, BoundedJsonError } from "../_shared/bounded_json.ts";
import { bearerToken, jsonResponse } from "../_shared/http.ts";

const maxBodyBytes = 8_192;
const maxAudioBytes = 25 * 1024 * 1024;
const audioBucket = "audio-temp";
const uuidPattern =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const extensions = new Set([
  "flac",
  "mp3",
  "mp4",
  "mpeg",
  "mpga",
  "m4a",
  "ogg",
  "wav",
  "webm",
]);
const mimeTypes = new Set([
  "audio/flac",
  "audio/mpeg",
  "audio/mp4",
  "audio/wav",
  "audio/ogg",
  "audio/webm",
]);

type UploadRequest = {
  jobId: string;
  extension: string;
  mimeType: string;
  sizeBytes: number;
};

function validatedBody(value: unknown): UploadRequest | null {
  if (!value || typeof value !== "object") return null;
  const body = value as Partial<UploadRequest>;
  const extension = typeof body.extension === "string"
    ? body.extension.replace(/^\./, "").toLowerCase()
    : "";
  if (
    typeof body.jobId !== "string" || !uuidPattern.test(body.jobId) ||
    !extensions.has(extension) ||
    typeof body.mimeType !== "string" || !mimeTypes.has(body.mimeType) ||
    !Number.isInteger(body.sizeBytes) || body.sizeBytes! <= 0 ||
    body.sizeBytes! > maxAudioBytes
  ) {
    return null;
  }
  return {
    jobId: body.jobId,
    extension,
    mimeType: body.mimeType,
    sizeBytes: body.sizeBytes!,
  };
}

Deno.serve(async (request) => {
  if (request.method !== "POST") {
    return jsonResponse(405, { error: "method_not_allowed" });
  }
  const token = bearerToken(request);
  if (!token) return jsonResponse(401, { error: "authentication_required" });

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (!supabaseUrl || !anonKey || !serviceRoleKey) {
    return jsonResponse(503, { error: "service_not_configured" });
  }

  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: `Bearer ${token}` } },
    auth: { persistSession: false },
  });
  const serviceClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false },
  });
  const { data: userData, error: userError } = await userClient.auth.getUser(
    token,
  );
  if (userError || !userData.user) {
    return jsonResponse(401, { error: "authentication_required" });
  }

  let body: UploadRequest | null = null;
  try {
    body = validatedBody(await boundedJson(request, maxBodyBytes));
  } catch (error) {
    if (error instanceof BoundedJsonError) {
      const code = error.status === 413
        ? "request_too_large"
        : error.status === 415
        ? "unsupported_media_type"
        : "invalid_request";
      return jsonResponse(error.status, { error: code });
    }
  }
  if (body == null) return jsonResponse(400, { error: "invalid_request" });

  const userId = userData.user.id;
  const storagePath = `${userId}/${body.jobId}/input.${body.extension}`;
  const { data: existingJob, error: existingJobError } = await serviceClient
    .from("processing_jobs")
    .select("status, result, expires_at")
    .eq("user_id", userId)
    .eq("id", body.jobId)
    .maybeSingle();
  if (existingJobError) {
    return jsonResponse(503, { error: "service_unavailable" });
  }
  if (
    existingJob?.status === "completed" && existingJob.result != null &&
    Date.parse(existingJob.expires_at) > Date.now()
  ) {
    return jsonResponse(200, { result: existingJob.result, idempotent: true });
  }
  if (
    existingJob?.status === "reserving" || existingJob?.status === "processing"
  ) {
    return jsonResponse(409, { error: "job_in_progress" });
  }

  const { data: expired, error: expiredError } = await serviceClient
    .from("audio_upload_reservations")
    .select("job_id, storage_path")
    .eq("user_id", userId)
    .lte("expires_at", new Date().toISOString())
    .limit(20);
  if (expiredError) return jsonResponse(503, { error: "service_unavailable" });
  if ((expired ?? []).length > 0) {
    const expiredPaths = expired!.map((item) => item.storage_path as string);
    const { error: removeError } = await serviceClient.storage.from(audioBucket)
      .remove(expiredPaths);
    if (removeError) {
      return jsonResponse(503, { error: "storage_cleanup_failed" });
    }
    const expiredIds = expired!.map((item) => item.job_id as string);
    const { error: reservationDeleteError } = await serviceClient
      .from("audio_upload_reservations")
      .delete()
      .eq("user_id", userId)
      .in("job_id", expiredIds);
    if (reservationDeleteError) {
      return jsonResponse(503, { error: "storage_cleanup_failed" });
    }
  }

  const { data: reservation, error: reservationError } = await serviceClient
    .rpc("reserve_voicebrief_upload", {
      p_user_id: userId,
      p_job_id: body.jobId,
      p_storage_path: storagePath,
      p_size_bytes: body.sizeBytes,
      p_mime_type: body.mimeType,
    });
  if (reservationError) {
    return jsonResponse(409, { error: "upload_reservation_failed" });
  }
  if (reservation?.state === "rate_limited") {
    return jsonResponse(429, { error: "upload_rate_limited" });
  }
  if (reservation?.state !== "reserved" && reservation?.state !== "existing") {
    return jsonResponse(409, { error: "upload_reservation_failed" });
  }

  if (reservation.state === "existing") {
    await serviceClient.storage.from(audioBucket).remove([storagePath]);
  }
  const { data: signed, error: signedError } = await serviceClient.storage
    .from(audioBucket)
    .createSignedUploadUrl(storagePath, { upsert: false });
  if (signedError || !signed?.token) {
    await serviceClient.rpc("release_voicebrief_upload", {
      p_user_id: userId,
      p_job_id: body.jobId,
    });
    return jsonResponse(503, { error: "upload_url_failed" });
  }
  return jsonResponse(200, {
    storagePath,
    uploadToken: signed.token,
  });
});
