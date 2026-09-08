create or replace function public.delete_trip_timeline_day(
  p_trip_id uuid,
  p_day_date date,
  p_day_start timestamptz,
  p_day_end timestamptz
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_deleted_activities integer := 0;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  if not public.is_trip_member(p_trip_id) then
    raise exception 'Trip not found or access denied';
  end if;

  if p_day_end <= p_day_start
      or p_day_end - p_day_start < interval '20 hours'
      or p_day_end - p_day_start > interval '28 hours' then
    raise exception 'Invalid itinerary day range';
  end if;

  if not exists (
    select 1
    from public.trip_timeline_days
    where trip_id = p_trip_id and day_date = p_day_date
  ) and not exists (
    select 1
    from public.trip_activities
    where trip_id = p_trip_id
      and start_time >= p_day_start
      and start_time < p_day_end
  ) then
    raise exception 'Timeline day not found';
  end if;

  if not public.is_trip_creator(p_trip_id) and exists (
    select 1
    from public.trip_activities
    where trip_id = p_trip_id
      and start_time >= p_day_start
      and start_time < p_day_end
      and is_locked
  ) then
    raise exception 'Only the trip creator can delete a day with locked activities';
  end if;

  delete from public.trip_activities
  where trip_id = p_trip_id
    and start_time >= p_day_start
    and start_time < p_day_end;
  get diagnostics v_deleted_activities = row_count;

  delete from public.trip_timeline_days
  where trip_id = p_trip_id and day_date = p_day_date;

  return v_deleted_activities;
end;
$$;

revoke all on function public.delete_trip_timeline_day(
  uuid,
  date,
  timestamptz,
  timestamptz
) from public;
grant execute on function public.delete_trip_timeline_day(
  uuid,
  date,
  timestamptz,
  timestamptz
) to authenticated;
