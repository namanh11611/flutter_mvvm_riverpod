import { createClient } from "npm:@supabase/supabase-js@2";
import { validVerificationUrl } from "../_shared/didit.ts";

Deno.serve(async (req: Request) => {
  try {
    if (req.method !== "POST") {
      return jsonResponse({ error: "Method not allowed" }, 405);
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");
    const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const diditApiKey = Deno.env.get("DIDIT_API_KEY");
    const diditWorkflowId = Deno.env.get("DIDIT_WORKFLOW_ID");

    if (
      !supabaseUrl || !supabaseAnonKey || !supabaseServiceRoleKey ||
      !diditApiKey || !diditWorkflowId
    ) {
      return jsonResponse({ error: "Server configuration is incomplete" }, 500);
    }

    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return jsonResponse({ error: "Missing Authorization header" }, 401);
    }

    const userClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
      auth: { persistSession: false },
    });
    const token = authHeader.replace(/^Bearer\s+/i, "");
    const { data: { user }, error: userError } = await userClient.auth.getUser(
      token,
    );
    if (userError || !user) {
      return jsonResponse({ error: "Unauthorized" }, 401);
    }

    const adminClient = createClient(supabaseUrl, supabaseServiceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const tokenId = crypto.randomUUID();
    const { data: reservation, error: reserveError } = await adminClient.rpc(
      "reserve_identity_verification",
      { p_user_id: user.id, p_token: tokenId },
    );
    if (reserveError) {
      return jsonResponse({ error: "Unable to start verification" }, 500);
    }
    if (reservation.action === "verified") {
      return jsonResponse({ error: "Your identity is already verified" }, 409);
    }
    if (reservation.action === "busy") {
      return jsonResponse({
        error:
          "Verification is already starting. Please wait a moment and retry.",
      }, 409);
    }
    if (reservation.action === "reuse") return jsonResponse(reservation);

    try {
      const diditResponse = await fetch(
        "https://verification.didit.me/v3/session/",
        {
          method: "POST",
          signal: AbortSignal.timeout(25000),
          headers: {
            "Content-Type": "application/json",
            "x-api-key": diditApiKey,
          },
          body: JSON.stringify({
            workflow_id: diditWorkflowId,
            vendor_data: user.id,
            callback: "gobuddy://app/identity-verification",
            callback_method: "both",
          }),
        },
      );
      const diditData = await diditResponse.json();

      if (!diditResponse.ok) {
        console.error("Didit session creation failed:", diditResponse.status);
        return jsonResponse(
          { error: "Failed to create Didit verification session" },
          diditResponse.status,
        );
      }

      const sessionId = diditData.session_id;
      const verificationUrl = diditData.url ?? diditData.session_url;
      if (
        typeof sessionId !== "string" || !sessionId ||
        !validVerificationUrl(verificationUrl)
      ) {
        return jsonResponse(
          { error: "Didit returned an invalid session response" },
          500,
        );
      }

      const { error: insertError } = await adminClient.rpc(
        "finish_identity_verification_start",
        {
          p_user_id: user.id,
          p_token: tokenId,
          p_session_id: sessionId,
          p_url: verificationUrl,
        },
      );
      if (insertError) {
        console.error("Failed to save identity verification:", insertError);
        return jsonResponse(
          { error: "Verification session created but database save failed" },
          500,
        );
      }

      return jsonResponse({
        session_id: sessionId,
        verification_url: verificationUrl,
        status: "pending",
      });
    } finally {
      await adminClient.from("identity_verification_starts").delete()
        .eq("user_id", user.id).eq("token", tokenId);
    }
  } catch (error) {
    console.error("Unexpected verification error:", error);
    return jsonResponse({ error: "Internal server error" }, 500);
  }
});

function jsonResponse(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
