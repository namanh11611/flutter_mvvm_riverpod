begin;

-- Bookmark creation uses an upsert so repeated taps and stale clients remain
-- idempotent. PostgreSQL therefore requires UPDATE in addition to INSERT when
-- the (user_id, trip_id) primary key already exists.
grant select, insert, update, delete
on table public.matchmaking_saved_trips
to authenticated;

-- Keep UPDATE access restricted to the authenticated user's own rows.
alter table public.matchmaking_saved_trips enable row level security;

drop policy if exists "users manage their saved trips"
on public.matchmaking_saved_trips;

create policy "users manage their saved trips"
on public.matchmaking_saved_trips
for all
to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

commit;
