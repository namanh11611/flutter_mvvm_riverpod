// npm install --prefix .dart_tool/verification-tools --no-save @electric-sql/pglite
// node --test supabase/tests/identity_verification_database.test.mjs
import test from "node:test";
import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { createRequire } from "node:module";
const requireTools = createRequire(
  new URL("../../.dart_tool/verification-tools/package.json", import.meta.url),
);
const { PGlite } = requireTools("@electric-sql/pglite");
const user = "11111111-1111-4111-8111-111111111111";
const token = "22222222-2222-4222-8222-222222222222";
const otherToken = "33333333-3333-4333-8333-333333333333";

test("migration, three statuses, session reuse, callbacks and notifications", async (t) => {
  const db = new PGlite();
  try {
    // Representative pre-migration tables, including the legacy status check.
    await db.exec(`
      create role anon; create role authenticated; create role service_role;
      create schema auth;
      create function auth.role() returns text language sql as
        $$ select current_setting('request.jwt.claim.role', true) $$;
      create table public.user_accounts(id uuid primary key,
        verification_status text not null default 'unverified'
          check(verification_status in ('unverified','pending','verified')),
        updated_at timestamptz default now());
      create table public.matchmaking_notifications(id uuid primary key default gen_random_uuid(),
        user_id uuid not null, trip_id uuid not null, title text not null, body text not null);
      create table public.identity_verifications(id uuid primary key default gen_random_uuid(),
        user_id uuid not null references public.user_accounts(id),
        provider text not null, provider_session_id text not null,
        status text not null check(status in ('not_started','approved','declined')),
        submitted_at timestamptz not null default now());
      insert into public.user_accounts(id) values ('${user}');
      insert into public.identity_verifications(user_id,provider,provider_session_id,status)
        values('${user}','didit','legacy','declined');
    `);
    await db.exec(
      await readFile(
        new URL(
          "../migrations/20260905120000_complete_identity_verification.sql",
          import.meta.url,
        ),
        "utf8",
      ),
    );
    const scalar = async (sql, params = []) =>
      Object.values((await db.query(sql, params)).rows[0])[0];
    const reserve = (key = token) =>
      scalar("select reserve_identity_verification($1,$2)", [user, key]);
    const finish = (session) =>
      db.query("select finish_identity_verification_start($1,$2,$3,$4)", [
        user,
        token,
        session,
        `https://verify.didit.me/session/${session}`,
      ]);
    const apply = (
      session,
      event,
      time,
      status,
      reason = null,
      vendor = user,
    ) =>
      scalar(
        "select apply_identity_verification_event($1,$2,$3,$4,$5,$6)",
        [session, event, time, status, reason, vendor],
      );
    const status = () =>
      scalar("select verification_status from user_accounts where id=$1", [
        user,
      ]);
    const count = () =>
      scalar("select count(*)::int from matchmaking_notifications");

    await t.test("converts legacy statuses and serializes session starts", async () => {
      assert.equal(
        await scalar(
          "select status from identity_verifications where provider_session_id='legacy'",
        ),
        "unverified",
      );
      assert.equal((await reserve()).action, "create");
      assert.equal((await reserve(otherToken)).action, "busy");
      await finish("first");
      assert.equal(await status(), "pending");
      assert.equal(await count(), 1);
      assert.equal((await reserve()).action, "reuse");
    });
    await t.test("rejection notifies with reason once and resets to unverified", async () => {
      assert.equal(
        await apply("first", "progress", 10, "In Progress"),
        "applied",
      );
      assert.equal(await count(), 1);
      assert.equal(
        await apply(
          "first",
          "rejection",
          20,
          "Declined",
          "Document unreadable",
        ),
        "applied",
      );
      assert.equal(await status(), "unverified");
      assert.equal(await count(), 2);
      const notification = (await db.query(
        "select * from matchmaking_notifications where title='Identity verification rejected'",
      )).rows[0];
      assert.match(notification.body, /Document unreadable/);
      assert.equal(notification.metadata.verification_status, "unverified");
      assert.equal(notification.metadata.type, "identity_verification");
      assert.equal(
        await apply(
          "first",
          "rejection",
          20,
          "Declined",
          "Document unreadable",
        ),
        "duplicate",
      );
      assert.equal(
        await apply(
          "first",
          "duplicate-status",
          21,
          "Declined",
          "Document unreadable",
        ),
        "applied",
      );
      assert.equal(
        await apply("first", "late-progress", 15, "In Progress"),
        "stale",
      );
      assert.equal(await count(), 2);
    });
    await t.test("new attempt ignores previous session callbacks and verifies once", async () => {
      assert.equal((await reserve()).action, "create");
      await finish("second");
      assert.equal(
        await apply("first", "old-approval", 30, "Approved"),
        "superseded",
      );
      assert.equal(await status(), "pending");
      assert.equal(
        await apply("second", "approval", 40, "Approved"),
        "applied",
      );
      assert.equal(await status(), "verified");
      assert.equal((await reserve()).action, "verified");
      assert.equal(await count(), 4);
      assert.equal(
        await apply("second", "older-review", 39, "In Review"),
        "stale",
      );
      assert.equal(await status(), "verified");
    });
    await t.test("expiry returns to unverified; missing sessions retry; mismatched users fail", async () => {
      assert.equal(
        await apply("second", "expiry", 50, "Kyc Expired"),
        "applied",
      );
      assert.equal(await status(), "unverified");
      assert.equal(await count(), 5);
      assert.equal(
        await apply("unknown", "early", 50, "In Progress"),
        "unknown_session",
      );
      await assert.rejects(
        apply("second", "forged-user", 51, "Approved", null, "another-user"),
        /user mismatch/,
      );
      assert.equal(await status(), "unverified");
    });
    await t.test("failure to notify rolls back the status and dedup record together", async () => {
      await reserve();
      await finish("third");
      await db.exec(
        "alter table matchmaking_notifications add constraint simulate_failure check(title <> 'Identity verified') not valid",
      );
      await assert.rejects(
        apply("third", "atomic-approval", 60, "Approved"),
        /simulate_failure/,
      );
      assert.equal(await status(), "pending");
      assert.equal(
        await scalar(
          "select count(*)::int from identity_verification_events where event_key='atomic-approval'",
        ),
        0,
      );
      await db.exec(
        "alter table matchmaking_notifications drop constraint simulate_failure",
      );
      assert.equal(
        await apply("third", "atomic-approval", 60, "Approved"),
        "applied",
      );
      assert.equal(await status(), "verified");
    });
    await t.test("authenticated clients cannot edit verification or call trusted RPCs", async () => {
      assert.equal(
        await scalar(
          "select has_function_privilege('authenticated', 'public.apply_identity_verification_event(text,text,bigint,text,text,text)', 'EXECUTE')",
        ),
        false,
      );
      assert.equal(
        await scalar(
          "select has_table_privilege('authenticated','public.identity_verifications','UPDATE')",
        ),
        false,
      );
      await db.exec(
        "select set_config('request.jwt.claim.role','authenticated',false)",
      );
      await assert.rejects(
        db.query(
          "update user_accounts set verification_status='unverified' where id=$1",
          [user],
        ),
        /only be changed/,
      );
      await db.exec("select set_config('request.jwt.claim.role','',false)");
    });
  } finally {
    await db.close();
  }
});
