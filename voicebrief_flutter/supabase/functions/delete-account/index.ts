import { createClient } from "@supabase/supabase-js";
import { bearerToken, jsonResponse, sha256 } from "../_shared/http.ts";
import {
  deleteAccountWithRevenueCatFirst,
  deleteRevenueCatSubscriber,
  RevenueCatSubscriberDeletionError,
} from "./core.ts";

async function allAudioPaths(
  bucket: ReturnType<ReturnType<typeof createClient>["storage"]["from"]>,
  userId: string,
): Promise<string[]> {
  const paths: string[] = [];
  const folders = [userId];
  const pageSize = 100;
  while (folders.length > 0) {
    const folder = folders.pop()!;
    let offset = 0;
    while (true) {
      const { data, error } = await bucket.list(folder, {
        limit: pageSize,
        offset,
        sortBy: { column: "name", order: "asc" },
      });
      if (error) throw new Error("storage_list_failed");
      const entries = data ?? [];
      for (const entry of entries) {
        const itemPath = `${folder}/${entry.name}`;
        if (entry.id) paths.push(itemPath);
        else folders.push(itemPath);
      }
      if (entries.length < pageSize) break;
      offset += entries.length;
    }
  }
  return paths;
}

Deno.serve(async (request) => {
  if (request.method !== "POST") {
    return jsonResponse(405, { error: "method_not_allowed" });
  }
  const token = bearerToken(request);
  if (!token) return jsonResponse(401, { error: "authentication_required" });

  const url = Deno.env.get("SUPABASE_URL") ?? "";
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (!url || !anonKey || !serviceRoleKey) {
    return jsonResponse(503, { error: "service_not_configured" });
  }

  const userClient = createClient(url, anonKey, {
    global: { headers: { Authorization: `Bearer ${token}` } },
    auth: { persistSession: false },
  });
  const serviceClient = createClient(url, serviceRoleKey, {
    auth: { persistSession: false },
  });
  const { data, error } = await userClient.auth.getUser(token);
  if (error || !data.user) {
    return jsonResponse(401, { error: "authentication_required" });
  }

  const userId = data.user.id;
  const userHash = (await sha256(userId)).slice(0, 12);
  const revenueCatSecret = Deno.env.get("REVENUECAT_SECRET_API_KEY") ?? "";
  if (!revenueCatSecret) {
    return jsonResponse(503, { error: "service_not_configured" });
  }

  try {
    await deleteAccountWithRevenueCatFirst(
      () => deleteRevenueCatSubscriber(userId, revenueCatSecret),
      async () => {
        await serviceClient.from("account_deletion_requests").insert({
          user_id: userId,
          status: "requested",
        });
        const bucket = serviceClient.storage.from("audio-temp");
        const paths = await allAudioPaths(bucket, userId);
        for (let offset = 0; offset < paths.length; offset += 100) {
          const { error: removeError } = await bucket.remove(
            paths.slice(offset, offset + 100),
          );
          if (removeError) throw new Error("storage_delete_failed");
        }
        const { data: remaining, error: verifyError } = await bucket.list(
          userId,
          { limit: 1 },
        );
        if (verifyError || (remaining?.length ?? 0) > 0) {
          throw new Error("storage_delete_incomplete");
        }
        const { error: deleteError } = await serviceClient.auth.admin
          .deleteUser(userId, false);
        if (deleteError) throw new Error("auth_delete_failed");
      },
    );
    return jsonResponse(200, { deleted: true });
  } catch (error) {
    const revenueCatFailure = error instanceof
      RevenueCatSubscriberDeletionError;
    console.error(
      JSON.stringify({
        event: "account_delete_failed",
        stage: revenueCatFailure ? "revenuecat" : "supabase",
        code: revenueCatFailure ? error.code : "supabase_delete_failed",
        user: userHash,
      }),
    );
    return jsonResponse(
      revenueCatFailure ? 502 : 500,
      { error: "account_deletion_failed" },
    );
  }
});
