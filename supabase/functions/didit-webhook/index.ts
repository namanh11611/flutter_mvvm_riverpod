import { createClient } from "npm:@supabase/supabase-js@2";
import {
  providerStatuses,
  rejectionReason,
  verifiedDateOfBirth,
  verifyDiditSignature,
} from "../_shared/didit.ts";

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }
  const secret = Deno.env.get("DIDIT_WEBHOOK_SECRET");
  const url = Deno.env.get("SUPABASE_URL");
  const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!secret || !url || !key) {
    return new Response("Missing server configuration", { status: 500 });
  }
  try {
    const rawBody = await req.text();
    if (!await verifyDiditSignature(rawBody, req.headers, secret)) {
      return new Response("Invalid signature or timestamp", { status: 401 });
    }
    const payload = JSON.parse(rawBody);
    if (
      !["status.updated", "data.updated"].includes(payload.webhook_type) ||
      payload.session_kind === "business"
    ) return Response.json({ ignored: true });
    if (
      typeof payload.session_id !== "string" ||
      !providerStatuses.has(payload.status) ||
      !Number.isSafeInteger(payload.created_at) || payload.created_at < 0 ||
      payload.created_at > Number(payload.timestamp) ||
      (payload.vendor_data != null && typeof payload.vendor_data !== "string")
    ) {
      return new Response("Invalid session event", { status: 400 });
    }
    let dateOfBirth = payload.status === "Approved"
      ? verifiedDateOfBirth(payload.decision)
      : null;
    if (payload.status === "Approved" && dateOfBirth === null) {
      const diditApiKey = Deno.env.get("DIDIT_API_KEY");
      if (!diditApiKey) {
        return new Response("Missing verification provider configuration", {
          status: 500,
        });
      }
      const decisionResponse = await fetch(
        `https://verification.didit.me/v3/session/${encodeURIComponent(payload.session_id)}/decision/`,
        { headers: { "x-api-key": diditApiKey } },
      );
      if (!decisionResponse.ok) {
        return new Response("Unable to retrieve verified identity data", {
          status: 503,
        });
      }
      dateOfBirth = verifiedDateOfBirth(await decisionResponse.json());
      if (dateOfBirth === null) {
        return new Response("Approved identity document has no valid birthday", {
          status: 422,
        });
      }
    }
    const admin = createClient(url, key, { auth: { persistSession: false } });
    const { data, error } = await admin.rpc(
      "apply_identity_verification_event",
      {
        p_session_id: payload.session_id,
        // created_at is the event time; timestamp is refreshed for each delivery.
        p_event_key: typeof payload.event_id === "string"
          ? payload.event_id
          : `${payload.session_id}:${payload.created_at}:${payload.status}:${payload.webhook_type}`,
        p_event_at: payload.created_at,
        p_provider_status: payload.status,
        p_reason: payload.status === "Declined"
          ? rejectionReason(payload.decision)
          : null,
        p_vendor_data: payload.vendor_data ?? null,
        p_date_of_birth: dateOfBirth,
      },
    );
    if (error) {
      console.error("Verification event database failure", error.code);
      return new Response("Unable to save verification result", {
        status: 500,
      });
    }
    // Request retry if the creation function has not committed the session yet.
    if (data === "unknown_session") {
      return new Response("Session not saved yet", { status: 503 });
    }
    return Response.json({ result: data });
  } catch {
    console.error("Unexpected verification webhook failure");
    return new Response("Unable to process verification result", {
      status: 500,
    });
  }
});
