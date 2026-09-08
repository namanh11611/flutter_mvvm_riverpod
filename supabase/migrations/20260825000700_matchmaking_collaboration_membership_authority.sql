-- Matchmaking membership is the source of truth for collaboration access.
-- Keep the collaboration projection synchronized for inserts and removals,
-- and repair users accepted before these triggers were installed.

create or replace function public.sync_matchmaking_member_to_collaboration()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    insert into public.trip_members (trip_id, user_id)
    values (new.trip_id, new.user_id)
    on conflict (trip_id, user_id) do nothing;
    return new;
  end if;

  -- Owners retain collaboration access through trip ownership. Ordinary
  -- members lose it when their matchmaking membership is removed.
  delete from public.trip_members membership
  where membership.trip_id = old.trip_id
    and membership.user_id = old.user_id
    and not exists (
      select 1
      from public.matchmaking_trips trip
      where trip.id = old.trip_id
        and trip.owner_id = old.user_id
    );
  return old;
end;
$$;

drop trigger if exists sync_matchmaking_trip_member_to_collaboration
  on public.matchmaking_trip_members;
create trigger sync_matchmaking_trip_member_to_collaboration
  after insert on public.matchmaking_trip_members
  for each row execute function
    public.sync_matchmaking_member_to_collaboration();

drop trigger if exists remove_matchmaking_trip_member_from_collaboration
  on public.matchmaking_trip_members;
create trigger remove_matchmaking_trip_member_from_collaboration
  after delete on public.matchmaking_trip_members
  for each row execute function
    public.sync_matchmaking_member_to_collaboration();

insert into public.trip_members (trip_id, user_id)
select id, owner_id
from public.matchmaking_trips
on conflict (trip_id, user_id) do nothing;

insert into public.trip_members (trip_id, user_id)
select trip_id, user_id
from public.matchmaking_trip_members
on conflict (trip_id, user_id) do nothing;

notify pgrst, 'reload schema';
