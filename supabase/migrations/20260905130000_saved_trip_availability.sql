-- Closed saved trips remain readable for their saver. The existing restrictive
-- blocking policy still applies; drafts are not exposed through bookmarks.
create policy "users can read their saved published trips"
on public.matchmaking_trips for select to authenticated
using (status in ('active', 'closed') and exists (
  select 1 from public.matchmaking_saved_trips saved
  where saved.trip_id = matchmaking_trips.id and saved.user_id = auth.uid()
));

-- Enforce current availability at the write boundary, including direct API
-- requests. Lock the trip row consistently with the existing join RPC.
create or replace function public.check_join_request_trip_availability()
returns trigger language plpgsql security definer set search_path = '' as $$
declare v_trip public.matchmaking_trips%rowtype; v_count integer;
begin
  if new.status not in ('pending', 'held', 'accepted') then return new; end if;
  if tg_op = 'UPDATE' and new.status = old.status and new.trip_id = old.trip_id then return new; end if;
  select * into v_trip from public.matchmaking_trips where id = new.trip_id for update;
  if not found or v_trip.status <> 'active' then
    raise exception 'This trip is not accepting join requests';
  end if;
  if coalesce(v_trip.start_time, v_trip.start_date::timestamp at time zone 'UTC') <= now() then
    raise exception 'This trip has already started';
  end if;
  select count(*) into v_count from public.matchmaking_trip_members
    where trip_id = new.trip_id and role = 'member'
      -- The existing approval RPC inserts membership before updating status.
      and not (new.status = 'accepted' and user_id = new.applicant_id);
  if v_count >= v_trip.vacancies then raise exception 'This trip is full'; end if;
  return new;
end $$;
revoke all on function public.check_join_request_trip_availability() from public;
create trigger check_join_request_trip_availability
before insert or update on public.matchmaking_join_requests
for each row execute function public.check_join_request_trip_availability();

do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime')
    and not exists (select 1 from pg_publication_tables
      where pubname = 'supabase_realtime' and schemaname = 'public'
        and tablename = 'matchmaking_saved_trips') then
    alter publication supabase_realtime add table public.matchmaking_saved_trips;
  end if;
end $$;
