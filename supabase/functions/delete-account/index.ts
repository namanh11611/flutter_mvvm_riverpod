import { createClient } from "npm:@supabase/supabase-js@2";

const personalBuckets = [
  "profile-images",
  "background-images",
  "user-gallery",
  "trip-images",
];

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const authHeader = req.headers.get("Authorization");

    if (!supabaseUrl || !supabaseAnonKey || !serviceRoleKey) {
      return jsonResponse({ error: "Server configuration is incomplete" }, 500);
    }
    if (!authHeader) {
      return jsonResponse({ error: "Missing Authorization header" }, 401);
    }

    const token = authHeader.replace(/^Bearer\s+/i, "");
    const userClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data: { user }, error: userError } =
      await userClient.auth.getUser(token);
    if (userError || !user) {
      return jsonResponse({ error: "Unauthorized" }, 401);
    }

    const adminClient = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    // Personal media uses a user-id directory in each bucket. Delete it before
    // the database transaction removes the account and invalidates its token.
    for (const bucket of personalBuckets) {
      await removeUserDirectory(adminClient, bucket, user.id);
    }
    await removeUserTripDocuments(adminClient, user.id);

    const { error: deleteError } = await adminClient.rpc(
      "delete_user_account",
      { p_user_id: user.id },
    );
    if (deleteError) {
      console.error("Account database deletion failed:", deleteError.message);
      return jsonResponse({ error: "Unable to delete account data" }, 500);
    }

    return jsonResponse({ deleted: true });
  } catch (error) {
    console.error("Unexpected account deletion error:", error);
    return jsonResponse({ error: "Unable to delete account" }, 500);
  }
});

async function removeUserDirectory(
  client: ReturnType<typeof createClient>,
  bucket: string,
  userId: string,
) {
  const paths = await listFilesRecursively(client, bucket, userId);
  await removePaths(client, bucket, paths);
}

async function listFilesRecursively(
  client: ReturnType<typeof createClient>,
  bucket: string,
  directory: string,
) {
  const paths: string[] = [];
  let offset = 0;
  const pageSize = 100;

  while (true) {
    const { data, error } = await client.storage.from(bucket).list(directory, {
      limit: pageSize,
      offset,
      sortBy: { column: "name", order: "asc" },
    });
    if (error) {
      throw new Error(`Unable to list ${bucket} files: ${error.message}`);
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

async function removeUserTripDocuments(
  client: ReturnType<typeof createClient>,
  userId: string,
) {
  const paths = new Set<string>();
  const { data: uploadedFiles, error: uploadedError } = await client
    .from("trip_files")
    .select("storage_path")
    .eq("uploaded_by", userId);
  if (uploadedError) throw new Error(uploadedError.message);
  for (const file of uploadedFiles ?? []) paths.add(file.storage_path);

  const { data: ownedTrips, error: tripsError } = await client
    .from("matchmaking_trips")
    .select("id")
    .eq("owner_id", userId);
  if (tripsError) throw new Error(tripsError.message);
  const tripIds = (ownedTrips ?? []).map((trip) => trip.id);
  if (tripIds.length > 0) {
    const { data: tripFiles, error: filesError } = await client
      .from("trip_files")
      .select("storage_path")
      .in("trip_id", tripIds);
    if (filesError) throw new Error(filesError.message);
    for (const file of tripFiles ?? []) paths.add(file.storage_path);
  }

  await removePaths(client, "trip-documents", [...paths]);
}

async function removePaths(
  client: ReturnType<typeof createClient>,
  bucket: string,
  paths: string[],
) {
  for (let index = 0; index < paths.length; index += 100) {
    const { error } = await client.storage
      .from(bucket)
      .remove(paths.slice(index, index + 100));
    if (error) {
      throw new Error(`Unable to remove ${bucket} files: ${error.message}`);
    }
  }
}

function jsonResponse(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
