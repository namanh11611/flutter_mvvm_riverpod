-- Let a removed user permanently dismiss a stale group left by older clients
-- that deleted collaboration membership without deleting matchmaking state.

create or replace function public.dismiss_removed_trip_group(
  p_trip_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;
  if public.is_trip_member(p_trip_id) then
    raise exception 'Leave or be removed from the group before dismissing it';
  end if;

  update public.matchmaking_join_requests
  set status = 'declined', updated_at = now()
  where trip_id = p_trip_id
    and applicant_id = auth.uid()
    and status in ('pending', 'held', 'accepted');

  delete from public.matchmaking_trip_members
  where trip_id = p_trip_id and user_id = auth.uid();

  delete from public.trip_member_roles
  where trip_id = p_trip_id and user_id = auth.uid();
end;
$$;

revoke all on function public.dismiss_removed_trip_group(uuid) from public;
grant execute on function public.dismiss_removed_trip_group(uuid)
  to authenticated;

notify pgrst, 'reload schema';
