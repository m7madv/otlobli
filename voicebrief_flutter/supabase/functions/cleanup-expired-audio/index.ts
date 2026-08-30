import { createClient } from "@supabase/supabase-js";
import {
  AudioCleanupError,
  cleanupExpiredAudio,
  configuredSecretKeys,
} from "./core.ts";
import { constantTimeEqual, jsonResponse } from "../_shared/http.ts";

const audioBucket = "audio-temp";

Deno.serve(async (request) => {
  if (request.method !== "POST") {
    return jsonResponse(405, { error: "method_not_allowed" });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const providedKey = request.headers.get("apikey") ?? "";
  const configuredKeys = configuredSecretKeys(
    Deno.env.get("SUPABASE_SECRET_KEYS"),
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY"),
  );
  if (
    !supabaseUrl || !providedKey ||
    !configuredKeys.some((key) => constantTimeEqual(providedKey, key))
  ) {
    return jsonResponse(401, { error: "invalid_cleanup_authorization" });
  }

  const serviceClient = createClient(supabaseUrl, providedKey, {
    auth: { persistSession: false },
  });

  try {
    const summary = await cleanupExpiredAudio({
      async claim(limit) {
        const { data, error } = await serviceClient.rpc(
          "claim_expired_voicebrief_uploads",
          { p_limit: limit },
        );
        if (error) throw new Error("cleanup_claim_failed");
        return data;
      },
      async remove(storagePaths) {
        const { error } = await serviceClient.storage.from(audioBucket).remove(
          storagePaths,
        );
        if (error) throw new Error("storage_cleanup_failed");
      },
      async complete(claimId, storagePaths) {
        const { data, error } = await serviceClient.rpc(
          "complete_expired_voicebrief_upload_cleanup",
          {
            p_claim_id: claimId,
            p_storage_paths: storagePaths,
          },
        );
        if (error) {
          throw new Error("cleanup_finalize_failed");
        }
        return data;
      },
      async release(claimId) {
        const { error } = await serviceClient.rpc(
          "release_expired_voicebrief_upload_cleanup",
          { p_claim_id: claimId },
        );
        if (error) throw new Error("cleanup_release_failed");
      },
    });
    console.info(
      JSON.stringify({
        event: "voicebrief_expired_audio_cleanup",
        claimed: summary.claimed,
        staged: summary.staged,
        deleted: summary.deleted,
      }),
    );
    return jsonResponse(200, summary);
  } catch (error) {
    const code = error instanceof AudioCleanupError
      ? error.code
      : "audio_cleanup_failed";
    console.error(
      JSON.stringify({
        event: "voicebrief_expired_audio_cleanup_failed",
        code,
      }),
    );
    return jsonResponse(503, { error: code });
  }
});
