-- Persist removed-trip dismissal so every signed-in device updates in real
-- time and the card stays hidden after a new session.

alter table public.matchmaking_notifications
  add column if not exists dismissed_at timestamptz;

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

  update public.matchmaking_notifications
  set dismissed_at = now(), read_at = coalesce(read_at, now())
  where user_id = auth.uid()
    and trip_id = p_trip_id
    and dismissed_at is null
    and lower(title) like '%removed%';

  if not found then
    raise exception 'Removed trip notification not found';
  end if;
end;
$$;

revoke all on function public.dismiss_removed_trip_group(uuid) from public;
grant execute on function public.dismiss_removed_trip_group(uuid)
  to authenticated;

notify pgrst, 'reload schema';
