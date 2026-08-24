import { createClient } from "@supabase/supabase-js";
import { bearerToken, jsonResponse, sha256 } from "../_shared/http.ts";

const MAX_AUDIO_BYTES = 25 * 1024 * 1024;
const MAX_DURATION_SECONDS = 6 * 60 * 60;
const AUDIO_BUCKET = "audio-temp";
const SUPPORTED_EXTENSIONS = new Set([
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
const SUPPORTED_MIME_TYPES = new Set([
  "audio/flac",
  "audio/mpeg",
  "audio/mp4",
  "audio/wav",
  "audio/ogg",
  "audio/webm",
]);
const UUID_PATTERN =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

class SafeError extends Error {
  constructor(public code: string, public status = 400) {
    super(code);
  }
}

type RequestBody = {
  jobId: string;
  storagePath: string;
  displayName: string;
  mimeType: string;
  sizeBytes: number;
  durationSeconds: number;
  timeZoneOffsetMinutes?: number;
  options?: Record<string, boolean>;
};

type ReserveResult = {
  state:
    | "reserved"
    | "completed"
    | "in_progress"
    | "quota_exhausted"
    | "service_budget_exhausted";
  plan?: "free" | "pro";
  result?: Record<string, unknown>;
};

function validateBody(value: unknown, userId: string): RequestBody {
  if (!value || typeof value !== "object") {
    throw new SafeError("invalid_request");
  }
  const body = value as Partial<RequestBody>;
  if (typeof body.jobId !== "string" || !UUID_PATTERN.test(body.jobId)) {
    throw new SafeError("invalid_job_id");
  }
  if (typeof body.storagePath !== "string") {
    throw new SafeError("invalid_storage_path");
  }
  const prefix = `${userId}/${body.jobId}/input.`;
  if (!body.storagePath.startsWith(prefix) || body.storagePath.includes("..")) {
    throw new SafeError("invalid_storage_path");
  }
  const extension = body.storagePath.slice(prefix.length).toLowerCase();
  if (!SUPPORTED_EXTENSIONS.has(extension)) {
    throw new SafeError("unsupported_audio");
  }
  if (
    typeof body.displayName !== "string" || body.displayName.length < 1 ||
    body.displayName.length > 255
  ) {
    throw new SafeError("invalid_file_name");
  }
  if (
    typeof body.mimeType !== "string" ||
    !SUPPORTED_MIME_TYPES.has(body.mimeType)
  ) {
    throw new SafeError("unsupported_audio");
  }
  if (
    !Number.isInteger(body.sizeBytes) || body.sizeBytes! <= 0 ||
    body.sizeBytes! > MAX_AUDIO_BYTES
  ) {
    throw new SafeError("invalid_file_size");
  }
  if (
    !Number.isInteger(body.durationSeconds) || body.durationSeconds! <= 0 ||
    body.durationSeconds! > MAX_DURATION_SECONDS
  ) {
    throw new SafeError("invalid_duration");
  }
  if (
    body.timeZoneOffsetMinutes !== undefined &&
    (!Number.isInteger(body.timeZoneOffsetMinutes) ||
      body.timeZoneOffsetMinutes < -840 || body.timeZoneOffsetMinutes > 840)
  ) {
    throw new SafeError("invalid_time_zone");
  }
  return body as RequestBody;
}

async function openAiRequest(
  url: string,
  initFactory: () => RequestInit,
): Promise<Record<string, unknown>> {
  for (let attempt = 0; attempt < 3; attempt += 1) {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 90_000);
    try {
      const response = await fetch(url, {
        ...initFactory(),
        signal: controller.signal,
      });
      if (response.ok) return await response.json();
      if (attempt < 2 && (response.status === 429 || response.status >= 500)) {
        await new Promise((resolve) =>
          setTimeout(resolve, 500 * (2 ** attempt))
        );
        continue;
      }
      throw new SafeError("openai_request_failed", 502);
    } catch (error) {
      if (error instanceof SafeError) throw error;
      if (attempt === 2) throw new SafeError("openai_timeout", 504);
    } finally {
      clearTimeout(timeout);
    }
  }
  throw new SafeError("openai_request_failed", 502);
}

function outputText(response: Record<string, unknown>): string {
  if (typeof response.output_text === "string") return response.output_text;
  const output = Array.isArray(response.output) ? response.output : [];
  for (const item of output) {
    if (!item || typeof item !== "object") continue;
    const content = Array.isArray((item as { content?: unknown }).content)
      ? (item as { content: unknown[] }).content
      : [];
    for (const part of content) {
      if (
        part && typeof part === "object" &&
        (part as { type?: unknown }).type === "output_text"
      ) {
        const text = (part as { text?: unknown }).text;
        if (typeof text === "string") return text;
      }
    }
  }
  throw new SafeError("invalid_model_response", 502);
}

const briefSchema = {
  type: "object",
  additionalProperties: false,
  required: [
    "detectedLanguage",
    "title",
    "summary",
    "keyPoints",
    "actionItems",
    "importantDates",
    "suggestedReplies",
  ],
  properties: {
    detectedLanguage: { type: "string", minLength: 2, maxLength: 20 },
    title: { type: "string", minLength: 1, maxLength: 120 },
    summary: { type: "string", maxLength: 4000 },
    keyPoints: {
      type: "array",
      maxItems: 20,
      items: { type: "string", maxLength: 500 },
    },
    actionItems: {
      type: "array",
      maxItems: 20,
      items: {
        type: "object",
        additionalProperties: false,
        required: [
          "title",
          "owner",
          "dueDateIso",
          "originalDatePhrase",
          "confidence",
        ],
        properties: {
          title: { type: "string", maxLength: 500 },
          owner: { type: ["string", "null"], maxLength: 120 },
          dueDateIso: { type: ["string", "null"], maxLength: 40 },
          originalDatePhrase: { type: ["string", "null"], maxLength: 240 },
          confidence: { type: "number", minimum: 0, maximum: 1 },
        },
      },
    },
    importantDates: {
      type: "array",
      maxItems: 20,
      items: {
        type: "object",
        additionalProperties: false,
        required: [
          "label",
          "dateIso",
          "originalPhrase",
          "confidence",
          "requiresConfirmation",
        ],
        properties: {
          label: { type: "string", maxLength: 240 },
          dateIso: { type: ["string", "null"], maxLength: 40 },
          originalPhrase: { type: "string", maxLength: 240 },
          confidence: { type: "number", minimum: 0, maximum: 1 },
          requiresConfirmation: { type: "boolean" },
        },
      },
    },
    suggestedReplies: {
      type: "object",
      additionalProperties: false,
      required: ["short", "friendly", "professional"],
      properties: {
        short: { type: "string", maxLength: 800 },
        friendly: { type: "string", maxLength: 1200 },
        professional: { type: "string", maxLength: 1200 },
      },
    },
  },
} as const;

Deno.serve(async (request) => {
  if (request.method !== "POST") {
    return jsonResponse(405, { error: "method_not_allowed" });
  }
  const token = bearerToken(request);
  if (!token) return jsonResponse(401, { error: "authentication_required" });

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  const openAiKey = Deno.env.get("OPENAI_API_KEY") ?? "";
  if (!supabaseUrl || !anonKey || !serviceRoleKey || !openAiKey) {
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

  let body: RequestBody;
  try {
    const contentLength = Number(request.headers.get("content-length") ?? "0");
    if (contentLength > 32_768) throw new SafeError("request_too_large", 413);
    body = validateBody(await request.json(), userData.user.id);
  } catch (error) {
    const safe = error instanceof SafeError
      ? error
      : new SafeError("invalid_request");
    return jsonResponse(safe.status, { error: safe.code });
  }

  const jobHash = (await sha256(body.jobId)).slice(0, 12);
  let reserved = false;
  try {
    const { data, error } = await serviceClient.rpc(
      "reserve_voicebrief_minutes",
      {
        p_user_id: userData.user.id,
        p_job_id: body.jobId,
        p_storage_path: body.storagePath,
        p_duration_seconds: body.durationSeconds,
      },
    );
    if (error) throw new SafeError("usage_reservation_failed", 409);
    const reservation = data as ReserveResult;
    if (reservation.state === "completed" && reservation.result) {
      return jsonResponse(200, {
        result: reservation.result,
        idempotent: true,
      });
    }
    if (reservation.state === "in_progress") {
      return jsonResponse(409, { error: "job_in_progress" });
    }
    if (reservation.state === "quota_exhausted") {
      return jsonResponse(402, { error: "quota_exhausted" });
    }
    if (reservation.state === "service_budget_exhausted") {
      return jsonResponse(503, { error: "service_budget_exhausted" });
    }
    if (reservation.state !== "reserved") {
      throw new SafeError("usage_reservation_failed", 409);
    }
    reserved = true;

    const { data: blob, error: downloadError } = await serviceClient.storage
      .from(AUDIO_BUCKET).download(body.storagePath);
    if (
      downloadError || !blob || blob.size <= 0 || blob.size > MAX_AUDIO_BYTES ||
      blob.size !== body.sizeBytes
    ) {
      throw new SafeError("invalid_uploaded_audio");
    }

    const { error: aiStartedError } = await serviceClient.rpc(
      "mark_voicebrief_ai_started",
      { p_user_id: userData.user.id, p_job_id: body.jobId },
    );
    if (aiStartedError) throw new SafeError("usage_reservation_failed", 409);

    const transcriptionModel = Deno.env.get("OPENAI_TRANSCRIPTION_MODEL") ||
      "gpt-transcribe";
    const transcription = await openAiRequest(
      "https://api.openai.com/v1/audio/transcriptions",
      () => {
        const form = new FormData();
        form.append("model", transcriptionModel);
        form.append("response_format", "json");
        form.append("file", blob, body.displayName);
        return {
          method: "POST",
          headers: { Authorization: `Bearer ${openAiKey}` },
          body: form,
        };
      },
    );
    if (
      typeof transcription.text !== "string" ||
      transcription.text.trim().length === 0
    ) {
      throw new SafeError("invalid_transcription", 502);
    }

    const plan = reservation.plan === "pro" ? "pro" : "free";
    const requested = body.options ?? {};
    const referenceInstant = new Date().toISOString();
    const timeZoneOffsetMinutes = body.timeZoneOffsetMinutes ?? 0;
    const productRules = plan === "pro"
      ? "Return every requested section and all three reply tones."
      : "This is the Free plan: return transcript and summary, no key points/actions/dates, and only the short reply; friendly and professional must be empty strings.";
    const prompt = [
      "Create an accurate VoiceBrief result from the transcript below.",
      "The audio may be English, Arabic, or mixed Arabic/English. detectedLanguage should be en, ar, or mixed.",
      "Never invent facts, owners, dates, phone numbers, or commitments.",
      `Reference instant: ${referenceInstant}. The user's UTC offset is ${timeZoneOffsetMinutes} minutes. Resolve relative dates such as tomorrow or next Thursday from the user's local date.`,
      "When a date or time is sufficiently clear, return an ISO 8601 value with the user's explicit UTC offset. Preserve the spoken phrase in originalPhrase.",
      "For ambiguous dates, keep dateIso null, preserve originalPhrase, lower confidence, and set requiresConfirmation true.",
      "Do not duplicate an action-item deadline in importantDates unless it is also a distinct calendar event.",
      "Suggested replies must preserve the speaker's meaning and must not add commitments.",
      productRules,
      `Requested options: ${JSON.stringify(requested)}`,
      "Transcript:",
      transcription.text,
    ].join("\n\n");

    const summaryModel = Deno.env.get("OPENAI_SUMMARY_MODEL") || "gpt-5.6-luna";
    const structured = await openAiRequest(
      "https://api.openai.com/v1/responses",
      () => ({
        method: "POST",
        headers: {
          Authorization: `Bearer ${openAiKey}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          model: summaryModel,
          input: prompt,
          text: {
            format: {
              type: "json_schema",
              name: "voicebrief_result",
              strict: true,
              schema: briefSchema,
            },
          },
        }),
      }),
    );
    const generated = JSON.parse(outputText(structured)) as Record<
      string,
      unknown
    >;
    if (plan === "free" || requested.actionItems === false) {
      generated.keyPoints = [];
      generated.actionItems = [];
      generated.importantDates = [];
    }
    if (requested.summary === false) generated.summary = "";
    const generatedReplies = generated.suggestedReplies as Record<
      string,
      unknown
    >;
    if (requested.suggestedReplies === false) {
      generated.suggestedReplies = {
        short: "",
        friendly: "",
        professional: "",
      };
    } else if (plan === "free") {
      generated.suggestedReplies = {
        short: typeof generatedReplies.short === "string"
          ? generatedReplies.short
          : "",
        friendly: "",
        professional: "",
      };
    }
    const result = {
      id: body.jobId,
      ...generated,
      transcript: requested.transcript === false ? "" : transcription.text,
      audioDurationSeconds: body.durationSeconds,
      processedAt: new Date().toISOString(),
      savedLocally: false,
    };
    const { error: completeError } = await serviceClient.rpc(
      "complete_voicebrief_job",
      {
        p_user_id: userData.user.id,
        p_job_id: body.jobId,
        p_result: result,
      },
    );
    if (completeError) throw new SafeError("usage_charge_failed", 500);
    reserved = false;
    return jsonResponse(200, { result });
  } catch (error) {
    const safe = error instanceof SafeError
      ? error
      : new SafeError("processing_failed", 500);
    if (reserved) {
      await serviceClient.rpc("fail_voicebrief_job", {
        p_user_id: userData.user.id,
        p_job_id: body.jobId,
        p_error_code: safe.code,
      });
    }
    console.error(
      JSON.stringify({
        event: "voicebrief_processing_failed",
        code: safe.code,
        job: jobHash,
      }),
    );
    return jsonResponse(safe.status, { error: safe.code });
  } finally {
    await serviceClient.storage.from(AUDIO_BUCKET).remove([body.storagePath]);
  }
});
