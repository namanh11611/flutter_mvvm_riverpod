// Provider contract: https://docs.didit.me/integration/webhooks
// Never accept the Simple signature: it does not authenticate rejection reasons.
export function canonicalJson(value: unknown): string {
  if (Array.isArray(value)) return `[${value.map(canonicalJson).join(",")}]`;
  if (value !== null && typeof value === "object") {
    const object = value as Record<string, unknown>;
    return `{${
      Object.keys(object).sort().map((key) =>
        `${JSON.stringify(key)}:${canonicalJson(object[key])}`
      ).join(",")
    }}`;
  }
  return JSON.stringify(value);
}

export async function verifyDiditSignature(
  rawBody: string,
  headers: Headers,
  secret: string,
  now = Date.now(),
): Promise<boolean> {
  const timestamp = headers.get("x-timestamp");
  if (
    !timestamp || !/^\d+$/.test(timestamp) ||
    Math.abs(now / 1000 - Number(timestamp)) > 300
  ) return false;
  let body: Record<string, unknown>;
  try {
    body = JSON.parse(rawBody);
  } catch {
    return false;
  }
  // Bind freshness to the authenticated body, not just an unsigned header.
  if (!body || Number(body.timestamp) !== Number(timestamp)) return false;
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["verify"],
  );
  for (
    const [header, message] of [
      ["x-signature-v2", canonicalJson(body)],
      ["x-signature", rawBody],
    ]
  ) {
    const signature = headers.get(header);
    if (!signature || !/^[a-fA-F0-9]{64}$/.test(signature)) continue;
    const bytes = Uint8Array.from(
      signature.match(/../g)!,
      (hex) => parseInt(hex, 16),
    );
    if (
      await crypto.subtle.verify("HMAC", key, bytes, encoder.encode(message))
    ) return true;
  }
  return false;
}

export const providerStatuses = new Set([
  "Not Started",
  "In Progress",
  "In Review",
  "Resubmitted",
  "Awaiting User",
  "Approved",
  "Declined",
  "Expired",
  "Abandoned",
  "Kyc Expired",
]);

export function rejectionReason(decision: unknown): string | null {
  if (!decision || typeof decision !== "object") return null;
  const data = decision as Record<string, unknown>;
  // A manual rejection's status-change comment is its reason. Ignore general
  // review comments and old declines superseded by a later status review.
  if (Array.isArray(data.reviews)) {
    const latest = data.reviews.filter((review) =>
      typeof review?.new_status === "string"
    )
      .sort((a, b) =>
        (Date.parse(b.created_at) || 0) - (Date.parse(a.created_at) || 0)
      )[0];
    if (
      latest?.new_status === "Declined" && typeof latest.comment === "string" &&
      latest.comment.trim()
    ) {
      return latest.comment.trim().slice(0, 1000);
    }
  }
  const reasons = new Set<string>();
  const collectWarnings = (warnings: unknown) => {
    if (!Array.isArray(warnings)) return;
    for (const warning of warnings) {
      // Only warning descriptions, never identity fields or arbitrary notes.
      const message = typeof warning === "string"
        ? warning
        : warning && typeof warning === "object"
        ? warning.short_description ?? warning.long_description
        : null;
      if (typeof message === "string" && message.trim()) {
        reasons.add(message.trim());
      }
    }
  };
  collectWarnings(data.warnings);
  for (
    const feature of [
      "id_verifications",
      "nfc_verifications",
      "liveness_checks",
      "face_matches",
      "poa_verifications",
      "aml_screenings",
      "phone_verifications",
      "email_verifications",
      "ip_analyses",
      "database_validations",
    ]
  ) {
    const checks = data[feature];
    if (!Array.isArray(checks)) continue;
    for (const check of checks) {
      if (check?.status === "Declined") collectWarnings(check.warnings);
    }
  }
  return reasons.size ? [...reasons].join("; ").slice(0, 1000) : null;
}

/// Returns only a calendar-valid ISO date from an approved V3 ID document.
export function verifiedDateOfBirth(decision: unknown): string | null {
  if (!decision || typeof decision !== "object") return null;
  const checks = (decision as Record<string, unknown>).id_verifications;
  if (!Array.isArray(checks)) return null;
  for (const value of checks) {
    if (!value || typeof value !== "object") continue;
    const check = value as Record<string, unknown>;
    if (check.status !== "Approved" || typeof check.date_of_birth !== "string") {
      continue;
    }
    const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(check.date_of_birth);
    if (!match) continue;
    const year = Number(match[1]);
    const month = Number(match[2]);
    const day = Number(match[3]);
    const date = new Date(Date.UTC(year, month - 1, day));
    if (
      date.getUTCFullYear() === year &&
      date.getUTCMonth() === month - 1 &&
      date.getUTCDate() === day
    ) return check.date_of_birth;
  }
  return null;
}

export function validVerificationUrl(value: unknown): value is string {
  if (typeof value !== "string") return false;
  try {
    const url = new URL(value);
    return url.protocol === "https:" && !url.username && !url.password &&
      (url.hostname === "didit.me" || url.hostname.endsWith(".didit.me"));
  } catch {
    return false;
  }
}
