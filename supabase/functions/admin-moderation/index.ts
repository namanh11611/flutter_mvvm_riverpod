import { createClient } from "npm:@supabase/supabase-js@2";

const headers = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json",
};
const reply = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers });
const checked = <T>(result: { data: T; error: unknown }): T => {
  if (result.error) throw result.error;
  return result.data;
};

const diditRequest = async (path: string, init: RequestInit = {}) => {
  const apiKey = Deno.env.get("DIDIT_API_KEY");
  if (!apiKey) throw new Error("DIDIT_API_KEY is not configured");
  const response = await fetch(`https://verification.didit.me${path}`, {
    ...init,
    signal: AbortSignal.timeout(25000),
    headers: {
      "Content-Type": "application/json",
      "x-api-key": apiKey,
      ...init.headers,
    },
  });
  const text = await response.text();
  let data: unknown = null;
  try { data = text ? JSON.parse(text) : null; } catch { data = null; }
  if (!response.ok) {
    console.error("Didit moderation request failed", response.status);
    throw new Error(`Didit returned ${response.status}`);
  }
  return data;
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers });
  if (req.method !== "POST") return reply({ error: "Method not allowed" }, 405);
  try {
    const client = createClient(Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
      { auth: { persistSession: false, autoRefreshToken: false } });
    const token = req.headers.get("Authorization")?.replace(/^Bearer\s+/i, "");
    if (!token) return reply({ error: "Sign in required" }, 401);
    const { data: { user }, error } = await client.auth.getUser(token);
    if (error || !user) return reply({ error: "Sign in required" }, 401);
    const role = checked(await client.from("admin_users").select("user_id").eq("user_id", user.id).maybeSingle());
    const banned = checked(await client.from("account_bans").select("user_id").eq("user_id", user.id).or(`expires_at.is.null,expires_at.gt.${new Date().toISOString()}`).maybeSingle());
    if (!role || banned) return reply({ error: "Admin access required" }, 403);
    const body = await req.json();
    const { action, targetId } = body;
    const page = Number.isInteger(body.page) && body.page >= 0 ? body.page : 0;
    if (action === "access") return reply({ isAdmin: true });
    if (action === "dashboard") {
      const counts: Record<string, number> = {};
      for (const status of ["pending", "reviewing", "resolved", "dismissed"]) {
        const result = await client.from("user_reports").select("id", { count: "exact", head: true }).eq("status", status);
        checked(result); counts[status] = result.count ?? 0;
      }
      for (const status of ["suspended", "banned"]) {
        const result = await client.from("admin_user_summary").select("id", { count: "exact", head: true }).eq("account_status", status);
        checked(result); counts[status] = result.count ?? 0;
      }
      const since = typeof body.since === "string" ? body.since : new Date().toISOString().slice(0, 10);
      const today = await client.from("user_reports").select("id", { count: "exact", head: true }).gte("created_at", since);
      checked(today); counts.today = today.count ?? 0;
      const recent = checked(await client.from("admin_report_summary").select("*").order("created_at", { ascending: false }).limit(5));
      const activity = checked(await client.from("moderation_audit").select("*").order("created_at", { ascending: false }).limit(5));
      return reply({ counts, recent, activity });
    }
    if (action === "reports") {
      return reply({ items: checked(await client.rpc("admin_search_reports", {
        p_search: body.search ?? "", p_status: body.status ?? "all", p_category: body.category ?? "all",
        p_since: body.since ?? null, p_oldest: body.oldest === true, p_page: page,
      })) });
    }
    if (action === "users") {
      return reply({ items: checked(await client.rpc("admin_search_users", {
        p_search: body.search ?? "", p_status: body.status ?? "all", p_page: page,
      })) });
    }
    if (action === "activity") {
      let query = client.from("moderation_audit").select("*").order("created_at", { ascending: false }).order("id", { ascending: false });
      if (body.actor) query = query.eq("actor_id", body.actor);
      if (body.type && body.type !== "all") query = query.eq("action", body.type);
      if (body.since) query = query.gte("created_at", body.since);
      const admins = checked(await client.from("admin_users").select("user_id"));
      const names = admins.length ? checked(await client.from("user_accounts").select("id,display_name").in("id", admins.map(a => a.user_id))) : [];
      return reply({ items: checked(await query.range(page * 50, page * 50 + 49)), admins: admins.map(a => ({ id: a.user_id, name: names.find(n => n.id === a.user_id)?.display_name ?? a.user_id })) });
    }
    if (action === "identityReviews") {
      // Use Didit's current session status as the source of truth. Webhooks keep
      // our local status useful elsewhere, but a delayed callback must not leave
      // an already-decided case in the manual-review queue.
      const diditPage = await diditRequest(
        `/v3/sessions/?session_kind=user&limit=100&offset=${page * 100}`,
      );
      const diditSessions = diditPage && typeof diditPage === "object" &&
          Array.isArray((diditPage as { results?: unknown }).results)
        ? (diditPage as { results: Array<Record<string, unknown>> }).results
        : [];
      const reviewSessions = diditSessions.filter((session) =>
        typeof session.status === "string" &&
        session.status.replaceAll("_", " ").trim().toLowerCase() ===
          "in review" &&
        typeof session.session_id === "string"
      );
      const sessionIds = reviewSessions.map((session) =>
        session.session_id as string
      );
      if (!sessionIds.length) {
        return reply({ items: [], diditReviewCount: 0, unmatchedCount: 0 });
      }
      const attempts = checked(await client.from("identity_verifications")
        .select("id,user_id,provider_session_id,provider_status,submitted_at")
        .eq("provider", "didit").in("provider_session_id", sessionIds));
      const attemptBySession = new Map(attempts.map((attempt) =>
        [attempt.provider_session_id, attempt]
      ));
      const orderedAttempts = reviewSessions.flatMap((session) => {
        const attempt = attemptBySession.get(session.session_id);
        return attempt ? [{ ...attempt, provider_status: "In Review" }] : [];
      });
      const users = orderedAttempts.length ? checked(await client.from("user_accounts")
        .select("id,display_name,profile_photo_path")
        .in("id", [...new Set(orderedAttempts.map((item) => item.user_id))])) : [];
      return reply({
        diditReviewCount: reviewSessions.length,
        unmatchedCount: reviewSessions.length - orderedAttempts.length,
        items: orderedAttempts.map((attempt) => ({
        ...attempt,
        display_name: users.find((account) => account.id === attempt.user_id)?.display_name ?? "Unknown user",
        profile_photo_path: users.find((account) => account.id === attempt.user_id)?.profile_photo_path ?? null,
        })),
      });
    }
    if (typeof targetId !== "string" || !/^[0-9a-f-]{36}$/i.test(targetId)) return reply({ error: "A valid target is required" }, 400);
    if (action === "identityReview" || action === "identityDecision") {
      const attempt = checked(await client.from("identity_verifications")
        .select("id,user_id,provider_session_id,provider_status,submitted_at")
        .eq("id", targetId).eq("provider", "didit").single());
      const account = checked(await client.from("user_accounts")
        .select("id,display_name,profile_photo_path,date_of_birth")
        .eq("id", attempt.user_id).single());
      if (action === "identityReview") {
        const decision = await diditRequest(`/v3/session/${encodeURIComponent(attempt.provider_session_id)}/decision/`);
        return reply({ attempt, account, decision });
      }
      if (
        typeof attempt.provider_status !== "string" ||
        attempt.provider_status.replaceAll("_", " ").trim().toLowerCase() !==
          "in review"
      ) {
        return reply({ error: "This verification is no longer in review" }, 409);
      }
      if (!["Approved", "Declined", "Resubmitted"].includes(body.decision)) {
        return reply({ error: "Choose Approve, Reject, or Request resubmission" }, 400);
      }
      const reason = typeof body.reason === "string" ? body.reason.trim() : "";
      if (!reason || reason.length > 1000) return reply({ error: "Enter a review note (1-1000 characters)" }, 400);
      await diditRequest(`/v3/session/${encodeURIComponent(attempt.provider_session_id)}/update-status/`, {
        method: "PATCH",
        body: JSON.stringify({ new_status: body.decision, comment: reason }),
      });
      if (body.decision === "Resubmitted") {
        checked(await client.from("matchmaking_notifications").insert({
          user_id: attempt.user_id,
          trip_id: null,
          title: "Identity verification needs more information",
          body: `Please complete your identity verification again. Instructions: ${reason}`,
          metadata: {
            type: "identity_verification",
            verification_status: "pending",
            reason,
          },
        }));
      }
      checked(await client.from("moderation_audit").insert({
        actor_id: user.id,
        action: `identity_${String(body.decision).toLowerCase()}`,
        target_id: attempt.user_id,
        reason: JSON.stringify({ reason, verification_id: attempt.id, session_id: attempt.provider_session_id }),
      }));
      return reply({ success: true });
    }
    if (typeof targetId !== "string" || !/^[0-9a-f-]{36}$/i.test(targetId)) return reply({ error: "A valid target is required" }, 400);
    if (action === "report") {
      const report = checked(await client.from("admin_report_summary").select("*").eq("id", targetId).single());
      const history = checked(await client.from("moderation_audit").select("*").or(`report_id.eq.${targetId},target_id.eq.${targetId}`).order("created_at"));
      return reply({ report, history });
    }
    if (action === "profile") {
      const profile = checked(await client.from("admin_user_summary").select("*").eq("id", targetId).single());
      const history = checked(await client.from("moderation_audit").select("*").eq("target_id", targetId).order("created_at", { ascending: false }).limit(50));
      const reports = checked(await client.from("admin_report_summary").select("*").eq("reported_user_id", targetId).order("created_at", { ascending: false }).limit(50));
      return reply({ profile, history, reports, images: [] });
    }
    if (action === "decision") {
      const decision = body.decision;
      // Clear legacy Auth bans before releasing the database restriction. If this
      // fails, the protected restriction remains in place and the admin can retry.
      if (decision === "reactivate") {
        const targetAdmin = checked(await client.from("admin_users").select("user_id").eq("user_id", targetId).maybeSingle());
        if (targetAdmin) return reply({ error: "Admin accounts cannot be moderated" }, 400);
        if (typeof body.reason !== "string" || !body.reason.trim() || body.reason.trim().length > 1000) return reply({ error: "Enter an internal note" }, 400);
        checked(await client.auth.admin.updateUserById(targetId, { ban_duration: "none" }));
      }
      checked(await client.rpc("admin_apply_decision", {
        p_actor_id: user.id, p_target_id: targetId, p_action: decision,
        p_reason: body.reason, p_report_id: body.reportId ?? null, p_days: body.days ?? null,
      }));
      return reply({ success: true });
    }
    const reason = typeof body.reason === "string" ? body.reason.trim() : "";
    if (!reason || reason.length > 1000) return reply({ error: "Enter a reason (1â€“1000 characters)" }, 400);
    if (!["review", "ban", "unban", "removeImage"].includes(action)) return reply({ error: "Unknown action" }, 400);
    if (action === "review") {
      if (!["reviewing", "resolved", "dismissed"].includes(body.status)) return reply({ error: "Invalid report status" }, 400);
      const result = await client.rpc("admin_review_report", {
        p_report_id: targetId, p_actor_id: user.id, p_status: body.status, p_reason: reason,
      });
      checked(result);
      return reply({ success: true });
    } else {
      const targetAdmin = checked(await client.from("admin_users").select("user_id").eq("user_id", targetId).maybeSingle());
      if (targetAdmin) return reply({ error: "Admin accounts cannot be moderated" }, 400);
      checked(await client.auth.admin.getUserById(targetId));
      if (action === "ban" || action === "unban") {
        if (action === "unban") checked(await client.auth.admin.updateUserById(targetId, { ban_duration: "none" }));
        checked(await client.rpc("admin_apply_decision", {
          p_actor_id: user.id, p_target_id: targetId, p_action: action === "ban" ? "ban" : "reactivate", p_reason: reason,
        }));
        return reply({ success: true });
      } else {
        const { bucket, path } = body;
        if (typeof path !== "string" || !path.startsWith(`${targetId}/`) || path.includes("..")) return reply({ error: "Invalid image path" }, 400);
        const column = bucket === "profile-images" ? "profile_photo_path" : bucket === "background-images" ? "background_photo_path" : null;
        if (column) {
          checked(await client.from("user_accounts").select("id").eq("id", targetId).eq(column, path).single());
        } else if (bucket === "user-gallery") {
          checked(await client.from("user_gallery").select("image_path").eq("user_id", targetId).eq("image_path", path).single());
        } else return reply({ error: "Invalid image bucket" }, 400);
        // Delete bytes first; if the database update fails, retry safely removes the reference.
        checked(await client.storage.from(bucket).remove([path]));
        if (column) checked(await client.from("user_accounts").update({ [column]: null }).eq("id", targetId).eq(column, path));
        else checked(await client.from("user_gallery").delete().eq("user_id", targetId).eq("image_path", path));
      }
    }
    checked(await client.from("moderation_audit").insert({ actor_id: user.id, action, target_id: targetId, reason: JSON.stringify({ reason, status: body.status, bucket: body.bucket, path: body.path }) }));
    return reply({ success: true });
  } catch (error) {
    console.error("Moderation request failed", error);
    return reply({ error: "Request could not be completed. Refresh to check the current state before retrying." }, 500);
  }
});
