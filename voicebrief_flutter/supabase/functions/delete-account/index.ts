import { createClient } from "@supabase/supabase-js";
import { bearerToken, jsonResponse, sha256 } from "../_shared/http.ts";

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
  try {
    await serviceClient.from("account_deletion_requests").insert({
      user_id: userId,
      status: "requested",
    });
    const { data: jobFolders, error: listError } = await serviceClient.storage
      .from("audio-temp")
      .list(userId, { limit: 1000 });
    if (listError) throw new Error("storage_list_failed");
    const paths: string[] = [];
    for (const folder of jobFolders ?? []) {
      if (folder.id) {
        paths.push(`${userId}/${folder.name}`);
        continue;
      }
      const { data: files } = await serviceClient.storage.from("audio-temp")
        .list(`${userId}/${folder.name}`, { limit: 1000 });
      for (const file of files ?? []) {
        paths.push(`${userId}/${folder.name}/${file.name}`);
      }
    }
    if (paths.length > 0) {
      const { error: removeError } = await serviceClient.storage.from(
        "audio-temp",
      ).remove(paths);
      if (removeError) throw new Error("storage_delete_failed");
    }
    const { error: deleteError } = await serviceClient.auth.admin.deleteUser(
      userId,
      false,
    );
    if (deleteError) throw new Error("auth_delete_failed");
    return jsonResponse(200, { deleted: true });
  } catch {
    console.error(
      JSON.stringify({ event: "account_delete_failed", user: userHash }),
    );
    return jsonResponse(500, { error: "account_deletion_failed" });
  }
});
