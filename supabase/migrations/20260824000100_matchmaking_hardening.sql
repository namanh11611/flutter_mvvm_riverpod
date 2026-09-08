-- Save a trip and its styles as one owner-authorized transaction.
create or replace function public.save_matchmaking_trip(
  p_id uuid,
  p_destination text,
  p_start_date date,
  p_end_date date,
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
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  select owner_id into v_existing_owner
  from public.matchmaking_trips
  where id = v_id
  for update;

  if found and v_existing_owner <> auth.uid() then
    raise exception 'Only the trip owner can update this trip';
  end if;

  insert into public.matchmaking_trips (
    id, owner_id, destination, start_date, end_date, budget, vacancies,
    preferred_gender, minimum_age, maximum_age, description,
    cover_image_url, status, updated_at
  ) values (
    v_id, auth.uid(), trim(p_destination), p_start_date, p_end_date,
    p_budget, p_vacancies, p_preferred_gender, p_minimum_age,
    p_maximum_age, trim(p_description), nullif(trim(p_cover_image_url), ''),
    p_status, now()
  )
  on conflict (id) do update set
    destination = excluded.destination,
    start_date = excluded.start_date,
    end_date = excluded.end_date,
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
  uuid, text, date, date, numeric, integer, text, integer, integer,
  text, text, public.trip_status, text[]
) from public;
grant execute on function public.save_matchmaking_trip(
  uuid, text, date, date, numeric, integer, text, integer, integer,
  text, text, public.trip_status, text[]
) to authenticated;

-- Applicants may cancel only their own non-accepted request. Removing it
-- allows a later request without conflicting with (trip, applicant).
create or replace function public.cancel_matchmaking_join_request(
  p_request_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  delete from public.matchmaking_join_requests
  where id = p_request_id
    and applicant_id = auth.uid()
    and status in ('pending', 'held');

  if not found then
    raise exception 'Request cannot be cancelled';
  end if;
end;
$$;

revoke all on function public.cancel_matchmaking_join_request(uuid)
  from public;
grant execute on function public.cancel_matchmaking_join_request(uuid)
  to authenticated;
