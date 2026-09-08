-- Return persisted itinerary days through the same authoritative membership
-- check used to enter the collaboration workspace. This prevents a member
-- from receiving an empty timeline because of account-specific table-policy
-- visibility while retaining explicit authorization on every request.

create or replace function public.get_trip_timeline_days(p_trip_id uuid)
returns table (
  trip_id uuid,
  day_date date
)
language plpgsql
security definer
stable
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;
  if not public.is_trip_member(p_trip_id) then
    raise exception 'Not permitted to view this trip itinerary';
  end if;

  return query
  select timeline.trip_id, timeline.day_date
  from public.trip_timeline_days as timeline
  where timeline.trip_id = p_trip_id
  order by timeline.day_date;
end;
$$;

revoke all on function public.get_trip_timeline_days(uuid) from public;
grant execute on function public.get_trip_timeline_days(uuid) to authenticated;

notify pgrst, 'reload schema';
