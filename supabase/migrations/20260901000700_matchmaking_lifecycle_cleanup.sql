-- Time-aware matchmaking lifecycle and self-service cleanup.

alter table public.matchmaking_trips
  add column if not exists start_time timestamptz;

update public.matchmaking_trips
set start_time = start_date::timestamp at time zone 'UTC'
where start_time is null;

create index if not exists matchmaking_trips_active_end_idx
  on public.matchmaking_trips(status, end_date);

create or replace function public.close_expired_matchmaking_trips()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count integer;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  update public.matchmaking_trips
  set status = 'closed', updated_at = now()
  where status = 'active' and end_date < current_date;
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

revoke all on function public.close_expired_matchmaking_trips() from public;
grant execute on function public.close_expired_matchmaking_trips()
  to authenticated;

create or replace function public.leave_matchmaking_trip(p_trip_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;
  if exists (
    select 1 from public.matchmaking_trips
    where id = p_trip_id and owner_id = auth.uid()
  ) then
    raise exception 'A trip creator cannot leave their own trip';
  end if;
  if not exists (
    select 1 from public.matchmaking_trip_members
    where trip_id = p_trip_id and user_id = auth.uid()
  ) then
    raise exception 'You are not a member of this trip';
  end if;

  delete from public.matchmaking_join_requests
  where trip_id = p_trip_id and applicant_id = auth.uid();

  -- Leaving is voluntary, so suppress the owner-removal notification.
  perform set_config('gobuddy.request_decision', '1', true);
  delete from public.matchmaking_trip_members
  where trip_id = p_trip_id and user_id = auth.uid();

  -- Membership sync triggers normally handle these rows. These deletes keep
  -- partially migrated databases consistent as well.
  delete from public.trip_members
  where trip_id = p_trip_id and user_id = auth.uid();
  delete from public.trip_member_roles
  where trip_id = p_trip_id and user_id = auth.uid();
end;
$$;

revoke all on function public.leave_matchmaking_trip(uuid) from public;
grant execute on function public.leave_matchmaking_trip(uuid) to authenticated;

drop function if exists public.save_matchmaking_trip(
  uuid, text, date, date, numeric, integer, text, integer, integer,
  text, text, public.trip_status, text[]
);

create or replace function public.save_matchmaking_trip(
  p_id uuid,
  p_destination text,
  p_start_date date,
  p_end_date date,
  p_start_time timestamptz,
  p_budget numeric,
  p_vacancies integer,
  p_preferred_gender text,
  p_minimum_age integer,
  p_maximum_age integer,
  p_description text,
  p_cover_image_url text,
  p_status public.trip_status,
  p_styles text[]
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid := coalesce(p_id, gen_random_uuid());
  v_existing_owner uuid;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if p_end_date < p_start_date then raise exception 'Invalid trip dates'; end if;

  if exists (
    select 1
    from public.matchmaking_trips trip
    where trip.owner_id = auth.uid()
      and trip.id <> v_id
      and trip.status <> 'closed'
      and daterange(trip.start_date, trip.end_date, '[]') &&
          daterange(p_start_date, p_end_date, '[]')
  ) then
    raise exception 'You already host a trip during this time period';
  end if;

  select owner_id into v_existing_owner
  from public.matchmaking_trips
  where id = v_id
  for update;
  if found and v_existing_owner <> auth.uid() then
    raise exception 'Only the trip owner can update this trip';
  end if;

  insert into public.matchmaking_trips (
    id, owner_id, destination, start_date, end_date, start_time, budget,
    vacancies, preferred_gender, minimum_age, maximum_age, description,
    cover_image_url, status, updated_at
  ) values (
    v_id, auth.uid(), trim(p_destination), p_start_date, p_end_date,
    coalesce(p_start_time, p_start_date::timestamp at time zone 'UTC'),
    p_budget, p_vacancies, p_preferred_gender, p_minimum_age, p_maximum_age,
    trim(p_description), nullif(trim(p_cover_image_url), ''), p_status, now()
  )
  on conflict (id) do update set
    destination = excluded.destination,
    start_date = excluded.start_date,
    end_date = excluded.end_date,
    start_time = excluded.start_time,
    budget = excluded.budget,
    vacancies = excluded.vacancies,
    preferred_gender = excluded.preferred_gender,
    minimum_age = excluded.minimum_age,
    maximum_age = excluded.maximum_age,
    description = excluded.description,
    cover_image_url = excluded.cover_image_url,
    status = excluded.status,
    updated_at = now();

  delete from public.matchmaking_trip_styles where trip_id = v_id;
  insert into public.matchmaking_trip_styles (trip_id, style)
  select v_id, style
  from (
    select distinct trim(value) as style
    from unnest(coalesce(p_styles, array[]::text[])) value
  ) styles
  where style <> '';
  return v_id;
end;
$$;

revoke all on function public.save_matchmaking_trip(
  uuid, text, date, date, timestamptz, numeric, integer, text, integer,
  integer, text, text, public.trip_status, text[]
) from public;
grant execute on function public.save_matchmaking_trip(
  uuid, text, date, date, timestamptz, numeric, integer, text, integer,
  integer, text, text, public.trip_status, text[]
) to authenticated;

notify pgrst, 'reload schema';
