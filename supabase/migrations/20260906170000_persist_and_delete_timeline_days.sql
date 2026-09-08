-- Timeline tabs must represent real trip_timeline_days records. Backfill the
-- original trip date range, keep new trip ranges in sync, and delete days by
-- the table's actual composite primary key: (trip_id, day_date).

insert into public.trip_timeline_days (trip_id, day_date, created_by)
select
  trip.id,
  generated.day_date::date,
  trip.owner_id
from public.matchmaking_trips as trip
cross join lateral generate_series(
  trip.start_date::timestamp,
  trip.end_date::timestamp,
  interval '1 day'
) as generated(day_date)
where trip.start_date is not null
  and trip.end_date is not null
  and trip.end_date >= trip.start_date
on conflict (trip_id, day_date) do nothing;

create or replace function public.sync_matchmaking_trip_timeline_days()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.start_date is null
      or new.end_date is null
      or new.end_date < new.start_date then
    return new;
  end if;

  insert into public.trip_timeline_days (trip_id, day_date, created_by)
  select new.id, generated.day_date::date, new.owner_id
  from generate_series(
    new.start_date::timestamp,
    new.end_date::timestamp,
    interval '1 day'
  ) as generated(day_date)
  on conflict (trip_id, day_date) do nothing;

  return new;
end;
$$;

drop trigger if exists sync_matchmaking_trip_timeline_days
  on public.matchmaking_trips;
create trigger sync_matchmaking_trip_timeline_days
after insert or update of start_date, end_date on public.matchmaking_trips
for each row
execute function public.sync_matchmaking_trip_timeline_days();

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
  v_deleted_day integer := 0;
  v_deleted_activities integer := 0;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;
  if not public.is_trip_admin(p_trip_id) then
    raise exception 'Only a trip admin can delete itinerary days';
  end if;
  if p_day_end <= p_day_start
      or p_day_end - p_day_start < interval '20 hours'
      or p_day_end - p_day_start > interval '28 hours' then
    raise exception 'Invalid itinerary day range';
  end if;

  -- Delete by the real composite record key, never by the UI tab index.
  delete from public.trip_timeline_days
  where trip_id = p_trip_id
    and day_date = p_day_date;
  get diagnostics v_deleted_day = row_count;

  -- Realtime updates or repeated taps can leave the client with a stale tab.
  -- Treat that as an idempotent no-op instead of raising P0001.
  if v_deleted_day = 0 then
    return 0;
  end if;

  delete from public.trip_activities
  where trip_id = p_trip_id
    and start_time >= p_day_start
    and start_time < p_day_end;
  get diagnostics v_deleted_activities = row_count;

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
