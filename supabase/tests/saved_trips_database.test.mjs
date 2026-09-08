import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { createRequire } from 'node:module';
const requireTools = createRequire(new URL('../../.dart_tool/verification-tools/package.json', import.meta.url));
const { PGlite } = requireTools('@electric-sql/pglite');
const user = '11111111-1111-4111-8111-111111111111';
const other = '22222222-2222-4222-8222-222222222222';
const id = '33333333-3333-4333-8333-333333333333';

test('saved visibility and authoritative join availability', async () => {
  const db = new PGlite();
  try {
    await db.exec(`
      create role authenticated;
      create schema auth;
      create function auth.uid() returns uuid language sql as $$
        select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$;
      grant usage on schema auth to authenticated;
      create table matchmaking_trips(id uuid primary key, owner_id uuid,
        status text, start_time timestamptz, start_date date, vacancies integer);
      create table matchmaking_saved_trips(user_id uuid, trip_id uuid,
        primary key(user_id, trip_id));
      create table matchmaking_trip_members(trip_id uuid, user_id uuid, role text);
      create table matchmaking_join_requests(id uuid default gen_random_uuid(),
        trip_id uuid, applicant_id uuid, status text default 'pending');
      alter table matchmaking_trips enable row level security;
      alter table matchmaking_saved_trips enable row level security;
      create policy active_trips on matchmaking_trips for select to authenticated using(status='active');
      create policy own_bookmarks on matchmaking_saved_trips for all to authenticated
        using(user_id=auth.uid()) with check(user_id=auth.uid());
      grant select on matchmaking_trips, matchmaking_saved_trips to authenticated;
      insert into matchmaking_trips values('${id}','${other}','closed',now()+interval '1 day',current_date+1,1);
      insert into matchmaking_saved_trips values('${user}','${id}');
    `);
    await db.exec(await readFile(new URL('../migrations/20260905130000_saved_trip_availability.sql', import.meta.url), 'utf8'));
    await db.exec(`set role authenticated; select set_config('request.jwt.claim.sub','${user}',false)`);
    assert.equal((await db.query('select * from matchmaking_trips')).rows.length, 1);
    await db.exec(`select set_config('request.jwt.claim.sub','${other}',false)`);
    assert.equal((await db.query('select * from matchmaking_trips')).rows.length, 0);
    await db.exec('reset role');
    const join = () => db.query('insert into matchmaking_join_requests(trip_id,applicant_id) values($1,$2)', [id,user]);
    await assert.rejects(join(), /not accepting/);
    await db.exec(`update matchmaking_trips set status='active', start_time=now()-interval '1 minute'`);
    await assert.rejects(join(), /already started/);
    await db.exec(`update matchmaking_trips set start_time=now()+interval '1 day';
      insert into matchmaking_trip_members values('${id}','${other}','member')`);
    await assert.rejects(join(), /full/);
    await db.exec('delete from matchmaking_trip_members');
    await join();
    // The production approval RPC adds the member before setting accepted.
    await db.exec(`insert into matchmaking_trip_members values('${id}','${user}','member');
      update matchmaking_join_requests set status='accepted'`);
    assert.equal((await db.query('select status from matchmaking_join_requests')).rows[0].status, 'accepted');
  } finally { await db.close(); }
});
