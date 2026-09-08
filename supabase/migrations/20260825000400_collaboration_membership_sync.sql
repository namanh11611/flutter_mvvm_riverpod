-- Keep collaboration membership aligned with newly created matchmaking trips.

create or replace function public.add_collaboration_owner_for_matchmaking_trip()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.trip_members (trip_id, user_id)
  values (new.id, new.owner_id)
  on conflict (trip_id, user_id) do nothing;
  return new;
end;
$$;

drop trigger if exists sync_matchmaking_trip_owner_to_collaboration on public.matchmaking_trips;
create trigger sync_matchmaking_trip_owner_to_collaboration
  after insert on public.matchmaking_trips
  for each row execute procedure public.add_collaboration_owner_for_matchmaking_trip();

-- Backfill collaboration membership for trips created after the first migration.
insert into public.trip_members (trip_id, user_id)
select id, owner_id from public.matchmaking_trips
on conflict (trip_id, user_id) do nothing;
