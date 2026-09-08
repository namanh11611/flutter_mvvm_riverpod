import { createClient } from "npm:@supabase/supabase-js@2";
import { GoogleAuth } from "npm:google-auth-library@9";

type NotificationRow = {
  id: string;
  user_id: string;
  trip_id: string | null;
  title: string;
  body: string;
  metadata?: Record<string, unknown>;
};

type WebhookPayload = {
  type: "INSERT";
  table: "notifications" | "matchmaking_notifications";
  record: NotificationRow;
};

async function handlePushNotification(request: Request): Promise<Response> {
  if (request.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  const webhookSecret = Deno.env.get("PUSH_WEBHOOK_SECRET");
  if (!webhookSecret ||
      request.headers.get("x-webhook-secret") !== webhookSecret) {
    return new Response("Unauthorized", { status: 401 });
  }

  const payload = (await request.json()) as WebhookPayload;
  const notification = payload.record;
  if (!notification?.user_id) {
    return new Response("Invalid webhook payload", { status: 400 });
  }

  const serviceAccountText = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!serviceAccountText || !supabaseUrl || !serviceRoleKey) {
    return new Response("Missing server configuration", { status: 500 });
  }

  const serviceAccount = JSON.parse(serviceAccountText);
  const supabase = createClient(supabaseUrl, serviceRoleKey);
  const { data: devices, error } = await supabase
    .from("push_device_tokens")
    .select("token")
    .eq("user_id", notification.user_id);
  if (error) throw error;
  if (!devices?.length) return Response.json({ sent: 0 });

  const auth = new GoogleAuth({
    credentials: serviceAccount,
    scopes: ["https://www.googleapis.com/auth/firebase.messaging"],
  });
  const accessToken = await auth.getAccessToken();
  const endpoint =
    `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`;

  let sent = 0;
  const invalidTokens: string[] = [];
  const metadata = notification.metadata ?? {};
  const notificationType = String(metadata.type ?? "update");
  const isIncomingCall = notificationType === "incoming_call";
  const isGroupMessage = notificationType === "group_message";
  for (const device of devices) {
    const response = await fetch(endpoint, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: {
          token: device.token,
          notification: {
            title: notification.title,
            body: notification.body,
          },
          data: {
            notification_id: notification.id,
            trip_id: notification.trip_id ?? "",
            type: notificationType,
            call_id: String(metadata.call_id ?? ""),
            call_type: String(metadata.call_type ?? ""),
            caller_id: String(metadata.caller_id ?? ""),
            message_id: String(metadata.message_id ?? ""),
          },
          android: {
            priority: "high",
            notification: isIncomingCall
              ? {
                channel_id: "gobuddy_incoming_calls",
                sound: "default",
                notification_priority: "PRIORITY_MAX",
                visibility: "PUBLIC",
              }
              : isGroupMessage
              ? {
                channel_id: "gobuddy_messages",
                sound: "default",
                notification_priority: "PRIORITY_HIGH",
              }
              : undefined,
          },
          apns: {
            headers: isIncomingCall
              ? { "apns-priority": "10" }
              : undefined,
            payload: {
              aps: {
                sound: "default",
                "interruption-level": isIncomingCall
                  ? "time-sensitive"
                  : "active",
              },
            },
          },
        },
      }),
    });
    if (response.ok) {
      sent++;
    } else {
      const failure = await response.text();
      if (failure.includes("UNREGISTERED") ||
          failure.includes("INVALID_ARGUMENT")) {
        invalidTokens.push(device.token);
      }
      console.error("FCM send failed", response.status, failure);
    }
  }

  if (invalidTokens.length) {
    await supabase.from("push_device_tokens").delete().in("token", invalidTokens);
  }
  return Response.json({ sent, failed: devices.length - sent });
}

Deno.serve(async (request) => {
  try {
    return await handlePushNotification(request);
  } catch (error) {
    const message = error instanceof Error
      ? error.message
      : typeof error === "object"
      ? JSON.stringify(error)
      : String(error);
    console.error("Push notification handler failed", message);
    return Response.json({ error: message }, { status: 500 });
  }
});
