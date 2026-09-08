/// <reference path="../editor-compat.d.ts" />

import { createClient, type SupabaseClient } from "npm:@supabase/supabase-js@2";

type CleanupQueueRow = {
  trip_id: string;
  owner_id: string;
  attempts: number;
};

const storageLocations = (row: CleanupQueueRow) => [
  { bucket: "trip-documents", directory: row.trip_id },
  { bucket: "trip-images", directory: `${row.owner_id}/${row.trip_id}` },
  { bucket: "group-expense-receipts", directory: `trips/${row.trip_id}` },
];

Deno.serve(async (request) => {
  if (request.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceRoleKey) {
    return jsonResponse({ error: "Server configuration is incomplete" }, 500);
  }

  const client = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  let removed = 0;
  let failed = 0;

  while (true) {
    const { data, error } = await client
      .from("trip_storage_cleanup_queue")
      .select("trip_id, owner_id, attempts")
      .order("queued_at")
      .limit(25);
    if (error) {
      console.error("Unable to read trip Storage cleanup queue", error);
      return jsonResponse({ error: "Unable to read cleanup queue" }, 500);
    }
    if (!data || data.length === 0) break;

    for (const row of data as CleanupQueueRow[]) {
      try {
        for (const location of storageLocations(row)) {
          await removeDirectoryRecursively(
            client,
            location.bucket,
            location.directory,
          );
        }

        const { error: deleteError } = await client
          .from("trip_storage_cleanup_queue")
          .delete()
          .eq("trip_id", row.trip_id);
        if (deleteError) throw deleteError;
        removed++;
      } catch (error) {
        failed++;
        const message = error instanceof Error ? error.message : String(error);
        console.error(`Storage cleanup failed for trip ${row.trip_id}`, error);
        const { error: updateError } = await client
          .from("trip_storage_cleanup_queue")
          .update({
            attempts: row.attempts + 1,
            last_error: message.slice(0, 2000),
            last_attempt_at: new Date().toISOString(),
          })
          .eq("trip_id", row.trip_id);
        if (updateError) {
          console.error(
            `Unable to record cleanup failure for trip ${row.trip_id}`,
            updateError,
          );
        }
      }
    }

    // Avoid retrying failed rows repeatedly during the same invocation.
    if (failed > 0 || data.length < 25) break;
  }

  return jsonResponse({ removed, failed });
});

async function removeDirectoryRecursively(
  client: SupabaseClient,
  bucket: string,
  directory: string,
) {
  const paths = await listFilesRecursively(client, bucket, directory);
  for (let index = 0; index < paths.length; index += 100) {
    const { error } = await client.storage
      .from(bucket)
      .remove(paths.slice(index, index + 100));
    if (error) {
      throw new Error(
        `Unable to remove files from ${bucket}: ${error.message}`,
      );
    }
  }
}

async function listFilesRecursively(
  client: SupabaseClient,
  bucket: string,
  directory: string,
): Promise<string[]> {
  const paths: string[] = [];
  const pageSize = 100;
  let offset = 0;

  while (true) {
    const { data, error } = await client.storage.from(bucket).list(directory, {
      limit: pageSize,
      offset,
      sortBy: { column: "name", order: "asc" },
    });
    if (error) {
      if (error.message.toLowerCase().includes("bucket not found")) {
        return paths;
      }
      throw new Error(`Unable to list ${bucket}: ${error.message}`);
    }
    if (!data || data.length === 0) break;

    for (const entry of data) {
      const path = `${directory}/${entry.name}`;
      if (entry.id == null) {
        paths.push(...await listFilesRecursively(client, bucket, path));
      } else {
        paths.push(path);
      }
    }
    if (data.length < pageSize) break;
    offset += pageSize;
  }

  return paths;
}

function jsonResponse(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
