-- GoBuddy matchmaking Row Level Security.
-- Run once after 001_matchmaking_schema.sql.

alter table public.matchmaking_trips enable row level security;
alter table public.matchmaking_trip_styles enable row level security;
alter table public.matchmaking_join_requests enable row level security;
alter table public.matchmaking_trip_members enable row level security;
alter table public.matchmaking_saved_trips enable row level security;

create policy "authenticated users can discover active trips"
on public.matchmaking_trips for select to authenticated
using (status = 'active' or owner_id = (select auth.uid()));

create policy "users can create their own trips"
on public.matchmaking_trips for insert to authenticated
with check (owner_id = (select auth.uid()));

create policy "owners can update their trips"
on public.matchmaking_trips for update to authenticated
using (owner_id = (select auth.uid()))
with check (owner_id = (select auth.uid()));

create policy "owners can delete their trips"
on public.matchmaking_trips for delete to authenticated
using (owner_id = (select auth.uid()));

create policy "authenticated users can read trip styles"
on public.matchmaking_trip_styles for select to authenticated
using (true);

create policy "owners can add trip styles"
on public.matchmaking_trip_styles for insert to authenticated
with check (
  exists (
    select 1 from public.matchmaking_trips
    where id = trip_id and owner_id = (select auth.uid())
  )
);

create policy "owners can delete trip styles"
on public.matchmaking_trip_styles for delete to authenticated
using (
  exists (
    select 1 from public.matchmaking_trips
    where id = trip_id and owner_id = (select auth.uid())
  )
);

create policy "applicants can create requests"
on public.matchmaking_join_requests for insert to authenticated
with check (
  applicant_id = (select auth.uid())
  and not exists (
    select 1 from public.matchmaking_trips
    where id = trip_id and owner_id = (select auth.uid())
  )
);

create policy "applicants and owners can read requests"
on public.matchmaking_join_requests for select to authenticated
using (
  applicant_id = (select auth.uid())
  or exists (
    select 1 from public.matchmaking_trips
    where id = trip_id and owner_id = (select auth.uid())
  )
);

create policy "owners can manage requests"
on public.matchmaking_join_requests for update to authenticated
using (
  exists (
    select 1 from public.matchmaking_trips
    where id = trip_id and owner_id = (select auth.uid())
  )
)
with check (
  exists (
    select 1 from public.matchmaking_trips
    where id = trip_id and owner_id = (select auth.uid())
  )
);

create policy "applicants can cancel requests"
on public.matchmaking_join_requests for delete to authenticated
using (applicant_id = (select auth.uid()));

create policy "users can read relevant memberships"
on public.matchmaking_trip_members for select to authenticated
using (
  user_id = (select auth.uid())
  or exists (
    select 1 from public.matchmaking_trips
    where id = trip_id and owner_id = (select auth.uid())
  )
);

create policy "users manage their saved trips"
on public.matchmaking_saved_trips for all to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

