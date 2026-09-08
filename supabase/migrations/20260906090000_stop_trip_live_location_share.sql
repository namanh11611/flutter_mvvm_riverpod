-- Allow a signed-in user to stop their own share for a trip. This also lets
-- the UI stop a share that was started before an app restart.
create or replace function public.stop_trip_live_location_share(p_trip_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  update public.live_location_shares
  set is_active = false
  where trip_id = p_trip_id
    and user_id = auth.uid()
    and is_active = true;
end;
$$;

revoke all on function public.stop_trip_live_location_share(uuid) from public;
grant execute on function public.stop_trip_live_location_share(uuid) to authenticated;
