-- A block applies in both directions throughout matchmaking. Keep this at the
-- database boundary so blocked trips cannot be recovered with a direct API
-- query and security-definer request functions cannot bypass the rule.

create or replace function public.users_are_blocked(
  p_first uuid,
  p_second uuid
)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from public.user_blocks
    where (blocker_id = p_first and blocked_id = p_second)
       or (blocker_id = p_second and blocked_id = p_first)
  );
$$;

revoke all on function public.users_are_blocked(uuid, uuid) from public;
grant execute on function public.users_are_blocked(uuid, uuid)
  to authenticated;

alter table public.matchmaking_trips enable row level security;

drop policy if exists "blocked users cannot read each other's trips"
  on public.matchmaking_trips;
create policy "blocked users cannot read each other's trips"
  on public.matchmaking_trips
  as restrictive
  for select
  to authenticated
  using (
    owner_id = auth.uid()
    or not public.users_are_blocked(auth.uid(), owner_id)
  );

create or replace function public.reject_blocked_trip_interaction()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_owner_id uuid;
begin
  select owner_id into v_owner_id
  from public.matchmaking_trips
  where id = new.trip_id;

  if public.users_are_blocked(new.applicant_id, v_owner_id) then
    raise exception 'This interaction is unavailable';
  end if;

  return new;
end;
$$;

drop trigger if exists reject_blocked_join_request
  on public.matchmaking_join_requests;
create trigger reject_blocked_join_request
before insert or update on public.matchmaking_join_requests
for each row execute function public.reject_blocked_trip_interaction();

notify pgrst, 'reload schema';

;
