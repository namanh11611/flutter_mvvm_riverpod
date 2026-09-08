import test from "node:test";
import assert from "node:assert/strict";
import { createHmac } from "node:crypto";
import {
  canonicalJson,
  rejectionReason,
  validVerificationUrl,
  verifyDiditSignature,
} from "../functions/_shared/didit.ts";

const now = 1800000000000;
const secret = "test-secret";
const body = {
  session_id: "session",
  status: "Declined",
  timestamp: now / 1000,
  decision: {
    id_verifications: [{
      status: "Declined",
      warnings: [{ short_description: "Document unreadable" }],
    }],
  },
  name: "José",
};
function headers(
  payload,
  header = "x-signature-v2",
  message = canonicalJson(payload),
) {
  return new Headers({
    "x-timestamp": String(payload.timestamp),
    [header]: createHmac("sha256", secret).update(message).digest("hex"),
  });
}

test("accepts signed Unicode payload and raw signature", async () => {
  assert.equal(
    await verifyDiditSignature(
      JSON.stringify(body),
      headers(body),
      secret,
      now,
    ),
    true,
  );
  const raw = JSON.stringify(body, null, 2);
  assert.equal(
    await verifyDiditSignature(
      raw,
      headers(body, "x-signature", raw),
      secret,
      now,
    ),
    true,
  );
});
test("rejects forged reasons, stale timestamps, unsigned timestamp changes and Simple signatures", async () => {
  const tampered = { ...body, decision: { warnings: ["Forged reason"] } };
  assert.equal(
    await verifyDiditSignature(
      JSON.stringify(tampered),
      headers(body),
      secret,
      now,
    ),
    false,
  );
  assert.equal(
    await verifyDiditSignature(
      JSON.stringify(body),
      headers(body),
      secret,
      now + 301000,
    ),
    false,
  );
  const changedHeaders = headers(body);
  changedHeaders.set("x-timestamp", String(now / 1000 + 400));
  assert.equal(
    await verifyDiditSignature(
      JSON.stringify(body),
      changedHeaders,
      secret,
      now + 400000,
    ),
    false,
  );
  assert.equal(
    await verifyDiditSignature(
      JSON.stringify(body),
      headers(body, "x-signature-simple"),
      secret,
      now,
    ),
    false,
  );
});
test("extracts only warning reasons and deduplicates without copying identity data", () => {
  assert.equal(rejectionReason(body.decision), "Document unreadable");
  assert.equal(
    rejectionReason({
      warnings: ["Document unreadable"],
      ...body.decision,
      full_name: "Secret",
      document_number: "123",
      reviews: [{ comment: "Private note" }],
    }),
    "Document unreadable",
  );
  assert.equal(
    rejectionReason({
      id_verifications: [{ status: "Approved", warnings: ["Not a rejection"] }],
    }),
    null,
  );
});
test("accepts hosted Didit URLs and rejects misleading hosts or credentials", () => {
  assert.equal(
    validVerificationUrl("https://verify.didit.me/session/123"),
    true,
  );
  for (
    const url of [
      "http://verify.didit.me/x",
      "https://didit.me.evil.test/x",
      "https://didit.me@evil.test/x",
      "https://user:pass@verify.didit.me/x",
      "not a url",
    ]
  ) {
    assert.equal(validVerificationUrl(url), false);
  }
});

test("manual rejection uses the latest status-change reason, not unrelated review notes", () => {
  const reviews = [
    {
      new_status: "Declined",
      comment: "Old reason",
      created_at: "2026-09-01T00:00:00Z",
    },
    {
      new_status: null,
      comment: "Internal discussion",
      created_at: "2026-09-05T00:00:00Z",
    },
    {
      new_status: "Declined",
      comment: "Please use an unexpired identity document.",
      created_at: "2026-09-04T00:00:00Z",
    },
  ];
  assert.equal(
    rejectionReason({ reviews }),
    "Please use an unexpired identity document.",
  );
  assert.equal(
    rejectionReason({
      reviews: [...reviews, {
        new_status: "Resubmitted",
        created_at: "2026-09-05T00:00:00Z",
      }],
    }),
    null,
  );
});
